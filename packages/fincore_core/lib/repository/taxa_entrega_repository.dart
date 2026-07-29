import 'package:drift/drift.dart';
import '../common/master_data_models.dart';
import '../common/domain_primitives.dart';
import '../context/tenant_context.dart';
import '../database/fincore_database.dart';
import '../sync/outbox_service.dart';
import '../sync/syncable_repository.dart';
import '../sync/sync_engine.dart';

class TaxaEntregaRepository extends SyncableRepository<TaxaEntrega> {
  TaxaEntregaRepository({
    required super.db,
    required super.context,
    required super.outbox,
    super.syncEngine,
  });

  @override
  String get entityName => 'taxas_entrega';

  @override
  String extractId(TaxaEntrega entity) => entity.id;

  @override
  int extractVersion(TaxaEntrega entity) => entity.metadata.version;

  @override
  Map<String, dynamic> toOutboxPayload(TaxaEntrega entity) => {
        'id': entity.id,
        'tenantId': entity.tenantId,
        'nome': entity.nome,
        'tipoRegra': entity.tipoRegra.name,
        'bairro': entity.bairro,
        'cepInicial': entity.cepInicial,
        'cepFinal': entity.cepFinal,
        'valorCentavos': entity.valorCentavos,
        'ativo': entity.ativo,
        'syncVersion': entity.metadata.version,
        'createdAt': entity.metadata.createdAt.toIso8601String(),
        'updatedAt': entity.metadata.updatedAt.toIso8601String(),
        'createdBy': entity.metadata.createdBy,
        'updatedBy': entity.metadata.updatedBy,
      };

  @override
  Future<TaxaEntrega?> findById(String id) async {
    final row = await (db.select(db.taxasEntregaTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .getSingleOrNull();
    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<List<TaxaEntrega>> findAll() async {
    final rows = await (db.select(db.taxasEntregaTable)
          ..where((t) => t.tenantId.equals(activeTenantId)))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<void> saveLocal(TaxaEntrega taxa) async {
    if (taxa.tenantId != activeTenantId) {
      throw StateError('Violação de Tenancy ao salvar TaxaEntrega');
    }
    await db.into(db.taxasEntregaTable).insertOnConflictUpdate(
          TaxasEntregaTableCompanion.insert(
            id: taxa.id,
            tenantId: activeTenantId,
            nome: taxa.nome,
            tipoRegra: taxa.tipoRegra.name,
            bairro: Value(taxa.bairro),
            cepInicial: Value(taxa.cepInicial),
            cepFinal: Value(taxa.cepFinal),
            valorCentavos: taxa.valorCentavos,
            ativo: taxa.ativo,
            createdAt: taxa.metadata.createdAt,
            updatedAt: DateTime.now().toUtc(),
            createdBy: taxa.metadata.createdBy,
            updatedBy: taxa.metadata.updatedBy,
            deletedAt: Value(taxa.metadata.deletedAt),
            syncStatus: SyncStatus.pending,
            lastSyncedAt: Value(taxa.metadata.lastSyncedAt),
          ),
        );
  }

  @override
  Future<void> deleteLocal(String id, TaxaEntrega entity) async {
    final now = DateTime.now().toUtc();
    await (db.update(db.taxasEntregaTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .write(TaxasEntregaTableCompanion(
      deletedAt: Value(now),
      syncStatus: const Value(SyncStatus.pending),
      updatedAt: Value(now),
    ));
  }

  Future<TaxaEntrega> save(TaxaEntrega taxa) => saveWithSync(taxa);
  Future<void> delete(String id) => deleteWithSync(id);

  TaxaEntrega _mapToDomain(TaxaEntregaData data) {
    return TaxaEntrega(
      id: data.id,
      tenantId: data.tenantId,
      nome: data.nome,
      tipoRegra: TipoRegraTaxaEntrega.values.firstWhere(
          (e) => e.name == data.tipoRegra,
          orElse: () => TipoRegraTaxaEntrega.fixo),
      bairro: data.bairro,
      cepInicial: data.cepInicial,
      cepFinal: data.cepFinal,
      valorCentavos: data.valorCentavos,
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
