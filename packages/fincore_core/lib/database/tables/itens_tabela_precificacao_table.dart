import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';
import 'tabelas_precificacao_table.dart';

@DataClassName('ItemTabelaPrecificacaoData')
@TableIndex(name: 'item_tabela_prec_idx', columns: {#tenantId, #tabelaPrecificacaoId})
class ItensTabelaPrecificacaoTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  TextColumn get tabelaPrecificacaoId => text().references(
        TabelasPrecificacaoTable,
        #id,
        onDelete: KeyAction.restrict,
        onUpdate: KeyAction.cascade,
      )();
  IntColumn get quantidadeMinima => integer()();
  IntColumn get quantidadeMaxima => integer().nullable()();
  IntColumn get valorUnitarioCentavos => integer()();
  IntColumn get ordem => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
