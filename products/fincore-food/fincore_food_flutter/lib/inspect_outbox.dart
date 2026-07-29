import 'dart:io';
import 'package:drift/native.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:path/path.dart' as p;

void main() async {
  // O path do banco no Windows fica na pasta Documents do usuário
  final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\eliez';
  final dbPath = p.join(userProfile, 'Documents', 'fincore_v3.db');
  
  print('Tentando abrir o banco de dados em: $dbPath');
  
  if (!File(dbPath).existsSync()) {
    print('Erro: Arquivo do banco de dados não encontrado em $dbPath!');
    return;
  }
  
  final db = FincoreDatabase(NativeDatabase(File(dbPath)));
  
  try {
    final entries = await db.select(db.outboxSync).get();
    print('\n=== TOTAL DE REGISTROS NA OUTBOX: ${entries.length} ===\n');
    
    final pendentes = entries.where((e) => e.status != 'synced').toList();
    
    if (pendentes.isEmpty) {
      print('Parabéns! Todas as transações foram sincronizadas com sucesso.');
    } else {
      print('--- ${pendentes.length} transações NÃO sincronizadas encontradas: ---');
      for (final e in pendentes.take(15)) {
        print('ID: ${e.id} | Entidade: ${e.entity} (${e.entityId}) | Action: ${e.action} | Status: ${e.status}');
        print('Tentativas: ${e.attemptsCount} | Erro: ${e.errorMessage}');
        print('Payload: ${e.payload}');
        print('----------------------------------------------------');
      }
    }
  } catch (e) {
    print('Erro ao inspecionar outbox: $e');
  } finally {
    await db.close();
  }
}
