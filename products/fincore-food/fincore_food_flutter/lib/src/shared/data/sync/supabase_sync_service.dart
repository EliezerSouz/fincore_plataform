import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:fincore_core/fincore_core.dart';
import '../../../estoque/controllers/estoque_controller.dart';

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

  final StreamController<String> _syncEventsController = StreamController<String>.broadcast();
  Stream<String> get onDataSynced => _syncEventsController.stream;

  // Conjunto de colunas ausentes conhecidas no Supabase (prevenção e auto-heal dinâmico)
  static final Set<String> _knownMissingColumns = {
    'forma_pagamento.isUsoInterno',
    'forma_pagamento.movimentaFinanceiro',
    'forma_pagamento.movimentaEstoque',
    'forma_pagamento.bandeiraPadrao',
    'forma_pagamento.descricao',
    'forma_pagamento.pixChave',
    'forma_pagamento.pixTipoChave',
    'forma_pagamento.pixTipoBanco',
  };

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
    'planejamento_producao': 'planejamento_producao',
    'PlanejamentoProducao': 'planejamento_producao',
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
    if (kIsWeb) {
      _updateConnectivity(CloudConnectivity.online);
      return true;
    }
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
      final recheck = await isOnline();
      if (!recheck) {
        LogService.instance.debug(LogModule.sync, 'Offline - push de ${entry.entity} adiado');
        throw OfflineSyncException('Sem conexao com o servidor (Offline)');
      }
    }

    final tableName = _entityToTable[entry.entity];
    if (tableName == null) {
      LogService.instance.warning(LogModule.sync, 'Entidade desconhecida: ${entry.entity} - ignorando push');
      return true;
    }

    try {
      final payload = jsonDecode(entry.payload) as Map<String, dynamic>;
      payload.remove('_traceId');
      payload.remove('traceId');

      // Remove preventivamente colunas que sabidamente não existem no schema remoto do Supabase
      payload.removeWhere((key, _) => _knownMissingColumns.contains('$tableName.$key'));

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

      if (tableName == 'usuarios') {
        payload.remove('createdAt');
        payload.remove('updatedAt');
        payload.remove('createdBy');
        payload.remove('updatedBy');
        payload.remove('syncVersion');
        payload.remove('sync_version');
        payload.remove('syncStatus');
        payload.remove('sync_status');
        payload.remove('lastSyncedAt');
        payload.remove('last_synced_at');

        if (payload.containsKey('username')) {
          final usernameVal = payload['username'] as String? ?? '';
          if (usernameVal.isNotEmpty) {
            try {
              final existing = await _supabase.from('usuarios').select('id').eq('username', usernameVal).maybeSingle();
              if (existing != null && existing['id'] != null) {
                final remoteId = existing['id'] as String;
                if (remoteId != payload['id']) {
                  payload['id'] = remoteId;
                  LogService.instance.info(
                    LogModule.sync,
                    'Usuário "$usernameVal" alinhado com ID existente no Supabase: $remoteId',
                  );
                }
              }
            } catch (_) {}
          }
        }
      }

      if (tableName == 'membro_empresa' && payload.containsKey('usuarioId')) {
        final usrId = payload['usuarioId'] as String? ?? '';
        if (usrId.isNotEmpty) {
          try {
            final db = DependencyInjection().get<FincoreDatabase>();
            final usr = await (db.select(db.usuariosTable)..where((t) => t.id.equals(usrId))).getSingleOrNull();
            if (usr != null) {
              final existingRemote = await _supabase.from('usuarios').select('id').eq('username', usr.username).maybeSingle();
              final targetUserId = existingRemote != null ? (existingRemote['id'] as String) : usr.id;
              payload['usuarioId'] = targetUserId;

              await _supabase.from('usuarios').upsert({
                'id': targetUserId,
                'tenantId': usr.tenantId,
                'authUserId': usr.authUserId,
                'username': usr.username,
                'email': usr.email,
                'nome': usr.nome,
                'avatarUrl': usr.avatarUrl,
                'ativo': usr.ativo,
                'criadoEm': usr.criadoEm.toIso8601String(),
                'atualizadoEm': usr.atualizadoEm.toIso8601String(),
              }, onConflict: 'id');
            } else if (_context.hasContext && _context.usuario.id.isNotEmpty) {
              final ctxUsr = _context.usuario;
              await _supabase.from('usuarios').upsert({
                'id': ctxUsr.id,
                'tenantId': ctxUsr.tenantId,
                'authUserId': null,
                'username': ctxUsr.nome.toLowerCase().replaceAll(' ', '_'),
                'email': ctxUsr.email,
                'nome': ctxUsr.nome,
                'avatarUrl': null,
                'ativo': true,
                'criadoEm': DateTime.now().toIso8601String(),
                'atualizadoEm': DateTime.now().toIso8601String(),
              }, onConflict: 'id');
              payload['usuarioId'] = ctxUsr.id;
            }
          } catch (_) {}
        }

        final targetUsrId = payload['usuarioId'] as String? ?? '';
        final targetTenantId = payload['tenantId'] as String? ?? '';
        if (targetUsrId.isNotEmpty && targetTenantId.isNotEmpty) {
          try {
            final existingMembro = await _supabase
                .from('membro_empresa')
                .select('id')
                .eq('usuarioId', targetUsrId)
                .eq('tenantId', targetTenantId)
                .maybeSingle();
            if (existingMembro != null && existingMembro['id'] != null) {
              final remoteMembroId = existingMembro['id'] as String;
              if (remoteMembroId != payload['id']) {
                payload['id'] = remoteMembroId;
                LogService.instance.info(
                  LogModule.sync,
                  'Membro empresa (usuarioId, tenantId) alinhado com ID existente no Supabase: $remoteMembroId',
                );
              }
            }
          } catch (_) {}
        }
      }

      LogService.instance.debug(
        LogModule.sync,
        'Supabase PUSH: Tabela: $tableName | Acao: ${entry.action} | ID: ${entry.entityId}',
        tenantId: _context.hasContext ? _context.tenantId : null,
      );

      // Sanitizar tenantId, createdBy e updatedBy
      final tenantUserId = _context.hasContext ? _context.usuario.id : '00000000-0000-0000-0000-000000000000';
      
      // A tabela 'empresa' / 'empresas' não possui a coluna 'tenantId' no Supabase (o ID da empresa É o tenantId)
      if (tableName == 'empresa' || tableName == 'empresas') {
        payload.remove('tenantId');
        payload.remove('tenant_id');
      } else if (!payload.containsKey('tenantId') || payload['tenantId'] == null || (payload['tenantId'] as String).isEmpty) {
        if (_context.hasContext && _context.tenantId.isNotEmpty) {
          payload['tenantId'] = _context.tenantId;
        }
      }

      // Garante campos obrigatórios de auditoria para integridade no Supabase (evitando violação de not-null constraint)
      if (tableName != 'audit_logs') {
        final valUpdated = payload['updatedBy'] as String? ?? '';
        if (valUpdated.isEmpty || valUpdated == 'PDV' || valUpdated == 'system' || !valUpdated.contains('-')) {
          payload['updatedBy'] = tenantUserId;
        }

        if (!payload.containsKey('createdAt') || payload['createdAt'] == null) {
          payload['createdAt'] = DateTime.now().toUtc().toIso8601String();
        }
        if (!payload.containsKey('updatedAt') || payload['updatedAt'] == null) {
          payload['updatedAt'] = DateTime.now().toUtc().toIso8601String();
        }
      }

      // REGRA DE IMUTABILIDADE DO CRIADOR [VAL-002]:
      // O criador original (createdBy / created_by) NUNCA pode ser alterado em edições/updates na nuvem.
      // Preservamos o createdBy original se ele já existir no Supabase, ou definimos um UUID válido caso novo.
      if (tableName != 'audit_logs' && payload.containsKey('id')) {
        try {
          final idVal = payload['id'] as String;
          final existingRemote = await _supabase.from(tableName).select('id, createdBy').eq('id', idVal).maybeSingle();
          if (existingRemote != null && existingRemote['createdBy'] != null && (existingRemote['createdBy'] as String).isNotEmpty) {
            payload['createdBy'] = existingRemote['createdBy'];
          } else {
            final val = payload['createdBy'] as String? ?? '';
            if (val.isEmpty || val == 'PDV' || val == 'system' || !val.contains('-')) {
              payload['createdBy'] = tenantUserId;
            }
          }
        } catch (_) {
          final val = payload['createdBy'] as String? ?? '';
          if (val.isEmpty || val == 'PDV' || val == 'system' || !val.contains('-')) {
            payload['createdBy'] = tenantUserId;
          }
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

      // Garantir integridade de chave estrangeira para lancamento_financeiro -> sessao_caixa
      if (tableName == 'lancamento_financeiro' && payload.containsKey('sessaoCaixaId')) {
        final sessaoId = payload['sessaoCaixaId'] as String? ?? '';
        if (sessaoId.isNotEmpty && RegExp(r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$').hasMatch(sessaoId)) {
          try {
            final remoteSessao = await _supabase.from('sessao_caixa').select('id').eq('id', sessaoId).maybeSingle();
            if (remoteSessao == null) {
              final db = DependencyInjection().get<FincoreDatabase>();
              final sessaoRow = await (db.select(db.sessoesCaixaTable)..where((t) => t.id.equals(sessaoId))).getSingleOrNull();
              if (sessaoRow != null) {
                await _supabase.from('sessao_caixa').upsert({
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
                }, onConflict: 'id');
                LogService.instance.info(
                  LogModule.sync,
                  'Sessão de caixa pai ($sessaoId) enviada preventivamente para garantir integridade do lançamento financeiro.',
                );
              }
            }
          } catch (e) {
            LogService.instance.warning(LogModule.sync, 'Aviso ao verificar sessao_caixa pai: $e');
          }
        }
      }

      // Sanitizar clienteId se contiver strings não-UUID (ex: 'consumidor_final')
      if (payload.containsKey('clienteId')) {
        final val = payload['clienteId'] as String? ?? '';
        if (val.isNotEmpty) {
          final isUuid = RegExp(r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$').hasMatch(val);
          if (!isUuid) {
            payload['clienteId'] = null;
          }
        }
      }

      // Sanitizar operadorId se contiver strings não-UUID (ex: 'system', 'admin')
      if (payload.containsKey('operadorId')) {
        final val = payload['operadorId'] as String? ?? '';
        if (val.isNotEmpty) {
          final isUuid = RegExp(r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$').hasMatch(val);
          if (!isUuid) {
            payload['operadorId'] = null;
          }
        }
      }

      // Sanitizar sessaoCaixaId se contiver strings não-UUID (ex: 'sessao_avulsa_...')
      if (tableName == 'lancamento_financeiro' || payload.containsKey('sessaoCaixaId')) {
        final val = payload['sessaoCaixaId'] as String? ?? '';
        final isUuid = RegExp(r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$').hasMatch(val);
        if (!isUuid) {
          try {
            final tId = payload['tenantId'] ?? _context.tenantId;
            final sessaoRemote = await _supabase.from('sessao_caixa').select('id').eq('tenantId', tId).eq('status', 'aberta').maybeSingle();
            if (sessaoRemote != null && sessaoRemote['id'] != null) {
              payload['sessaoCaixaId'] = sessaoRemote['id'] as String;
            } else {
              final fallbackSessaoId = const Uuid().v4();
              await _supabase.from('sessao_caixa').upsert({
                'id': fallbackSessaoId,
                'tenantId': tId,
                'operadorId': tenantUserId,
                'operadorNome': 'Operador',
                'status': 'aberta',
                'dataAbertura': DateTime.now().toUtc().toIso8601String(),
                'createdAt': DateTime.now().toUtc().toIso8601String(),
                'updatedAt': DateTime.now().toUtc().toIso8601String(),
                'createdBy': tenantUserId,
                'updatedBy': tenantUserId,
              }, onConflict: 'id');
              payload['sessaoCaixaId'] = fallbackSessaoId;
            }
          } catch (_) {
            payload['sessaoCaixaId'] = const Uuid().v4();
          }
        }
      }

      // Sanitizar campo 'status' para tabelas pedido e ordens_preparo:
      // O CHECK CONSTRAINT no PostgreSQL ('pedido_status_check') exige:
      // ('rascunho', 'confirmado', 'em_preparo', 'pronto', 'entregue', 'cancelado').
      if (tableName == 'pedido') {
        // Sanitizar valorTaxaServicoCentavos apenas se for envio com valores financeiros
        if (payload.containsKey('valorSubtotalCentavos')) {
          final subtotal = (payload['valorSubtotalCentavos'] as num?)?.toInt() ?? 0;
          final entrega = (payload['valorTaxaEntregaCentavos'] as num?)?.toInt() ?? 0;
          final total = (payload['valorTotalCentavos'] as num?)?.toInt() ?? 0;
          int servico = (payload['valorTaxaServicoCentavos'] as num?)?.toInt() ?? (total - subtotal - entrega);
          if (servico < 0) servico = 0;
          payload['valorTaxaServicoCentavos'] = servico;
        }

        if (payload.containsKey('status')) {
          const statusMap = {
            'emPreparo': 'em_preparo',
            'recebido': 'confirmado',
            'saiuparaentrega': 'saiu_para_entrega',
            'saiuParaEntrega': 'saiu_para_entrega',
            'saiu_entrega': 'saiu_para_entrega',
            'em_transito': 'saiu_para_entrega',
            'emtransito': 'saiu_para_entrega',
            'emTransito': 'saiu_para_entrega',
            'a_caminho': 'saiu_para_entrega',
            'em_entrega': 'saiu_para_entrega',
          };
          final rawStatus = payload['status'] as String? ?? '';
          if (statusMap.containsKey(rawStatus)) {
            payload['status'] = statusMap[rawStatus];
            LogService.instance.debug(
              LogModule.sync,
              'Status de Pedido sanitizado: "$rawStatus" → "${payload['status']}" ($tableName)',
            );
          } else if (!const {
            'rascunho',
            'pendente',
            'confirmado',
            'recebido',
            'em_preparo',
            'pronto',
            'aguardando_retirada',
            'saiu_para_entrega',
            'saiu_entrega',
            'em_entrega',
            'a_caminho',
            'entregue',
            'concluido',
            'finalizado',
            'cancelado'
          }.contains(rawStatus)) {
            // Fallback defensivo para qualquer outro status desconhecido
            payload['status'] = 'confirmado';
          }
          try {
            final remoteRow = await _supabase.from('pedido').select('status, syncVersion').eq('id', entry.entityId).maybeSingle();
            if (remoteRow != null && remoteRow['status'] != null) {
              final remoteStatus = remoteRow['status'] as String;
              final remoteVersion = (remoteRow['syncVersion'] as num?)?.toInt() ?? 1;
              final payloadStatus = payload['status'] as String;
              final payloadVersion = (payload['syncVersion'] as num?)?.toInt() ?? entry.version;

              if (StatusPrecedence.isHigherOrEqual(payloadStatus, remoteStatus)) {
                // Se o status local é mais avançado ou igual (ex: entregue vs pronto/saiu_para_entrega):
                // garante que syncVersion supere a versão remota para gravar com sucesso na nuvem
                if (payloadVersion <= remoteVersion) {
                  payload['syncVersion'] = remoteVersion + 1;
                }
              } else {
                // Status local é inferior ao remoto (ex: remoto já entregue e local tenta voltar a em_preparo)
                if (payloadVersion < remoteVersion) {
                  payload['status'] = remoteStatus;
                }
              }
            }
          } catch (_) {}
        }
      } else if (tableName == 'ordens_preparo' && payload.containsKey('status')) {
        const statusCamelToSnake = {
          'emPreparo': 'em_preparo',
          'confirmado': 'pendente',
          'saiuparaentrega': 'saiu_para_entrega',
          'saiuParaEntrega': 'saiu_para_entrega',
          'saiu_entrega': 'saiu_para_entrega',
          'em_transito': 'saiu_para_entrega',
          'emtransito': 'saiu_para_entrega',
          'emTransito': 'saiu_para_entrega',
          'a_caminho': 'saiu_para_entrega',
          'em_entrega': 'saiu_para_entrega',
        };
        final rawStatus = payload['status'] as String? ?? '';
        if (statusCamelToSnake.containsKey(rawStatus)) {
          payload['status'] = statusCamelToSnake[rawStatus];
          LogService.instance.debug(
            LogModule.sync,
            'Status sanitizado: "$rawStatus" → "${payload['status']}" ($tableName)',
          );
        }
        try {
          final remoteRow = await _supabase.from('ordens_preparo').select('status, syncVersion').eq('id', entry.entityId).maybeSingle();
          if (remoteRow != null && remoteRow['status'] != null) {
            final remoteStatus = remoteRow['status'] as String;
            final remoteVersion = (remoteRow['syncVersion'] as num?)?.toInt() ?? 1;
            final payloadStatus = payload['status'] as String;
            final payloadVersion = (payload['syncVersion'] as num?)?.toInt() ?? entry.version;

            if (StatusPrecedence.isHigherOrEqual(payloadStatus, remoteStatus)) {
              if (payloadVersion <= remoteVersion) {
                payload['syncVersion'] = remoteVersion + 1;
              }
            } else {
              if (payloadVersion < remoteVersion) {
                payload['status'] = remoteStatus;
              }
            }
          }
        } catch (_) {}
      }

      if (tableName == 'planejamento_producao') {
        payload.remove('necessidadeOrigem');
        payload.remove('necessidade_origem');
      }

      if (entry.action == 'DELETE') {
        await _supabase
            .from(tableName)
            .update({'deletedAt': DateTime.now().toUtc().toIso8601String()})
            .eq('id', entry.entityId)
            .eq('tenantId', _context.tenantId)
            .timeout(const Duration(seconds: 10));
      } else if (entry.action.toLowerCase() == 'update') {
        final idCol = tableName == 'empresa_configuracao' ? 'tenantId' : 'id';
        int attempts = 0;
        while (attempts < 30) {
          try {
            await _supabase
                .from(tableName)
                .update(payload)
                .eq(idCol, entry.entityId)
                .eq('tenantId', _context.tenantId)
                .timeout(const Duration(seconds: 10));
            break;
          } on PostgrestException catch (e) {
            attempts++;
            if ((e.code == 'PGRST204' || e.message.contains("Could not find the '") || e.message.contains('in the schema cache')) && attempts < 30) {
              final match = RegExp(r"Could not find the '([^']+)' column").firstMatch(e.message);
              if (match != null) {
                final missingCol = match.group(1)!;
                _knownMissingColumns.add('$tableName.$missingCol');
                payload.remove(missingCol);
                if (tableName == 'pedido' && missingCol == 'valorTaxaServicoCentavos') {
                  int subtotal = (payload['valorSubtotalCentavos'] as num?)?.toInt() ?? 0;
                  int entrega = (payload['valorTaxaEntregaCentavos'] as num?)?.toInt() ?? 0;
                  if (subtotal == 0) {
                    try {
                      final db = DependencyInjection().get<FincoreDatabase>();
                      final localPed = await (db.select(db.pedidosTable)..where((t) => t.id.equals(entry.entityId))).getSingleOrNull();
                      if (localPed != null) {
                        subtotal = localPed.valorSubtotalCentavos;
                        entrega = localPed.valorTaxaEntregaCentavos;
                        payload['valorSubtotalCentavos'] = subtotal;
                        payload['valorTaxaEntregaCentavos'] = entrega;
                      }
                    } catch (_) {}
                  }
                  payload['valorTotalCentavos'] = subtotal + entrega;
                }
                LogService.instance.warning(
                  LogModule.sync,
                  'Coluna "$missingCol" ausente na tabela "$tableName" do Supabase - removida do payload para desobstruir sync.',
                );
                continue;
              }
            }
            rethrow;
          }
        }
      } else {
        final conflictCol = tableName == 'empresa_configuracao' ? 'tenantId' : 'id';
        int attempts = 0;
        while (attempts < 30) {
          try {
            await _supabase.from(tableName).upsert(
              payload,
              onConflict: conflictCol,
            ).timeout(const Duration(seconds: 10));
            break;
          } on PostgrestException catch (e) {
            attempts++;
            if (e.code == '23505') {
              if (tableName == 'membro_empresa' && payload.containsKey('usuarioId') && payload.containsKey('tenantId')) {
                await _supabase
                    .from('membro_empresa')
                    .update(payload)
                    .eq('usuarioId', payload['usuarioId'])
                    .eq('tenantId', payload['tenantId'])
                    .timeout(const Duration(seconds: 10));
                LogService.instance.info(
                  LogModule.sync,
                  'Membro empresa duplicado atualizado via (usuarioId, tenantId) no Supabase com sucesso.',
                );
                break;
              }
              if (tableName == 'usuarios' && payload.containsKey('username')) {
                await _supabase
                    .from('usuarios')
                    .update(payload)
                    .eq('username', payload['username'])
                    .timeout(const Duration(seconds: 10));
                LogService.instance.info(
                  LogModule.sync,
                  'Usuário duplicado atualizado via username no Supabase com sucesso.',
                );
                break;
              }
            }
            if ((e.code == 'PGRST204' || e.message.contains("Could not find the '") || e.message.contains('in the schema cache')) && attempts < 30) {
              final match = RegExp(r"Could not find the '([^']+)' column").firstMatch(e.message);
              if (match != null) {
                final missingCol = match.group(1)!;
                _knownMissingColumns.add('$tableName.$missingCol');
                payload.remove(missingCol);
                if (tableName == 'pedido' && missingCol == 'valorTaxaServicoCentavos') {
                  final subtotal = (payload['valorSubtotalCentavos'] as num?)?.toInt() ?? 0;
                  final entrega = (payload['valorTaxaEntregaCentavos'] as num?)?.toInt() ?? 0;
                  payload['valorTotalCentavos'] = subtotal + entrega;
                }
                LogService.instance.warning(
                  LogModule.sync,
                  'Coluna "$missingCol" ausente na tabela "$tableName" do Supabase - removida do payload para desobstruir sync.',
                );
                continue;
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
    final pullTraceId = CorrelationIdGenerator.generateCorrelationId();

    try {
      await LogService.instance.logSync(
        step: 'PULL',
        action: 'INICIO',
        traceId: pullTraceId,
        status: LogStatus.inProgress,
        message: 'Buscando atualizações remotas na nuvem',
        tenantId: tenantId,
      );

      int totalApplied = 0;
      int totalProtected = 0;

      final tables = [
        'usuarios',
        'empresas',
        'empresa_configuracao',
        'membros_empresa',
        'categorias',
        'tabelas_precificacao',
        'taxas_entrega',
        'formas_pagamento',
        'clientes',
        'produtos',
        'locais_entrega',
        'itens_tabela_precificacao',
        'produtos_tabelas_precificacao',
        'categorias_tabelas_precificacao',
        // P0-01: Pedidos e KDS Ordens de Preparo (Pull para sincronizar entre dispositivos)
        'pedidos',
        'itens_pedido',
        'ordens_preparo',
        'historicos_ordem_preparo',
        // Onboarding / IAM
        'empresa_convites',
        // ESTOQUE
        'estoque_produto',
        'movimentacao_estoque',
        'planejamento_producao',
        // FINANCEIRO
        'sessao_caixa',
        'lancamento_financeiro',
      ];

      // Rastreia quais tabelas tiveram mudanças aplicadas (para recálculo seletivo de estoque)
      final tablesWithChanges = <String>{};
      for (final table in tables) {
        final res = await _pullTable(table, tenantId, lastSyncAt, db);
        totalApplied += res.applied;
        totalProtected += res.protected;
        if (res.applied > 0) tablesWithChanges.add(table);
      }

      final durationMs = DateTime.now().difference(startTime).inMilliseconds;

      await LogService.instance.logSync(
        step: 'PULL',
        action: 'RESULTADO',
        traceId: pullTraceId,
        status: LogStatus.success,
        durationMs: durationMs,
        message: 'Tabelas verificadas: ${tables.length} | Aplicados: $totalApplied | Protegidos: $totalProtected | Resultado: SUCESSO',
        tenantId: tenantId,
      );

      // Se pedidos, itens ou movimentações foram atualizados via pull, recalcula
      // reservas e estoques para manter consistência entre múltiplos dispositivos.
      // O recálculo é idempotente e seguro de chamar após qualquer pull.
      final estoqueAlterado = tablesWithChanges.any((t) =>
          t == 'pedidos' ||
          t == 'itens_pedido' ||
          t == 'movimentacao_estoque' ||
          t == 'estoque_produto');
      if (estoqueAlterado) {
        try {
          final estoqueCtrl = DependencyInjection().tryGet<EstoqueController>();
          if (estoqueCtrl != null) {
            await estoqueCtrl.recalcularReservasEEstoques(isFromSync: true);
            LogService.instance.info(
              LogModule.sync,
              '[ESTOQUE] Recálculo de reservas disparado após pull (tabelas: ${tablesWithChanges.where((t) => t == "pedidos" || t == "itens_pedido" || t == "movimentacao_estoque" || t == "estoque_produto").join(", ")})',
              tenantId: tenantId,
            );
          }
        } catch (e) {
          LogService.instance.debug(LogModule.sync, '[ESTOQUE] Recálculo pós-pull adiado: $e');
        }
      }

      // Marca a data/hora exata em UTC do término do PULL bem-sucedido
      _lastPullTimestamp = DateTime.now().toUtc();
      _syncEventsController.add('ALL');
      return true;
    } catch (e) {
      await LogService.instance.logSync(
        step: 'PULL',
        action: 'RESULTADO',
        traceId: pullTraceId,
        status: LogStatus.failed,
        errorMessage: e.toString(),
        tenantId: tenantId,
      );
      return false;
    } finally {
      _isPulling = false;
    }
  }

  final ConflictResolver _conflictResolver = const ConflictResolver();

  Future<List<Map<String, dynamic>>> _fetchRemoteRows({
    required String tableName,
    required String tenantId,
    required DateTime since,
  }) async {
    if (tableName == 'empresa') {
      try {
        if (since.millisecondsSinceEpoch > 0) {
          try {
            final res = await _supabase.from(tableName).select().eq('id', tenantId).gte('updatedAt', since.toIso8601String());
            return res.cast<Map<String, dynamic>>();
          } catch (_) {
            final res = await _supabase.from(tableName).select().eq('id', tenantId).gte('updated_at', since.toIso8601String());
            return res.cast<Map<String, dynamic>>();
          }
        }
      } catch (_) {}
      final res = await _supabase.from(tableName).select().eq('id', tenantId);
      return res.cast<Map<String, dynamic>>();
    }

    if (tableName == 'usuarios') {
      try {
        List<dynamic> membroRows = [];
        try {
          membroRows = await _supabase.from('membro_empresa').select('usuarioId').eq('tenantId', tenantId);
        } catch (_) {
          membroRows = await _supabase.from('membro_empresa').select('usuario_id').eq('tenant_id', tenantId);
        }
        final userIds = membroRows.map((m) => (m['usuarioId'] ?? m['usuario_id']) as String?).whereType<String>().toSet().toList();
        if (userIds.isNotEmpty) {
          if (since.millisecondsSinceEpoch > 0) {
            for (final dCol in ['atualizadoEm', 'atualizado_em', 'updatedAt', 'updated_at']) {
              try {
                final res = await _supabase.from(tableName).select().inFilter('id', userIds).gte(dCol, since.toIso8601String());
                return res.cast<Map<String, dynamic>>();
              } catch (_) {}
            }
          }
          final res = await _supabase.from(tableName).select().inFilter('id', userIds);
          return res.cast<Map<String, dynamic>>();
        }
      } catch (_) {}
      return [];
    }

    // Default tables (pedidos, itens_pedido, produtos, etc.)
    final tenantCols = ['tenantId', 'tenant_id'];
    final dateCols = ['updatedAt', 'updated_at', 'dataHoraCriacao', 'data_hora_criacao', 'createdAt', 'created_at'];

    if (since.millisecondsSinceEpoch > 0) {
      final isoDate = since.toIso8601String();
      for (final tCol in tenantCols) {
        for (final dCol in dateCols) {
          try {
            final res = await _supabase.from(tableName).select().eq(tCol, tenantId).gte(dCol, isoDate);
            return res.cast<Map<String, dynamic>>();
          } catch (_) {}
        }
      }
    }

    for (final tCol in tenantCols) {
      try {
        final res = await _supabase.from(tableName).select().eq(tCol, tenantId);
        return res.cast<Map<String, dynamic>>();
      } catch (_) {}
    }

    // Final fallback: query table with strict tenant filter
    try {
      final res = await _supabase.from(tableName).select();
      final allRows = res.cast<Map<String, dynamic>>();
      return allRows.where((row) {
        final rTenant = row['tenantId'] ?? row['tenant_id'];
        return rTenant != null && rTenant == tenantId;
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<({int applied, int protected})> _pullTable(
    String entityName,
    String tenantId,
    DateTime since,
    FincoreDatabase db,
  ) async {
    final tableName = _entityToTable[entityName];
    if (tableName == null) return (applied: 0, protected: 0);

    try {
      final rows = await _fetchRemoteRows(tableName: tableName, tenantId: tenantId, since: since);

      if (rows.isEmpty) {
        return (applied: 0, protected: 0);
      }

      await LogService.instance.logSync(
        step: 'PULL',
        action: 'AVALIAR',
        entity: entityName,
        status: LogStatus.inProgress,
        message: '┌── INÍCIO SINCRONIZAÇÃO [${entityName.toUpperCase()}] (${rows.length} registro(s) recebidos da nuvem) ──',
        tenantId: tenantId,
      );

      // ── ESCUDO DO PULL (OUTBOX) ─────────────────────────────
      final lockedIds = await _outbox.getPendingEntityIds(entityName);
      // ─────────────────────────────────────────────────────────

      int appliedCount = 0;
      int protectedCount = 0;
      int stalledCount = 0;

      try {
        LogService.instance.logDatabase(
          step: 'PULL_INICIO',
          action: 'INICIO_LOTE',
          entity: entityName,
          id: 'LOTE',
          details: '┌── INÍCIO GRAVAÇÃO LOCAL [${entityName.toUpperCase()}] (${rows.length} registro(s)) ──',
          tenantId: tenantId,
        );
      } catch (_) {}

      await db.transaction(() async {
        for (final row in rows) {
          final rowId = row['id'] as String?;
          if (rowId == null) continue;

          final fullId = rowId;
          final shortId = fullId.length > 8 ? '${fullId.substring(0, 8)}...' : fullId;
          final rawDesc = row['nome'] ?? row['descricao'] ?? row['tipo'] ?? row['apelido'] ?? row['nomeIdentificador'] ?? row['numeroPedido'];
          final desc = rawDesc?.toString() ?? '';
          final descStr = desc.isNotEmpty ? ' "$desc"' : '';
          final serverVersion = (row['syncVersion'] as num?)?.toInt() ?? (row['sync_version'] as num?)?.toInt() ?? 1;
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
              await LogService.instance.logSync(
                step: 'PULL',
                action: 'PROTEGIDO',
                entity: entityName,
                id: shortId,
                status: LogStatus.skipped,
                message: '[REGISTRO PROTEGIDO CONTRA SOBREESCRITA] $entityName$descStr\n'
                    '  ID: $shortId\n'
                    '${desc.isNotEmpty ? '  Descrição: $desc\n' : ''}'
                    '  Motivo: Possui alterações pendentes no Outbox local.\n'
                    '  Decisão: Dado do servidor bloqueado (Escudo do Pull).',
                tenantId: tenantId,
              );
            } else {
              stalledCount++;
            }
            continue;
          }

          // Se o registro já existe localmente e a versão do servidor é menor ou igual à local,
          // o dado local já está totalmente em dia. Não é necessário re-aplicar.
          if (localVersion != null && serverVersion <= localVersion) {
            stalledCount++;
            continue;
          }
          // ─────────────────────────────────────────────────────────

          try {
            await _applyRowLocally(entityName, row, db);
            appliedCount++;

            await LogService.instance.logSync(
              step: 'PULL',
              action: 'APLICADO',
              entity: entityName,
              id: shortId,
              status: LogStatus.success,
              message: '[APLICADO NO BANCO LOCAL] $entityName$descStr (v$serverVersion)\n'
                  '  ID: $shortId\n'
                  '${desc.isNotEmpty ? '  Descrição: $desc\n' : ''}'
                  '  Versão Servidor: v$serverVersion\n'
                  '  Decisão: Gravado no SQLite local (Last Write Wins).',
              tenantId: tenantId,
            );
          } catch (e) {
            stalledCount++;
            await LogService.instance.logSync(
              step: 'PULL',
              action: 'ERRO_LINHA',
              entity: entityName,
              id: shortId,
              status: LogStatus.failed,
              message: 'Falha ao aplicar linha $shortId ($entityName) no SQLite: $e',
              tenantId: tenantId,
            );
          }

          // Espelha mutação remota recebida no log de Banco de Dados (banco_dados_YYYY-MM-DD.log)
          try {
            LogService.instance.logDatabase(
              step: 'PULL_APLICADO',
              action: 'UPSERT_REMOTO',
              entity: entityName,
              id: fullId,
              version: serverVersion,
              oldVersion: localVersion,
              details: desc.isNotEmpty ? 'Gravado no SQLite local vindo da nuvem: "$desc"' : 'Gravado no SQLite local vindo da nuvem',
              tenantId: tenantId,
            );
          } catch (_) {}
        }
      });

      try {
        LogService.instance.logDatabase(
          step: 'PULL_FIM',
          action: 'FIM_LOTE',
          entity: entityName,
          id: 'LOTE',
          details: '└── FIM GRAVAÇÃO LOCAL [${entityName.toUpperCase()}] ($appliedCount gravados) ──\n',
          tenantId: tenantId,
        );
      } catch (_) {}

      await LogService.instance.logSync(
        step: 'PULL',
        action: 'RESULTADO',
        entity: entityName,
        status: LogStatus.success,
        message: 'Resultado [${entityName.toUpperCase()}]: $appliedCount aplicado(s) no banco local, $protectedCount protegido(s), $stalledCount mantido(s)\n'
            '  Resumo: $appliedCount aplicado(s) no banco local, $protectedCount protegido(s), $stalledCount mantido(s)\n'
            '└── FIM SINCRONIZAÇÃO [${entityName.toUpperCase()}] ──────────────────────────────────────────\n',
        tenantId: tenantId,
      );

      return (applied: appliedCount, protected: protectedCount);
    } on SocketException {
      _updateConnectivity(CloudConnectivity.offline);
      await LogService.instance.logSync(
        step: 'PULL',
        action: 'OFFLINE',
        entity: entityName,
        status: LogStatus.skipped,
        message: 'Sem conexão durante atualização de $entityName - mantendo dados locais.\n'
            '└── FIM SINCRONIZAÇÃO [${entityName.toUpperCase()}] (OFFLINE) ─────────────────────────────\n',
        tenantId: tenantId,
      );
      return (applied: 0, protected: 0);
    } catch (e, stack) {
      await LogService.instance.logSync(
        step: 'PULL',
        action: 'ERRO',
        entity: entityName,
        status: LogStatus.failed,
        errorMessage: '$e\n$stack',
        message: 'Falha ao processar atualização remota de $entityName: $e\n'
            '  Erro: $e\n'
            '└── FIM SINCRONIZAÇÃO [${entityName.toUpperCase()}] (ERRO) ───────────────────────────────\n',
        tenantId: tenantId,
      );
      return (applied: 0, protected: 0);
    }
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
        case 'taxa_entrega':
        case 'taxas_entrega':
          final row = await (db.select(db.taxasEntregaTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'membros_empresa':
        case 'membro_empresa':
          final row = await (db.select(db.membrosEmpresaTable)
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
        case 'categorias_tabelas_precificacao':
          final row = await (db.select(db.categoriasTabelasPrecificacaoTable)
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
          return row != null ? 1 : null;
        case 'pedidos':
        case 'Pedido':
          final row = await (db.select(db.pedidosTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'itens_pedido':
        case 'ItensPedido':
          final row = await (db.select(db.itensPedidoTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'ordens_preparo':
        case 'OrdemPreparo':
          final row = await (db.select(db.ordensPreparoTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'historicos_ordem_preparo':
        case 'HistoricoOrdemPreparo':
          final row = await (db.select(db.historicosOrdemPreparoTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'estoque_produto':
        case 'EstoqueProduto':
          final row = await (db.select(db.estoqueProdutosTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'movimentacao_estoque':
        case 'MovimentacaoEstoque':
          final row = await (db.select(db.movimentacoesEstoqueTable)
                ..where((t) => t.id.equals(entityId)))
              .getSingleOrNull();
          return row?.syncVersion;
        case 'planejamento_producao':
        case 'PlanejamentoProducao':
          final row = await (db.select(db.planejamentoProducaoTable)
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

      case 'membros_empresa':
      case 'membro_empresa':
        final usrId = row['usuarioId'] as String?;
        if (usrId != null && usrId.isNotEmpty) {
          final usrExists = await (db.select(db.usuariosTable)..where((t) => t.id.equals(usrId))).getSingleOrNull();
          if (usrExists == null) {
            // Garante que o usuário existe localmente antes de inserir membro_empresa (evita FK constraint error)
            await db.into(db.usuariosTable).insertOnConflictUpdate(
              UsuariosTableCompanion.insert(
                id: usrId,
                tenantId: Value(row['tenantId'] as String?),
                username: 'usuario_$usrId',
                nome: 'Usuário do Sistema',
                criadoEm: DateTime.now(),
                atualizadoEm: DateTime.now(),
              ),
            );
          }
        }
        await db.into(db.membrosEmpresaTable).insertOnConflictUpdate(
              MembrosEmpresaTableCompanion.insert(
                id: row['id'] as String,
                tenantId: row['tenantId'] as String,
                usuarioId: row['usuarioId'] as String,
                role: row['role'] as String? ?? 'OPERADOR',
                ativo: Value(row['ativo'] as bool? ?? true),
                convidadoEm: _parseDate(row['convidadoEm'] as String?) ?? DateTime.now(),
                aceitoEm: Value(_parseDate(row['aceitoEm'] as String?)),
                syncVersion: Value((row['syncVersion'] as num?)?.toInt() ?? 1),
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
                isUsoInterno: Value(row['isUsoInterno'] as bool? ?? false),
                movimentaFinanceiro: Value(row['movimentaFinanceiro'] as bool? ?? true),
                movimentaEstoque: Value(row['movimentaEstoque'] as bool? ?? true),
                bandeiraPadrao: Value(row['bandeiraPadrao'] as String?),
                descricao: Value(row['descricao'] as String?),
                pixChave: Value(row['pixChave'] as String?),
                pixTipoChave: Value(row['pixTipoChave'] as String?),
                pixTipoBanco: Value(row['pixTipoBanco'] as String?),
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

      case 'taxa_entrega':
      case 'taxas_entrega':
        final isKm = (row['tipoRegra'] ?? row['tipo_regra']) == 'km';
        final cepIni = isKm
            ? (row['distanciaMinKm'] ?? row['distancia_min_km'] ?? row['cepInicial'])?.toString()
            : row['cepInicial'] as String?;
        final cepFin = isKm
            ? (row['distanciaMaxKm'] ?? row['distancia_max_km'] ?? row['cepFinal'])?.toString()
            : row['cepFinal'] as String?;

        await db.into(db.taxasEntregaTable).insertOnConflictUpdate(
              TaxasEntregaTableCompanion.insert(
                id: row['id'] as String,
                tenantId: (row['tenantId'] ?? row['tenant_id']) as String,
                nome: row['nome'] as String,
                tipoRegra: (row['tipoRegra'] ?? row['tipo_regra'] ?? 'fixo') as String,
                bairro: Value(row['bairro'] as String?),
                cepInicial: Value(cepIni),
                cepFinal: Value(cepFin),
                valorCentavos: (row['valorCentavos'] ?? row['valor_centavos'] ?? 0) as int,
                ativo: (row['ativo'] ?? true) as bool,
                pedidoMinimoCentavos: Value((row['pedidoMinimoCentavos'] ?? row['pedido_minimo_centavos'] ?? 0) as int?),
                prazoEstimado: Value(row['prazoEstimado'] as String?),
                observacoes: Value(row['observacoes'] as String?),
                syncVersion: Value((row['syncVersion'] ?? row['sync_version'] ?? 1) as int),
                syncStatus: SyncStatus.synced,
                lastSyncedAt: Value(DateTime.now().toUtc()),
                createdAt: _parseDate(row['createdAt'] ?? row['created_at']) ?? DateTime.now(),
                updatedAt: _parseDate(row['updatedAt'] ?? row['updated_at']) ?? DateTime.now(),
                createdBy: (row['createdBy'] ?? row['created_by'] ?? '') as String,
                updatedBy: (row['updatedBy'] ?? row['updated_by'] ?? '') as String,
                deletedAt: Value(_parseDate(row['deletedAt'] ?? row['deleted_at'])),
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

      case 'categorias_tabelas_precificacao':
        await db.into(db.categoriasTabelasPrecificacaoTable).insertOnConflictUpdate(
              CategoriasTabelasPrecificacaoTableCompanion.insert(
                id: row['id'] as String,
                tenantId: row['tenantId'] as String,
                categoriaId: row['categoriaId'] as String,
                tabelaPrecificacaoId: row['tabelaPrecificacaoId'] as String,
                ativo: row['ativo'] as bool? ?? true,
                prioridade: row['prioridade'] as int? ?? 1,
                dataInicio: Value(_parseDate(row['dataInicio'] as String?)),
                dataFim: Value(_parseDate(row['dataFim'] as String?)),
                syncVersion: Value((row['syncVersion'] as num?)?.toInt() ?? 1),
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
        break;
      case 'OrdemPreparo':
      case 'ordens_preparo':
        final listItensRaw = row['itensJson'] as String? ?? '[]';
        final incomingStatusOrdem = row['status'] as String? ?? 'pendente';
        final pedidoIdOrdem = row['pedidoId'] as String? ?? '';
        final ordemId = row['id'] as String;

        final incomingVersion = (row['syncVersion'] as num?)?.toInt() ?? 1;
        final existingOrdem = await (db.select(db.ordensPreparoTable)..where((t) => t.id.equals(ordemId))).getSingleOrNull();

        String finalStatusOrdem = incomingStatusOrdem;
        if (existingOrdem != null) {
          final existingVersion = existingOrdem.syncVersion;
          if (incomingVersion < existingVersion) {
            finalStatusOrdem = existingOrdem.status;
          } else if (incomingVersion == existingVersion) {
            if (StatusPrecedence.isHigherOrEqual(existingOrdem.status, incomingStatusOrdem)) {
              finalStatusOrdem = existingOrdem.status;
            }
          }
        }

        await db.into(db.ordensPreparoTable).insertOnConflictUpdate(
              OrdensPreparoTableCompanion.insert(
                id: ordemId,
                tenantId: row['tenantId'] as String,
                pedidoId: pedidoIdOrdem,
                itensJson: listItensRaw,
                status: finalStatusOrdem,
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
        if (pedidoIdOrdem.isNotEmpty) {
          try {
            final pedidoStatusCandidate = finalStatusOrdem;

            final existingPedido = await (db.select(db.pedidosTable)..where((t) => t.id.equals(pedidoIdOrdem))).getSingleOrNull();
            if (existingPedido == null || !StatusPrecedence.isHigherOrEqual(existingPedido.status, pedidoStatusCandidate)) {
              await (db.update(db.pedidosTable)..where((t) => t.id.equals(pedidoIdOrdem))).write(
                PedidosTableCompanion(
                  status: Value(pedidoStatusCandidate),
                  updatedAt: Value(DateTime.now()),
                ),
              );
            }
          } catch (_) {}
        }
        break;
      case 'HistoricoOrdemPreparo':
      case 'historicos_ordem_preparo':
        final parentId = row['ordemPreparoId'] as String?;
        if (parentId != null && parentId.isNotEmpty) {
          final parentExists = await (db.select(db.ordensPreparoTable)..where((t) => t.id.equals(parentId))).getSingleOrNull();
          if (parentExists == null) {
            // Ordem de preparo pai não existe no SQLite local; ignora histórico orfão para evitar erro de Foreign Key
            break;
          }
        }
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

      case 'planejamento_producao':
      case 'PlanejamentoProducao':
        await db.into(db.planejamentoProducaoTable).insertOnConflictUpdate(
          PlanejamentoProducaoTableCompanion.insert(
            id: row['id'] as String,
            tenantId: row['tenantId'] as String,
            produtoId: row['produtoId'] as String,
            quantidadePlanejada: row['quantidadePlanejada'] as int? ?? 0,
            quantidadeProduzida: Value(row['quantidadeProduzida'] as int? ?? 0),
            status: Value(row['status'] as String? ?? 'planejada'),
            dataPlano: _parseDate(row['dataPlano'] as String?) ?? DateTime.now(),
            observacoes: Value(row['observacoes'] as String?),
            necessidadeOrigem: Value(row['necessidadeOrigem'] as String?),
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
    final pedidoId = row['id'] as String;
    final incomingStatus = row['status'] as String? ?? 'confirmado';

    final incomingVersion = (row['syncVersion'] as num?)?.toInt() ?? 1;
    final existingPedido = await (db.select(db.pedidosTable)..where((t) => t.id.equals(pedidoId))).getSingleOrNull();

    String finalStatus = incomingStatus;
    if (existingPedido != null) {
      final existingVersion = existingPedido.syncVersion;
      // Se localmente o pedido já está em status igual ou de precedência superior (ex: entregue vs pronto/saiu_para_entrega),
      // o pull da nuvem nunca deve rebaixar o pedido local para um status anterior.
      if (StatusPrecedence.isHigherOrEqual(existingPedido.status, incomingStatus)) {
        finalStatus = existingPedido.status;
      } else if (incomingVersion < existingVersion) {
        finalStatus = existingPedido.status;
      }
    }

    await db.into(db.pedidosTable).insertOnConflictUpdate(
      PedidosTableCompanion.insert(
        id: pedidoId,
        tenantId: row['tenantId'] as String? ?? row['tenant_id'] as String? ?? _context.tenantId,
        status: Value(finalStatus),
        tipoLogistica: row['tipoLogistica'] as String? ?? row['tipo_logistica'] as String? ?? 'Retirada',
        clienteId: Value(row['clienteId'] as String? ?? row['cliente_id'] as String?),
        clienteNomeAvulso: Value(row['clienteNomeAvulso'] as String? ?? row['cliente_nome_avulso'] as String?),
        clienteTelefoneAvulso: Value(row['clienteTelefoneAvulso'] as String? ?? row['cliente_telefone_avulso'] as String?),
        valorSubtotalCentavos: (row['valorSubtotalCentavos'] as num?)?.toInt() ?? (row['valor_subtotal_centavos'] as num?)?.toInt() ?? 0,
        valorTaxaEntregaCentavos: Value((row['valorTaxaEntregaCentavos'] as num?)?.toInt() ?? (row['valor_taxa_entrega_centavos'] as num?)?.toInt() ?? 0),
        valorTaxaServicoCentavos: Value((row['valorTaxaServicoCentavos'] as num?)?.toInt() ?? (row['valor_taxa_servico_centavos'] as num?)?.toInt() ?? 0),
        valorTotalCentavos: (row['valorTotalCentavos'] as num?)?.toInt() ?? (row['valor_total_centavos'] as num?)?.toInt() ?? 0,
        trocoParaCentavos: Value((row['trocoParaCentavos'] as num?)?.toInt() ?? (row['troco_para_centavos'] as num?)?.toInt()),
        formaPagamentoId: Value(row['formaPagamentoId'] as String? ?? row['forma_pagamento_id'] as String?),
        formaPagamentoNome: Value(row['formaPagamentoNome'] as String? ?? row['forma_pagamento_nome'] as String?),
        enderecoJson: Value(row['enderecoJson'] as String? ?? row['endereco_json'] as String?),
        operadorId: Value(row['operadorId'] as String? ?? row['operador_id'] as String?),
        dataHoraCriacao: _parseDate(row['dataHoraCriacao'] as String?) ?? _parseDate(row['data_hora_criacao'] as String?) ?? _parseDate(row['createdAt'] as String?) ?? DateTime.now(),
        dataHoraEntregaPrevista: Value(_parseDate(row['dataHoraEntregaPrevista'] as String?) ?? _parseDate(row['data_hora_entrega_prevista'] as String?)),
        numeroPedido: Value((row['numeroPedido'] as num?)?.toInt() ?? (row['numero_pedido'] as num?)?.toInt()),
        observacoes: Value(row['observacoes'] as String?),
        canalOrigem: Value(row['canalOrigem'] as String? ?? row['canal_origem'] as String? ?? 'pdv_express'),
        syncVersion: Value((row['syncVersion'] as num?)?.toInt() ?? (row['sync_version'] as num?)?.toInt() ?? 1),
        syncStatus: SyncStatus.synced,
        lastSyncedAt: Value(DateTime.now().toUtc()),
        createdAt: _parseDate(row['createdAt'] as String?) ?? _parseDate(row['created_at'] as String?) ?? DateTime.now(),
        updatedAt: _parseDate(row['updatedAt'] as String?) ?? _parseDate(row['updated_at'] as String?) ?? DateTime.now(),
        createdBy: row['createdBy'] as String? ?? row['created_by'] as String? ?? '',
        updatedBy: row['updatedBy'] as String? ?? row['updated_by'] as String? ?? '',
        deletedAt: Value(_parseDate(row['deletedAt'] as String?) ?? _parseDate(row['deleted_at'] as String?)),
        deletedBy: const Value(null),
      ),
    );

    try {
      final ordens = await (db.select(db.ordensPreparoTable)..where((t) => t.pedidoId.equals(pedidoId))).get();
      if (ordens.isNotEmpty) {
        String ordensStatusCandidate = finalStatus;
        if (finalStatus == 'confirmado') ordensStatusCandidate = 'pendente';
        for (final ordem in ordens) {
          if (!StatusPrecedence.isHigherOrEqual(ordem.status, ordensStatusCandidate)) {
            await (db.update(db.ordensPreparoTable)..where((t) => t.id.equals(ordem.id))).write(
              OrdensPreparoTableCompanion(
                status: Value(ordensStatusCandidate),
                updatedAt: Value(DateTime.now()),
              ),
            );
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _applyItemPedidoLocally(Map<String, dynamic> row, FincoreDatabase db) async {
    await db.into(db.itensPedidoTable).insertOnConflictUpdate(
      ItensPedidoTableCompanion.insert(
        id: row['id'] as String,
        tenantId: row['tenantId'] as String? ?? row['tenant_id'] as String? ?? _context.tenantId,
        pedidoId: row['pedidoId'] as String? ?? row['pedido_id'] as String? ?? '',
        produtoId: row['produtoId'] as String? ?? row['produto_id'] as String? ?? '',
        nomeProduto: row['nomeProduto'] as String? ?? row['nome_produto'] as String? ?? '',
        quantidade: (row['quantidade'] as num?)?.toDouble() ?? 1.0,
        valorUnitarioCentavos: (row['valorUnitarioCentavos'] as num?)?.toInt() ?? (row['valor_unitario_centavos'] as num?)?.toInt() ?? 0,
        valorTotalCentavos: (row['valorTotalCentavos'] as num?)?.toInt() ?? (row['valor_total_centavos'] as num?)?.toInt() ?? 0,
        observacoes: Value(row['observacoes'] as String?),
        syncVersion: Value((row['syncVersion'] as num?)?.toInt() ?? (row['sync_version'] as num?)?.toInt() ?? 1),
        syncStatus: SyncStatus.synced,
        lastSyncedAt: Value(DateTime.now().toUtc()),
        createdAt: _parseDate(row['createdAt'] as String?) ?? _parseDate(row['created_at'] as String?) ?? DateTime.now(),
        updatedAt: _parseDate(row['updatedAt'] as String?) ?? _parseDate(row['updated_at'] as String?) ?? DateTime.now(),
        createdBy: row['createdBy'] as String? ?? row['created_by'] as String? ?? '',
        updatedBy: row['updatedBy'] as String? ?? row['updated_by'] as String? ?? '',
        deletedAt: Value(_parseDate(row['deletedAt'] as String?) ?? _parseDate(row['deleted_at'] as String?)),
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

    // 1. Configura Polling de Fallback Periódico (30s de intervalo de segurança)
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final online = await isOnline();
      if (online) {
        final dateThreshold = _lastPullTimestamp != null
            ? _lastPullTimestamp!.subtract(const Duration(seconds: 10))
            : DateTime.fromMillisecondsSinceEpoch(0);
        try {
          await pullAll(db, dateThreshold);
        } catch (e) {
          LogService.instance.error(LogModule.sync, '[SupabaseSync] Falha no fallback polling', exception: e.toString());
        }
      }
    });

    // 3. Configura Realtime Listeners (WebSocket)
    final uniqueTables = _entityToTable.values.toSet();
    for (final tableName in uniqueTables) {
      final entityName = _entityToTable.entries.firstWhere((e) => e.value == tableName).key;

      final channel = _supabase
          .channel('fincore_${tableName}_$tenantId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: tableName,
            callback: (payload) async {
              final newRecord = payload.newRecord;
              if (newRecord.isEmpty) return;

              // Validação de TenantContext defensiva (suporta tenantId ou tenant_id do Postgres)
              final recTenant = newRecord['tenantId'] ?? newRecord['tenant_id'];
              if (recTenant != null && recTenant.toString() != tenantId) {
                return;
              }

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
                _syncEventsController.add(entityName);
                _syncEventsController.add('ALL');
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

  DateTime? _parseDate(dynamic input) {
    if (input == null) return null;
    final s = input.toString().trim();
    if (s.isEmpty) return null;
    try {
      String formatted = s;
      if (!s.endsWith('Z') && !RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s)) {
        formatted = '${s.replaceAll(' ', 'T')}Z';
      }
      return DateTime.parse(formatted).toUtc();
    } catch (_) {
      return DateTime.tryParse(s)?.toUtc();
    }
  }
}

class OfflineSyncException implements Exception {
  final String message;
  OfflineSyncException(this.message);

  @override
  String toString() => message;
}
