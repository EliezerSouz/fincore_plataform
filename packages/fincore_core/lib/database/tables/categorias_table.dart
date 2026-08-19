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

  // Campos de negócio
  TextColumn get icone => text().nullable()();
  TextColumn get cor => text().nullable()();

  /// JSON com configurações operacionais herdáveis para produtos:
  /// preco_base, setor_impressao, tempo_medio, controla_estoque,
  /// estoque_minimo, estoque_maximo, ncm, cest, canais, estrategia_comercial, etc.
  TextColumn get metadataPayload => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
