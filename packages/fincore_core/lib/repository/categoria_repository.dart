import 'package:drift/drift.dart';
import '../common/master_data_models.dart';
import '../common/domain_exceptions.dart';
import '../common/domain_primitives.dart';
import '../context/tenant_context.dart';
import '../database/fincore_database.dart';
import '../sync/outbox_service.dart';
import '../sync/syncable_repository.dart';
import '../sync/sync_engine.dart';

class CategoriaRepository extends SyncableRepository<Categoria> {
  CategoriaRepository({
    required super.db,
    required super.context,
    required super.outbox,
    super.syncEngine,
  });

  @override
  String get entityName => 'categorias';

  @override
  String extractId(Categoria entity) => entity.id;

  @override
  int extractVersion(Categoria entity) => entity.metadata.version;

  @override
  Map<String, dynamic> toOutboxPayload(Categoria entity) => {
        'id': entity.id,
        'tenantId': entity.tenantId,
        'parentId': entity.parentId,
        'nome': entity.nome,
        'descricao': entity.descricao,
        'ordemExibicao': entity.ordemExibicao,
        'ativo': entity.ativo,
        'icone': entity.icone,
        'cor': entity.cor,
        'metadataPayload': entity.metadataPayload,
        'syncVersion': entity.metadata.version,
        'createdAt': entity.metadata.createdAt.toIso8601String(),
        'updatedAt': entity.metadata.updatedAt.toIso8601String(),
        'createdBy': entity.metadata.createdBy,
        'updatedBy': entity.metadata.updatedBy,
      };

  @override
  Future<Categoria?> findById(String id) async {
    final row = await (db.select(db.categoriasTable)
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
  Future<List<Categoria>> findAll() async {
    final rows = await (db.select(db.categoriasTable)
          ..where(
            (t) =>
                t.tenantId.equals(activeTenantId) & t.deletedAt.isNull(),
          ))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  /// Retorna as subcategorias vinculadas ao [parentId] informado,
  /// ou as categorias-raiz se [parentId] for nulo.
  Future<List<Categoria>> findByParentId(String? parentId) async {
    final rows = await (db.select(db.categoriasTable)
          ..where(
            (t) =>
                t.tenantId.equals(activeTenantId) &
                t.deletedAt.isNull() &
                (parentId == null
                    ? t.parentId.isNull()
                    : t.parentId.equals(parentId)),
          ))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<void> saveLocal(Categoria categoria) async {
    if (categoria.tenantId != activeTenantId) {
      throw StateError('Violação de Tenancy ao salvar Categoria');
    }
    await db.into(db.categoriasTable).insertOnConflictUpdate(
          CategoriasTableCompanion.insert(
            id: categoria.id,
            tenantId: activeTenantId,
            parentId: Value(categoria.parentId),
            nome: categoria.nome,
            descricao: categoria.descricao,
            ordemExibicao: categoria.ordemExibicao,
            ativo: categoria.ativo,
            icone: Value(categoria.icone),
            cor: Value(categoria.cor),
            metadataPayload: Value(categoria.metadataPayload),
            createdAt: categoria.metadata.createdAt,
            updatedAt: DateTime.now().toUtc(),
            createdBy: categoria.metadata.createdBy,
            updatedBy: categoria.metadata.updatedBy,
            deletedAt: Value(categoria.metadata.deletedAt),
            syncStatus: SyncStatus.pending,
            syncVersion: Value(categoria.metadata.version),
            lastSyncedAt: Value(categoria.metadata.lastSyncedAt),
          ),
        );
  }

  @override
  Future<void> deleteLocal(String id, Categoria entity) async {
    final now = DateTime.now().toUtc();
    await (db.update(db.categoriasTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .write(CategoriasTableCompanion(
      deletedAt: Value(now),
      syncStatus: const Value(SyncStatus.pending),
      updatedAt: Value(now),
    ));
  }

  /// Verifica se já existe outra categoria ativa (não excluída) com o mesmo
  /// nome normalizado no tenant corrente.
  Future<bool> existeNomeDuplicado(String nome, {String? ignorarId}) async {
    final alvo = normalizarNomeCadastro(nome);
    final todas = await findAll();
    return todas.any((c) => c.id != ignorarId && normalizarNomeCadastro(c.nome) == alvo);
  }

  Future<Categoria> save(Categoria categoria) async {
    if (await existeNomeDuplicado(categoria.nome, ignorarId: categoria.id)) {
      throw NomeDuplicadoException(entidade: 'uma categoria', nome: categoria.nome.trim());
    }
    return saveWithSync(categoria);
  }
  Future<void> delete(String id) => deleteWithSync(id);

  Categoria _mapToDomain(CategoriaData data) {
    return Categoria(
      id: data.id,
      tenantId: data.tenantId,
      parentId: data.parentId,
      nome: data.nome,
      descricao: data.descricao,
      ordemExibicao: data.ordemExibicao,
      ativo: data.ativo,
      icone: data.icone,
      cor: data.cor,
      metadataPayload: data.metadataPayload,
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
