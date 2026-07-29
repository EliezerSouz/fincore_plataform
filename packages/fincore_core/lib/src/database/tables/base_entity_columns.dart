import 'package:drift/drift.dart';
import '../../../common/domain_primitives.dart';
import '../../../database/tables/empresas_table.dart';

mixin IdentityColumns on Table {
  TextColumn get id => text()(); // UUID
  TextColumn get tenantId => text().references(EmpresasTable, #id, onDelete: KeyAction.restrict)();
}

mixin AuditColumns on Table {
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get createdBy => text()(); // UUID do usuário criador
  TextColumn get updatedBy => text()(); // UUID do usuário alterador
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deletedBy => text().nullable()(); // UUID do usuário removedor
}

mixin SyncColumns on Table {
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();
  TextColumn get originDeviceId => text().nullable()();
  TextColumn get lastModifiedByDevice => text().nullable()();
  TextColumn get entityHash => text().nullable()();
}
