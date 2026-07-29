import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';

@DataClassName('CategoriaData')
@TableIndex(name: 'categoria_tenant_idx', columns: {#tenantId})
@TableIndex(name: 'categoria_parent_idx', columns: {#tenantId, #parentId})
@TableIndex(name: 'categoria_ordem_idx', columns: {#tenantId, #ordemExibicao})
class CategoriasTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  TextColumn get parentId => text().nullable().references(
        CategoriasTable,
        #id,
        onDelete: KeyAction.restrict,
        onUpdate: KeyAction.cascade,
      )();
  TextColumn get nome => text()();
  TextColumn get descricao => text()();
  IntColumn get ordemExibicao => integer()();
  BoolColumn get ativo => boolean()();

  // Novos campos de negócio
  TextColumn get icone => text().nullable()();
  TextColumn get cor => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
