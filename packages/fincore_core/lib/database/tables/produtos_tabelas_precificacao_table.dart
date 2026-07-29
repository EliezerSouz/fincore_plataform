import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';
import 'produtos_table.dart';
import 'tabelas_precificacao_table.dart';

@DataClassName('ProdutoTabelaPrecificacaoData')
@TableIndex(name: 'prod_tabela_prec_compound_idx', columns: {#tenantId, #produtoId, #tabelaPrecificacaoId})
class ProdutosTabelasPrecificacaoTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  TextColumn get produtoId => text().references(
        ProdutosTable,
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
