import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';
import 'empresas_table.dart';

@DataClassName('EmpresaConviteData')
@TableIndex(name: 'convite_tenant_idx', columns: {#tenantId})
class EmpresaConvitesTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  @override
  TextColumn get tenantId => text().references(
        EmpresasTable,
        #id,
        onDelete: KeyAction.restrict,
        onUpdate: KeyAction.cascade,
      )();
  TextColumn get email => text()();
  TextColumn get role => text().withDefault(const Constant('OPERADOR'))(); // ADMIN | GESTOR | OPERADOR | VIEWER
  TextColumn get status => text().withDefault(const Constant('PENDENTE'))(); // PENDENTE | ACEITO | CANCELADO | EXPIRADO
  DateTimeColumn get expiracaoEm => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
