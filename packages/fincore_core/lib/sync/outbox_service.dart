import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../common/domain_primitives.dart';
import '../context/tenant_context.dart';
import '../database/fincore_database.dart';
import 'status_precedence.dart';

class OutboxService {
  final FincoreDatabase db;
  final TenantContext context;
  void Function()? onMutationEnqueued;

  OutboxService({required this.db, required this.context, this.onMutationEnqueued});

  /// Enfileira uma mutação offline de forma transacional no banco SQLite local.
  Future<int> enqueue({
    required String entity,
    required String entityId,
    required String action,
    required Map<String, dynamic> payload,
    required int version,
  }) async {
    final activeTenantId = context.tenantId;

    final aliases = _getEntityAliases(entity);

    // Busca mutação pendente ou em retentativa para o mesmo registro (considerando aliases)
    final existing = await (db.select(db.outboxSync)
          ..where((t) =>
              t.tenantId.equals(activeTenantId) &
              t.entity.isIn(aliases) &
              t.entityId.equals(entityId) &
              (t.status.equals(SyncStatus.pending.name) |
                  t.status.equals(SyncStatus.retrying.name))))
        .getSingleOrNull();

    if (existing != null) {
      if (action == 'DELETE') {
        if (existing.version == 1) {
          // Registro criado localmente que nunca chegou ao servidor e foi deletado.
          // Podemos apagar a entrada da fila sem enviar nada ao servidor.
          await (db.delete(db.outboxSync)..where((t) => t.id.equals(existing.id))).go();
          return 0;
        } else {
          // Atualiza a transação existente para DELETE
          final updated = existing.copyWith(
            action: action,
            payload: jsonEncode(payload),
            version: version,
            status: SyncStatus.pending.name,
            attemptsCount: 0,
            errorMessage: const Value(null),
          );
          await db.update(db.outboxSync).replace(updated);
          onMutationEnqueued?.call();
          return existing.id;
        }
      } else {
        // UPSERT substitui o payload e versão da transação anterior (coalescing)
        // Monotonic Status Precedence: Preserva status superior se existir no payload anterior
        final payloadMap = Map<String, dynamic>.from(payload);
        if ((entity.toLowerCase().contains('pedido') || entity.toLowerCase().contains('preparo')) && payloadMap.containsKey('status')) {
          try {
            final existingPayloadMap = jsonDecode(existing.payload) as Map<String, dynamic>;
            if (existingPayloadMap.containsKey('status')) {
              final existingStatus = existingPayloadMap['status'] as String?;
              final newStatus = payloadMap['status'] as String?;
              if (StatusPrecedence.isHigherOrEqual(existingStatus, newStatus)) {
                payloadMap['status'] = existingStatus;
              }
            }
          } catch (_) {}
        }

        final updated = existing.copyWith(
          action: action,
          payload: jsonEncode(payloadMap),
          version: version,
          status: SyncStatus.pending.name,
          attemptsCount: 0,
          errorMessage: const Value(null),
        );
        await db.update(db.outboxSync).replace(updated);
        onMutationEnqueued?.call();
        return existing.id;
      }
    }

    final entry = OutboxSyncCompanion.insert(
      tenantId: activeTenantId,
      entity: entity,
      entityId: entityId,
      action: action,
      payload: jsonEncode(payload),
      status: SyncStatus.pending.name,
      version: version,
      createdAt: DateTime.now(),
      attemptsCount: const Value(0),
    );

    final insertedId = await db.into(db.outboxSync).insert(entry);
    onMutationEnqueued?.call();
    return insertedId;
  }

  /// Retorna as operações pendentes ou em retentativa filtradas pelo Tenant ativo.
  Future<List<OutboxEntry>> getPendingEntries() async {
    final activeTenantId = context.tenantId;
    return await (db.select(db.outboxSync)
          ..where((t) =>
              t.tenantId.equals(activeTenantId) &
              (t.status.equals(SyncStatus.pending.name) |
                  t.status.equals(SyncStatus.retrying.name))))
        .get();
  }

  static List<String> _getEntityAliases(String entity) {
    switch (entity.toLowerCase()) {
      case 'pedido':
      case 'pedidos':
        return const ['Pedido', 'pedidos', 'pedido'];
      case 'itenspedido':
      case 'itens_pedido':
      case 'item_pedido':
        return const ['ItensPedido', 'itens_pedido', 'item_pedido'];
      case 'ordempreparo':
      case 'ordens_preparo':
      case 'ordem_preparo':
        return const ['OrdemPreparo', 'ordens_preparo', 'ordem_preparo'];
      case 'historicoordempreparo':
      case 'historicos_ordem_preparo':
      case 'historico_ordem_preparo':
        return const ['HistoricoOrdemPreparo', 'historicos_ordem_preparo', 'historico_ordem_preparo'];
      case 'produto':
      case 'produtos':
        return const ['Produto', 'produtos', 'produto'];
      case 'categoria':
      case 'categorias':
        return const ['Categoria', 'categorias', 'categoria'];
      case 'cliente':
      case 'clientes':
        return const ['Cliente', 'clientes', 'cliente'];
      case 'estoqueproduto':
      case 'estoque_produto':
        return const ['EstoqueProduto', 'estoque_produto'];
      case 'movimentacaoestoque':
      case 'movimentacao_estoque':
        return const ['MovimentacaoEstoque', 'movimentacao_estoque'];
      default:
        return [entity, entity.toLowerCase()];
    }
  }

  /// Retorna o conjunto de entityIds que ainda possuem operações pendentes
  /// para uma determinada entidade (considerando aliases e estado processing).
  /// Usado pelo PULL para proteger registros que não devem ser sobrescritos.
  Future<Set<String>> getPendingEntityIds(String entity) async {
    final activeTenantId = context.tenantId;
    final aliases = _getEntityAliases(entity);
    final entries = await (db.select(db.outboxSync)
          ..where((t) =>
              t.tenantId.equals(activeTenantId) &
              t.entity.isIn(aliases) &
              (t.status.equals(SyncStatus.pending.name) |
                  t.status.equals(SyncStatus.retrying.name) |
                  t.status.equals(SyncStatus.processing.name))))
        .get();
    return entries.map((e) => e.entityId).toSet();
  }

  /// Retorna true se existir alguma operação pendente, retentativa ou em processamento
  /// para a entidade (ou qualquer um dos seus aliases).
  Future<bool> hasPendingForEntity(String entity, String entityId) async {
    final activeTenantId = context.tenantId;
    final aliases = _getEntityAliases(entity);
    final entry = await (db.select(db.outboxSync)
          ..where((t) =>
              t.tenantId.equals(activeTenantId) &
              t.entity.isIn(aliases) &
              t.entityId.equals(entityId) &
              (t.status.equals(SyncStatus.pending.name) |
                  t.status.equals(SyncStatus.retrying.name) |
                  t.status.equals(SyncStatus.processing.name))))
        .getSingleOrNull();
    return entry != null;
  }

  /// Retorna true se não houver NENHUMA operação pendente ou em retentativa
  /// para o tenant ativo. Usado pelo router para decidir se é seguro executar o PULL.
  Future<bool> isOutboxEmpty() async {
    final pending = await getPendingEntries();
    return pending.isEmpty;
  }

  /// Atualiza o estado da transação no outbox.
  Future<void> updateStatus(
    int id,
    SyncStatus status, {
    String? errorMessage,
  }) async {
    final entry = await (db.select(db.outboxSync)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (entry != null) {
      final updated = entry.copyWith(
        status: status.name,
        lastAttempt: Value(DateTime.now()),
        attemptsCount: entry.attemptsCount + 1,
        errorMessage: Value(errorMessage),
      );
      await db.update(db.outboxSync).replace(updated);

      if (status == SyncStatus.failed) {
        try {
          final auditCompanion = AuditLogsTableCompanion.insert(
            id: const Uuid().v4(),
            targetEntity: 'SyncEngine',
            entityId: entry.entityId,
            tenantId: entry.tenantId,
            userId: 'system',
            action: 'SYNC_ERROR',
            timestamp: DateTime.now().toUtc(),
            entityDisplayName: Value('Falha de Sincronização: ${entry.entity}'),
            entityModule: const Value('Sync Center'),
            diff: Value(jsonEncode({
              '_summary': 'Falha na sincronização da entidade ${entry.entity}: ${errorMessage ?? "Erro de sincronização"}',
              'entidade': entry.entity,
              'entityId': entry.entityId,
              'action': entry.action,
              'erro': errorMessage ?? 'Erro desconhecido',
              'tentativas': entry.attemptsCount + 1,
              'status': 'failed',
            })),
          );
          await db.into(db.auditLogsTable).insert(auditCompanion);
        } catch (_) {}
      }
    }
  }

  /// Remove entradas sincronizadas com sucesso para manter o banco enxuto.
  Future<int> purgeSyncedEntries() async {
    return await (db.delete(db.outboxSync)
          ..where((t) => t.status.equals(SyncStatus.synced.name)))
        .go();
  }

  /// Reprocessa todas as entradas com falha ou retentativa, voltando o status para 'pending'.
  Future<int> retryFailedEntries() async {
    final activeTenantId = context.tenantId;
    final failedEntries = await (db.select(db.outboxSync)
          ..where((t) =>
              t.tenantId.equals(activeTenantId) &
              (t.status.equals(SyncStatus.failed.name) |
                  t.status.equals(SyncStatus.retrying.name))))
        .get();

    for (final entry in failedEntries) {
      final updated = entry.copyWith(
        status: SyncStatus.pending.name,
        attemptsCount: 0,
        errorMessage: const Value(null),
      );
      await db.update(db.outboxSync).replace(updated);
    }

    return failedEntries.length;
  }

  /// Reprocessa uma entrada específica pelo ID da transação no outbox.
  Future<bool> retryEntry(int id) async {
    final entry = await (db.select(db.outboxSync)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (entry == null) return false;

    final updated = entry.copyWith(
      status: SyncStatus.pending.name,
      attemptsCount: 0,
      errorMessage: const Value(null),
    );
    await db.update(db.outboxSync).replace(updated);
    return true;
  }

  /// Retorna estatísticas estruturadas da fila de sincronização (Outbox) para a UI.
  Future<({int pending, int retrying, int failed, int total})> getOutboxStats() async {
    final activeTenantId = context.tenantId;
    final entries = await (db.select(db.outboxSync)
          ..where((t) => t.tenantId.equals(activeTenantId)))
        .get();

    int pending = 0;
    int retrying = 0;
    int failed = 0;

    for (final e in entries) {
      if (e.status == SyncStatus.pending.name) {
        pending++;
      } else if (e.status == SyncStatus.retrying.name) {
        retrying++;
      } else if (e.status == SyncStatus.failed.name) {
        failed++;
      }
    }

    return (pending: pending, retrying: retrying, failed: failed, total: entries.length);
  }
}
