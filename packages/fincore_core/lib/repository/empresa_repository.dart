import 'package:drift/drift.dart';
import '../common/core_models.dart';
import '../common/domain_primitives.dart';
import '../context/tenant_context.dart';
import '../database/fincore_database.dart';
import '../sync/outbox_service.dart';
import '../sync/syncable_repository.dart';
import '../sync/sync_engine.dart';

class EmpresaRepository extends SyncableRepository<CoreEmpresa> {
  EmpresaRepository({
    required super.db,
    required super.context,
    required super.outbox,
    super.syncEngine,
  });

  @override
  String get entityName => 'empresas';

  @override
  String extractId(CoreEmpresa entity) => entity.id;

  @override
  int extractVersion(CoreEmpresa entity) => entity.version;

  @override
  Map<String, dynamic> toOutboxPayload(CoreEmpresa entity) => {
        'id': entity.id,
        'razaoSocial': entity.razaoSocial,
        'nomeFantasia': entity.nomeFantasia,
        'documentoFiscal': entity.documentoFiscal,
        'email': entity.email,
        'telefone': entity.telefone,
        'status': entity.status.name,
        'plano': entity.plano.name,
        'timezone': entity.timezone,
        'locale': entity.locale,
        'currency': entity.currency,
        'country': entity.country,
        'createdFrom': entity.createdFrom,
        'segmento': entity.segmento,
        'tipoPessoa': entity.tipoPessoa,
        'inscricaoEstadual': entity.inscricaoEstadual,
        'inscricaoMunicipal': entity.inscricaoMunicipal,
        'regimeTributario': entity.regimeTributario,
        'cep': entity.cep,
        'logradouro': entity.logradouro,
        'numero': entity.numero,
        'complemento': entity.complemento,
        'bairro': entity.bairro,
        'cidade': entity.cidade,
        'estado': entity.estado,
        'syncVersion': entity.version,
        'createdAt': entity.metadata.createdAt.toIso8601String(),
        'updatedAt': entity.metadata.updatedAt.toIso8601String(),
        'createdBy': entity.metadata.createdBy,
        'updatedBy': entity.metadata.updatedBy,
      };

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

  Future<void> save(CoreEmpresa empresa) => saveWithSync(empresa);

  @override
  Future<void> saveLocal(CoreEmpresa empresa) async {
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
      vencimento: const Value.absent(),
      segmento: Value(empresa.segmento),
      syncVersion: Value(empresa.metadata.version + 1),
      tipoPessoa: Value(empresa.tipoPessoa),
      inscricaoEstadual: Value(empresa.inscricaoEstadual),
      inscricaoMunicipal: Value(empresa.inscricaoMunicipal),
      regimeTributario: Value(empresa.regimeTributario),
      cep: Value(empresa.cep),
      logradouro: Value(empresa.logradouro),
      numero: Value(empresa.numero),
      complemento: Value(empresa.complemento),
      bairro: Value(empresa.bairro),
      cidade: Value(empresa.cidade),
      estado: Value(empresa.estado),
      createdAt: empresa.metadata.createdAt,
      updatedAt: DateTime.now().toUtc(),
      createdBy: empresa.metadata.createdBy,
      updatedBy: empresa.metadata.updatedBy,
      deletedAt: Value(empresa.metadata.deletedAt),
      syncStatus: empresa.metadata.syncStatus,
      lastSyncedAt: Value(empresa.metadata.lastSyncedAt),
    );

    await db.into(db.empresasTable).insertOnConflictUpdate(entry);
  }

  Future<void> delete(String id) => deleteWithSync(id);

  @override
  Future<void> deleteLocal(String id, CoreEmpresa entity) async {
    await (db.delete(db.empresasTable)..where((t) => t.id.equals(id))).go();
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
      tipoPessoa: data.tipoPessoa,
      inscricaoEstadual: data.inscricaoEstadual,
      inscricaoMunicipal: data.inscricaoMunicipal,
      regimeTributario: data.regimeTributario,
      cep: data.cep,
      logradouro: data.logradouro,
      numero: data.numero,
      complemento: data.complemento,
      bairro: data.bairro,
      cidade: data.cidade,
      estado: data.estado,
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
