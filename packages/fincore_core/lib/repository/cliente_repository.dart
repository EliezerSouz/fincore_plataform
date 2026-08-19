import 'package:drift/drift.dart';
import '../common/master_data_models.dart';
import '../common/domain_primitives.dart';
import '../context/tenant_context.dart';
import '../database/fincore_database.dart';
import '../sync/outbox_service.dart';
import '../sync/syncable_repository.dart';
import '../sync/sync_engine.dart';

class ClienteRepository extends SyncableRepository<Cliente> {
  ClienteRepository({
    required super.db,
    required super.context,
    required super.outbox,
    super.syncEngine,
  });

  @override
  String get entityName => 'clientes';

  @override
  String extractId(Cliente entity) => entity.id;

  @override
  int extractVersion(Cliente entity) => entity.metadata.version;

  @override
  Map<String, dynamic> toOutboxPayload(Cliente entity) => {
        'id': entity.id,
        'tenantId': entity.tenantId,
        'nome': entity.nome,
        'telefone': entity.telefone,
        'email': entity.email,
        'documento': entity.documento,
        'observacoes': entity.observacoes,
        'ativo': entity.ativo,
        'aceitaWhatsapp': entity.aceitaWhatsapp,
        'aceitaMarketing': entity.aceitaMarketing,
        'apelido': entity.apelido,
        'dataNascimento': entity.dataNascimento?.toIso8601String(),
        'preferenciaEntrega': entity.preferenciaEntrega,
        'limiteCredito': entity.limiteCredito,
        'syncVersion': entity.metadata.version,
        'createdAt': entity.metadata.createdAt.toIso8601String(),
        'updatedAt': entity.metadata.updatedAt.toIso8601String(),
        'createdBy': entity.metadata.createdBy,
        'updatedBy': entity.metadata.updatedBy,
      };

  @override
  Future<Cliente?> findById(String id) async {
    final row = await (db.select(db.clientesTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .getSingleOrNull();
    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<List<Cliente>> findAll() async {
    final rows = await (db.select(db.clientesTable)
          ..where((t) => t.tenantId.equals(activeTenantId) & t.deletedAt.isNull()))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  Future<List<Cliente>> search(String query) async {
    if (query.trim().isEmpty) return findAll();
    final q = '%${query.trim().toLowerCase()}%';
    final rows = await (db.select(db.clientesTable)
          ..where((t) =>
              t.tenantId.equals(activeTenantId) &
              t.deletedAt.isNull() &
              (t.nome.lower().like(q) |
               t.apelido.lower().like(q) |
               t.telefone.like(q) |
               t.documento.like(q) |
               t.email.lower().like(q))))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<void> saveLocal(Cliente cliente) async {
    if (cliente.tenantId != activeTenantId) {
      throw StateError('Violação de Tenancy ao salvar Cliente');
    }
    await db.into(db.clientesTable).insertOnConflictUpdate(
          ClientesTableCompanion.insert(
            id: cliente.id,
            tenantId: activeTenantId,
            nome: cliente.nome,
            telefone: cliente.telefone,
            email: Value(cliente.email),
            documento: Value(cliente.documento),
            observacoes: cliente.observacoes,
            ativo: cliente.ativo,
            aceitaWhatsapp: Value(cliente.aceitaWhatsapp),
            aceitaMarketing: Value(cliente.aceitaMarketing),
            apelido: Value(cliente.apelido),
            dataNascimento: Value(cliente.dataNascimento),
            preferenciaEntrega: Value(cliente.preferenciaEntrega),
            limiteCredito: Value(cliente.limiteCredito),
            createdAt: cliente.metadata.createdAt,
            updatedAt: DateTime.now().toUtc(),
            createdBy: cliente.metadata.createdBy,
            updatedBy: cliente.metadata.updatedBy,
            deletedAt: Value(cliente.metadata.deletedAt),
            syncStatus: SyncStatus.pending,
            lastSyncedAt: Value(cliente.metadata.lastSyncedAt),
          ),
        );
  }

  @override
  Future<void> deleteLocal(String id, Cliente entity) async {
    final now = DateTime.now().toUtc();
    await (db.update(db.clientesTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .write(ClientesTableCompanion(
      deletedAt: Value(now),
      syncStatus: const Value(SyncStatus.pending),
      updatedAt: Value(now),
    ));
  }

  Future<Cliente> save(Cliente cliente) => saveWithSync(cliente);
  Future<void> delete(String id) => deleteWithSync(id);

  Cliente _mapToDomain(ClienteData data) {
    return Cliente(
      id: data.id,
      tenantId: data.tenantId,
      nome: data.nome,
      telefone: data.telefone,
      email: data.email,
      documento: data.documento,
      observacoes: data.observacoes,
      ativo: data.ativo,
      aceitaWhatsapp: data.aceitaWhatsapp,
      aceitaMarketing: data.aceitaMarketing,
      apelido: data.apelido,
      dataNascimento: data.dataNascimento,
      preferenciaEntrega: data.preferenciaEntrega,
      limiteCredito: data.limiteCredito,
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
