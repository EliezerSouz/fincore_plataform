import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
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

  /// Busca um cliente pelo telefone (compara telefones normalizados).
  Future<Cliente?> findByTelefone(String rawTelefone, {String? excludeId}) async {
    final telNorm = normalizarTelefone(rawTelefone);
    if (telNorm.isEmpty || telNorm == '0000000000' || telNorm == '00000000000') {
      return null;
    }

    final rows = await (db.select(db.clientesTable)
          ..where((t) => t.tenantId.equals(activeTenantId) & t.deletedAt.isNull()))
        .get();

    for (final r in rows) {
      if (excludeId != null && r.id == excludeId) continue;
      if (normalizarTelefone(r.telefone) == telNorm) {
        return _mapToDomain(r);
      }
    }
    return null;
  }

  @override
  Future<List<Cliente>> findAll() async {
    final rows = await (db.select(db.clientesTable)
          ..where((t) => t.tenantId.equals(activeTenantId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.nome.lower(), mode: OrderingMode.asc)]))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  Future<List<Cliente>> search(String query) async {
    if (query.trim().isEmpty) return findAll();
    final q = '%${query.trim().toLowerCase()}%';
    final qNormTel = normalizarTelefone(query);

    final rows = await (db.select(db.clientesTable)
          ..where((t) =>
              t.tenantId.equals(activeTenantId) &
              t.deletedAt.isNull() &
              (t.nome.lower().like(q) |
               t.apelido.lower().like(q) |
               t.telefone.like(q) |
               t.documento.like(q) |
               t.email.lower().like(q)))
          ..orderBy([(t) => OrderingTerm(expression: t.nome.lower(), mode: OrderingMode.asc)]))
        .get();

    final results = rows.map(_mapToDomain).toList();

    // Se a busca for numérica/telefone e não encontrou exato por like, filtra pela normalização
    if (qNormTel.isNotEmpty && qNormTel.length >= 4) {
      final all = await findAll();
      for (final c in all) {
        if (!results.any((r) => r.id == c.id)) {
          if (c.telefoneNormalizado.contains(qNormTel)) {
            results.add(c);
          }
        }
      }
      results.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    }

    return results;
  }

  @override
  Future<void> saveLocal(Cliente cliente) async {
    if (cliente.tenantId != activeTenantId) {
      throw StateError('Violação de Tenancy ao salvar Cliente');
    }
    final telSalvar = cliente.telefone.trim().isNotEmpty
        ? (normalizarTelefone(cliente.telefone).isNotEmpty ? normalizarTelefone(cliente.telefone) : cliente.telefone.trim())
        : cliente.telefone.trim();

    await db.into(db.clientesTable).insertOnConflictUpdate(
          ClientesTableCompanion.insert(
            id: cliente.id,
            tenantId: activeTenantId,
            nome: cliente.nome,
            telefone: telSalvar,
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
            syncStatus: cliente.metadata.syncStatus,
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

  /// Retorna a quantidade de pedidos vinculados ao cliente no banco de dados local.
  Future<int> countPedidosByClienteId(String clienteId) async {
    final count = await (db.selectOnly(db.pedidosTable)
          ..addColumns([db.pedidosTable.id.count()])
          ..where(db.pedidosTable.tenantId.equals(activeTenantId) &
                  db.pedidosTable.clienteId.equals(clienteId)))
        .map((row) => row.read(db.pedidosTable.id.count()) ?? 0)
        .getSingle();
    return count;
  }

  /// Garante a existência do cliente 'Consumidor Final' para um tenant específico.
  /// Se não existir, cria o registro local e enfileira no Outbox para sincronização ao Supabase.
  Future<Cliente> ensureConsumidorFinalForTenant(String tenantId) async {
    final rows = await (db.select(db.clientesTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull() &
              (t.nome.like('%Consumidor Final%') | t.telefone.equals('00000000000'))))
        .get();

    if (rows.isNotEmpty) {
      return _mapToDomain(rows.first);
    }

    final now = DateTime.now().toUtc();
    final id = tenantId == '00000000-0000-4000-a000-000000000001'
        ? '00000000-0000-4000-a000-000000000301'
        : const Uuid().v4();

    final consumidor = Cliente(
      id: id,
      tenantId: tenantId,
      nome: 'Consumidor Final',
      telefone: '00000000000',
      email: 'consumidor@fincore.com',
      documento: '000.000.000-00',
      observacoes: 'Consumidor final genérico (imutável)',
      ativo: true,
      metadata: SyncMetadata(
        version: 1,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
        updatedBy: 'system',
        syncStatus: SyncStatus.pending,
      ),
    );

    await saveLocal(consumidor);
    await outbox.enqueue(
      entity: entityName,
      entityId: id,
      action: 'create',
      payload: toOutboxPayload(consumidor),
      version: 1,
    );

    return consumidor;
  }

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
