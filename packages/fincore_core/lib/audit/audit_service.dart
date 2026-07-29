import '../context/tenant_context.dart';

enum AuditAction {
  create,
  update,
  delete,
}

class AuditEvent {
  final String id;
  final String entity;
  final String entityId;
  final String tenantId;
  final AuditAction action;
  final String? before;
  final String? after;
  final String performedBy;
  final DateTime performedAt;
  final String deviceId;
  final String origin;

  const AuditEvent({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.tenantId,
    required this.action,
    this.before,
    this.after,
    required this.performedBy,
    required this.performedAt,
    required this.deviceId,
    required this.origin,
  });
}

class AuditService {
  final TenantContext context;
  final List<AuditEvent> _auditLog = [];

  AuditService({required this.context});

  List<AuditEvent> get logs => List.unmodifiable(_auditLog);

  /// Registra imutavelmente um log de alteração de dados.
  Future<void> log({
    required String id,
    required String entity,
    required String entityId,
    required AuditAction action,
    String? before,
    String? after,
    required String deviceId,
    required String origin,
  }) async {
    final activeTenantId = context.tenantId;
    final activeUser = context.usuario;

    final event = AuditEvent(
      id: id,
      entity: entity,
      entityId: entityId,
      tenantId: activeTenantId,
      action: action,
      before: before,
      after: after,
      performedBy: activeUser.id,
      performedAt: DateTime.now(),
      deviceId: deviceId,
      origin: origin,
    );

    _auditLog.add(event);
  }
}
