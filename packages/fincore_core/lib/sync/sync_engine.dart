import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import '../common/domain_primitives.dart';
import '../context/tenant_context.dart';
import '../database/fincore_database.dart';
import 'outbox_service.dart';
import '../src/logging/log_service.dart';

typedef ServerPushHandler = Future<bool> Function(OutboxEntry entry);

/// Resultado estruturado do ciclo de PUSH.
///
/// Usado pelo router para decidir se é seguro executar o PULL:
/// - [successCount]: quantas entradas foram sincronizadas com sucesso
/// - [failureCount]: quantas entradas falharam (após o máximo de tentativas ou erro fatal)
/// - [hasPendingAfter]: true se ainda restar alguma entrada pendente/retrying após o ciclo
///   → quando true, o router NÃO deve executar o PULL (Modo Degradado)
class SyncResult {
  final int successCount;
  final int failureCount;
  final bool hasPendingAfter;
  final int initialPendingCount;
  final int durationMs;

  const SyncResult({
    required this.successCount,
    required this.failureCount,
    required this.hasPendingAfter,
    this.initialPendingCount = 0,
    this.durationMs = 0,
  });

  /// Conveniência: retorna true se o push foi totalmente bem-sucedido e o outbox está vazio.
  bool get isClean => failureCount == 0 && !hasPendingAfter;

  @override
  String toString() =>
      'SyncResult(ok=$successCount, fail=$failureCount, pendingBefore=$initialPendingCount, pendingAfter=$hasPendingAfter, time=${durationMs}ms)';
}

class SyncEngine {
  final OutboxService outboxService;
  final TenantContext context;
  final FincoreDatabase db;
  final ServerPushHandler? serverPushHandler;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;
  Timer? _autoSyncTimer;

  SyncEngine({
    required this.outboxService,
    required this.context,
    required this.db,
    this.serverPushHandler,
    bool autoStart = true,
    Duration autoSyncInterval = const Duration(seconds: 30),
  }) {
    if (autoStart) {
      startAutoSync(interval: autoSyncInterval);
    }
  }

  /// Inicia o timer autônomo de sincronização periódica da fila Outbox.
  void startAutoSync({Duration interval = const Duration(seconds: 30)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) async {
      if (context.hasContext && !_isProcessing) {
        try {
          final hasPending = !(await outboxService.isOutboxEmpty());
          if (hasPending) {
            await processPendingQueue();
          }
        } catch (_) {}
      }
    });
  }

  /// Para o timer autônomo.
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Executa o ciclo de sincronização das transações pendentes no Outbox.
  ///
  /// Retorna um [SyncResult] com o resultado detalhado:
  /// - [SyncResult.isClean] == true → seguro para fazer PULL
  /// - [SyncResult.hasPendingAfter] == true → modo degradado, NÃO faça PULL
  Future<SyncResult> processPendingQueue() async {
    if (!context.hasContext) {
      throw ContextStateError('Nenhum contexto de tenant ativo para sincronização.');
    }

    if (_isProcessing) {
      return const SyncResult(
        successCount: 0,
        failureCount: 0,
        hasPendingAfter: false,
        initialPendingCount: 0,
        durationMs: 0,
      );
    }
    _isProcessing = true;

    final overallStart = DateTime.now();
    int successCount = 0;
    int failureCount = 0;
    int initialCount = 0;

    final traceId = CorrelationIdGenerator.generateCorrelationId();

    try {
      await outboxService.retryFailedEntries();
      final entries = await outboxService.getPendingEntries();
      initialCount = entries.length;

      // Ordenação topológica para evitar erro 23503 (FK Violation) no Supabase:
      // Entidades Pai (Cliente, Categoria, TabelaPrecificacao) são sincronizadas
      // antes de Entidades Filhas (LocalEntrega, ItemTabelaPrecificacao, etc.).
      entries.sort((a, b) {
        final pA = _getEntityPriority(a.entity);
        final pB = _getEntityPriority(b.entity);
        if (pA != pB) return pA.compareTo(pB);
        return a.createdAt.compareTo(b.createdAt);
      });

      if (entries.isNotEmpty) {
        await LogService.instance.logSync(
          step: 'PREPARACAO',
          action: 'INICIO',
          traceId: traceId,
          status: LogStatus.inProgress,
          message: 'Fila de envio: $initialCount registro(s) pendente(s) - iniciando sincronização com a nuvem',
          tenantId: context.hasContext ? context.tenantId : null,
        );
      }

      final Set<String> failedEntityKeys = {};

      for (final entry in entries) {
        final startTime = DateTime.now();
        String entryTraceId = traceId;
        try {
          final payloadMap = jsonDecode(entry.payload) as Map<String, dynamic>;
          if (payloadMap.containsKey('_traceId') && payloadMap['_traceId'] != null) {
            entryTraceId = payloadMap['_traceId'].toString();
          }
        } catch (_) {}

        // ── VERIFICAÇÃO DE DEPENDÊNCIA DE ENTIDADE FALTANTE ───────
        if (_isBlockedByDependency(entry, failedEntityKeys)) {
          await LogService.instance.logSync(
            step: 'PUSH',
            action: 'BLOQUEADO',
            entity: entry.entity,
            id: entry.entityId,
            traceId: entryTraceId,
            status: LogStatus.skipped,
            errorMessage: 'Depende de registro pai com falha. PUSH adiado.',
            tenantId: context.hasContext ? context.tenantId : null,
          );
          continue;
        }

        await LogService.instance.logSync(
          step: 'PUSH',
          action: 'INICIO',
          entity: entry.entity,
          id: entry.entityId,
          traceId: entryTraceId,
          attempt: entry.attemptsCount + 1,
          status: LogStatus.inProgress,
          tenantId: context.hasContext ? context.tenantId : null,
        );
        await outboxService.updateStatus(entry.id, SyncStatus.processing);

        bool pushSuccess = false;
        String? pushError;

        try {
          if (serverPushHandler != null) {
            pushSuccess = await serverPushHandler!(entry);
          } else {
            pushSuccess = true;
          }
        } catch (e) {
          pushSuccess = false;
          pushError = e.toString();
        }

        if (pushSuccess) {
          final duration = DateTime.now().difference(startTime).inMilliseconds;
          await LogService.instance.logSync(
            step: 'PUSH',
            action: 'RESULTADO',
            entity: entry.entity,
            id: entry.entityId,
            traceId: entryTraceId,
            attempt: entry.attemptsCount + 1,
            durationMs: duration,
            status: LogStatus.success,
            tenantId: context.hasContext ? context.tenantId : null,
          );
          await outboxService.updateStatus(entry.id, SyncStatus.synced);
          await _updateSourceTableSyncStatus(entry);
          successCount++;
        } else {
          final pushErrorStr = pushError ?? 'Falha genérica no envio remoto';
          final isNetworkOffline = pushErrorStr.contains('OfflineSyncException') ||
              pushErrorStr.contains('SocketException') ||
              pushErrorStr.contains('Sem conexão');
          final isPermanent = _isPermanentError(pushErrorStr);
          final errCode = _extractErrorCode(pushErrorStr);
          final errReason = _classifyErrorReason(pushErrorStr);

          if (isNetworkOffline) {
            await outboxService.updateStatus(
              entry.id,
              SyncStatus.retrying,
              errorMessage: pushErrorStr,
            );
            failureCount++;
            await LogService.instance.logSync(
              step: 'PUSH',
              action: 'RESULTADO',
              entity: entry.entity,
              id: entry.entityId,
              traceId: entryTraceId,
              attempt: entry.attemptsCount + 1,
              status: LogStatus.retrying,
              errorCode: 'NETWORK_OFFLINE',
              errorReason: 'OFFLINE_SEM_CONEXAO',
              errorMessage: 'Conexão interrompida. Envio da fila pausado temporariamente.',
              tenantId: context.hasContext ? context.tenantId : null,
            );
            break; // Interrompe o envio sequencial se não há rede
          } else if (isPermanent) {
            // Falha de schema/constraint: marca falha permanente imediatamente (sem 5 retries ineficientes)
            await outboxService.updateStatus(
              entry.id,
              SyncStatus.failed,
              errorMessage: pushErrorStr,
            );
            failedEntityKeys.add('${entry.entity}:${entry.entityId}');
            failureCount++;

            await LogService.instance.logSync(
              step: 'PUSH',
              action: 'RESULTADO',
              entity: entry.entity,
              id: entry.entityId,
              traceId: entryTraceId,
              attempt: entry.attemptsCount + 1,
              status: LogStatus.failed,
              errorCode: errCode,
              errorReason: errReason,
              errorMessage: pushErrorStr,
              tenantId: context.hasContext ? context.tenantId : null,
            );
          } else {
            final attempts = entry.attemptsCount + 1;
            final nextStatus = attempts >= 5 ? SyncStatus.failed : SyncStatus.retrying;
            if (nextStatus == SyncStatus.failed) {
              failedEntityKeys.add('${entry.entity}:${entry.entityId}');
            }

            await LogService.instance.logSync(
              step: 'PUSH',
              action: 'RESULTADO',
              entity: entry.entity,
              id: entry.entityId,
              traceId: entryTraceId,
              attempt: attempts,
              maxAttempts: 5,
              status: nextStatus == SyncStatus.failed ? LogStatus.failed : LogStatus.retrying,
              errorCode: errCode,
              errorReason: errReason,
              errorMessage: pushErrorStr,
              tenantId: context.hasContext ? context.tenantId : null,
            );

            if (pushErrorStr.contains('23503') || pushErrorStr.contains('violates foreign key constraint')) {
              await _autoHealMissingParent(entry);
            }

            await outboxService.updateStatus(
              entry.id,
              nextStatus,
              errorMessage: pushErrorStr,
            );
            failureCount++;
          }
        }
      }
    } finally {
      _isProcessing = false;
    }

    final durationMs = DateTime.now().difference(overallStart).inMilliseconds;
    final hasPendingAfter = !(await outboxService.isOutboxEmpty());

    final statusStr = hasPendingAfter
        ? 'Ainda há pendências locais - recebimento remoto suspenso'
        : 'Fila local limpa, pronto para recebimento de atualizações da nuvem';

    if (initialCount > 0) {
      final cycleStatus = (hasPendingAfter || failureCount > 0)
          ? (successCount > 0 ? LogStatus.partial : LogStatus.failed)
          : LogStatus.success;

      await LogService.instance.logSync(
        step: 'FINALIZACAO',
        action: 'CONCLUIDO',
        traceId: traceId,
        status: cycleStatus,
        durationMs: durationMs,
        message: 'Enviados: $successCount | Falhas: $failureCount | Pendentes: ${hasPendingAfter ? "SIM" : "0"} | $statusStr',
        tenantId: context.hasContext ? context.tenantId : null,
      );
    }

    return SyncResult(
      successCount: successCount,
      failureCount: failureCount,
      hasPendingAfter: hasPendingAfter,
      initialPendingCount: initialCount,
      durationMs: durationMs,
    );
  }

  /// Atualiza o `syncStatus` e `lastSyncedAt` na tabela de origem da entidade
  /// após um push bem-sucedido. Isso garante que cada registro saiba quando
  /// foi sincronizado pela última vez com a nuvem.
  Future<void> _updateSourceTableSyncStatus(OutboxEntry entry) async {
    final now = DateTime.now();
    final syncedStatus = SyncStatus.synced;
    final entityId = entry.entityId;

    try {
      switch (entry.entity) {
        case 'Cliente':
        case 'clientes':
          await (db.update(db.clientesTable)
                ..where((t) => t.id.equals(entityId)))
              .write(ClientesTableCompanion(
            syncStatus: Value(syncedStatus),
            lastSyncedAt: Value(now),
          ));
          break;
        case 'Produto':
        case 'produtos':
          await (db.update(db.produtosTable)
                ..where((t) => t.id.equals(entityId)))
              .write(ProdutosTableCompanion(
            syncStatus: Value(syncedStatus),
            lastSyncedAt: Value(now),
          ));
          break;
        case 'Categoria':
        case 'categorias':
          await (db.update(db.categoriasTable)
                ..where((t) => t.id.equals(entityId)))
              .write(CategoriasTableCompanion(
            syncStatus: Value(syncedStatus),
            lastSyncedAt: Value(now),
          ));
          break;
        case 'Empresa':
          await (db.update(db.empresasTable)
                ..where((t) => t.id.equals(entityId)))
              .write(EmpresasTableCompanion(
            syncStatus: Value(syncedStatus),
            lastSyncedAt: Value(now),
          ));
          break;
        case 'TabelaPrecificacao':
        case 'tabelas_precificacao':
          await (db.update(db.tabelasPrecificacaoTable)
                ..where((t) => t.id.equals(entityId)))
              .write(TabelasPrecificacaoTableCompanion(
            syncStatus: Value(syncedStatus),
            lastSyncedAt: Value(now),
          ));
          break;
        case 'ItemTabelaPrecificacao':
        case 'itens_tabela_precificacao':
          await (db.update(db.itensTabelaPrecificacaoTable)
                ..where((t) => t.id.equals(entityId)))
              .write(ItensTabelaPrecificacaoTableCompanion(
            syncStatus: Value(syncedStatus),
            lastSyncedAt: Value(now),
          ));
          break;
        case 'ProdutoTabelaPrecificacao':
        case 'produtos_tabelas_precificacao':
          await (db.update(db.produtosTabelasPrecificacaoTable)
                ..where((t) => t.id.equals(entityId)))
              .write(ProdutosTabelasPrecificacaoTableCompanion(
            syncStatus: Value(syncedStatus),
            lastSyncedAt: Value(now),
          ));
          break;
        case 'FormaPagamento':
        case 'formas_pagamento':
          await (db.update(db.formasPagamentoTable)
                ..where((t) => t.id.equals(entityId)))
              .write(FormasPagamentoTableCompanion(
            syncStatus: Value(syncedStatus),
            lastSyncedAt: Value(now),
          ));
          break;
        case 'LocalEntrega':
        case 'locais_entrega':
          await (db.update(db.locaisEntregaTable)
                ..where((t) => t.id.equals(entityId)))
              .write(LocaisEntregaTableCompanion(
            syncStatus: Value(syncedStatus),
            lastSyncedAt: Value(now),
          ));
          break;
        case 'TaxaEntrega':
        case 'taxas_entrega':
          await (db.update(db.taxasEntregaTable)
                ..where((t) => t.id.equals(entityId)))
              .write(TaxasEntregaTableCompanion(
            syncStatus: Value(syncedStatus),
            lastSyncedAt: Value(now),
          ));
          break;
        case 'OrdemPreparo':
          await (db.update(db.ordensPreparoTable)
                ..where((t) => t.id.equals(entityId)))
              .write(OrdensPreparoTableCompanion(
            syncStatus: Value(syncedStatus),
            lastSyncedAt: Value(now),
          ));
          break;
        case 'HistoricoOrdemPreparo':
        case 'historicos_ordem_preparo':
        case 'historico_ordem_preparo':
          await (db.update(db.historicosOrdemPreparoTable)
                ..where((t) => t.id.equals(entityId)))
              .write(HistoricosOrdemPreparoTableCompanion(
            syncStatus: Value(syncedStatus),
            lastSyncedAt: Value(now),
          ));
          break;

        case 'Pedido':
        case 'pedidos':
          await (db.update(db.pedidosTable)..where((t) => t.id.equals(entityId)))
              .write(PedidosTableCompanion(syncStatus: Value(syncedStatus), lastSyncedAt: Value(now)));
          break;
        case 'ItensPedido':
        case 'itens_pedido':
          await (db.update(db.itensPedidoTable)..where((t) => t.id.equals(entityId)))
              .write(ItensPedidoTableCompanion(syncStatus: Value(syncedStatus), lastSyncedAt: Value(now)));
          break;
        case 'estoque_produto':
        case 'EstoqueProduto':
          await (db.update(db.estoqueProdutosTable)..where((t) => t.id.equals(entityId)))
              .write(EstoqueProdutosTableCompanion(syncStatus: Value(syncedStatus), lastSyncedAt: Value(now)));
          break;
        case 'movimentacao_estoque':
        case 'MovimentacaoEstoque':
          await (db.update(db.movimentacoesEstoqueTable)..where((t) => t.id.equals(entityId)))
              .write(MovimentacoesEstoqueTableCompanion(syncStatus: Value(syncedStatus), lastSyncedAt: Value(now)));
          break;
        case 'sessao_caixa':
        case 'SessaoCaixa':
          await (db.update(db.sessoesCaixaTable)..where((t) => t.id.equals(entityId)))
              .write(SessoesCaixaTableCompanion(syncStatus: Value(syncedStatus), lastSyncedAt: Value(now)));
          break;
        case 'lancamento_financeiro':
        case 'LancamentoFinanceiro':
          await (db.update(db.lancamentosFinanceirosTable)..where((t) => t.id.equals(entityId)))
              .write(LancamentosFinanceirosTableCompanion(syncStatus: Value(syncedStatus), lastSyncedAt: Value(now)));
          break;
        case 'planejamento_producao':
        case 'PlanoProducao':
          await (db.update(db.planejamentoProducaoTable)..where((t) => t.id.equals(entityId)))
              .write(PlanejamentoProducaoTableCompanion(syncStatus: Value(syncedStatus), lastSyncedAt: Value(now)));
          break;
        case 'empresa_configuracao':
          await (db.update(db.empresaConfiguracaoTable)
                ..where((t) => t.id.equals(entityId)))
              .write(EmpresaConfiguracaoTableCompanion(
            syncStatus: Value(syncedStatus),
            lastSyncedAt: Value(now),
          ));
          break;
        default:
          // Entidade desconhecida — ignora silenciosamente
          break;
      }
    } catch (e) {
      // Falha ao atualizar a tabela de origem não deve impedir o fluxo do outbox.
      // O status no outbox já foi marcado como synced.
    }
  }

  /// Retorna a prioridade topológica da entidade para push no Outbox.
  /// Menor valor = enviado primeiro. Isso evita violação de Foreign Key (FK 23503).
  int _getEntityPriority(String entity) {
    switch (entity) {
      case 'Empresa':
      case 'empresa':
      case 'empresa_configuracao':
        return 1;
      case 'Categoria':
      case 'categoria':
        return 2;
      case 'TabelaPrecificacao':
      case 'tabela_precificacao':
        return 3;
      case 'TaxaEntrega':
      case 'taxa_entrega':
      case 'taxas_entrega':
        return 4;
      case 'FormaPagamento':
      case 'forma_pagamento':
      case 'formas_pagamento':
        return 5;
      case 'Cliente':
      case 'cliente':
      case 'clientes':
        return 6; // PAI de LocalEntrega e Pedido
      case 'Produto':
      case 'produto':
      case 'produtos':
        return 7; // PAI de ItemPedido e PlanoProducao
      case 'usuarios':
      case 'usuario':
      case 'Usuario':
        return 8; // PAI de MembroEmpresa — enviado antes!
      case 'Pedido':
      case 'pedido':
      case 'pedidos':
        return 10; // PAI de ItemPedido — enviado ANTES dos itens!
      case 'OrdemPreparo':
      case 'ordem_preparo':
      case 'ordens_preparo':
        return 11; // PAI de HistoricoOrdemPreparo
      case 'Caixa':
      case 'caixa':
      case 'caixas':
        return 12;
      case 'EstoqueProduto':
      case 'estoque_produto':
        return 13;
      case 'sessao_caixa':
      case 'SessaoCaixa':
      case 'sessoes_caixa':
        return 14; // PAI de LancamentoFinanceiro — enviado ANTES dos lançamentos!
      case 'LocalEntrega':
      case 'local_entrega':
      case 'locais_entrega':
        return 20; // FILHO de Cliente — DEVE ser enviado DEPOIS do Cliente!
      case 'ItemTabelaPrecificacao':
      case 'item_tabela_precificacao':
        return 21;
      case 'ProdutoTabelaPrecificacao':
      case 'produto_tabela_precificacao':
        return 22;
      case 'membros_empresa':
      case 'membro_empresa':
      case 'MembroEmpresa':
        return 25; // FILHO de Usuario e Empresa
      case 'planejamento_producao':
      case 'PlanoProducao':
        return 30; // FILHO de Produto
      case 'ItemPedido':
      case 'item_pedido':
      case 'itens_pedido':
        return 40; // FILHO de Pedido — DEVE ser enviado DEPOIS do Pedido!
      case 'HistoricoOrdemPreparo':
      case 'historico_ordem_preparo':
      case 'historicos_ordem_preparo':
        return 41; // FILHO de OrdemPreparo
      case 'MovimentacaoCaixa':
      case 'movimentacao_caixa':
      case 'movimentacoes_caixa':
        return 42;
      case 'MovimentacaoEstoque':
      case 'movimentacao_estoque':
        return 43;
      case 'lancamento_financeiro':
      case 'LancamentoFinanceiro':
      case 'lancamentos_financeiros':
        return 44; // FILHO de SessaoCaixa e Pedido — DEVE ser enviado DEPOIS!
      default:
        return 50;
    }
  }

  bool _isPermanentError(String errorMsg) {
    final lower = errorMsg.toLowerCase();
    // Erros RLS (42501) e FK Constraint (23503 - pai ainda não sincronizado) NÃO são falhas permanentes de schema.
    if (lower.contains('row-level security') ||
        lower.contains('42501') ||
        lower.contains('violates foreign key constraint') ||
        lower.contains('23503') ||
        lower.contains('23505')) {
      return false;
    }
    return lower.contains('postgrestexception') ||
        lower.contains('pgrst') ||
        lower.contains('column') ||
        lower.contains('does not exist') ||
        lower.contains('schema cache') ||
        lower.contains('syntax error') ||
        lower.contains('bad request');
  }

  bool _isBlockedByDependency(OutboxEntry entry, Set<String> failedEntityKeys) {
    if (failedEntityKeys.isEmpty) return false;

    final payload = entry.payload;

    if (entry.entity == 'locais_entrega' || entry.entity == 'LocalEntrega') {
      for (final key in failedEntityKeys) {
        if (key.startsWith('clientes:') || key.startsWith('Cliente:')) {
          final parentId = key.split(':').last;
          if (payload.contains(parentId)) return true;
        }
      }
    }

    if (entry.entity == 'itens_tabela_precificacao' || entry.entity == 'ItemTabelaPrecificacao') {
      for (final key in failedEntityKeys) {
        if (key.startsWith('tabelas_precificacao:') || key.startsWith('TabelaPrecificacao:')) {
          final parentId = key.split(':').last;
          if (payload.contains(parentId)) return true;
        }
      }
    }

    if (entry.entity == 'itens_pedido' || entry.entity == 'item_pedido' || entry.entity == 'ItensPedido') {
      for (final key in failedEntityKeys) {
        if (key.startsWith('pedidos:') || key.startsWith('pedido:') || key.startsWith('Pedido:')) {
          final parentId = key.split(':').last;
          if (payload.contains(parentId)) return true;
        }
      }
    }

    if (entry.entity == 'historicos_ordem_preparo' || entry.entity == 'historico_ordem_preparo' || entry.entity == 'HistoricoOrdemPreparo') {
      for (final key in failedEntityKeys) {
        if (key.startsWith('ordens_preparo:') || key.startsWith('ordem_preparo:') || key.startsWith('OrdemPreparo:')) {
          final parentId = key.split(':').last;
          if (payload.contains(parentId)) return true;
        }
      }
    }

    if (entry.entity == 'lancamento_financeiro' || entry.entity == 'LancamentoFinanceiro' || entry.entity == 'lancamentos_financeiros') {
      for (final key in failedEntityKeys) {
        if (key.startsWith('sessao_caixa:') || key.startsWith('SessaoCaixa:') || key.startsWith('sessoes_caixa:')) {
          final parentId = key.split(':').last;
          if (payload.contains(parentId)) return true;
        }
      }
    }

    return false;
  }

  /// Auto-recuperação de entidade pai ausente na nuvem.
  /// Quando um filho (ex: item_pedido, lancamento_financeiro) falha com erro de FK (23503),
  /// este método verifica se o pai (ex: Pedido, SessaoCaixa) existe no SQLite local
  /// e o re-enfileira no Outbox para subir no próximo ciclo.
  Future<void> _autoHealMissingParent(OutboxEntry entry) async {
    try {
      final entityLower = entry.entity.toLowerCase();
      final payloadMap = jsonDecode(entry.payload) as Map<String, dynamic>?;
      if (payloadMap == null) return;

      if (entityLower.contains('item_pedido') || entityLower.contains('itens_pedido')) {
        final parentId = payloadMap['pedidoId'] as String?;
        if (parentId != null && parentId.isNotEmpty) {
          final parentRow = await (db.select(db.pedidosTable)
                ..where((t) => t.id.equals(parentId)))
              .getSingleOrNull();

          if (parentRow != null) {
            await outboxService.enqueue(
              entity: 'Pedido',
              entityId: parentRow.id,
              action: 'UPSERT',
              payload: {
                'id': parentRow.id,
                'tenantId': parentRow.tenantId,
                'clienteId': parentRow.clienteId,
                'clienteNomeAvulso': parentRow.clienteNomeAvulso,
                'clienteTelefoneAvulso': parentRow.clienteTelefoneAvulso,
                'tipoLogistica': parentRow.tipoLogistica,
                'valorSubtotalCentavos': parentRow.valorSubtotalCentavos,
                'valorTaxaEntregaCentavos': parentRow.valorTaxaEntregaCentavos,
                'valorTotalCentavos': parentRow.valorTotalCentavos,
                'formaPagamentoId': parentRow.formaPagamentoId,
                'formaPagamentoNome': parentRow.formaPagamentoNome,
                'trocoParaCentavos': parentRow.trocoParaCentavos,
                'observacoes': parentRow.observacoes,
                'status': parentRow.status,
                'canalOrigem': parentRow.canalOrigem,
                'operadorId': parentRow.operadorId,
                'dataHoraCriacao': parentRow.dataHoraCriacao.toIso8601String(),
                if (parentRow.dataHoraEntregaPrevista != null)
                  'dataHoraEntregaPrevista': parentRow.dataHoraEntregaPrevista!.toIso8601String(),
                'numeroPedido': parentRow.numeroPedido,
                'enderecoJson': parentRow.enderecoJson,
                'syncVersion': parentRow.syncVersion,
                'createdAt': parentRow.createdAt.toIso8601String(),
                'updatedAt': parentRow.updatedAt.toIso8601String(),
                'createdBy': parentRow.createdBy,
                'updatedBy': parentRow.updatedBy,
              },
              version: parentRow.syncVersion,
            );
            LogService.instance.info(
              LogModule.sync,
              '[AUTO-HEAL] Re-enfileirado Pedido pai (ID: ${parentRow.id.length > 8 ? parentRow.id.substring(0, 8) : parentRow.id}...) no Outbox para resolver pendencia de itens.',
            );
          }
        }
      }

      if (entityLower.contains('lancamento_financeiro')) {
        final sessaoId = payloadMap['sessaoCaixaId'] as String?;
        if (sessaoId != null && sessaoId.isNotEmpty) {
          final sessaoRow = await (db.select(db.sessoesCaixaTable)
                ..where((t) => t.id.equals(sessaoId)))
              .getSingleOrNull();

          if (sessaoRow != null) {
            await outboxService.enqueue(
              entity: 'sessao_caixa',
              entityId: sessaoRow.id,
              action: 'UPSERT',
              payload: {
                'id': sessaoRow.id,
                'tenantId': sessaoRow.tenantId,
                'operadorId': sessaoRow.operadorId,
                'operadorNome': sessaoRow.operadorNome,
                'status': sessaoRow.status,
                'dataAbertura': sessaoRow.dataAbertura.toIso8601String(),
                if (sessaoRow.dataFechamento != null)
                  'dataFechamento': sessaoRow.dataFechamento!.toIso8601String(),
                'valorAberturaCentavos': sessaoRow.valorAberturaCentavos,
                'valorFechamentoCentavos': sessaoRow.valorFechamentoCentavos,
                'totalVendasCentavos': sessaoRow.totalVendasCentavos,
                'totalDespesasCentavos': sessaoRow.totalDespesasCentavos,
                'diferencaCentavos': sessaoRow.diferencaCentavos,
                'observacoes': sessaoRow.observacoes,
                'syncVersion': sessaoRow.syncVersion,
                'createdAt': sessaoRow.createdAt.toIso8601String(),
                'updatedAt': sessaoRow.updatedAt.toIso8601String(),
                'createdBy': sessaoRow.createdBy,
                'updatedBy': sessaoRow.updatedBy,
              },
              version: sessaoRow.syncVersion,
            );
            LogService.instance.info(
              LogModule.sync,
              '[AUTO-HEAL] Re-enfileirada SessaoCaixa pai (ID: ${sessaoRow.id.length > 8 ? sessaoRow.id.substring(0, 8) : sessaoRow.id}...) no Outbox para resolver FK de lancamento financeiro.',
            );
          }
        }
      }
    } catch (_) {}
  }

  String _extractErrorCode(String errorStr) {
    if (errorStr.contains('42501')) return '42501';
    if (errorStr.contains('23503')) return '23503';
    if (errorStr.contains('23505')) return '23505';
    if (errorStr.contains('22P02')) return '22P02';
    if (errorStr.contains('PGRST204')) return 'PGRST204';
    if (errorStr.contains('SocketException') || errorStr.contains('OfflineSyncException')) return 'NETWORK_OFFLINE';
    final match = RegExp(r'\b([0-9]{5}|PGRST[0-9]{3})\b').firstMatch(errorStr);
    if (match != null) return match.group(1)!;
    return 'ERR_PUSH';
  }

  String _classifyErrorReason(String errorStr) {
    if (errorStr.contains('42501') || errorStr.contains('row-level security') || errorStr.contains('permission denied')) {
      return 'RLS_POLICY_DENIED';
    }
    if (errorStr.contains('23503') || errorStr.contains('foreign key constraint')) {
      return 'FOREIGN_KEY_VIOLATION';
    }
    if (errorStr.contains('23505') || errorStr.contains('unique constraint')) {
      return 'UNIQUE_VIOLATION';
    }
    if (errorStr.contains('PGRST204') || errorStr.contains('Could not find')) {
      return 'SCHEMA_COLUMN_MISSING';
    }
    if (errorStr.contains('OfflineSyncException') || errorStr.contains('SocketException') || errorStr.contains('Sem conexão')) {
      return 'NETWORK_OFFLINE';
    }
    return 'GENERIC_PUSH_ERROR';
  }

  String _parseSyncError(String errorMsg) {
    if (errorMsg.contains('OfflineSyncException') ||
        errorMsg.contains('Sem conexão com o servidor') ||
        errorMsg.contains('SocketException')) {
      return '''Sem conexão com o servidor.
Banco: Supabase
Ação: Nova tentativa automática ao restabelecer a conexão.''';
    }
    if (errorMsg.contains('code: 23502') || errorMsg.contains('violates not-null constraint')) {
      final match = RegExp(r'column "(.+?)"').firstMatch(errorMsg);
      final colName = match != null ? match.group(1) : 'desconhecido';
      return '''Campo obrigatório não enviado.
Campo: $colName
Banco: Supabase''';
    }
    if (errorMsg.contains('code: 23505') ||
        errorMsg.contains('duplicate key value violates unique constraint')) {
      return '''Registro já existe (Chave duplicada).
Banco: Supabase''';
    }
    if (errorMsg.contains('code: 23503') ||
        errorMsg.contains('violates foreign key constraint')) {
      return '''Violação de chave estrangeira (Registro pai não encontrado).
Banco: Supabase''';
    }
    return errorMsg;
  }
}
