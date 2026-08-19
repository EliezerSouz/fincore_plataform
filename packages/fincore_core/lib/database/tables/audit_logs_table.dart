import 'package:drift/drift.dart';

@DataClassName('AuditLogEntry')
class AuditLogsTable extends Table {
  TextColumn get id => text()();
  TextColumn get targetEntity => text().named('entity_name')();
  TextColumn get entityId => text()();
  TextColumn get tenantId => text()(); // UUID da empresa do log
  TextColumn get userId => text()();
  TextColumn get action => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get diff => text().nullable()();
  TextColumn get deviceInfo => text().nullable()();
  TextColumn get origin => text().nullable()();
  TextColumn get reason => text().nullable()();
  IntColumn get syncVersion => integer().nullable()();

  // Campos de contexto histórico forense desnormalizados
  TextColumn get userName => text().nullable()();
  TextColumn get userRole => text().nullable()();
  TextColumn get machineName => text().nullable()();
  TextColumn get hostName => text().nullable()();
  TextColumn get ipAddress => text().nullable()();
  TextColumn get macAddress => text().nullable()();
  TextColumn get platform => text().nullable()();
  TextColumn get osVersion => text().nullable()();
  TextColumn get appVersion => text().nullable()();
  TextColumn get sessionId => text().nullable()();
  TextColumn get browser => text().nullable()();
  TextColumn get deviceDescription => text().nullable()();
  TextColumn get entityDisplayName => text().nullable()();
  TextColumn get entityModule => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
