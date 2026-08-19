import 'package:drift/drift.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:fincore_core/sync/syncable_repository.dart';
import 'package:fincore_core/sync/sync_engine.dart';
import '../common/pricing_models.dart';

class TabelaPrecificacaoRepository extends SyncableRepository<TabelaPrecificacao> {
  TabelaPrecificacaoRepository({
    required super.db,
    required super.context,
    required super.outbox,
    super.syncEngine,
  });

  @override
  String get entityName => 'tabelas_precificacao';

  @override
  String extractId(TabelaPrecificacao entity) => entity.id;

  @override
  int extractVersion(TabelaPrecificacao entity) => entity.metadata.version;

  @override
  Map<String, dynamic> toOutboxPayload(TabelaPrecificacao entity) => {
        'id': entity.id,
        'tenantId': entity.tenantId,
        'nome': entity.nome,
        'descricao': entity.descricao,
        'tipoPolitica': entity.tipoPolitica.name,
        'prioridade': entity.prioridade,
        'ativo': entity.ativo,
        'canal': entity.canal, // P1-07
        'syncVersion': entity.metadata.version,
        'createdAt': entity.metadata.createdAt.toIso8601String(),
        'updatedAt': entity.metadata.updatedAt.toIso8601String(),
        'createdBy': entity.metadata.createdBy,
        'updatedBy': entity.metadata.updatedBy,
      };

  @override
  Future<TabelaPrecificacao?> findById(String id) async {
    final row = await (db.select(db.tabelasPrecificacaoTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .getSingleOrNull();
    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<List<TabelaPrecificacao>> findAll() async {
    final rows = await (db.select(db.tabelasPrecificacaoTable)
          ..where((t) => t.tenantId.equals(activeTenantId) & t.deletedAt.isNull()))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<void> saveLocal(TabelaPrecificacao tabela) async {
    if (tabela.tenantId != activeTenantId) {
      throw StateError('Violação de Tenancy ao salvar TabelaPrecificacao');
    }
    await db.into(db.tabelasPrecificacaoTable).insertOnConflictUpdate(
          TabelasPrecificacaoTableCompanion.insert(
            id: tabela.id,
            tenantId: activeTenantId,
            nome: tabela.nome,
            descricao: tabela.descricao,
            tipoPolitica: tabela.tipoPolitica.name,
            prioridade: tabela.prioridade,
            ativo: tabela.ativo,
            canal: Value(tabela.canal), // P1-07
            createdAt: tabela.metadata.createdAt,
            updatedAt: DateTime.now().toUtc(),
            createdBy: tabela.metadata.createdBy,
            updatedBy: tabela.metadata.updatedBy,
            deletedAt: Value(tabela.metadata.deletedAt),
            syncStatus: SyncStatus.pending,
            lastSyncedAt: Value(tabela.metadata.lastSyncedAt),
          ),
        );
  }

  @override
  Future<void> deleteLocal(String id, TabelaPrecificacao entity) async {
    final now = DateTime.now().toUtc();
    await (db.update(db.tabelasPrecificacaoTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .write(TabelasPrecificacaoTableCompanion(
      deletedAt: Value(now),
      syncStatus: const Value(SyncStatus.pending),
      updatedAt: Value(now),
    ));
  }

  Future<TabelaPrecificacao> save(TabelaPrecificacao tabela) => saveWithSync(tabela);
  Future<void> delete(String id) => deleteWithSync(id);

  TabelaPrecificacao _mapToDomain(TabelaPrecificacaoData data) {
    return TabelaPrecificacao(
      id: data.id,
      tenantId: data.tenantId,
      nome: data.nome,
      descricao: data.descricao,
      tipoPolitica: PricingPolicyType.values.firstWhere(
          (e) => e.name == data.tipoPolitica,
          orElse: () => PricingPolicyType.unitario),
      prioridade: data.prioridade,
      ativo: data.ativo,
      canal: data.canal ?? 'todos', // P1-07: fallback retroativo
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
