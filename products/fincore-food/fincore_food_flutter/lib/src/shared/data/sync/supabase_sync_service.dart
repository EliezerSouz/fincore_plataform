import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fincore_core/fincore_core.dart';

/// Estado de conectividade com a nuvem.
enum CloudConnectivity { online, offline, unknown }

/// Gerencia a sincronização bidirecional entre SQLite local e Supabase.
///
/// ## ⚡ CANAL OFICIAL DE SINCRONIZAÇÃO (ARC-001)
/// Este serviço é o ÚNICO canal de sincronização ativo em produção.
/// O SyncEndpoint do Serverpod está incompleto e não é usado para sync de dados.
/// A decisão de usar Supabase SDK direto foi tomada pela equipe por menor latência
/// e menor complexidade. O isolamento multi-tenant é garantido por RLS no Supabase.
///
/// ## Offline-First por Design
/// - Push e Pull são tentados SOMENTE se houver conectividade
/// - O Outbox retém as mutações locais com retry automático ao reconectar
/// - O Realtime WebSocket reconecta automaticamente quando a rede volta
/// - A UI nunca para — o banco local é sempre a fonte de leitura
///
/// ## Proteção do Pull (Regra de Ouro)
/// Nenhum registro vindo do servidor pode sobrescrever um registro local que
/// ainda possua alterações pendentes no Outbox. O método [_pullTable] consulta
/// os IDs bloqueados ANTES de aplicar qualquer linha recebida do Supabase.
///
/// ## Resolução de Conflito: Last Write Wins + syncVersion
/// Para cadastros (clientes, produtos, categorias etc.), o servidor só vence se:
/// 1. O registro NÃO tem Outbox pendente (regra de ouro)
/// 2. O syncVersion do servidor é ≥ ao syncVersion local
///
/// Push (local → nuvem): Pega entradas do Outbox e faz upsert no Supabase
/// Pull (nuvem → local): Busca registros atualizados desde [lastSyncAt]
/// Realtime: Escuta changes no Supabase via WebSocket (push instantâneo)
class SupabaseSyncService {
  final SupabaseClient _supabase;
  final TenantContext _context;
  final OutboxService _outbox;
  final List<RealtimeChannel> _channels = [];
  Timer? _pollingTimer;

  CloudConnectivity _connectivity = CloudConnectivity.unknown;
  CloudConnectivity get connectivity => _connectivity;

  // Callback para notificar a UI sobre mudanças de conectividade
  void Function(CloudConnectivity)? onConnectivityChanged;

  // Mapeamento: entityName do outbox → nome da tabela no Supabase
  static const Map<String, String> _entityToTable = {
    'empresa_configuracao': 'empresa_configuracao',
    'empresas': 'empresa',
    'empresa': 'empresa',
    'categorias': 'categoria',
    'produtos': 'produto',
    'clientes': 'cliente',
    'formas_pagamento': 'forma_pagamento',
    'locais_entrega': 'local_entrega',
    'taxas_entrega': 'taxa_entrega',
    'membros_empresa': 'membro_empresa',
    'membro_empresa': 'membro_empresa',
    'usuarios': 'usuarios',
    'usuario': 'usuarios',
    'tabelas_precificacao': 'tabela_precificacao',
    'itens_tabela_precificacao': 'item_tabela_precificacao',
    'produtos_tabelas_precificacao': 'produto_tabela_precificacao',
    'categorias_tabelas_precificacao': 'categoria_tabela_precificacao',
    // P0-01: Pedidos — canal oficial de vendas
    'Pedido': 'pedido',
    'pedidos': 'pedido',
    'ItensPedido': 'item_pedido',
    'itens_pedido': 'item_pedido',
    // Onboarding / IAM
    'empresa_convite': 'empresa_convite',
    'empresa_convites': 'empresa_convite',
    // Auditoria
    'audit_log': 'audit_logs',
    // KDS Ordens de Preparo
    'OrdemPreparo': 'ordens_preparo',
    'ordens_preparo': 'ordens_preparo',
    'HistoricoOrdemPreparo': 'historicos_ordem_preparo',
    'historicos_ordem_preparo': 'historicos_ordem_preparo',
    // ESTOQUE: Controle de produtos acabados
    'estoque_produto': 'estoque_produto',
    'EstoqueProduto': 'estoque_produto',
    'movimentacao_estoque': 'movimentacao_estoque',
    'MovimentacaoEstoque': 'movimentacao_estoque',
    // FINANCEIRO: Sessões de caixa e lançamentos
    'sessao_caixa': 'sessao_caixa',
    'SessaoCaixa': 'sessao_caixa',
    'lancamento_financeiro': 'lancamento_financeiro',
    'LancamentoFinanceiro': 'lancamento_financeiro',
  };

  SupabaseSyncService({
    required SupabaseClient supabase,
    required TenantContext context,
    required OutboxService outbox,
  })  : _supabase = supabase,
        _context = context,
        _outbox = outbox;

  Future<({int pending, int retrying, int failed, int total})> getOutboxStats() => _outbox.getOutboxStats();
  Future<int> retryFailedEntries() => _outbox.retryFailedEntries();

  // ──────────────────────────────────────────────────────────
  // CONECTIVIDADE: verifica acesso antes de qualquer operação
  // ──────────────────────────────────────────────────────────

  /// Verifica se há conectividade com o Supabase fazendo um health check leve.
  /// Retorna false se estiver offline, em vez de lançar exceção.
  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('supabase.co')
          .timeout(const Duration(seconds: 3));
      final online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      _updateConnectivity(online ? CloudConnectivity.online : CloudConnectivity.offline);
      return online;
    } catch (_) {
      _updateConnectivity(CloudConnectivity.offline);
      return false;
    }
  }

  void _updateConnectivity(CloudConnectivity status) {
    if (_connectivity != status) {
      _connectivity = status;
      onConnectivityChanged?.call(status);
      if (status == CloudConnectivity.online) {
        LogService.instance.info(LogModule.sync, '[OK] Conectividade restaurada - sync retomado');
      } else {
        LogService.instance.warning(LogModule.sync, '[AVISO] Sem conectividade - modo offline. Dados salvos localmente.');
      }
    }
  }

  // ──────────────────────────────────────────────────────────
  // PUSH: Outbox → Supabase (com verificação offline)
  // ──────────────────────────────────────────────────────────

  /// Envia uma entrada do Outbox para o Supabase via REST.
  /// Retorna false se offline — o SyncEngine irá fazer retry automaticamente.
  Future<bool> push(OutboxEntry entry) async {
    if (_connectivity == CloudConnectivity.offline) {
      LogService.instance.debug(LogModule.sync, 'Offline - push de ${entry.entity} adiado');
      throw OfflineSyncException('Sem conexao com o servidor (Offline)');
    }

    final tableName = _entityToTable[entry.entity];
    if (tableName == null) {
      LogService.instance.warning(LogModule.sync, 'Entidade desconhecida: ${entry.entity} - ignorando push');
      return true;
    }

    try {
      final payload = jsonDecode(entry.payload) as Map<String, dynamic>;

      if (tableName == 'audit_logs') {
        payload.remove('device_info');
        payload.remove('tenant_id');
        payload.remove('entity_name');
        payload.remove('targetEntity');
        payload.remove('target_entity');
        payload.remove('entity_id');
        payload.remove('user_id');
        payload.remove('sync_version');
        payload.remove('userName');
        payload.remove('userRole');
        payload.remove('machineName');
        payload.remove('hostName');
        payload.remove('ipAddress');
        payload.remove('macAddress');
        payload.remove('osVersion');
        payload.remove('appVersion');
        payload.remove('sessionId');
        payload.remove('deviceDescription');
        payload.remove('entityDisplayName');
        payload.remove('entityModule');
      }

      LogService.instance.debug(
        LogModule.sync,
        'Supabase PUSH: Tabela: $tableName | Acao: ${entry.action} | ID: ${entry.entityId}',
        tenantId: _context.hasContext ? _context.tenantId : null,
      );

      // Sanitizar createdBy e updatedBy se contiverem strings não-UUID (ex: 'PDV')
      final tenantUserId = _context.hasContext ? _context.usuario.id : '00000000-0000-0000-0000-000000000000';
      if (payload.containsKey('createdBy')) {
        final val = payload['createdBy'] as String? ?? '';
        if (val.isEmpty || val == 'PDV' || val == 'system' || !val.contains('-')) {
          payload['createdBy'] = tenantUserId;
        }
      }
      if (payload.containsKey('updatedBy')) {
        final val = payload['updatedBy'] as String? ?? '';
        if (val.isEmpty || val == 'PDV' || val == 'system' || !val.contains('-')) {
          payload['updatedBy'] = tenantUserId;
        }
      }

      // Sanitizar formaPagamentoId se contiver strings não-UUID (evitando erro 22P02 no Postgres)
      if (payload.containsKey('formaPagamentoId')) {
        final val = payload['formaPagamentoId'] as String? ?? '';
        if (val.isNotEmpty) {
          final isUuid = RegExp(r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$').hasMatch(val);
          if (!isUuid) {
            payload['formaPagamentoId'] = null;
          }
        }
      }

      // Sanitizar campo 'status' para tabela pedido: o CHECK CONSTRAINT
      // pedido_status_check exige snake_case ('em_preparo'), mas o Dart enum
      // .name retorna camelCase ('emPreparo'). Tradução defensiva aqui.
      if (tableName == 'pedido' && payload.containsKey('status')) {
        const statusCamelToSnake = {
          'emPreparo': 'em_preparo',
          'pendente': 'confirmado',
        };
        final rawStatus = payload['status'] as String? ?? '';
        if (statusCamelToSnake.containsKey(rawStatus)) {
          payload['status'] = statusCamelToSnake[rawStatus];
          LogService.instance.debug(
            LogModule.sync,
            'Status sanitizado: "$rawStatus" → "${payload['status']}" (pedido_status_check)',
          );
        }
      }

      if (entry.action == 'DELETE') {
        await _supabase
            .from(tableName)
            .update({'deletedAt': DateTime.now().toUtc().toIso8601String()})
            .eq('id', entry.entityId)
            .eq('tenantId', _context.tenantId);
      } else if (entry.action.toLowerCase() == 'update') {
        final idCol = tableName == 'empresa_configuracao' ? 'tenantId' : 'id';
        int attempts = 0;
        while (attempts < 5) {
          try {
            await _supabase
                .from(tableName)
                .update(payload)
                .eq(idCol, entry.entityId)
                .eq('tenantId', _context.tenantId);
            break;
          } on PostgrestException catch (e) {
            attempts++;
            if ((e.code == 'PGRST204' || e.message.contains("Could not find the '")) && attempts < 5) {
              final match = RegExp(r"Could not find the '([^']+)' column").firstMatch(e.message);
              if (match != null) {
                final missingCol = match.group(1)!;
                throw StateError(
                  'Schema remoto incompatível: coluna "$missingCol" ausente em "$tableName".',
                );
              }
            }
            rethrow;
          }
        }
      } else {
        final conflictCol = tableName == 'empresa_configuracao' ? 'tenantId' : 'id';
        int attempts = 0;
        while (attempts < 5) {
          try {
            await _supabase.from(tableName).upsert(
              payload,
              onConflict: conflictCol,
            );
            break;
          } on PostgrestException catch (e) {
            attempts++;
            if ((e.code == 'PGRST204' || e.message.contains("Could not find the '")) && attempts < 5) {
              final match = RegExp(r"Could not find the '([^']+)' column").firstMatch(e.message);
              if (match != null) {
                final missingCol = match.group(1)!;
                // Não descarte atributos de negócio para "fazer o sync passar".
                // O chamador manterá a entrada no Outbox para retry após a
                // migração remota, preservando a operação inteira.
                throw StateError(
                  'Schema remoto incompatível: coluna "$missingCol" ausente em "$tableName".',
                );
              }
            }
            rethrow;
          }
        }
      }

      _updateConnectivity(CloudConnectivity.online);
      return true;
    } on SocketException catch (e) {
      _updateConnectivity(CloudConnectivity.offline);
      throw OfflineSyncException('Sem conexão com o servidor (SocketException: ${e.message})');
    } catch (e) {
      // Propaga o erro real de banco para ser tratado e armazenado no SyncEngine
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────
  // PULL: Supabase → local SQLite (com Escudo + LWW)
  // ──────────────────────────────────────────────────────────

  DateTime? _lastPullTimestamp;

  /// Busca todas as tabelas atualizadas desde [lastSyncAt] e aplica localmente.
  ///
  /// **IMPORTANTE**: Este método NUNCA deve ser chamado se o Outbox ainda tiver
  /// pendências. O router é responsável por garantir isso via [SyncResult.hasPendingAfter].
  /// Mesmo assim, cada linha é protegida individualmente pelo Escudo do Pull.
  ///
  bool _isPulling = false;
  bool get isPulling => _isPulling;

  /// Busca todas as tabelas atualizadas desde [lastSyncAt] e aplica localmente.
  ///
  /// **IMPORTANTE**: Este método NUNCA deve ser chamado se o Outbox ainda tiver
  /// pendências. O router é responsável por garantir isso via [SyncResult.hasPendingAfter].
  /// Mesmo assim, cada linha é protegida individualmente pelo Escudo do Pull.
  ///
  /// Retorna `true` se a sincronização foi completada com sucesso, ou `false` se offline/erro.
  Future<bool> pullAll(FincoreDatabase db, DateTime lastSyncAt) async {
    if (!_context.hasContext || _isPulling) return false;
    _isPulling = true;

    final online = await isOnline();
    if (!online) {
      _isPulling = false;
      LogService.instance.debug(LogModule.sync, 'Pull cancelado - sem conexao. App rodando 100% offline.');
      return false;
    }

    final tenantId = _context.tenantId;
    final startTime = DateTime.now();

    final logCtxStr = _context.hasContext
        ? '${_context.usuario.nome} @ ${_context.empresa.nomeFantasia}'
        : null;

    try {
      await FincoreLogger.instance.beginCycle(
        LogModule.sync,
        'CICLO DE RECEBIMENTO REMOTO (PULL)',
        context: logCtxStr,
      );

      int totalApplied = 0;
      int totalProtected = 0;

      final tables = [
        'empresa_configuracao',
        'empresas',
        'categorias',
        'membros_empresa',
        'usuarios',
        'tabelas_precificacao',
        'taxas_entrega',
        'formas_pagamento',
        'clientes',
        'produtos',
        'locais_entrega',
        'itens_tabela_precificacao',
        'produtos_tabelas_precificacao',
        'categorias_tabelas_precificacao',
        // P0-01: Pedidos (Pull para sincronizar entre dispositivos do mesmo tenant)
        'pedidos',
        'itens_pedido',
        // Onboarding / IAM
        'empresa_convites',
        // ESTOQUE
        'estoque_produto',
        'movimentacao_estoque',
        // FINANCEIRO
        'sessao_caixa',
        'lancamento_financeiro',
      ];

      for (final table in tables) {
        final res = await _pullTable(table, tenantId, lastSyncAt, db);
        totalApplied += res.applied;
        totalProtected += res.protected;
      }

      final durationMs = DateTime.now().difference(startTime).inMilliseconds;

      if (totalApplied > 0 || totalProtected > 0) {
        LogService.instance.info(
          LogModule.sync,
          '[OK] Ciclo de recebimento (Pull) concluido com sucesso em ${durationMs}ms | $totalApplied mudanca(s) aplicada(s), $totalProtected protegida(s) | Banco local sincronizado.',
          tenantId: tenantId,
        );
      } else {
        LogService.instance.info(
          LogModule.sync,
          '[OK] Ciclo de recebimento (Pull) concluido em ${durationMs}ms | Sem mudancas na nuvem | Banco local atualizado.',
          tenantId: tenantId,
        );
      }

      await FincoreLogger.instance.endCycle(LogModule.sync, 'FIM DO CICLO DE RECEBIMENTO (PULL)');

      // Marca a data/hora exata em UTC do término do PULL bem-sucedido
      _lastPullTimestamp = DateTime.now().toUtc();
      return true;
    } catch (e) {
      LogService.instance.error(LogModule.sync, '[PULL] Falha critica durante o ciclo de recebimento (Pull)', exception: e.toString());
      return false;
    } finally {
      _isPulling = false;
    }
  }

  final ConflictResolver _conflictResolver = const ConflictResolver();

  Future<({int applied, int protected})> _pullTable(
    String entityName,
    String tenantId,
    DateTime since,
    FincoreDatabase db,
  ) async {
    final tableName = _entityToTable[entityName];
    if (tableName == null) return (applied: 0, protected: 0);

    final isFullPull = since.isBefore(DateTime.now().subtract(const Duration(days: 6)));
    final pullType = isFullPull ? 'Carga Total' : 'Incremental';

    try {
      final queryBuilder = _supabase.from(tableName).select();
      final dateColumn = tableName == 'usuarios' ? 'atualizadoEm' : 'updatedAt';
      final rows = await (tableName == 'empresa'
              ? queryBuilder.eq('id', tenantId)
              : tableName == 'usuarios'
                  ? queryBuilder.eq('activeTenantId', tenantId)
                  : queryBuilder.eq('tenantId', tenantId))
          .gte(dateColumn, since.toIso8601String());

      if (rows.isEmpty) {
        return (applied: 0, protected: 0);
      }

      LogService.instance.info(
        LogModule.sync,
        '  Encontrada(s) ${rows.length} mudanca(s) na nuvem para [$entityName]. Processando...',
        tenantId: tenantId,
      );

      // ── ESCUDO DO PULL (OUTBOX) ─────────────────────────────
      final lockedIds = await _outbox.getPendingEntityIds(entityName);
      // ─────────────────────────────────────────────────────────

      int appliedCount = 0;
      int protectedCount = 0;
      int stalledCount = 0;
      final List<String> protectedDetails = [];

      await db.transaction(() async {
        for (final row in rows) {
          final rowId = row['id'] as String?;
          if (rowId == null) continue;

          final shortId = rowId.length > 8 ? '${rowId.substring(0, 8)}...' : rowId;
          final desc = (row['nome'] ?? row['descricao'] ?? row['tipo'] ?? row['apelido'] ?? row['nomeIdentificador'] ?? '') as String;
          final serverVersion = (row['syncVersion'] as num?)?.toInt() ?? 1;
          final localVersion = await _getLocalSyncVersion(entityName, rowId, db);
          final hasPending = lockedIds.contains(rowId);

          // ── CONFLICT RESOLVER ───────────────────────────────────
          final decision = _conflictResolver.resolve(
            entityName: entityName,
            entityId: rowId,
            hasOutboxPending: hasPending,
            localVersion: localVersion,
            serverVersion: serverVersion,
          );

          if (!decision.allowOverwrite) {
            if (hasPending) {
              protectedCount++;
              protectedDetails.add('* $entityName [$shortId] "$desc" - Outbox pendente');
            } else {
              stalledCount++;
            }
            continue;
          }
          // ─────────────────────────────────────────────────────────

          await _applyRowLocally(entityName, row, db);
          appliedCount++;
        }
      });

      LogService.instance.info(
        LogModule.sync,
        '  Resultado [$entityName]: $appliedCount aplicado(s) no banco local, $protectedCount protegido(s), $stalledCount mantido(s)',
        tenantId: tenantId,
      );

      for (final d in protectedDetails) {
        LogService.instance.info(
          LogModule.sync,
          '    Registro protegido contra sobrescrita: $d',
          tenantId: tenantId,
        );
      }

      return (applied: appliedCount, protected: protectedCount);
    } on SocketException {
      _updateConnectivity(CloudConnectivity.offline);
      LogService.instance.debug(LogModule.sync, 'Sem conexao durante atualizacao de $entityName - mantendo dados locais.');
      return (applied: 0, protected: 0);
    } catch (e) {
      LogService.instance.error(LogModule.sync, 'Falha ao processar atualizacao remota de $entityName', exception: e.toString());
      return (applied: 0, protected: 0);
    }
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final ss = local.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss';
  }

  /// Retorna a syncVersion atual do registro local, ou null se não existir.
  Future<int?> _getLocalSyncVersion(
    String entityName,
    String entityId,
    FincoreDatabase db,
  ) async {
    try {
      switch (entityName) {
        case 'produtos':
          final row = await (db.select(db.produtosTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'clientes':
          final row = await (db.select(db.clientesTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'categorias':
          final row = await (db.select(db.categoriasTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'empresa_configuracao':
          final row = await (db.select(db.empresaConfiguracaoTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'empresas':
        case 'empresa':
          final row = await (db.select(db.empresasTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'formas_pagamento':
          final row = await (db.select(db.formasPagamentoTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'locais_entrega':
          final row = await (db.select(db.locaisEntregaTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'taxas_entrega':
          final row = await (db.select(db.taxasEntregaTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'tabelas_precificacao':
          final row = await (db.select(db.tabelasPrecificacaoTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'itens_tabela_precificacao':
          final row = await (db.select(db.itensTabelaPrecificacaoTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'produtos_tabelas_precificacao':
          final row = await (db.select(db.produtosTabelasPrecificacaoTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'empresa_convite':
        case 'empresa_convites':
          final row = await (db.select(db.empresaConvitesTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'usuarios':
        case 'usuario':
          final row = await (db.select(db.usuariosTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.atualizadoEm.millisecondsSinceEpoch ?? 1;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _applyRowLocally(
    String entityName,
    Map<String, dynamic> row,
    FincoreDatabase db,
  ) async {
    switch (entityName) {
      case 'empresa_configuracao':
        await db.into(db.empresaConfiguracaoTable).insertOnConflictUpdate(
              EmpresaConfiguracaoTableCompanion.insert(
                id: row['id'] as String,
                tenantId: row['tenantId'] as String,
                taxaServico: Value((row['taxaServico'] as num?)?.toDouble() ?? 0.10),
                usarWhatsApp: Value(row['usarWhatsApp'] as bool? ?? false),
                tema: Value(row['tema'] as String? ?? 'dark'),
                pixKey: Value(row['pixKey'] as String?),
                printerConfig: Value(row['printerConfig'] as String?),
                logoUrl: Value(row['logoUrl'] as String?),
                printerCaixa: Value(row['printerCaixa'] as String?),
                printerCozinha: Value(row['printerCozinha'] as String?),
                printerBalcao: Value(row['printerBalcao'] as String?),
                printerExpedicao: Value(row['printerExpedicao'] as String?),
                autoPrintCaixa: Value(row['autoPrintCaixa'] as bool? ?? true),
                autoPrintCozinha: Value(row['autoPrintCozinha'] as bool? ?? true),
                autoPrintBalcao: Value(row['autoPrintBalcao'] as bool? ?? false),
                autoPrintExpedicao: Value(row['autoPrintExpedicao'] as bool? ?? false),
                viasCliente: Value(row['viasCliente'] as int? ?? 1),
                viasCozinha: Value(row['viasCozinha'] as int? ?? 1),
                viasBalcao: Value(row['viasBalcao'] as int? ?? 0),
                viasExpedicao: Value(row['viasExpedicao'] as int? ?? 0),
                larguraPapel: Value(row['larguraPapel'] as int? ?? 80),
                cortarPapel: Value(row['cortarPapel'] as bool? ?? true),
                abrirGaveta: Value(row['abrirGaveta'] as bool? ?? false),
                imprimirQRCode: Value(row['imprimirQRCode'] as bool? ?? true),
                imprimirCopiaCola: Value(row['imprimirCopiaCola'] as bool? ?? true),
                imprimirLogo: Value(row['imprimirLogo'] as bool? ?? false),
                imprimirRodape: Value(row['imprimirRodape'] as bool? ?? true),
                mensagemRodape: Value(row['mensagemRodape'] as String? ?? 'Obrigado pela preferência!'),
                pixFavorecido: Value(row['pixFavorecido'] as String?),
                pixBanco: Value(row['pixBanco'] as String?),
                pixTipo: Value(row['pixTipo'] as String? ?? 'CPF'),
                mercadoPagoAtivo: Value(row['mercadoPagoAtivo'] as bool? ?? false),
                openPixAtivo: Value(row['openPixAtivo'] as bool? ?? false),
                asaasAtivo: Value(row['asaasAtivo'] as bool? ?? false),
                ifoodAtivo: Value(row['ifoodAtivo'] as bool? ?? false),
                margemSegurancaMinutos: Value(row['margemSegurancaMinutos'] as int? ?? 10),
                taxaEntregaPorKm: Value(row['taxaEntregaPorKm'] as bool? ?? false),
                valorPorKmCentavos: Value(row['valorPorKmCentavos'] as int? ?? 0),
                syncVersion: Value(row['syncVersion'] as int? ?? 1),
                syncStatus: SyncStatus.synced,
                lastSyncedAt: Value(DateTime.now().toUtc()),
                createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
                createdBy: row['createdBy'] as String? ?? '',
                updatedBy: row['updatedBy'] as String? ?? '',
                deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
                deletedBy: const Value(null),
              ),
            );

        if (row.containsKey('modoDeliveryAtivo') ||
            row.containsKey('clienteObrigatorioVenda') ||
            row.containsKey('atendimentoPadrao') ||
            row.containsKey('margemSegurancaMinutos') ||
            row.containsKey('taxaEntregaPorKm') ||
            row.containsKey('valorPorKmCentavos')) {
          try {
            await db.customStatement(
              'UPDATE empresa_configuracao_table SET modo_delivery_ativo = ?, cliente_obrigatorio_venda = ?, atendimento_padrao = ?, margem_seguranca_minutos = ?, taxa_entrega_por_km = ?, valor_por_km_centavos = ? WHERE id = ?',
              [
                row['modoDeliveryAtivo'] == true || row['modoDeliveryAtivo'] == 1 ? 1 : 0,
                row['clienteObrigatorioVenda'] == true || row['clienteObrigatorioVenda'] == 1 ? 1 : 0,
                row['atendimentoPadrao'] as String? ?? 'Mesa/Balcão',
                row['margemSegurancaMinutos'] as int? ?? 10,
                row['taxaEntregaPorKm'] == true || row['taxaEntregaPorKm'] == 1 ? 1 : 0,
                row['valorPorKmCentavos'] as int? ?? 0,
                row['id'],
              ],
            );
          } catch (_) {}
        }
        break;

      case 'empresas':
      case 'empresa':
        await db.into(db.empresasTable).insertOnConflictUpdate(
              EmpresasTableCompanion.insert(
                id: row['id'] as String,
                razaoSocial: row['razaoSocial'] as String? ?? '',
                nomeFantasia: row['nomeFantasia'] as String? ?? '',
                documentoFiscal: row['documentoFiscal'] as String? ?? '',
                email: row['email'] as String? ?? '',
                telefone: row['telefone'] as String? ?? '',
                status: row['status'] as String? ?? 'ativo',
                plano: row['plano'] as String? ?? 'bronze',
                timezone: row['timezone'] as String? ?? 'America/Sao_Paulo',
                locale: row['locale'] as String? ?? 'pt_BR',
                currency: row['currency'] as String? ?? 'BRL',
                country: row['country'] as String? ?? 'BR',
                createdFrom: row['createdFrom'] as String? ?? 'PDV',
                vencimento: row['vencimento'] != null ? Value(_parseDate(row['vencimento'] as String?)) : const Value.absent(),
                segmento: Value(row['segmento'] as String?),
                tipoPessoa: Value(row['tipoPessoa'] as String? ?? 'JURIDICA'),
                inscricaoEstadual: Value(row['inscricaoEstadual'] as String?),
                inscricaoMunicipal: Value(row['inscricaoMunicipal'] as String?),
                regimeTributario: Value(row['regimeTributario'] as String?),
                cep: Value(row['cep'] as String?),
                logradouro: Value(row['logradouro'] as String?),
                numero: Value(row['numero'] as String?),
                complemento: Value(row['complemento'] as String?),
                bairro: Value(row['bairro'] as String?),
                cidade: Value(row['cidade'] as String?),
                estado: Value(row['estado'] as String?),
                syncVersion: Value(row['syncVersion'] as int? ?? 1),
                syncStatus: SyncStatus.synced,
                lastSyncedAt: Value(DateTime.now().toUtc()),
                createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
                createdBy: row['createdBy'] as String? ?? '',
                updatedBy: row['updatedBy'] as String? ?? '',
                deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
                deletedBy: const Value(null),
              ),
            );
        break;

      case 'categorias':
        await db.into(db.categoriasTable).insertOnConflictUpdate(
              CategoriasTableCompanion.insert(
                id: row['id'] as String,
                tenantId: row['tenantId'] as String,
                nome: row['nome'] as String,
                descricao: row['descricao'] as String? ?? '',
                ordemExibicao: row['ordemExibicao'] as int? ?? 0,
                ativo: row['ativo'] as bool? ?? true,
                icone: Value(row['icone'] as String?),
                cor: Value(row['cor'] as String?),
                metadataPayload: Value(row['metadataPayload'] as String?),
                syncVersion: Value(row['syncVersion'] as int? ?? 1),
                syncStatus: SyncStatus.synced,
                lastSyncedAt: Value(DateTime.now().toUtc()),
                createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
                createdBy: row['createdBy'] as String? ?? '',
                updatedBy: row['updatedBy'] as String? ?? '',
                deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
                deletedBy: const Value(null),
              ),
            );
        break;

      case 'produtos':
        await db.into(db.produtosTable).insertOnConflictUpdate(
              ProdutosTableCompanion.insert(
                id: row['id'] as String,
                tenantId: row['tenantId'] as String,
                codigo: Value(row['codigo'] as String?),
                nome: row['nome'] as String,
                descricao: Value(row['descricao'] as String?),
                categoriaId: row['categoriaId'] as String,
                unidadeVenda: row['unidadeVenda'] as String? ?? 'un',
                statusComercial: row['statusComercial'] as String? ?? 'disponivel',
                tempoMedioMinutos: row['tempoMedioMinutos'] as int? ?? 15,
                controlaEstoque: row['controlaEstoque'] as bool? ?? false,
                ordemProducao: row['ordemProducao'] as int? ?? 0,
                ativo: row['ativo'] as bool? ?? true,
                sku: Value(row['sku'] as String?),
                codigoBarras: Value(row['codigoBarras'] as String?),
                imagem: Value(row['imagem'] as String?),
                corEtiqueta: Value(row['corEtiqueta'] as String?),
                metadata: Value(row['metadata'] as String?),
                syncVersion: Value(row['syncVersion'] as int? ?? 1),
                syncStatus: SyncStatus.synced,
                lastSyncedAt: Value(DateTime.now().toUtc()),
                createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
                createdBy: row['createdBy'] as String? ?? '',
                updatedBy: row['updatedBy'] as String? ?? '',
                deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
                deletedBy: const Value(null),
              ),
            );
        break;

      case 'clientes':
        await db.into(db.clientesTable).insertOnConflictUpdate(
              ClientesTableCompanion.insert(
                id: row['id'] as String,
                tenantId: row['tenantId'] as String,
                nome: row['nome'] as String,
                telefone: row['telefone'] as String? ?? '',
                email: Value(row['email'] as String?),
                documento: Value(row['documento'] as String?),
                observacoes: row['observacoes'] as String? ?? '',
                apelido: Value(row['apelido'] as String?),
                aceitaWhatsapp: Value(row['aceitaWhatsapp'] as bool? ?? true),
                aceitaMarketing: Value(row['aceitaMarketing'] as bool? ?? false),
                preferenciaEntrega: Value(row['preferenciaEntrega'] as String?),
                ativo: row['ativo'] as bool? ?? true,
                syncVersion: Value(row['syncVersion'] as int? ?? 1),
                syncStatus: SyncStatus.synced,
                lastSyncedAt: Value(DateTime.now().toUtc()),
                createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
                createdBy: row['createdBy'] as String? ?? '',
                updatedBy: row['updatedBy'] as String? ?? '',
                deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
                deletedBy: const Value(null),
              ),
            );
        break;

      case 'formas_pagamento':
        await db.into(db.formasPagamentoTable).insertOnConflictUpdate(
              FormasPagamentoTableCompanion.insert(
                id: row['id'] as String,
                tenantId: row['tenantId'] as String,
                nome: row['nome'] as String,
                tipo: row['tipo'] as String? ?? 'dinheiro',
                ordem: row['ordem'] as int? ?? 0,
                permiteTroco: row['permiteTroco'] as bool? ?? false,
                ativo: row['ativo'] as bool? ?? true,
                syncVersion: Value(row['syncVersion'] as int? ?? 1),
                syncStatus: SyncStatus.synced,
                lastSyncedAt: Value(DateTime.now().toUtc()),
                createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
                createdBy: row['createdBy'] as String? ?? '',
                updatedBy: row['updatedBy'] as String? ?? '',
                deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
                deletedBy: const Value(null),
              ),
            );
        break;

      case 'locais_entrega':
        await db.into(db.locaisEntregaTable).insertOnConflictUpdate(
              LocaisEntregaTableCompanion.insert(
                id: row['id'] as String,
                tenantId: row['tenantId'] as String,
                clienteId: row['clienteId'] as String,
                nomeIdentificador: row['nomeIdentificador'] as String? ?? row['apelido'] as String? ?? '',
                logradouro: row['logradouro'] as String? ?? '',
                numero: row['numero'] as String? ?? '',
                bairro: row['bairro'] as String? ?? '',
                cidade: row['cidade'] as String? ?? '',
                cep: row['cep'] as String? ?? '',
                referencia: row['referencia'] as String? ?? '',
                ativo: row['ativo'] as bool? ?? true,
                syncVersion: Value(row['syncVersion'] as int? ?? 1),
                syncStatus: SyncStatus.synced,
                lastSyncedAt: Value(DateTime.now().toUtc()),
                createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
                createdBy: row['createdBy'] as String? ?? '',
                updatedBy: row['updatedBy'] as String? ?? '',
                deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
                deletedBy: const Value(null),
              ),
            );
        break;

      case 'taxas_entrega':
        await db.into(db.taxasEntregaTable).insertOnConflictUpdate(
              TaxasEntregaTableCompanion.insert(
                id: row['id'] as String,
                tenantId: row['tenantId'] as String,
                nome: row['nome'] as String,
                tipoRegra: row['tipoRegra'] as String? ?? 'fixo',
                bairro: Value(row['bairro'] as String?),
                cepInicial: Value(row['cepInicial'] as String?),
                cepFinal: Value(row['cepFinal'] as String?),
                valorCentavos: row['valorCentavos'] as int? ?? 0,
                ativo: row['ativo'] as bool? ?? true,
                syncVersion: Value(row['syncVersion'] as int? ?? 1),
                syncStatus: SyncStatus.synced,
                lastSyncedAt: Value(DateTime.now().toUtc()),
                createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
                createdBy: row['createdBy'] as String? ?? '',
                updatedBy: row['updatedBy'] as String? ?? '',
                deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
                deletedBy: const Value(null),
              ),
            );
        break;

      case 'tabelas_precificacao':
        await db.into(db.tabelasPrecificacaoTable).insertOnConflictUpdate(
              TabelasPrecificacaoTableCompanion.insert(
                id: row['id'] as String,
                tenantId: row['tenantId'] as String,
                nome: row['nome'] as String,
                descricao: row['descricao'] as String? ?? '',
                tipoPolitica: row['tipoPolitica'] as String? ?? 'unitario',
                prioridade: row['prioridade'] as int? ?? 1,
                ativo: row['ativo'] as bool? ?? true,
                syncVersion: Value(row['syncVersion'] as int? ?? 1),
                syncStatus: SyncStatus.synced,
                lastSyncedAt: Value(DateTime.now().toUtc()),
                createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
                createdBy: row['createdBy'] as String? ?? '',
                updatedBy: row['updatedBy'] as String? ?? '',
                deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
                deletedBy: const Value(null),
              ),
            );
        break;

      case 'itens_tabela_precificacao':
        await db.into(db.itensTabelaPrecificacaoTable).insertOnConflictUpdate(
              ItensTabelaPrecificacaoTableCompanion.insert(
                id: row['id'] as String,
                tenantId: row['tenantId'] as String,
                tabelaPrecificacaoId: row['tabelaPrecificacaoId'] as String,
                quantidadeMinima: row['quantidadeMinima'] as int? ?? 1,
                quantidadeMaxima: Value(row['quantidadeMaxima'] as int?),
                valorUnitarioCentavos: row['valorUnitarioCentavos'] as int? ?? 0,
                ordem: row['ordem'] as int? ?? 0,
                syncVersion: Value(row['syncVersion'] as int? ?? 1),
                syncStatus: SyncStatus.synced,
                lastSyncedAt: Value(DateTime.now().toUtc()),
                createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
                createdBy: row['createdBy'] as String? ?? '',
                updatedBy: row['updatedBy'] as String? ?? '',
                deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
                deletedBy: const Value(null),
              ),
            );
        break;

      case 'produtos_tabelas_precificacao':
        await db.into(db.produtosTabelasPrecificacaoTable).insertOnConflictUpdate(
              ProdutosTabelasPrecificacaoTableCompanion.insert(
                id: row['id'] as String,
                tenantId: row['tenantId'] as String,
                produtoId: row['produtoId'] as String,
                tabelaPrecificacaoId: row['tabelaPrecificacaoId'] as String,
                ativo: row['ativo'] as bool? ?? true,
                prioridade: row['prioridade'] as int? ?? 1,
                dataInicio: Value(_parseDate(row['dataInicio'] as String?)),
                dataFim: Value(_parseDate(row['dataFim'] as String?)),
                syncVersion: Value(row['syncVersion'] as int? ?? 1),
                syncStatus: SyncStatus.synced,
                lastSyncedAt: Value(DateTime.now().toUtc()),
                createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
                createdBy: row['createdBy'] as String? ?? '',
                updatedBy: row['updatedBy'] as String? ?? '',
                deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
                deletedBy: const Value(null),
              ),
            );
        break;

      case 'membros_empresa':
        await db.into(db.membrosEmpresaTable).insertOnConflictUpdate(
              MembrosEmpresaTableCompanion.insert(
                id: row['id'] as String,
                tenantId: row['tenantId'] as String,
                usuarioId: row['usuarioId'] as String,
                role: row['role'] as String? ?? 'OPERADOR',
                ativo: Value(row['ativo'] as bool? ?? true),
                convidadoEm: _parseDate(row['convidadoEm'] as String?) ?? DateTime.now(),
                aceitoEm: Value(_parseDate(row['aceitoEm'] as String?)),
                syncVersion: Value(row['syncVersion'] as int? ?? 1),
                syncStatus: SyncStatus.synced,
                lastSyncedAt: Value(DateTime.now().toUtc()),
                createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
                createdBy: row['createdBy'] as String? ?? '',
                updatedBy: row['updatedBy'] as String? ?? '',
                deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
                deletedBy: const Value(null),
              ),
            );
        break;

      case 'usuarios':
      case 'usuario':
        await db.into(db.usuariosTable).insertOnConflictUpdate(
              UsuariosTableCompanion.insert(
                id: row['id'] as String,
                tenantId: Value(row['activeTenantId'] as String? ?? row['tenantId'] as String?),
                authUserId: Value(row['authUserId'] as String?),
                username: row['username'] as String? ?? '',
                email: Value(row['email'] as String?),
                nome: row['nome'] as String? ?? '',
                avatarUrl: Value(row['avatarUrl'] as String?),
                ativo: Value(row['ativo'] as bool? ?? true),
                criadoEm: _parseDate(row['criadoEm'] as String?) ?? DateTime.now(),
                atualizadoEm: _parseDate(row['atualizadoEm'] as String?) ?? DateTime.now(),
              ),
            );
        break;

      // P0-01: Pedidos — sincronização bidirecional entre dispositivos do mesmo tenant
      case 'pedidos':
      case 'Pedido':
        await _applyPedidoLocally(row, db);
        break;

      case 'itens_pedido':
      case 'ItensPedido':
        await _applyItemPedidoLocally(row, db);
        break;

      case 'empresa_convite':
      case 'empresa_convites':
        await db.into(db.empresaConvitesTable).insertOnConflictUpdate(
              EmpresaConvitesTableCompanion.insert(
                id: row['id'] as String,
                tenantId: row['tenantId'] as String,
                email: row['email'] as String? ?? '',
                role: Value(row['role'] as String? ?? 'OPERADOR'),
                status: Value(row['status'] as String? ?? 'PENDENTE'),
                expiracaoEm: _parseDate(row['expiracaoEm'] as String?) ?? DateTime.now().add(const Duration(days: 7)),
                syncVersion: Value(row['syncVersion'] as int? ?? 1),
                syncStatus: SyncStatus.synced,
                lastSyncedAt: Value(DateTime.now().toUtc()),
                createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
                createdBy: row['createdBy'] as String? ?? '',
                updatedBy: row['updatedBy'] as String? ?? '',
                deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
              ),
            );
      case 'OrdemPreparo':
      case 'ordens_preparo':
        final listItensRaw = row['itensJson'] as String? ?? '[]';
        await db.into(db.ordensPreparoTable).insertOnConflictUpdate(
              OrdensPreparoTableCompanion.insert(
                id: row['id'] as String,
                tenantId: row['tenantId'] as String,
                pedidoId: row['pedidoId'] as String? ?? '',
                itensJson: listItensRaw,
                status: row['status'] as String? ?? 'pendente',
                prioridade: row['prioridade'] as String? ?? 'normal',
                operadorId: Value(row['operadorId'] as String?),
                criadaEm: _parseDate(row['criadaEm'] as String?) ?? DateTime.now(),
                iniciadaEm: Value(_parseDate(row['iniciadaEm'] as String?)),
                concluidaEm: Value(_parseDate(row['concluidaEm'] as String?)),
                canceladaEm: Value(_parseDate(row['canceladaEm'] as String?)),
                tempoEstimadoSegundos: Value(row['tempoEstimadoSegundos'] as int? ?? 0),
                observacoes: Value(row['observacoes'] as String?),
                syncVersion: Value(row['syncVersion'] as int? ?? 1),
                syncStatus: SyncStatus.synced,
                lastSyncedAt: Value(DateTime.now().toUtc()),
                createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
                createdBy: row['createdBy'] as String? ?? '',
                updatedBy: row['updatedBy'] as String? ?? '',
                deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
              ),
            );
      case 'HistoricoOrdemPreparo':
      case 'historicos_ordem_preparo':
        await db.into(db.historicosOrdemPreparoTable).insertOnConflictUpdate(
              HistoricosOrdemPreparoTableCompanion.insert(
                id: row['id'] as String,
                tenantId: row['tenantId'] as String,
                ordemPreparoId: row['ordemPreparoId'] as String,
                titulo: row['titulo'] as String? ?? 'Status alterado',
                descricao: row['descricao'] as String? ?? '',
                operadorNome: Value(row['operadorNome'] as String? ?? 'Operador'),
                criadaEm: _parseDate(row['criadaEm'] as String?) ?? DateTime.now(),
                syncVersion: Value(row['syncVersion'] as int? ?? 1),
                syncStatus: SyncStatus.synced,
                lastSyncedAt: Value(DateTime.now().toUtc()),
                createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
                createdBy: row['createdBy'] as String? ?? '',
                updatedBy: row['updatedBy'] as String? ?? '',
                deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
              ),
            );
        break;

      // ESTOQUE: Produtos Acabados
      case 'estoque_produto':
      case 'EstoqueProduto':
        await db.into(db.estoqueProdutosTable).insertOnConflictUpdate(
          EstoqueProdutosTableCompanion.insert(
            id: row['id'] as String,
            tenantId: row['tenantId'] as String,
            produtoId: row['produtoId'] as String,
            quantidadeAtual: Value(row['quantidadeAtual'] as int? ?? 0),
            quantidadeReservada: Value(row['quantidadeReservada'] as int? ?? 0),
            quantidadeSeguranca: Value(row['quantidadeSeguranca'] as int? ?? 0),
            quantidadeMinima: Value(row['quantidadeMinima'] as int? ?? 0),
            quantidadeCritica: Value(row['quantidadeCritica'] as int? ?? 0),
            quantidadeMaxima: Value(row['quantidadeMaxima'] as int? ?? 9999),
            quantidadeProducaoLote: Value(row['quantidadeProducaoLote'] as int? ?? 100),
            diasCoberturaAlvo: Value(row['diasCoberturaAlvo'] as int? ?? 3),
            capacidadeCampanha: Value(row['capacidadeCampanha'] as int? ?? 0),
            estrategiaProducao: Value(row['estrategiaProducao'] as String? ?? 'concentrada'),
            tempoPreparacao: Value(row['tempoPreparacao'] as int? ?? 0),
            unidade: Value(row['unidade'] as String? ?? 'un'),
            syncVersion: Value(row['syncVersion'] as int? ?? 1),
            syncStatus: SyncStatus.synced,
            lastSyncedAt: Value(DateTime.now().toUtc()),
            createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
            updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
            createdBy: row['createdBy'] as String? ?? '',
            updatedBy: row['updatedBy'] as String? ?? '',
            deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
            deletedBy: const Value(null),
          ),
        );
        break;

      case 'movimentacao_estoque':
      case 'MovimentacaoEstoque':
        await db.into(db.movimentacoesEstoqueTable).insertOnConflictUpdate(
          MovimentacoesEstoqueTableCompanion.insert(
            id: row['id'] as String,
            tenantId: row['tenantId'] as String,
            produtoId: row['produtoId'] as String,
            pedidoId: Value(row['pedidoId'] as String?),
            tipo: row['tipo'] as String? ?? 'saida',
            quantidade: row['quantidade'] as int? ?? 0,
            quantidadeAntes: row['quantidadeAntes'] as int? ?? 0,
            quantidadeDepois: row['quantidadeDepois'] as int? ?? 0,
            quantidadeReservadaAntes: Value(row['quantidadeReservadaAntes'] as int?),
            quantidadeReservadaDepois: Value(row['quantidadeReservadaDepois'] as int?),
            motivo: Value(row['motivo'] as String? ?? ''),
            operadorId: Value(row['operadorId'] as String?),
            dataHora: _parseDate(row['dataHora'] as String?) ?? DateTime.now(),
            dataEntregaPrevista: Value(_parseDate(row['dataEntregaPrevista'] as String?)),
            syncVersion: Value(row['syncVersion'] as int? ?? 1),
            syncStatus: SyncStatus.synced,
            lastSyncedAt: Value(DateTime.now().toUtc()),
            createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
            updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
            createdBy: row['createdBy'] as String? ?? '',
            updatedBy: row['updatedBy'] as String? ?? '',
            deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
            deletedBy: const Value(null),
          ),
        );
        break;

      // FINANCEIRO: Sessões de Caixa e Lançamentos
      case 'sessao_caixa':
      case 'SessaoCaixa':
        await db.into(db.sessoesCaixaTable).insertOnConflictUpdate(
          SessoesCaixaTableCompanion.insert(
            id: row['id'] as String,
            tenantId: row['tenantId'] as String,
            operadorId: row['operadorId'] as String? ?? '',
            operadorNome: Value(row['operadorNome'] as String? ?? 'Operador'),
            status: Value(row['status'] as String? ?? 'aberta'),
            dataAbertura: _parseDate(row['dataAbertura'] as String?) ?? DateTime.now(),
            dataFechamento: Value(_parseDate(row['dataFechamento'] as String?)),
            valorAberturaCentavos: Value(row['valorAberturaCentavos'] as int? ?? 0),
            valorFechamentoCentavos: Value(row['valorFechamentoCentavos'] as int?),
            totalVendasCentavos: Value(row['totalVendasCentavos'] as int? ?? 0),
            totalDespesasCentavos: Value(row['totalDespesasCentavos'] as int? ?? 0),
            diferencaCentavos: Value(row['diferencaCentavos'] as int?),
            observacoes: Value(row['observacoes'] as String?),
            syncVersion: Value(row['syncVersion'] as int? ?? 1),
            syncStatus: SyncStatus.synced,
            lastSyncedAt: Value(DateTime.now().toUtc()),
            createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
            updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
            createdBy: row['createdBy'] as String? ?? '',
            updatedBy: row['updatedBy'] as String? ?? '',
            deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
            deletedBy: const Value(null),
          ),
        );
        break;

      case 'lancamento_financeiro':
      case 'LancamentoFinanceiro':
        await db.into(db.lancamentosFinanceirosTable).insertOnConflictUpdate(
          LancamentosFinanceirosTableCompanion.insert(
            id: row['id'] as String,
            tenantId: row['tenantId'] as String,
            sessaoCaixaId: row['sessaoCaixaId'] as String,
            pedidoId: Value(row['pedidoId'] as String?),
            tipo: row['tipo'] as String? ?? 'receita',
            formaPagamentoId: Value(row['formaPagamentoId'] as String?),
            formaPagamentoNome: Value(row['formaPagamentoNome'] as String?),
            valorCentavos: row['valorCentavos'] as int? ?? 0,
            descricao: Value(row['descricao'] as String? ?? ''),
            operadorId: Value(row['operadorId'] as String?),
            dataHora: _parseDate(row['dataHora'] as String?) ?? DateTime.now(),
            syncVersion: Value(row['syncVersion'] as int? ?? 1),
            syncStatus: SyncStatus.synced,
            lastSyncedAt: Value(DateTime.now().toUtc()),
            createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
            updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
            createdBy: row['createdBy'] as String? ?? '',
            updatedBy: row['updatedBy'] as String? ?? '',
            deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
            deletedBy: const Value(null),
          ),
        );
        break;

      default:
        break;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // _applyRowLocally: PEDIDOS e ITENS DO PEDIDO
  // Chamado durante o PULL para sincronizar pedidos de outros
  // dispositivos do mesmo tenant (multi-caixa, multi-operador).
  // ──────────────────────────────────────────────────────────────
  Future<void> _applyPedidoLocally(Map<String, dynamic> row, FincoreDatabase db) async {
    await db.into(db.pedidosTable).insertOnConflictUpdate(
      PedidosTableCompanion.insert(
        id: row['id'] as String,
        tenantId: row['tenantId'] as String,
        status: Value(row['status'] as String? ?? 'confirmado'),
        tipoLogistica: row['tipoLogistica'] as String? ?? 'Retirada',
        clienteId: Value(row['clienteId'] as String?),
        clienteNomeAvulso: Value(row['clienteNomeAvulso'] as String?),
        clienteTelefoneAvulso: Value(row['clienteTelefoneAvulso'] as String?),
        valorSubtotalCentavos: row['valorSubtotalCentavos'] as int? ?? 0,
        valorTaxaEntregaCentavos: Value(row['valorTaxaEntregaCentavos'] as int? ?? 0),
        valorTotalCentavos: row['valorTotalCentavos'] as int? ?? 0,
        trocoParaCentavos: Value(row['trocoParaCentavos'] as int?),
        formaPagamentoId: Value(row['formaPagamentoId'] as String?),
        formaPagamentoNome: Value(row['formaPagamentoNome'] as String?),
        enderecoJson: Value(row['enderecoJson'] as String?),
        operadorId: Value(row['operadorId'] as String?),
        dataHoraCriacao: _parseDate(row['dataHoraCriacao'] as String?) ?? DateTime.now(),
        numeroPedido: Value(row['numeroPedido'] as int?),
        observacoes: Value(row['observacoes'] as String?),
        canalOrigem: Value(row['canalOrigem'] as String? ?? 'pdv_express'),
        syncVersion: Value(row['syncVersion'] as int? ?? 1),
        syncStatus: SyncStatus.synced,
        lastSyncedAt: Value(DateTime.now().toUtc()),
        createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
        updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
        createdBy: row['createdBy'] as String? ?? '',
        updatedBy: row['updatedBy'] as String? ?? '',
        deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
        deletedBy: const Value(null),
      ),
    );
  }

  Future<void> _applyItemPedidoLocally(Map<String, dynamic> row, FincoreDatabase db) async {
    await db.into(db.itensPedidoTable).insertOnConflictUpdate(
      ItensPedidoTableCompanion.insert(
        id: row['id'] as String,
        tenantId: row['tenantId'] as String,
        pedidoId: row['pedidoId'] as String,
        produtoId: row['produtoId'] as String,
        nomeProduto: row['nomeProduto'] as String? ?? '',
        quantidade: (row['quantidade'] as num?)?.toDouble() ?? 1.0,
        valorUnitarioCentavos: row['valorUnitarioCentavos'] as int? ?? 0,
        valorTotalCentavos: row['valorTotalCentavos'] as int? ?? 0,
        observacoes: Value(row['observacoes'] as String?),
        syncVersion: Value(row['syncVersion'] as int? ?? 1),
        syncStatus: SyncStatus.synced,
        lastSyncedAt: Value(DateTime.now().toUtc()),
        createdAt: _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
        updatedAt: _parseDate(row['updatedAt'] as String?) ?? DateTime.now(),
        createdBy: row['createdBy'] as String? ?? '',
        updatedBy: row['updatedBy'] as String? ?? '',
        deletedAt: Value(_parseDate(row['deletedAt'] as String?)),
        deletedBy: const Value(null),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // REALTIME: Supabase WebSocket → local imediato
  // ──────────────────────────────────────────────────────────

  /// Inicia listeners Realtime e o Polling de fallback de rede a cada 10 segundos.
  void startRealtimeListeners(FincoreDatabase db) {
    if (!_context.hasContext) return;
    final tenantId = _context.tenantId;

    // Cancela timer de polling ativo para evitar duplicidade
    _pollingTimer?.cancel();

    // 1. Configura Polling de Fallback Periódico (caso o Realtime não esteja ativo)
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      final online = await isOnline();
      if (online) {
        final dateThreshold = _lastPullTimestamp ?? DateTime.now().subtract(const Duration(minutes: 10)).toUtc();
        try {
          await pullAll(db, dateThreshold);
        } catch (e) {
          LogService.instance.error(LogModule.sync, '[SupabaseSync] Falha no fallback polling', exception: e.toString());
        }
      }
    });

    // 3. Configura Realtime Listeners (WebSocket)
    for (final entry in _entityToTable.entries) {
      final entityName = entry.key;
      final tableName = entry.value;

      final channel = _supabase
          .channel('fincore_${tableName}_$tenantId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: tableName,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'tenantId',
              value: tenantId,
            ),
            callback: (payload) async {
              final newRecord = payload.newRecord;
              if (newRecord.isEmpty) return;

              final rowId = newRecord['id'] as String?;
              if (rowId == null) return;

              final shortId = rowId.length > 8 ? '${rowId.substring(0, 8)}...' : rowId;
              final desc = (newRecord['nome'] ?? newRecord['descricao'] ?? newRecord['tipo'] ?? '') as String;
              final serverVersion = (newRecord['syncVersion'] as num?)?.toInt() ?? 1;
              final localVersion = await _getLocalSyncVersion(entityName, rowId, db);
              final isLocked = await _outbox.hasPendingForEntity(entityName, rowId);

              final decision = _conflictResolver.resolve(
                entityName: entityName,
                entityId: rowId,
                hasOutboxPending: isLocked,
                localVersion: localVersion,
                serverVersion: serverVersion,
              );

              if (!decision.allowOverwrite) {
                LogService.instance.info(
                  LogModule.sync,
                  '[REALTIME] 🛡️ IGNORADO / PROTEGIDO\n'
                  '  Entidade: $entityName\n'
                  '  ID: $shortId\n'
                  '  Descrição: $desc\n'
                  '  Motivo: ${decision.reason}\n'
                  '  Ação: Evento Realtime descartado localmente.',
                  tenantId: tenantId,
                );
                return;
              }

              try {
                await db.transaction(() async {
                  await _applyRowLocally(entityName, newRecord, db);
                });
                _updateConnectivity(CloudConnectivity.online);
                final serverVersion = (newRecord['syncVersion'] as num?)?.toInt() ?? 1;
                LogService.instance.info(
                  LogModule.sync,
                  'Sincronização em tempo real: Registro [$entityName] id=$shortId ("$desc") atualizado localmente (v$serverVersion)',
                );
              } catch (e) {
                LogService.instance.error(
                  LogModule.sync,
                  'Falha ao aplicar alteração em tempo real para $entityName',
                  exception: e.toString(),
                );
              }
            },
          )
          .subscribe((status, [error]) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              LogService.instance.debug(LogModule.sync, 'Canal de tempo real ativado com sucesso: $tableName');
            } else if (status == RealtimeSubscribeStatus.channelError) {
              LogService.instance.debug(
                LogModule.sync,
                'Canal de tempo real inativo para $tableName — consulta periódica ativa.',
              );
            }
          });

      _channels.add(channel);
    }

    LogService.instance.info(LogModule.sync, 'Serviço de sincronização em tempo real ativo em ${_channels.length} tabela(s).');
  }

  /// Para todos os listeners Realtime e cancela o polling periódico. Deve ser chamado no logout.
  Future<void> stopRealtimeListeners() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    for (final channel in _channels) {
      await _supabase.removeChannel(channel);
    }
    _channels.clear();
    _connectivity = CloudConnectivity.unknown;
    LogService.instance.info(LogModule.sync, 'Serviço de sincronização em tempo real encerrado.');
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }
}

class OfflineSyncException implements Exception {
  final String message;
  OfflineSyncException(this.message);

  @override
  String toString() => message;
}
