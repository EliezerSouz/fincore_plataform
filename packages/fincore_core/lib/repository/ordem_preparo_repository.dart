import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../common/kds_models.dart';
import '../common/domain_primitives.dart';
import '../context/tenant_context.dart';
import '../database/fincore_database.dart';
import 'base_repository.dart';

class OrdemPreparoRepository extends BaseRepository<OrdemPreparo, String> {
  final FincoreDatabase db;

  OrdemPreparoRepository({required this.db, required TenantContext context})
      : super(context);

  @override
  Future<OrdemPreparo?> findById(String id) async {
    final activeTenant = activeTenantId;
    final row = await (db.select(db.ordensPreparoTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenant)))
        .getSingleOrNull();

    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<List<OrdemPreparo>> findAll() async {
    final activeTenant = activeTenantId;
    final rows = await (db.select(db.ordensPreparoTable)
          ..where((t) => t.tenantId.equals(activeTenant)))
        .get();

    return rows.map(_mapToDomain).toList();
  }

  /// Retorna as ordens de preparo ativas na cozinha (pendentes, em preparo, prontas) ordenadas por prioridade e criacao.
  Future<List<OrdemPreparo>> findAtivasKds() async {
    final activeTenant = activeTenantId;
    final statusAtivos = [
      StatusOrdemPreparo.pendente.name,
      StatusOrdemPreparo.emPreparo.name,
      StatusOrdemPreparo.pronto.name,
    ];

    final rows = await (db.select(db.ordensPreparoTable)
          ..where((t) =>
              t.tenantId.equals(activeTenant) & t.status.isIn(statusAtivos))
          ..orderBy([
            // VIP/Urgente primeiro, depois por ordem de criacao
            (t) => OrderingTerm(
                expression: t.prioridade,
                mode: OrderingMode.desc), // vip e urgente na ordenação alf. ou manual
            (t) => OrderingTerm(expression: t.criadaEm, mode: OrderingMode.asc),
          ]))
        .get();

    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<void> save(OrdemPreparo ordem) async {
    final activeTenant = activeTenantId;
    if (ordem.tenantId != activeTenant) {
      throw StateError(
          'Violação de Tenancy: Não é permitido salvar uma OrdemPreparo com ID de Tenant (${ordem.tenantId}) diferente do Tenant ativo ($activeTenant).');
    }

    final itensRaw = jsonEncode(ordem.itens.map((i) => i.toJson()).toList());

    final entry = OrdensPreparoTableCompanion.insert(
      id: ordem.id,
      tenantId: activeTenant,
      pedidoId: ordem.pedidoId,
      itensJson: itensRaw,
      status: ordem.status.name,
      prioridade: ordem.prioridade.name,
      operadorId: Value(ordem.operadorId),
      criadaEm: ordem.criadaEm,
      iniciadaEm: Value(ordem.iniciadaEm),
      concluidaEm: Value(ordem.concluidaEm),
      canceladaEm: Value(ordem.canceladaEm),
      tempoEstimadoSegundos: Value(ordem.tempoEstimadoSegundos),
      observacoes: Value(ordem.observacoes),
      createdAt: ordem.metadata.createdAt,
      updatedAt: ordem.metadata.updatedAt,
      createdBy: ordem.metadata.createdBy,
      updatedBy: ordem.metadata.updatedBy,
      deletedAt: Value(ordem.metadata.deletedAt),
      syncStatus: ordem.metadata.syncStatus,
      lastSyncedAt: Value(ordem.metadata.lastSyncedAt),
    );

    await db.into(db.ordensPreparoTable).insertOnConflictUpdate(entry);
  }

  @override
  Future<void> delete(String id) async {
    final activeTenant = activeTenantId;
    final now = DateTime.now();
    await (db.update(db.ordensPreparoTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenant)))
        .write(OrdensPreparoTableCompanion(
          deletedAt: Value(now),
          syncStatus: Value(SyncStatus.pending),
          updatedAt: Value(now),
          status: Value(StatusOrdemPreparo.cancelado.name),
          canceladaEm: Value(now),
        ));
  }

  OrdemPreparo _mapToDomain(OrdemPreparoData data) {
    final List<dynamic> rawItens = jsonDecode(data.itensJson) as List<dynamic>;
    final List<ItemOrdemPreparo> itens = rawItens
        .map((x) => ItemOrdemPreparo.fromJson(x as Map<String, dynamic>))
        .toList();

    return OrdemPreparo(
      id: data.id,
      tenantId: data.tenantId,
      pedidoId: data.pedidoId,
      itens: itens,
      status: StatusOrdemPreparo.values.firstWhere(
          (e) => e.name == data.status,
          orElse: () => StatusOrdemPreparo.pendente),
      prioridade: PrioridadeOrdem.values.firstWhere(
          (e) => e.name == data.prioridade,
          orElse: () => PrioridadeOrdem.normal),
      operadorId: data.operadorId,
      criadaEm: data.criadaEm,
      iniciadaEm: data.iniciadaEm,
      concluidaEm: data.concluidaEm,
      canceladaEm: data.canceladaEm,
      tempoEstimadoSegundos: data.tempoEstimadoSegundos,
      observacoes: data.observacoes,
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

  Future<List<HistoricoOrdemPreparo>> findHistoricoByOrdemId(String ordemId) async {
    final activeTenant = activeTenantId;
    final rows = await (db.select(db.historicosOrdemPreparoTable)
          ..where((t) => t.ordemPreparoId.equals(ordemId) & t.tenantId.equals(activeTenant))
          ..orderBy([(t) => OrderingTerm(expression: t.criadaEm, mode: OrderingMode.asc)]))
        .get();

    return rows.map((row) => HistoricoOrdemPreparo(
          id: row.id,
          tenantId: row.tenantId,
          ordemPreparoId: row.ordemPreparoId,
          titulo: row.titulo,
          descricao: row.descricao,
          operadorNome: row.operadorNome,
          criadaEm: row.criadaEm,
          versao: row.versao,
          metadata: SyncMetadata(
            version: row.syncVersion,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            createdBy: row.createdBy,
            updatedBy: row.updatedBy,
            deletedAt: row.deletedAt,
            syncStatus: row.syncStatus,
            lastSyncedAt: row.lastSyncedAt,
          ),
        )).toList();
  }

  Future<void> registrarHistorico(String ordemId, String titulo, String descricao, {String? operadorNome}) async {
    final activeTenant = activeTenantId;
    final now = DateTime.now().toUtc();
    final id = const Uuid().v4();

    final entry = HistoricosOrdemPreparoTableCompanion.insert(
      id: id,
      tenantId: activeTenant,
      ordemPreparoId: ordemId,
      titulo: titulo,
      descricao: descricao,
      operadorNome: Value(operadorNome ?? 'Operador'),
      criadaEm: now,
      createdAt: now,
      updatedAt: now,
      createdBy: activeTenant,
      updatedBy: activeTenant,
      syncStatus: SyncStatus.pending,
    );

    await db.into(db.historicosOrdemPreparoTable).insertOnConflictUpdate(entry);
  }
}
