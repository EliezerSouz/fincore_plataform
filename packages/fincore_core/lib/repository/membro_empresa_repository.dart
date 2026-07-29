import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/fincore_database.dart';
import '../common/core_models.dart';
import '../common/domain_primitives.dart';
import '../context/tenant_context.dart';
import '../sync/outbox_service.dart';
import '../di/dependency_injection.dart';
import 'base_repository.dart';

class MembroEmpresaRepository extends BaseRepository<CoreMembroEmpresa, String> {
  final FincoreDatabase db;

  MembroEmpresaRepository({required this.db, required TenantContext context})
      : super(context);

  @override
  Future<CoreMembroEmpresa?> findById(String id) async {
    final result = await (db.select(db.membrosEmpresaTable)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.tenantId.equals(activeTenantId)))
        .getSingleOrNull();

    if (result == null) return null;
    return _mapToCore(result);
  }

  @override
  Future<List<CoreMembroEmpresa>> findAll() async {
    final results = await (db.select(db.membrosEmpresaTable)
          ..where((t) => t.tenantId.equals(activeTenantId)))
        .get();
    return results.map(_mapToCore).toList();
  }

  Future<List<CoreMembroEmpresa>> findByUsuario(String usuarioId) async {
    final results = await (db.select(db.membrosEmpresaTable)
          ..where((t) => t.usuarioId.equals(usuarioId))
          ..where((t) => t.tenantId.equals(activeTenantId)))
        .get();
    return results.map(_mapToCore).toList();
  }

  @override
  Future<void> save(CoreMembroEmpresa entity) async {
    if (entity.tenantId != activeTenantId) {
      throw StateError('Violação de Tenancy: tenant diferente');
    }
    
    final now = DateTime.now().toUtc();
    final updatedMetadata = entity.metadata.copyWith(
      updatedAt: now,
    );

    await db.into(db.membrosEmpresaTable).insertOnConflictUpdate(
          MembrosEmpresaTableCompanion.insert(
            id: entity.id,
            tenantId: entity.tenantId,
            usuarioId: entity.usuarioId,
            role: entity.role,
            ativo: Value(entity.ativo),
            convidadoEm: entity.convidadoEm,
            aceitoEm: Value(entity.aceitoEm),
            syncVersion: Value(updatedMetadata.version),
            syncStatus: updatedMetadata.syncStatus,
            createdAt: updatedMetadata.createdAt,
            updatedAt: updatedMetadata.updatedAt,
            createdBy: updatedMetadata.createdBy,
            updatedBy: updatedMetadata.updatedBy,
            deletedAt: Value(updatedMetadata.deletedAt),
            deletedBy: const Value(null),
          ),
        );

    // Registra a mutação no Outbox
    final outbox = DependencyInjection().get<OutboxService>();
    await outbox.enqueue(
      entity: 'membros_empresa',
      entityId: entity.id,
      action: 'UPSERT',
      payload: _toJson(entity, updatedMetadata),
      version: updatedMetadata.version,
    );
  }

  @override
  Future<void> delete(String id) async {
    final entity = await findById(id);
    if (entity != null) {
      final outbox = DependencyInjection().get<OutboxService>();
      await outbox.enqueue(
        entity: 'membros_empresa',
        entityId: id,
        action: 'DELETE',
        payload: {'id': id, 'tenantId': entity.tenantId},
        version: entity.metadata.version + 1,
      );

      await (db.delete(db.membrosEmpresaTable)
            ..where((t) => t.id.equals(id))
            ..where((t) => t.tenantId.equals(activeTenantId)))
          .go();
    }
  }

  CoreMembroEmpresa _mapToCore(MembroEmpresaData data) {
    return CoreMembroEmpresa(
      id: data.id,
      tenantId: data.tenantId,
      usuarioId: data.usuarioId,
      role: data.role,
      ativo: data.ativo,
      convidadoEm: data.convidadoEm,
      aceitoEm: data.aceitoEm,
      metadata: SyncMetadata(
        version: data.syncVersion,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
        createdBy: data.createdBy,
        updatedBy: data.updatedBy,
        deletedAt: data.deletedAt,
        syncStatus: data.syncStatus,
      ),
    );
  }

  Map<String, dynamic> _toJson(CoreMembroEmpresa entity, SyncMetadata metadata) {
    return {
      'id': entity.id,
      'tenantId': entity.tenantId,
      'usuarioId': entity.usuarioId,
      'role': entity.role,
      'ativo': entity.ativo,
      'convidadoEm': entity.convidadoEm.toIso8601String(),
      'aceitoEm': entity.aceitoEm?.toIso8601String(),
      'syncVersion': metadata.version,
      'syncStatus': metadata.syncStatus.name,
      'createdAt': metadata.createdAt.toIso8601String(),
      'updatedAt': metadata.updatedAt.toIso8601String(),
      'createdBy': metadata.createdBy,
      'updatedBy': metadata.updatedBy,
    };
  }
}
