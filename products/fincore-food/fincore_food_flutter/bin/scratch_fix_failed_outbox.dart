import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:path/path.dart' as p;

void main() async {
  final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\eliez';
  final dbPath = p.join(userProfile, 'Documents', 'fincore_v3.db');
  
  print('Abrindo banco local: $dbPath');
  if (!File(dbPath).existsSync()) {
    print('Erro: Banco local não encontrado.');
    return;
  }
  
  final db = FincoreDatabase(NativeDatabase(File(dbPath)));
  
  try {
    print('Buscando entradas falhadas de HistoricoOrdemPreparo no outbox...');
    final rows = await db.customSelect(
      "SELECT * FROM outbox_sync WHERE entity = 'HistoricoOrdemPreparo' AND status = 'failed'"
    ).get();
    
    if (rows.isEmpty) {
      print('Nenhuma entrada falhada encontrada.');
      return;
    }
    
    print('Encontrada(s) ${rows.length} entrada(s). Corrigindo payloads...');
    for (final row in rows) {
      final id = row.read<int>('id');
      final payloadStr = row.read<String>('payload');
      final Map<String, dynamic> payload = jsonDecode(payloadStr) as Map<String, dynamic>;
      
      if (!payload.containsKey('versao')) {
        payload['versao'] = 'v1';
        final newPayloadStr = jsonEncode(payload);
        
        // Atualizar no banco SQLite local mudando o status para 'pending'
        await db.customStatement(
          "UPDATE outbox_sync SET payload = ?, status = 'pending', error_message = NULL, attempts_count = 0 WHERE id = ?",
          [newPayloadStr, id]
        );
        print('  -> Entrada ID $id corrigida e redefinida para "pending"!');
      } else {
        print('  -> Entrada ID $id já contém o campo "versao". Mudando apenas status para "pending"...');
        await db.customStatement(
          "UPDATE outbox_sync SET status = 'pending', error_message = NULL, attempts_count = 0 WHERE id = ?",
          [id]
        );
      }
    }
    print('Payloads corrigidos com sucesso!');
  } catch (e) {
    print('Erro ao corrigir outbox: $e');
  } finally {
    await db.close();
  }
}
