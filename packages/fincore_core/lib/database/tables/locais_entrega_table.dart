import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';
import 'clientes_table.dart';

@DataClassName('LocalEntregaData')
@TableIndex(name: 'local_entrega_cliente_idx', columns: {#tenantId, #clienteId})
class LocaisEntregaTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  TextColumn get clienteId => text().references(
        ClientesTable,
        #id,
        onDelete: KeyAction.restrict,
        onUpdate: KeyAction.cascade,
      )();
  TextColumn get nomeIdentificador => text()();
  TextColumn get logradouro => text()();
  TextColumn get numero => text()();
  TextColumn get bairro => text()();
  TextColumn get cidade => text()();
  TextColumn get cep => text()();
  TextColumn get referencia => text()();
  BoolColumn get ativo => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}
