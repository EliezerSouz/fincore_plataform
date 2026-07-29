import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../context/tenant_context.dart';

class AuditLogRepository {
  final FincoreDatabase _db;
  final OutboxService _outboxRepo;

  AuditLogRepository({
    FincoreDatabase? db,
    OutboxService? outboxRepo,
  })  : _db = db ?? DependencyInjection().get<FincoreDatabase>(),
        _outboxRepo = outboxRepo ?? DependencyInjection().get<OutboxService>();

  /// Registra uma nova entrada de auditoria e já envia para a fila de sincronização (Outbox).
  Future<void> log({
    required String entityName,
    required String entityId,
    required String userId,
    required String action, // CREATE, UPDATE, DELETE
    Map<String, dynamic>? diff,
    int? syncVersion,
    String? deviceInfo,
    String? origin,
    String? reason,
  }) async {
    final auditId = const Uuid().v4();
    final timestamp = DateTime.now().toUtc();
    
    final diffJson = diff != null ? jsonEncode(diff) : null;

    final companion = AuditLogsTableCompanion.insert(
      id: auditId,
      targetEntity: entityName,
      entityId: entityId,
      userId: userId,
      action: action,
      timestamp: timestamp,
      diff: Value(diffJson),
      syncVersion: Value(syncVersion),
      deviceInfo: Value(deviceInfo),
      origin: Value(origin),
      reason: Value(reason),
    );

    // Salva localmente
    await _db.into(_db.auditLogsTable).insert(companion);

    // Enfileira para o Supabase (Push)
    String activeTenantId = 'system';
    try {
      activeTenantId = DependencyInjection().get<TenantContext>().tenantId;
    } catch (_) {}

    final payload = {
      'id': auditId,
      'tenantId': activeTenantId,
      'entityName': entityName,
      'entityId': entityId,
      'userId': userId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'diff': diff, // Envia o Map bruto direto para a coluna JSONB do Supabase
      'syncVersion': syncVersion,
      'deviceInfo': deviceInfo,
      'origin': origin,
      'reason': reason,
    };

    await _outboxRepo.enqueue(
      entity: 'audit_log',
      entityId: auditId,
      action: 'UPSERT',
      payload: payload,
      version: 1,
    );
  }

  /// Retorna o histórico de auditoria para uma entidade específica, ordenado do mais recente para o mais antigo.
  Future<List<AuditLogEntry>> findByEntity(String entityName, String entityId) async {
    return (_db.select(_db.auditLogsTable)
          ..where((t) => t.targetEntity.equals(entityName) & t.entityId.equals(entityId))
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .get();
  }
}
