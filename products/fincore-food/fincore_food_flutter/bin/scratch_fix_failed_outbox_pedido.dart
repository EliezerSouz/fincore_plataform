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
    // 1. Corrigir tabela de pedidos local
    print('Corrigindo status "emPreparo" para "em_preparo" na tabela de pedidos local...');
    await db.customStatement(
      "UPDATE pedidos_table SET status = 'em_preparo' WHERE status = 'emPreparo'"
    );
    print('Pedidos atualizados na tabela local.');

    // 2. Corrigir payloads na outbox_sync
    print('Buscando entradas de outbox para Pedido contendo "emPreparo"...');
    final rows = await db.customSelect(
      "SELECT * FROM outbox_sync WHERE entity IN ('Pedido', 'pedidos') AND payload LIKE '%emPreparo%'"
    ).get();
    
    if (rows.isEmpty) {
      print('Nenhuma entrada com payload contendo "emPreparo" encontrada na outbox.');
    } else {
      print('Encontrada(s) ${rows.length} entrada(s). Corrigindo payloads...');
      for (final row in rows) {
        final id = row.read<int>('id');
        final payloadStr = row.read<String>('payload');
        final Map<String, dynamic> payload = jsonDecode(payloadStr) as Map<String, dynamic>;
        
        if (payload['status'] == 'emPreparo') {
          payload['status'] = 'em_preparo';
          final newPayloadStr = jsonEncode(payload);
          
          await db.customStatement(
            "UPDATE outbox_sync SET payload = ?, status = 'pending', error_message = NULL, attempts_count = 0 WHERE id = ?",
            [newPayloadStr, id]
          );
          print('  -> Entrada outbox ID $id corrigida de "emPreparo" para "em_preparo" e redefinida para "pending"!');
        }
      }
    }

    // 3. Destravar quaisquer outras entradas que falharam por causa desse constraint
    print('Redefinindo entradas falhadas da tabela Pedido/pedidos para "pending" no outbox...');
    await db.customStatement(
      "UPDATE outbox_sync SET status = 'pending', error_message = NULL, attempts_count = 0 WHERE entity IN ('Pedido', 'pedidos') AND status = 'failed'"
    );
    print('Fila de outbox destravada com sucesso!');

  } catch (e) {
    print('Erro ao higienizar banco local: $e');
    try {
      print('Listando tabelas existentes no banco local:');
      final tables = await db.customSelect("SELECT name FROM sqlite_master WHERE type='table'").get();
      for (final t in tables) {
        print('  - ${t.read<String>('name')}');
      }
    } catch (err) {
      print('Erro ao listar tabelas: $err');
    }
  } finally {
    await db.close();
    print('Conexão encerrada.');
  }
}
