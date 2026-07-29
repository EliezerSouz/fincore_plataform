import 'package:drift/drift.dart';
import '../../src/database/tables/base_entity_columns.dart';
import 'usuarios_table.dart';
import 'empresas_table.dart';

@DataClassName('MembroEmpresaData')
@TableIndex(name: 'membro_emp_usr_idx', columns: {#usuarioId})
class MembrosEmpresaTable extends Table with IdentityColumns, AuditColumns, SyncColumns {
  @override
  TextColumn get tenantId => text().references(
        EmpresasTable,
        #id,
        onDelete: KeyAction.restrict,
        onUpdate: KeyAction.cascade,
      )();
  TextColumn get usuarioId => text().references(
        UsuariosTable,
        #id,
        onDelete: KeyAction.restrict,
        onUpdate: KeyAction.cascade,
      )();
  TextColumn get role => text()(); // ADMIN | GESTOR | OPERADOR | VIEWER
  BoolColumn get ativo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get convidadoEm => dateTime()();
  DateTimeColumn get aceitoEm => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
