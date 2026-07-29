import 'package:drift/drift.dart';

@DataClassName('AuditLogEntry')
class AuditLogsTable extends Table {
  TextColumn get id => text()();
  TextColumn get targetEntity => text().named('entity_name')();
  TextColumn get entityId => text()();
  TextColumn get userId => text()();
  TextColumn get action => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get diff => text().nullable()();
  TextColumn get deviceInfo => text().nullable()();
  TextColumn get origin => text().nullable()();
  TextColumn get reason => text().nullable()();
  IntColumn get syncVersion => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
