import 'package:drift/drift.dart';
import '../common/master_data_models.dart';
import '../common/domain_exceptions.dart';
import '../common/domain_primitives.dart';
import '../context/tenant_context.dart';
import '../database/fincore_database.dart';
import '../sync/outbox_service.dart';
import '../sync/syncable_repository.dart';
import '../sync/sync_engine.dart';

class ProdutoRepository extends SyncableRepository<Produto> {
  ProdutoRepository({
    required super.db,
    required super.context,
    required super.outbox,
    super.syncEngine,
  });

  @override
  String get entityName => 'produtos';

  @override
  String extractId(Produto entity) => entity.id;

  @override
  int extractVersion(Produto entity) => entity.metadata.version;

  @override
  Map<String, dynamic> toOutboxPayload(Produto entity) => {
        'id': entity.id,
        'tenantId': entity.tenantId,
        'codigo': entity.codigo,
        'nome': entity.nome,
        'descricao': entity.descricao,
        'categoriaId': entity.categoriaId,
        'unidadeVenda': entity.unidadeVenda.name,
        'statusComercial': entity.statusComercial.name,
        'tempoMedioMinutos': entity.tempoMedioMinutos,
        'controlaEstoque': entity.controlaEstoque,
        'ordemProducao': entity.ordemProducao,
        'ativo': entity.ativo,
        'sku': entity.sku,
        'codigoBarras': entity.codigoBarras,
        'imagem': entity.imagem,
        'corEtiqueta': entity.corEtiqueta,
        'metadata': entity.metadataPayload,
        'syncVersion': entity.metadata.version,
        'createdAt': entity.metadata.createdAt.toIso8601String(),
        'updatedAt': entity.metadata.updatedAt.toIso8601String(),
        'createdBy': entity.metadata.createdBy,
        'updatedBy': entity.metadata.updatedBy,
      };

  @override
  Future<Produto?> findById(String id) async {
    final row = await (db.select(db.produtosTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId) & t.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) return null;
    return _mapToDomain(row);
  }

  @override
  Future<List<Produto>> findAll() async {
    final rows = await (db.select(db.produtosTable)
          ..where((t) => t.tenantId.equals(activeTenantId) & t.deletedAt.isNull()))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  Future<List<Produto>> findAtivos() async {
    final rows = await (db.select(db.produtosTable)
          ..where((t) => t.tenantId.equals(activeTenantId) & t.ativo.equals(true) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.ordemProducao)]))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  Future<List<Produto>> findByCategoria(String categoriaId) async {
    final rows = await (db.select(db.produtosTable)
          ..where((t) =>
              t.tenantId.equals(activeTenantId) &
              t.categoriaId.equals(categoriaId) &
              t.deletedAt.isNull()))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<void> saveLocal(Produto produto) async {
    if (produto.tenantId != activeTenantId) {
      throw StateError('Violação de Tenancy ao salvar Produto');
    }
    await db.into(db.produtosTable).insertOnConflictUpdate(
          ProdutosTableCompanion.insert(
            id: produto.id,
            tenantId: activeTenantId,
            codigo: Value(produto.codigo),
            nome: produto.nome,
            descricao: Value(produto.descricao),
            categoriaId: produto.categoriaId,
            unidadeVenda: produto.unidadeVenda.name,
            statusComercial: produto.statusComercial.name,
            tempoMedioMinutos: produto.tempoMedioMinutos,
            controlaEstoque: produto.controlaEstoque,
            ordemProducao: produto.ordemProducao,
            ativo: produto.ativo,
            sku: Value(produto.sku),
            codigoBarras: Value(produto.codigoBarras),
            imagem: Value(produto.imagem),
            corEtiqueta: Value(produto.corEtiqueta),
            metadata: Value(produto.metadataPayload),
            createdAt: produto.metadata.createdAt,
            updatedAt: DateTime.now().toUtc(),
            createdBy: produto.metadata.createdBy,
            updatedBy: produto.metadata.updatedBy,
            deletedAt: Value(produto.metadata.deletedAt),
            syncStatus: SyncStatus.pending,
            lastSyncedAt: Value(produto.metadata.lastSyncedAt),
          ),
        );
  }

  @override
  Future<void> deleteLocal(String id, Produto entity) async {
    final now = DateTime.now().toUtc();
    await (db.update(db.produtosTable)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(activeTenantId)))
        .write(ProdutosTableCompanion(
      deletedAt: Value(now),
      syncStatus: const Value(SyncStatus.pending),
      updatedAt: Value(now),
    ));
  }

  /// Verifica se já existe outro produto (não excluído) com o mesmo nome
  /// normalizado na mesma categoria do tenant corrente.
  Future<bool> existeNomeDuplicado(String nome, String? categoriaId, {String? ignorarId}) async {
    final alvo = normalizarNomeCadastro(nome);
    final todos = await findAll();
    return todos.any((p) =>
        p.id != ignorarId &&
        p.categoriaId == categoriaId &&
        normalizarNomeCadastro(p.nome) == alvo);
  }

  Future<Produto> save(Produto produto) async {
    if (await existeNomeDuplicado(produto.nome, produto.categoriaId, ignorarId: produto.id)) {
      throw NomeDuplicadoException(entidade: 'um produto nesta categoria', nome: produto.nome.trim());
    }
    return saveWithSync(produto);
  }
  Future<void> delete(String id) => deleteWithSync(id);

  Produto _mapToDomain(ProdutoData data) {
    return Produto(
      id: data.id,
      tenantId: data.tenantId,
      codigo: data.codigo,
      nome: data.nome,
      descricao: data.descricao,
      categoriaId: data.categoriaId,
      unidadeVenda: UnidadeVenda.values.firstWhere(
          (e) => e.name == data.unidadeVenda,
          orElse: () => UnidadeVenda.un),
      statusComercial: ProductStatus.values.firstWhere(
          (e) => e.name == data.statusComercial,
          orElse: () => ProductStatus.disponivel),
      tempoMedioMinutos: data.tempoMedioMinutos,
      controlaEstoque: data.controlaEstoque,
      ordemProducao: data.ordemProducao,
      ativo: data.ativo,
      sku: data.sku,
      codigoBarras: data.codigoBarras,
      imagem: data.imagem,
      corEtiqueta: data.corEtiqueta,
      metadataPayload: data.metadata,
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
