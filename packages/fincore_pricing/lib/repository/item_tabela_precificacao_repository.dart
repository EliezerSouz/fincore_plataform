import 'package:drift/drift.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:fincore_core/sync/syncable_repository.dart';
import 'package:fincore_core/sync/sync_engine.dart';
import '../common/pricing_models.dart';

class ItemTabelaPrecificacaoRepository extends SyncableRepository<ItemTabelaPrecificacao> {
  ItemTabelaPrecificacaoRepository({
    required super.db,
    required super.context,
    required super.outbox,
    super.syncEngine,
  });

  @override
  String get entityName => 'itens_tabela_precificacao';

  @override
  String extractId(ItemTabelaPrecificacao entity) => entity.id;

  @override
  int extractVersion(ItemTabelaPrecificacao entity) => entity.metadata.version;

  @override
  Map<String, dynamic> toOutboxPayload(ItemTabelaPrecificacao entity) => {
        'id': entity.id,
        'tenantId': entity.tenantId,
        'tabelaPrecificacaoId': entity.tabelaPrecificacaoId,
        'quantidadeMinima': entity.quantidadeMinima,
        'quantidadeMaxima': entity.quantidadeMaxima,
        'valorUnitarioCentavos': entity.valorUnitarioCentavos,
        'ordem': entity.ordem,
        'syncVersion': entity.metadata.version,
        'createdAt': entity.metadata.createdAt.toIso8601String(),
        'updatedAt': entity.metadata.updatedAt.toIso8601String(),
        'createdBy': entity.metadata.createdBy,
        'updatedBy': entity.metadata.updatedBy,
      };

  @override
  Future<ItemTabelaPrecificacao?> findById(String id) async {
    final row = await (db.select(db.itensTabelaPrecificacaoTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .getSingleOrNull();
    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<List<ItemTabelaPrecificacao>> findAll() async {
    final rows = await (db.select(db.itensTabelaPrecificacaoTable)
          ..where((t) => t.tenantId.equals(activeTenantId) & t.deletedAt.isNull()))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  Future<List<ItemTabelaPrecificacao>> findByTabelaId(String tabelaId) async {
    final rows = await (db.select(db.itensTabelaPrecificacaoTable)
          ..where((t) =>
              t.tabelaPrecificacaoId.equals(tabelaId) &
              t.tenantId.equals(activeTenantId) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.ordem)]))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<void> saveLocal(ItemTabelaPrecificacao item) async {
    if (item.tenantId != activeTenantId) {
      throw StateError('Violação de Tenancy ao salvar ItemTabelaPrecificacao');
    }
    await db.into(db.itensTabelaPrecificacaoTable).insertOnConflictUpdate(
          ItensTabelaPrecificacaoTableCompanion.insert(
            id: item.id,
            tenantId: activeTenantId,
            tabelaPrecificacaoId: item.tabelaPrecificacaoId,
            quantidadeMinima: item.quantidadeMinima,
            quantidadeMaxima: Value(item.quantidadeMaxima),
            valorUnitarioCentavos: item.valorUnitarioCentavos,
            ordem: item.ordem,
            createdAt: item.metadata.createdAt,
            updatedAt: DateTime.now().toUtc(),
            createdBy: item.metadata.createdBy,
            updatedBy: item.metadata.updatedBy,
            deletedAt: Value(item.metadata.deletedAt),
            syncStatus: SyncStatus.pending,
            lastSyncedAt: Value(item.metadata.lastSyncedAt),
          ),
        );
  }

  @override
  Future<void> deleteLocal(String id, ItemTabelaPrecificacao entity) async {
    final now = DateTime.now().toUtc();
    await (db.update(db.itensTabelaPrecificacaoTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .write(ItensTabelaPrecificacaoTableCompanion(
      deletedAt: Value(now),
      syncStatus: const Value(SyncStatus.pending),
      updatedAt: Value(now),
    ));
  }

  Future<ItemTabelaPrecificacao> save(ItemTabelaPrecificacao item) => saveWithSync(item);
  Future<void> delete(String id) => deleteWithSync(id);

  ItemTabelaPrecificacao _mapToDomain(ItemTabelaPrecificacaoData data) {
    return ItemTabelaPrecificacao(
      id: data.id,
      tenantId: data.tenantId,
      tabelaPrecificacaoId: data.tabelaPrecificacaoId,
      quantidadeMinima: data.quantidadeMinima,
      quantidadeMaxima: data.quantidadeMaxima,
      valorUnitarioCentavos: data.valorUnitarioCentavos,
      ordem: data.ordem,
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
