import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../common/domain_primitives.dart';
import '../context/tenant_context.dart';
import '../database/fincore_database.dart';

class OutboxService {
  final FincoreDatabase db;
  final TenantContext context;

  OutboxService({required this.db, required this.context});

  /// Enfileira uma mutação offline de forma transacional no banco SQLite local.
  Future<int> enqueue({
    required String entity,
    required String entityId,
    required String action,
    required Map<String, dynamic> payload,
    required int version,
  }) async {
    final activeTenantId = context.tenantId;

    // Busca mutação pendente ou em retentativa para o mesmo registro
    final existing = await (db.select(db.outboxSync)
          ..where((t) =>
              t.tenantId.equals(activeTenantId) &
              t.entity.equals(entity) &
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
          return existing.id;
        }
      } else {
        // UPSERT substitui o payload e versão da transação anterior (coalescing)
        final updated = existing.copyWith(
          action: action,
          payload: jsonEncode(payload),
          version: version,
          status: SyncStatus.pending.name,
          attemptsCount: 0,
          errorMessage: const Value(null),
        );
        await db.update(db.outboxSync).replace(updated);
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

    return await db.into(db.outboxSync).insert(entry);
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

  /// Retorna o conjunto de entityIds que ainda possuem operações pendentes
  /// para uma determinada entidade. Usado pelo PULL para proteger registros
  /// que não devem ser sobrescritos por dados do servidor.
  ///
  /// Exemplo:
  /// ```dart
  /// final locked = await outbox.getPendingEntityIds('produtos');
  /// if (locked.contains(row['id'])) { /* ignora este registro */ }
  /// ```
  Future<Set<String>> getPendingEntityIds(String entity) async {
    final activeTenantId = context.tenantId;
    final entries = await (db.select(db.outboxSync)
          ..where((t) =>
              t.tenantId.equals(activeTenantId) &
              t.entity.equals(entity) &
              (t.status.equals(SyncStatus.pending.name) |
                  t.status.equals(SyncStatus.retrying.name))))
        .get();
    return entries.map((e) => e.entityId).toSet();
  }

  /// Retorna true se existir alguma operação pendente ou em retentativa para
  /// o par (entity, entityId) informado. Útil para verificação pontual.
  Future<bool> hasPendingForEntity(String entity, String entityId) async {
    final activeTenantId = context.tenantId;
    final entry = await (db.select(db.outboxSync)
          ..where((t) =>
              t.tenantId.equals(activeTenantId) &
              t.entity.equals(entity) &
              t.entityId.equals(entityId) &
              (t.status.equals(SyncStatus.pending.name) |
                  t.status.equals(SyncStatus.retrying.name))))
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
