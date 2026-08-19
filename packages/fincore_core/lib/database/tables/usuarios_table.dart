import 'package:drift/drift.dart';
import 'empresas_table.dart';

@DataClassName('UsuarioData')
@TableIndex(name: 'usr_tenant_username_idx', columns: {#tenantId, #username}, unique: true)
class UsuariosTable extends Table {
  TextColumn get id => text()(); // UUID (PK)
  TextColumn get tenantId => text().nullable().references(
        EmpresasTable,
        #id,
        onDelete: KeyAction.setNull,
        onUpdate: KeyAction.cascade,
      )();
  TextColumn get authUserId => text().nullable()(); // Supabase Auth UID
  TextColumn get username => text()(); // Login de acesso por tenant (admin, caixa, etc.)
  TextColumn get email => text().nullable()(); // Email opcional (comunicação/recuperação)
  TextColumn get nome => text()();
  TextColumn get avatarUrl => text().nullable()();
  BoolColumn get ativo => boolean().withDefault(const Constant(true))();

  // Metadados
  DateTimeColumn get criadoEm => dateTime()();
  DateTimeColumn get atualizadoEm => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
