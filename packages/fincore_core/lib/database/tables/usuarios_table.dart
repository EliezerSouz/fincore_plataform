import 'package:drift/drift.dart';

@DataClassName('UsuarioData')
class UsuariosTable extends Table {
  TextColumn get id => text()(); // Supabase UID (PK)
  TextColumn get email => text().unique()();
  TextColumn get nome => text()();
  TextColumn get avatarUrl => text().nullable()();

  // Metadados
  DateTimeColumn get criadoEm => dateTime()();
  DateTimeColumn get atualizadoEm => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
