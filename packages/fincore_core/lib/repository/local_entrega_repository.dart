import 'package:drift/drift.dart';
import '../common/master_data_models.dart';
import '../common/domain_primitives.dart';
import '../context/tenant_context.dart';
import '../database/fincore_database.dart';
import '../sync/outbox_service.dart';
import '../sync/syncable_repository.dart';
import '../sync/sync_engine.dart';

class LocalEntregaRepository extends SyncableRepository<LocalEntrega> {
  LocalEntregaRepository({
    required super.db,
    required super.context,
    required super.outbox,
    super.syncEngine,
  });

  @override
  String get entityName => 'locais_entrega';

  @override
  String extractId(LocalEntrega entity) => entity.id;

  @override
  int extractVersion(LocalEntrega entity) => entity.metadata.version;

  @override
  Map<String, dynamic> toOutboxPayload(LocalEntrega entity) => {
        'id': entity.id,
        'tenantId': entity.tenantId,
        'clienteId': entity.clienteId,
        'nomeIdentificador': entity.nomeIdentificador,
        'logradouro': entity.logradouro,
        'numero': entity.numero,
        'bairro': entity.bairro,
        'cidade': entity.cidade,
        'cep': entity.cep,
        'referencia': entity.referencia,
        'ativo': entity.ativo,
        'syncVersion': entity.metadata.version,
        'createdAt': entity.metadata.createdAt.toIso8601String(),
        'updatedAt': entity.metadata.updatedAt.toIso8601String(),
        'createdBy': entity.metadata.createdBy,
        'updatedBy': entity.metadata.updatedBy,
      };

  @override
  Future<LocalEntrega?> findById(String id) async {
    final row = await (db.select(db.locaisEntregaTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .getSingleOrNull();
    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<List<LocalEntrega>> findAll() async {
    final rows = await (db.select(db.locaisEntregaTable)
          ..where((t) => t.tenantId.equals(activeTenantId)))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  Future<List<LocalEntrega>> findByClienteId(String clienteId) async {
    final rows = await (db.select(db.locaisEntregaTable)
          ..where((t) => t.clienteId.equals(clienteId) & t.tenantId.equals(activeTenantId)))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<void> saveLocal(LocalEntrega local) async {
    if (local.tenantId != activeTenantId) {
      throw StateError('Violação de Tenancy ao salvar LocalEntrega');
    }
    await db.into(db.locaisEntregaTable).insertOnConflictUpdate(
          LocaisEntregaTableCompanion.insert(
            id: local.id,
            tenantId: activeTenantId,
            clienteId: local.clienteId,
            nomeIdentificador: local.nomeIdentificador,
            logradouro: local.logradouro,
            numero: local.numero,
            bairro: local.bairro,
            cidade: local.cidade,
            cep: local.cep,
            referencia: local.referencia,
            ativo: local.ativo,
            createdAt: local.metadata.createdAt,
            updatedAt: DateTime.now().toUtc(),
            createdBy: local.metadata.createdBy,
            updatedBy: local.metadata.updatedBy,
            deletedAt: Value(local.metadata.deletedAt),
            syncStatus: SyncStatus.pending,
            lastSyncedAt: Value(local.metadata.lastSyncedAt),
          ),
        );
  }

  @override
  Future<void> deleteLocal(String id, LocalEntrega entity) async {
    final now = DateTime.now().toUtc();
    await (db.update(db.locaisEntregaTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .write(LocaisEntregaTableCompanion(
      deletedAt: Value(now),
      syncStatus: const Value(SyncStatus.pending),
      updatedAt: Value(now),
    ));
  }

  Future<LocalEntrega> save(LocalEntrega local) => saveWithSync(local);
  Future<void> delete(String id) => deleteWithSync(id);

  LocalEntrega _mapToDomain(LocalEntregaData data) {
    return LocalEntrega(
      id: data.id,
      tenantId: data.tenantId,
      clienteId: data.clienteId,
      nomeIdentificador: data.nomeIdentificador,
      logradouro: data.logradouro,
      numero: data.numero,
      bairro: data.bairro,
      cidade: data.cidade,
      cep: data.cep,
      referencia: data.referencia,
      ativo: data.ativo,
      metadata: SyncMetadata(
        version: data.syncVersion,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
        createdBy: data.createdBy,
        updatedBy: data.updatedBy,
        deletedAt: data.deletedAt,
        syncStatus: data.syncStatus,
        lastSyncedAt: data.lastSyncedAt,
      ),
    );
  }
}
