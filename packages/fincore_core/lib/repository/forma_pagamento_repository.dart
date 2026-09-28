import 'package:drift/drift.dart';
import '../common/master_data_models.dart';
import '../common/domain_primitives.dart';
import '../context/tenant_context.dart';
import '../database/fincore_database.dart';
import '../sync/outbox_service.dart';
import '../sync/syncable_repository.dart';
import '../sync/sync_engine.dart';

class FormaPagamentoRepository extends SyncableRepository<FormaPagamento> {
  FormaPagamentoRepository({
    required super.db,
    required super.context,
    required super.outbox,
    super.syncEngine,
  });

  @override
  String get entityName => 'formas_pagamento';

  @override
  String extractId(FormaPagamento entity) => entity.id;

  @override
  int extractVersion(FormaPagamento entity) => entity.metadata.version;

  @override
  Map<String, dynamic> toOutboxPayload(FormaPagamento entity) => {
        'id': entity.id,
        'tenantId': entity.tenantId,
        'nome': entity.nome,
        'tipo': entity.tipo.name,
        'ordem': entity.ordem,
        'ativo': entity.ativo,
        'permiteTroco': entity.permiteTroco,
        'isUsoInterno': entity.isUsoInterno,
        'movimentaFinanceiro': entity.movimentaFinanceiro,
        'movimentaEstoque': entity.movimentaEstoque,
        'bandeiraPadrao': entity.bandeiraPadrao,
        'descricao': entity.descricao,
        'pixChave': entity.pixChave,
        'pixTipoChave': entity.pixTipoChave,
        'pixTipoBanco': entity.pixTipoBanco,
        'syncVersion': entity.metadata.version,
        'createdAt': entity.metadata.createdAt.toIso8601String(),
        'updatedAt': entity.metadata.updatedAt.toIso8601String(),
        'createdBy': entity.metadata.createdBy,
        'updatedBy': entity.metadata.updatedBy,
      };

  @override
  Future<FormaPagamento?> findById(String id) async {
    final row = await (db.select(db.formasPagamentoTable)
          ..where(
            (t) =>
                t.id.equals(id) &
                t.tenantId.equals(activeTenantId) &
                t.deletedAt.isNull(),
          ))
        .getSingleOrNull();
    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<List<FormaPagamento>> findAll() async {
    final rows = await (db.select(db.formasPagamentoTable)
          ..where(
            (t) =>
                t.tenantId.equals(activeTenantId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.ordem)]))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<void> saveLocal(FormaPagamento forma) async {
    if (forma.tenantId != activeTenantId) {
      throw StateError('Violação de Tenancy ao salvar FormaPagamento');
    }
    await db.into(db.formasPagamentoTable).insertOnConflictUpdate(
          FormasPagamentoTableCompanion.insert(
            id: forma.id,
            tenantId: activeTenantId,
            nome: forma.nome,
            tipo: forma.tipo.name,
            ordem: forma.ordem,
            ativo: forma.ativo,
            permiteTroco: forma.permiteTroco,
            isUsoInterno: Value(forma.isUsoInterno),
            movimentaFinanceiro: Value(forma.movimentaFinanceiro),
            movimentaEstoque: Value(forma.movimentaEstoque),
            bandeiraPadrao: Value(forma.bandeiraPadrao),
            descricao: Value(forma.descricao),
            pixChave: Value(forma.pixChave),
            pixTipoChave: Value(forma.pixTipoChave),
            pixTipoBanco: Value(forma.pixTipoBanco),
            createdAt: forma.metadata.createdAt,
            updatedAt: DateTime.now().toUtc(),
            createdBy: forma.metadata.createdBy,
            updatedBy: forma.metadata.updatedBy,
            deletedAt: Value(forma.metadata.deletedAt),
            syncStatus: SyncStatus.pending,
            lastSyncedAt: Value(forma.metadata.lastSyncedAt),
          ),
        );
  }

  @override
  Future<void> deleteLocal(String id, FormaPagamento entity) async {
    final now = DateTime.now().toUtc();
    await (db.update(db.formasPagamentoTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .write(FormasPagamentoTableCompanion(
      deletedAt: Value(now),
      syncStatus: const Value(SyncStatus.pending),
      updatedAt: Value(now),
    ));
  }

  Future<FormaPagamento> save(FormaPagamento forma) => saveWithSync(forma);
  Future<void> delete(String id) => deleteWithSync(id);

  FormaPagamento _mapToDomain(FormaPagamentoData data) {
    return FormaPagamento(
      id: data.id,
      tenantId: data.tenantId,
      nome: data.nome,
      tipo: TipoFormaPagamento.values.firstWhere((e) => e.name == data.tipo,
          orElse: () => TipoFormaPagamento.outro),
      ordem: data.ordem,
      ativo: data.ativo,
      permiteTroco: data.permiteTroco,
      isUsoInterno: data.isUsoInterno,
      movimentaFinanceiro: data.movimentaFinanceiro,
      movimentaEstoque: data.movimentaEstoque,
      bandeiraPadrao: data.bandeiraPadrao,
      descricao: data.descricao,
      pixChave: data.pixChave,
      pixTipoChave: data.pixTipoChave,
      pixTipoBanco: data.pixTipoBanco,
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
