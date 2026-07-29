import 'package:drift/drift.dart';
import '../common/kds_models.dart';
import '../common/domain_primitives.dart';
import '../context/tenant_context.dart';
import '../database/fincore_database.dart';
import 'base_repository.dart';

class LoteInsumoRepository extends BaseRepository<LoteInsumo, String> {
  final FincoreDatabase db;

  LoteInsumoRepository({required this.db, required TenantContext context})
      : super(context);

  @override
  Future<LoteInsumo?> findById(String id) async {
    final activeTenant = activeTenantId;
    final row = await (db.select(db.lotesInsumoTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenant)))
        .getSingleOrNull();

    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<List<LoteInsumo>> findAll() async {
    final activeTenant = activeTenantId;
    final rows = await (db.select(db.lotesInsumoTable)
          ..where((t) => t.tenantId.equals(activeTenant)))
        .get();

    return rows.map(_mapToDomain).toList();
  }

  /// Busca os lotes ativos de um produto ordenados por data de validade/entrada (FIFO)
  Future<List<LoteInsumo>> findAtivosPorProdutoFIFO(String produtoId) async {
    final activeTenant = activeTenantId;
    final rows = await (db.select(db.lotesInsumoTable)
          ..where((t) =>
              t.produtoId.equals(produtoId) &
              t.tenantId.equals(activeTenant) &
              t.statusLote.equals(StatusLoteInsumo.ativo.name))
          ..orderBy([
            (t) => OrderingTerm(expression: t.dataValidade, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.dataEntrada, mode: OrderingMode.asc),
          ]))
        .get();

    return rows.map(_mapToDomain).toList();
  }

  /// Busca todos os lotes de um produto ordenados por data de entrada decrescente (LIFO para estorno)
  Future<List<LoteInsumo>> findLotesParaEstornoLIFO(String produtoId) async {
    final activeTenant = activeTenantId;
    final rows = await (db.select(db.lotesInsumoTable)
          ..where((t) =>
              t.produtoId.equals(produtoId) &
              t.tenantId.equals(activeTenant) &
              t.statusLote.equals(StatusLoteInsumo.ativo.name)))
        .get();

    // Ordenar no Dart por data de entrada descrescente (LIFO) para estorno do lote mais recente
    final list = rows.map(_mapToDomain).toList();
    list.sort((a, b) => b.dataEntrada.compareTo(a.dataEntrada));
    return list;
  }

  @override
  Future<void> save(LoteInsumo lote) async {
    final activeTenant = activeTenantId;
    if (lote.tenantId != activeTenant) {
      throw StateError(
          'Violação de Tenancy: Não é permitido salvar um LoteInsumo com ID de Tenant (${lote.tenantId}) diferente do Tenant ativo ($activeTenant).');
    }

    final entry = LotesInsumoTableCompanion.insert(
      id: lote.id,
      tenantId: activeTenant,
      produtoId: lote.produtoId,
      codigoLote: Value(lote.codigoLote),
      quantidadeInicial: lote.quantidadeInicial,
      quantidadeDisponivel: lote.quantidadeDisponivel,
      quantidadeReservada: Value(lote.quantidadeReservada),
      unidade: lote.unidade,
      dataValidade: Value(lote.dataValidade),
      dataEntrada: lote.dataEntrada,
      statusLote: lote.statusLote.name,
      createdAt: lote.metadata.createdAt,
      updatedAt: lote.metadata.updatedAt,
      createdBy: lote.metadata.createdBy,
      updatedBy: lote.metadata.updatedBy,
      deletedAt: Value(lote.metadata.deletedAt),
      syncStatus: lote.metadata.syncStatus,
      lastSyncedAt: Value(lote.metadata.lastSyncedAt),
    );

    await db.into(db.lotesInsumoTable).insertOnConflictUpdate(entry);
  }

  @override
  Future<void> delete(String id) async {
    final activeTenant = activeTenantId;
    final now = DateTime.now();
    await (db.update(db.lotesInsumoTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenant)))
        .write(LotesInsumoTableCompanion(
          deletedAt: Value(now),
          syncStatus: Value(SyncStatus.pending),
          updatedAt: Value(now),
          statusLote: Value(StatusLoteInsumo.cancelado.name),
        ));
  }

  LoteInsumo _mapToDomain(LoteInsumoData data) {
    return LoteInsumo(
      id: data.id,
      tenantId: data.tenantId,
      produtoId: data.produtoId,
      codigoLote: data.codigoLote,
      quantidadeInicial: data.quantidadeInicial,
      quantidadeDisponivel: data.quantidadeDisponivel,
      quantidadeReservada: data.quantidadeReservada,
      unidade: data.unidade,
      dataValidade: data.dataValidade,
      dataEntrada: data.dataEntrada,
      statusLote: StatusLoteInsumo.values.firstWhere(
          (e) => e.name == data.statusLote,
          orElse: () => StatusLoteInsumo.ativo),
      metadata: SyncMetadata(
        version: 1,
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
