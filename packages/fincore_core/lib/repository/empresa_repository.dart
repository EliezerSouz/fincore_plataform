import 'package:drift/drift.dart';
import '../common/core_models.dart';
import '../common/domain_primitives.dart';
import '../context/tenant_context.dart';
import '../database/fincore_database.dart';
import 'base_repository.dart';

class EmpresaRepository extends BaseRepository<CoreEmpresa, String> {
  final FincoreDatabase db;

  EmpresaRepository({required this.db, required TenantContext context})
      : super(context);

  @override
  Future<CoreEmpresa?> findById(String id) async {
    final activeTenant = context.hasContext ? activeTenantId : id;
    if (id != activeTenant) {
      // Bloqueia tentativas de leitura de outros tenants
      return null;
    }

    final row = await (db.select(db.empresasTable)
          ..where((t) => t.id.equals(activeTenant)))
        .getSingleOrNull();

    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<List<CoreEmpresa>> findAll() async {
    final activeTenant = context.hasContext ? activeTenantId : null;
    if (activeTenant == null) {
      final rows = await db.select(db.empresasTable).get();
      return rows.map(_mapToDomain).toList();
    }
    final rows = await (db.select(db.empresasTable)
          ..where((t) => t.id.equals(activeTenant)))
        .get();

    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<void> save(CoreEmpresa empresa) async {
    final activeTenant = context.hasContext ? activeTenantId : empresa.id;
    if (empresa.id != activeTenant) {
      throw StateError(
          'Violação de Tenancy: Não é permitido salvar uma Empresa com ID (${empresa.id}) diferente do Tenant ativo ($activeTenant).');
    }

    final entry = EmpresasTableCompanion.insert(
      id: empresa.id,
      razaoSocial: empresa.razaoSocial,
      nomeFantasia: empresa.nomeFantasia,
      documentoFiscal: empresa.documentoFiscal,
      email: empresa.email,
      telefone: empresa.telefone,
      status: empresa.status.name,
      plano: empresa.plano.name,
      timezone: empresa.timezone,
      locale: empresa.locale,
      currency: empresa.currency,
      country: empresa.country,
      createdFrom: empresa.createdFrom,
      segmento: Value(empresa.segmento),
      syncVersion: Value(empresa.metadata.version),
      createdAt: empresa.metadata.createdAt,
      updatedAt: empresa.metadata.updatedAt,
      createdBy: empresa.metadata.createdBy,
      updatedBy: empresa.metadata.updatedBy,
      deletedAt: Value(empresa.metadata.deletedAt),
      syncStatus: empresa.metadata.syncStatus,
      lastSyncedAt: Value(empresa.metadata.lastSyncedAt),
    );

    await db.into(db.empresasTable).insertOnConflictUpdate(entry);
  }

  @override
  Future<void> delete(String id) async {
    final activeTenant = context.hasContext ? activeTenantId : id;
    if (id != activeTenant) return;

    await (db.delete(db.empresasTable)..where((t) => t.id.equals(activeTenant))).go();
  }

  CoreEmpresa _mapToDomain(EmpresaData data) {
    return CoreEmpresa(
      id: data.id,
      razaoSocial: data.razaoSocial,
      nomeFantasia: data.nomeFantasia,
      documentoFiscal: data.documentoFiscal,
      email: data.email,
      telefone: data.telefone,
      status: StatusEmpresa.values.firstWhere((e) => e.name == data.status,
          orElse: () => StatusEmpresa.ativo),
      plano: PlanoEmpresa.values.firstWhere((e) => e.name == data.plano,
          orElse: () => PlanoEmpresa.bronze),
      timezone: data.timezone,
      locale: data.locale,
      currency: data.currency,
      country: data.country,
      createdFrom: data.createdFrom,
      segmento: data.segmento,
      version: data.syncVersion,
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
