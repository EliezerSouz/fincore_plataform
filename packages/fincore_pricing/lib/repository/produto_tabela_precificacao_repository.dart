import 'package:drift/drift.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:fincore_core/sync/syncable_repository.dart';
import 'package:fincore_core/sync/sync_engine.dart';
import '../common/pricing_models.dart';

class ProdutoTabelaPrecificacaoRepository extends SyncableRepository<ProdutoTabelaPrecificacao> {
  ProdutoTabelaPrecificacaoRepository({
    required super.db,
    required super.context,
    required super.outbox,
    super.syncEngine,
  });

  @override
  String get entityName => 'produtos_tabelas_precificacao';

  @override
  String extractId(ProdutoTabelaPrecificacao entity) => entity.id;

  @override
  int extractVersion(ProdutoTabelaPrecificacao entity) => entity.metadata.version;

  @override
  Map<String, dynamic> toOutboxPayload(ProdutoTabelaPrecificacao entity) => {
        'id': entity.id,
        'tenantId': entity.tenantId,
        'produtoId': entity.produtoId,
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
  Future<ProdutoTabelaPrecificacao?> findById(String id) async {
    final row = await (db.select(db.produtosTabelasPrecificacaoTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .getSingleOrNull();
    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<List<ProdutoTabelaPrecificacao>> findAll() async {
    final rows = await (db.select(db.produtosTabelasPrecificacaoTable)
          ..where((t) => t.tenantId.equals(activeTenantId) & t.deletedAt.isNull()))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  Future<List<ProdutoTabelaPrecificacao>> findByProdutoId(String produtoId) async {
    final rows = await (db.select(db.produtosTabelasPrecificacaoTable)
          ..where((t) =>
              t.produtoId.equals(produtoId) &
              t.tenantId.equals(activeTenantId) &
              t.deletedAt.isNull()))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<void> saveLocal(ProdutoTabelaPrecificacao assoc) async {
    if (assoc.tenantId != activeTenantId) {
      throw StateError('Violação de Tenancy ao salvar ProdutoTabelaPrecificacao');
    }
    await db.into(db.produtosTabelasPrecificacaoTable).insertOnConflictUpdate(
          ProdutosTabelasPrecificacaoTableCompanion.insert(
            id: assoc.id,
            tenantId: activeTenantId,
            produtoId: assoc.produtoId,
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
            lastSyncedAt: Value(assoc.metadata.lastSyncedAt),
          ),
        );
  }

  @override
  Future<void> deleteLocal(String id, ProdutoTabelaPrecificacao entity) async {
    final now = DateTime.now().toUtc();
    await (db.update(db.produtosTabelasPrecificacaoTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .write(ProdutosTabelasPrecificacaoTableCompanion(
      deletedAt: Value(now),
      syncStatus: const Value(SyncStatus.pending),
      updatedAt: Value(now),
    ));
  }

  Future<ProdutoTabelaPrecificacao> save(ProdutoTabelaPrecificacao assoc) => saveWithSync(assoc);
  Future<void> delete(String id) => deleteWithSync(id);

  ProdutoTabelaPrecificacao _mapToDomain(ProdutoTabelaPrecificacaoData data) {
    return ProdutoTabelaPrecificacao(
      id: data.id,
      tenantId: data.tenantId,
      produtoId: data.produtoId,
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
