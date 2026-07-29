import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:fincore_core/fincore_core.dart';

/// Estado de conectividade com a nuvem.
enum CloudConnectivity { online, offline, unknown }

/// Gerencia a sincronização bidirecional entre SQLite local e Supabase.
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

  // Mapeamento: entityName do outbox → nome da tabela no Supabase (no singular)
  static const Map<String, String> _entityToTable = {
    'empresa_configuracao': 'empresa_configuracao',
    'categorias': 'categoria',
    'produtos': 'produto',
    'clientes': 'cliente',
    'formas_pagamento': 'forma_pagamento',
    'locais_entrega': 'local_entrega',
    'taxas_entrega': 'taxa_entrega',
    'membros_empresa': 'membro_empresa',
    'tabelas_precificacao': 'tabela_precificacao',
    'itens_tabela_precificacao': 'item_tabela_precificacao',
    'produtos_tabelas_precificacao': 'produto_tabela_precificacao',
    'audit_log': 'audit_logs',
  };

  SupabaseSyncService({
    required SupabaseClient supabase,
    required TenantContext context,
    required OutboxService outbox,
  })  : _supabase = supabase,
        _context = context,
        _outbox = outbox;

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
        LogService.instance.info(LogModule.sync, '✅ Conectividade restaurada — sync retomado');
      } else {
        LogService.instance.warning(LogModule.sync, '⚠️ Sem conectividade — modo offline. Dados salvos localmente.');
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
      LogService.instance.debug(LogModule.sync, 'Offline — push de ${entry.entity} adiado');
      throw OfflineSyncException('Sem conexão com o servidor (Offline)');
    }

    final tableName = _entityToTable[entry.entity];
    if (tableName == null) {
      LogService.instance.warning(LogModule.sync, 'Entidade desconhecida: ${entry.entity} — ignorando push');
      return true;
    }

    try {
      final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
      
      // Mapeamento de compatibilidade para registros antigos na fila local de audit_logs
      if (tableName == 'audit_logs' && payload.containsKey('targetEntity')) {
        payload['entityName'] = payload.remove('targetEntity');
      }

      LogService.instance.debug(
        LogModule.sync,
        'SupabaseSync enviando PUSH:\nTabela: $tableName\nAção: ${entry.action}\nID: ${entry.entityId}\nPayload: ${entry.payload}',
        tenantId: _context.hasContext ? _context.tenantId : null,
      );

      if (entry.action == 'DELETE') {
        await _supabase
            .from(tableName)
            .update({'deletedAt': DateTime.now().toUtc().toIso8601String()})
            .eq('id', entry.entityId)
            .eq('tenantId', _context.tenantId);
      } else {
        await _supabase.from(tableName).upsert(
          payload,
          onConflict: 'id',
        );
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
  /// Retorna `true` se a sincronização foi completada com sucesso, ou `false` se offline/erro.
  Future<bool> pullAll(FincoreDatabase db, DateTime lastSyncAt) async {
    if (!_context.hasContext) return false;

    final online = await isOnline();
    if (!online) {
      LogService.instance.debug(LogModule.sync, 'Pull cancelado — sem conexão. App rodando 100% offline.');
      return false;
    }

    final tenantId = _context.tenantId;

    try {
      // Executa as tabelas em ordem topológica (pai antes de filho)
      // para evitar FK violations no banco local durante o pull.
      await _pullTable('empresa_configuracao', tenantId, lastSyncAt, db);
      await _pullTable('categorias', tenantId, lastSyncAt, db);
      await _pullTable('tabelas_precificacao', tenantId, lastSyncAt, db);
      await _pullTable('taxas_entrega', tenantId, lastSyncAt, db);
      await _pullTable('formas_pagamento', tenantId, lastSyncAt, db);
      await _pullTable('clientes', tenantId, lastSyncAt, db);
      await _pullTable('produtos', tenantId, lastSyncAt, db);
      await _pullTable('locais_entrega', tenantId, lastSyncAt, db);
      await _pullTable('itens_tabela_precificacao', tenantId, lastSyncAt, db);
      await _pullTable('produtos_tabelas_precificacao', tenantId, lastSyncAt, db);

      // Marca a data/hora exata em UTC do término do PULL bem-sucedido
      _lastPullTimestamp = DateTime.now().toUtc();
      return true;
    } catch (e) {
      LogService.instance.error(LogModule.sync, '[PULL] Falha crítica durante o pullAll', exception: e.toString());
      return false;
    }
  }

  final ConflictResolver _conflictResolver = const ConflictResolver();

  Future<void> _pullTable(
    String entityName,
    String tenantId,
    DateTime since,
    FincoreDatabase db,
  ) async {
    final tableName = _entityToTable[entityName];
    if (tableName == null) return;

    final isFullPull = since.isBefore(DateTime.now().subtract(const Duration(days: 6)));
    final pullType = isFullPull
        ? 'FULL PULL (Carga Inicial)'
        : 'INCREMENTAL PULL (Desde ${_formatDateTime(since)})';

    try {
      final rows = await _supabase
          .from(tableName)
          .select()
          .eq('tenantId', tenantId)
          .gte('updatedAt', since.toIso8601String());

      if (rows.isEmpty) return;

      // ── ESCUDO DO PULL (OUTBOX) ─────────────────────────────
      final lockedIds = await _outbox.getPendingEntityIds(entityName);
      // ─────────────────────────────────────────────────────────

      int appliedCount = 0;
      int protectedCount = 0;
      int stalledCount = 0;
      final List<String> protectedDetails = [];
      final List<String> stalledDetails = [];

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
              protectedDetails.add('• $entityName [$shortId] "$desc" — Outbox pendente');
            } else {
              stalledCount++;
              stalledDetails.add('• $entityName [$shortId] "$desc" — Servidor v$serverVersion < Local v$localVersion');
            }
            continue;
          }
          // ─────────────────────────────────────────────────────────

          await _applyRowLocally(entityName, row, db);
          appliedCount++;
        }
      });

      if (rows.isNotEmpty) {
        final total = rows.length;
        final buffer = StringBuffer();
        buffer.writeln('[PULL] 📥 $entityName ($pullType)');
        buffer.writeln('Total alterados no servidor: $total');
        buffer.writeln('✔ Aplicados: $appliedCount');
        buffer.writeln('🛡️ Protegidos (Outbox pendente): $protectedCount');
        buffer.writeln('⏭️ Ignorados (versão obsoleta): $stalledCount');

        if (protectedDetails.isNotEmpty) {
          buffer.writeln('');
          buffer.writeln('── Registros Protegidos ──');
          for (final d in protectedDetails) {
            buffer.writeln(d);
          }
        }

        if (stalledDetails.isNotEmpty) {
          buffer.writeln('');
          buffer.writeln('── Registros Ignorados (versão obsoleta) ──');
          for (final d in stalledDetails) {
            buffer.writeln(d);
          }
        }

        LogService.instance.info(
          LogModule.sync,
          buffer.toString(),
          tenantId: tenantId,
        );
      }
    } on SocketException {
      _updateConnectivity(CloudConnectivity.offline);
      LogService.instance.debug(LogModule.sync, '[PULL] Offline durante $pullType de $entityName — dados locais mantidos.');
    } catch (e) {
      LogService.instance.error(LogModule.sync, '[PULL] Erro no $pullType de $entityName', exception: e.toString());
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
                timezone: Value(row['timezone'] as String? ?? 'America/Sao_Paulo'),
                locale: Value(row['locale'] as String? ?? 'pt_BR'),
                currency: Value(row['currency'] as String? ?? 'BRL'),
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
                pixCidade: Value(row['pixCidade'] as String? ?? 'Sorocaba'),
                nomeEmpresaCupom: Value(row['nomeEmpresaCupom'] as String?),
                telefoneEmpresa: Value(row['telefoneEmpresa'] as String?),
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

      default:
        break;
    }
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
                  '[REALTIME] ✔ Aplicado\n'
                  '  Entidade: $entityName\n'
                  '  ID: $shortId\n'
                  '  Descrição: $desc\n'
                  '  syncVersion: $serverVersion',
                );
              } catch (e) {
                LogService.instance.error(
                  LogModule.sync,
                  '[REALTIME] Erro ao aplicar $entityName ($tableName)',
                  exception: e.toString(),
                );
              }
            },
          )
          .subscribe((status, [error]) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              LogService.instance.info(LogModule.sync, '[REALTIME] ✅ Canal WebSocket ativo: $tableName (Tempo real ligado)');
            } else if (status == RealtimeSubscribeStatus.channelError) {
              LogService.instance.debug(
                LogModule.sync,
                '[REALTIME] ℹ️ Canal WebSocket inativo para $tableName. '
                '(Nota: Se desejar atualizações instantâneas sem aguardar o polling de 60s, '
                'ative a opção "Realtime" para a tabela "$tableName" no Supabase Dashboard em Database -> Realtime).',
              );
            }
          });

      _channels.add(channel);
    }

    LogService.instance.info(LogModule.sync, '[SupabaseSync] ${_channels.length} listeners Realtime iniciados.');
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
    LogService.instance.info(LogModule.sync, '[SupabaseSync] Listeners Realtime e fallback polling encerrados.');
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
