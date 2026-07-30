import 'dart:async';
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

  SyncEngine({
    required this.outboxService,
    required this.context,
    required this.db,
    this.serverPushHandler,
  });

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

    final traceId = 'SYNC-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}';
    final logContext = {
      if (context.hasContext) 'usuario': context.usuario.nome,
      if (context.hasContext) 'empresa': context.empresa.nomeFantasia,
    };
    final logCtxStr = context.hasContext
        ? '${context.usuario.nome} @ ${context.empresa.nomeFantasia}'
        : null;

    try {
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
        await FincoreLogger.instance.beginCycle(
          LogModule.sync,
          'CICLO DE ENVIO (PUSH)',
          context: logCtxStr,
        );
        LogService.instance.info(
          LogModule.sync,
          'Outbox: $initialCount registro(s) pendente(s) — iniciando envio ao Supabase',
          traceId: traceId,
          context: logContext,
        );
      }

      for (final entry in entries) {
        final startTime = DateTime.now();
        LogService.instance.debug(
          LogModule.sync,
          'Iniciando [${entry.action}] da entidade [${entry.entity}] ID [${entry.entityId}]. Payload: ${entry.payload}',
          tenantId: context.hasContext ? context.tenantId : null,
          traceId: traceId,
          context: logContext,
        );
        await outboxService.updateStatus(entry.id, SyncStatus.processing);

        bool pushSuccess = false;
        String? pushError;

        try {
          if (serverPushHandler != null) {
            pushSuccess = await serverPushHandler!(entry);
          } else {
            // Em ambiente sem handler de servidor configurado, considera simulado com sucesso
            pushSuccess = true;
          }
        } catch (e) {
          pushSuccess = false;
          pushError = e.toString();
        }

        if (pushSuccess) {
          final duration = DateTime.now().difference(startTime).inMilliseconds;
          final shortId = entry.entityId.length > 8 ? entry.entityId.substring(0, 8) : entry.entityId;
          LogService.instance.info(
            LogModule.sync,
            '${entry.entity.padRight(28)} id=${shortId}...  ENVIADO   ${entry.action}  (${duration}ms)',
            tenantId: context.hasContext ? context.tenantId : null,
            traceId: traceId,
            context: logContext,
          );
          await outboxService.updateStatus(entry.id, SyncStatus.synced);
          await _updateSourceTableSyncStatus(entry);
          successCount++;
        } else {
          final attempts = entry.attemptsCount + 1;
          final nextStatus = attempts >= 5 ? SyncStatus.failed : SyncStatus.retrying;
          final shortId = entry.entityId.length > 8 ? entry.entityId.substring(0, 8) : entry.entityId;
          final parsedReason = _parseSyncError(pushError ?? 'Desconhecido');
          LogService.instance.warning(
            LogModule.sync,
            '${entry.entity.padRight(28)} id=${shortId}...  FALHA     tentativa $attempts/5 — $parsedReason',
            tenantId: context.hasContext ? context.tenantId : null,
            traceId: traceId,
            context: logContext,
          );
          if (pushError != null) {
            LogService.instance.error(
              LogModule.sync,
              'Detalhe do erro',
              traceId: traceId,
              context: logContext,
              exception: pushError,
            );
          }
          await outboxService.updateStatus(
            entry.id,
            nextStatus,
            errorMessage: pushError ?? 'Falha no envio remoto (Tentativa $attempts/5)',
          );
          failureCount++;
        }
      }
    } finally {
      _isProcessing = false;
    }

    final durationMs = DateTime.now().difference(overallStart).inMilliseconds;
    final hasPendingAfter = !(await outboxService.isOutboxEmpty());

    final statusStr = hasPendingAfter
        ? 'Modo degradado — PULL suspenso (ainda há pendências)'
        : 'OK — Outbox limpo, pronto para PULL';

    LogService.instance.info(
      LogModule.sync,
      'Ciclo encerrado: $successCount enviado(s)  $failureCount falha(s)  ${durationMs}ms  $statusStr',
      tenantId: context.hasContext ? context.tenantId : null,
      traceId: traceId,
      context: logContext,
    );

    if (entries.isNotEmpty) {
      await FincoreLogger.instance.endCycle(LogModule.sync, 'FIM DO CICLO DE ENVIO');
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
        return 6; // PAI de LocalEntrega
      case 'Produto':
      case 'produto':
      case 'produtos':
        return 7;
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
      default:
        return 50;
    }
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
