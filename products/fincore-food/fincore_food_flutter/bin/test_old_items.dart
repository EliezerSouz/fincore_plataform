import 'dart:io';
import 'package:drift/native.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';

void main() async {
  final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\eliez';
  final dbPath = p.join(userProfile, 'Documents', 'fincore_v3.db');
  
  print('Lendo banco de dados em: $dbPath');
  if (!File(dbPath).existsSync()) {
    print('Erro: Arquivo do banco de dados não encontrado!');
    return;
  }
  
  final db = FincoreDatabase(NativeDatabase(File(dbPath)));
  
  try {
    final pedidoId = '38a5c662-646d-45b6-b0fa-cddabe83b643';
    
    // Executar a query exata
    final query = db.select(db.itensPedidoTable)
      ..where((t) => t.pedidoId.equals(pedidoId) & t.deletedAt.isNull());
    
    final oldItems = await query.get();
    print('\n=== PRODUTOS RETORNADOS PELA QUERY ===');
    print('Total de itens encontrados: ${oldItems.length}');
    for (final item in oldItems) {
      print('ID: ${item.id} | Nome: ${item.nomeProduto} | Qtd: ${item.quantidade} | Deletado: ${item.deletedAt}');
    }
  } catch (e) {
    print('Erro: $e');
  } finally {
    await db.close();
  }
}
