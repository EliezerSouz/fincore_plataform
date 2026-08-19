import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';
import 'categorias_table.dart';
import 'tabelas_precificacao_table.dart';

@DataClassName('CategoriaTabelaPrecificacaoData')
@TableIndex(name: 'cat_tabela_prec_compound_idx', columns: {#tenantId, #categoriaId, #tabelaPrecificacaoId})
class CategoriasTabelasPrecificacaoTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  TextColumn get categoriaId => text().references(
        CategoriasTable,
        #id,
        onDelete: KeyAction.restrict,
        onUpdate: KeyAction.cascade,
      )();
  TextColumn get tabelaPrecificacaoId => text().references(
        TabelasPrecificacaoTable,
        #id,
        onDelete: KeyAction.restrict,
        onUpdate: KeyAction.cascade,
      )();
  BoolColumn get ativo => boolean()();
  IntColumn get prioridade => integer()();
  DateTimeColumn get dataInicio => dateTime().nullable()();
  DateTimeColumn get dataFim => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
