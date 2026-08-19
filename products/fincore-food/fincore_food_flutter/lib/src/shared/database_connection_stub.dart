import 'package:drift/drift.dart';

QueryExecutor createDatabaseConnection(String path, {bool inMemory = false}) {
  throw UnsupportedError('Cannot create database connection on this platform.');
}

bool checkDatabaseExists(String path) {
  return false;
}

void deleteDatabaseFile(String path) {
  throw UnsupportedError('Cannot delete database file on this platform.');
}
