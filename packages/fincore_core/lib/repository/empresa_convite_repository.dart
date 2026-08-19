import 'package:drift/drift.dart';
import '../database/fincore_database.dart';
import '../common/core_models.dart';
import '../common/domain_primitives.dart';
import '../context/tenant_context.dart';
import 'base_repository.dart';

/// Repositório local de [CoreEmpresaConvite].
///
/// ## Direção de sincronização: ⬇️ Pull-only
/// Convites são criados exclusivamente pelo backend/admin via Supabase.
/// O cliente NUNCA deve fazer Push de convites para o Outbox.
///
/// O método [save] é chamado apenas pelo [SupabaseSyncService._applyRowLocally]
/// para persistir localmente os convites recebidos do Pull.
class EmpresaConviteRepository extends BaseRepository<CoreEmpresaConvite, String> {
  final FincoreDatabase db;

  EmpresaConviteRepository({required this.db, required TenantContext context})
      : super(context);

  @override
  Future<CoreEmpresaConvite?> findById(String id) async {
    final row = await (db.select(db.empresaConvitesTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .getSingleOrNull();

    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<List<CoreEmpresaConvite>> findAll() async {
    final rows = await (db.select(db.empresaConvitesTable)
          ..where((t) => t.tenantId.equals(activeTenantId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  /// Retorna apenas convites com status PENDENTE e não expirados.
  Future<List<CoreEmpresaConvite>> findPendentes() async {
    final agora = DateTime.now();
    final rows = await (db.select(db.empresaConvitesTable)
          ..where((t) =>
              t.tenantId.equals(activeTenantId) &
              t.status.equals('PENDENTE') &
              t.expiracaoEm.isBiggerThanValue(agora)))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  /// Persiste localmente um convite recebido do Supabase via Pull.
  ///
  /// Não envia para o Outbox — este método é chamado apenas pelo Sync.
  @override
  Future<void> save(CoreEmpresaConvite convite) async {
    if (convite.tenantId != activeTenantId) {
      throw StateError(
          'Violação de Tenancy: Não é permitido salvar um EmpresaConvite com tenantId (${convite.tenantId}) '
          'diferente do tenant ativo ($activeTenantId).');
    }

    final entry = EmpresaConvitesTableCompanion.insert(
      id: convite.id,
      tenantId: convite.tenantId,
      email: convite.email,
      role: Value(convite.role),
      status: Value(convite.status),
      expiracaoEm: convite.expiracaoEm,
      syncVersion: Value(convite.metadata.version),
      syncStatus: SyncStatus.synced,
      lastSyncedAt: Value(DateTime.now().toUtc()),
      createdAt: convite.metadata.createdAt,
      updatedAt: convite.metadata.updatedAt,
      createdBy: convite.metadata.createdBy,
      updatedBy: convite.metadata.updatedBy,
      deletedAt: Value(convite.metadata.deletedAt),
    );

    await db.into(db.empresaConvitesTable).insertOnConflictUpdate(entry);
  }

  @override
  Future<void> delete(String id) async {
    await (db.delete(db.empresaConvitesTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .go();
  }

  CoreEmpresaConvite _mapToDomain(EmpresaConviteData data) {
    return CoreEmpresaConvite(
      id: data.id,
      tenantId: data.tenantId,
      email: data.email,
      role: data.role,
      status: data.status,
      expiracaoEm: data.expiracaoEm,
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
