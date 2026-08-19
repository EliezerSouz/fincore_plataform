import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';

@DataClassName('TaxaEntregaData')
@TableIndex(name: 'taxa_ent_tenant_idx', columns: {#tenantId})
class TaxasEntregaTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  TextColumn get nome => text()();
  TextColumn get tipoRegra => text()(); // Mapeado como String do Enum
  TextColumn get bairro => text().nullable()();
  TextColumn get cepInicial => text().nullable()();
  TextColumn get cepFinal => text().nullable()();
  IntColumn get valorCentavos => integer()();
  BoolColumn get ativo => boolean()();
  IntColumn get pedidoMinimoCentavos => integer().nullable().withDefault(const Constant(0))();
  TextColumn get prazoEstimado => text().nullable()();
  TextColumn get observacoes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
