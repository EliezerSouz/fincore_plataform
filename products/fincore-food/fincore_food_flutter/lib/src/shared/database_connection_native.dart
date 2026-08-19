import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

QueryExecutor createDatabaseConnection(String path, {bool inMemory = false}) {
  if (inMemory) {
    return NativeDatabase.memory();
  }
  return NativeDatabase(File(path));
}

bool checkDatabaseExists(String path) {
  return File(path).existsSync();
}

void deleteDatabaseFile(String path) {
  final file = File(path);
  if (file.existsSync()) {
    file.deleteSync();
  }
}
