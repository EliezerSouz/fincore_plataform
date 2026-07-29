import 'package:drift/drift.dart';

@DataClassName('EventoEmpresaData')
class EventosEmpresaTable extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get tenantId => text()();
  TextColumn get tipo => text()(); // CRIADA | ATIVADA | SUSPENSA | CANCELADA
  TextColumn get payload => text().nullable()(); // JSON
  TextColumn get geradoPor => text()(); // usuarioId ou 'SYSTEM'
  DateTimeColumn get ocorridoEm => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
