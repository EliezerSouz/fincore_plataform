import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';

@DataClassName('FormaPagamentoData')
@TableIndex(name: 'forma_pag_tenant_idx', columns: {#tenantId})
class FormasPagamentoTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  TextColumn get nome => text()();
  TextColumn get tipo => text()(); // Mapeado como String do Enum
  IntColumn get ordem => integer()();
  BoolColumn get ativo => boolean()();
  BoolColumn get permiteTroco => boolean()();
  BoolColumn get isUsoInterno => boolean().withDefault(const Constant(false))();
  BoolColumn get movimentaFinanceiro => boolean().withDefault(const Constant(true))();
  BoolColumn get movimentaEstoque => boolean().withDefault(const Constant(true))();
  TextColumn get bandeiraPadrao => text().nullable()();
  TextColumn get descricao => text().nullable()();
  TextColumn get pixChave => text().nullable()();
  TextColumn get pixTipoChave => text().nullable()();
  TextColumn get pixTipoBanco => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
