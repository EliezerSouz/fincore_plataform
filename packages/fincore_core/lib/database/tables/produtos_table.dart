import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';
import 'categorias_table.dart';

@DataClassName('ProdutoData')
@TableIndex(name: 'produto_tenant_cat_idx', columns: {#tenantId, #categoriaId})
@TableIndex(name: 'produto_tenant_ativo_idx', columns: {#tenantId, #ativo})
@TableIndex(name: 'produto_tenant_cod_idx', columns: {#tenantId, #codigo})
class ProdutosTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  TextColumn get codigo => text().nullable()();
  TextColumn get nome => text()();
  TextColumn get descricao => text().nullable()();
  TextColumn get categoriaId => text().references(
        CategoriasTable,
        #id,
        onDelete: KeyAction.restrict,
        onUpdate: KeyAction.cascade,
      )();
  TextColumn get unidadeVenda => text()(); // Mapeado como String do Enum
  TextColumn get statusComercial => text()(); // Mapeado como String do Enum
  IntColumn get tempoMedioMinutos => integer()();
  BoolColumn get controlaEstoque => boolean()();
  IntColumn get ordemProducao => integer()();
  BoolColumn get ativo => boolean()();

  // Novos campos de negócio
  TextColumn get sku => text().nullable()();
  TextColumn get codigoBarras => text().nullable()();
  TextColumn get imagem => text().nullable()();
  TextColumn get corEtiqueta => text().nullable()();
  TextColumn get metadata => text().nullable()(); // JSON string para metadados flexíveis

  @override
  Set<Column> get primaryKey => {id};
}
