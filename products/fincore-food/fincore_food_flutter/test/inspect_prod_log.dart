import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

void main() {
  final dbPath = 'F:/Eigent/fincore_platform/fincore_food/data/fincore_v3.db';
  if (!File(dbPath).existsSync()) {
    print('DB not found: $dbPath');
    return;
  }
  final db = sqlite3.open(dbPath);
  try {
    final rs = db.select('SELECT id, evento_id, idempotency_key, destinatario_mascarado, status, erro, criado_em FROM whatsapp_mensagens_log ORDER BY rowid DESC LIMIT 10');
    if (rs.isEmpty) {
      print('Tabela whatsapp_mensagens_log vazia.');
    }
    for (final row in rs) {
      print(row);
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    db.dispose();
  }
}
