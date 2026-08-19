import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor createDatabaseConnection(String path, {bool inMemory = false}) {
  if (inMemory) {
    return WebDatabase.withStorage(DriftWebStorage.volatile());
  }
  return WebDatabase.withStorage(DriftWebStorage.indexedDb('fincore_v3'));
}

bool checkDatabaseExists(String path) {
  return false;
}

void deleteDatabaseFile(String path) {
  // On web, we let the browser manage storage or do a no-op
}
