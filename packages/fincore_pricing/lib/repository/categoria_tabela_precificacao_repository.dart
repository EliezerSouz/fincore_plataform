import 'package:drift/drift.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:fincore_core/sync/syncable_repository.dart';
import 'package:fincore_core/sync/sync_engine.dart';
import '../common/pricing_models.dart';

class CategoriaTabelaPrecificacaoRepository extends SyncableRepository<CategoriaTabelaPrecificacao> {
  CategoriaTabelaPrecificacaoRepository({
    required super.db,
    required super.context,
    required super.outbox,
    super.syncEngine,
  });

  @override
  String get entityName => 'categorias_tabelas_precificacao';

  @override
  String extractId(CategoriaTabelaPrecificacao entity) => entity.id;

  @override
  int extractVersion(CategoriaTabelaPrecificacao entity) => entity.metadata.version;

  @override
  Map<String, dynamic> toOutboxPayload(CategoriaTabelaPrecificacao entity) => {
        'id': entity.id,
        'tenantId': entity.tenantId,
        'categoriaId': entity.categoriaId,
        'tabelaPrecificacaoId': entity.tabelaPrecificacaoId,
        'ativo': entity.ativo,
        'prioridade': entity.prioridade,
        'dataInicio': entity.dataInicio?.toIso8601String(),
        'dataFim': entity.dataFim?.toIso8601String(),
        'syncVersion': entity.metadata.version,
        'createdAt': entity.metadata.createdAt.toIso8601String(),
        'updatedAt': entity.metadata.updatedAt.toIso8601String(),
        'createdBy': entity.metadata.createdBy,
        'updatedBy': entity.metadata.updatedBy,
      };

  @override
  Future<CategoriaTabelaPrecificacao?> findById(String id) async {
    final row = await (db.select(db.categoriasTabelasPrecificacaoTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .getSingleOrNull();
    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<List<CategoriaTabelaPrecificacao>> findAll() async {
    final rows = await (db.select(db.categoriasTabelasPrecificacaoTable)
          ..where((t) => t.tenantId.equals(activeTenantId) & t.deletedAt.isNull()))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  Future<List<CategoriaTabelaPrecificacao>> findByCategoriaId(String categoriaId) async {
    final rows = await (db.select(db.categoriasTabelasPrecificacaoTable)
          ..where((t) =>
              t.categoriaId.equals(categoriaId) &
              t.tenantId.equals(activeTenantId) &
              t.deletedAt.isNull()))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<void> saveLocal(CategoriaTabelaPrecificacao assoc) async {
    if (assoc.tenantId != activeTenantId) {
      throw StateError('Violação de Tenancy ao salvar CategoriaTabelaPrecificacao');
    }
    await db.into(db.categoriasTabelasPrecificacaoTable).insertOnConflictUpdate(
          CategoriasTabelasPrecificacaoTableCompanion.insert(
            id: assoc.id,
            tenantId: activeTenantId,
            categoriaId: assoc.categoriaId,
            tabelaPrecificacaoId: assoc.tabelaPrecificacaoId,
            ativo: assoc.ativo,
            prioridade: assoc.prioridade,
            dataInicio: Value(assoc.dataInicio),
            dataFim: Value(assoc.dataFim),
            createdAt: assoc.metadata.createdAt,
            updatedAt: DateTime.now().toUtc(),
            createdBy: assoc.metadata.createdBy,
            updatedBy: assoc.metadata.updatedBy,
            deletedAt: Value(assoc.metadata.deletedAt),
            syncStatus: SyncStatus.pending,
            syncVersion: Value(assoc.metadata.version),
            lastSyncedAt: Value(assoc.metadata.lastSyncedAt),
          ),
        );
  }

  @override
  Future<void> deleteLocal(String id, CategoriaTabelaPrecificacao entity) async {
    final now = DateTime.now().toUtc();
    await (db.update(db.categoriasTabelasPrecificacaoTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .write(CategoriasTabelasPrecificacaoTableCompanion(
      deletedAt: Value(now),
      syncStatus: const Value(SyncStatus.pending),
      updatedAt: Value(now),
    ));
  }

  Future<CategoriaTabelaPrecificacao> save(CategoriaTabelaPrecificacao assoc) => saveWithSync(assoc);
  Future<void> delete(String id) => deleteWithSync(id);

  CategoriaTabelaPrecificacao _mapToDomain(CategoriaTabelaPrecificacaoData data) {
    return CategoriaTabelaPrecificacao(
      id: data.id,
      tenantId: data.tenantId,
      categoriaId: data.categoriaId,
      tabelaPrecificacaoId: data.tabelaPrecificacaoId,
      ativo: data.ativo,
      prioridade: data.prioridade,
      dataInicio: data.dataInicio,
      dataFim: data.dataFim,
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
