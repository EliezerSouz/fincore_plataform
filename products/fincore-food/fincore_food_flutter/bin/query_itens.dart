import 'dart:io';
import 'package:drift/native.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:path/path.dart' as p;

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
    // 1. Listar todos os pedidos para achar o ID do pedido #0009
    final allPedidos = await db.select(db.pedidosTable).get();
    print('\n=== PEDIDOS NO BANCO ===');
    String? pedidoId0009;
    for (final p in allPedidos) {
      print('ID: ${p.id} | Número: ${p.numeroPedido} | Status: ${p.status} | Cliente: ${p.clienteId}');
      if (p.numeroPedido == 9) {
        pedidoId0009 = p.id;
      }
    }
    
    if (pedidoId0009 == null) {
      print('\nPedido #0009 não encontrado!');
      return;
    }
    
    print('\n=== ITENS DO PEDIDO #0009 (ID: $pedidoId0009) ===');
    final query = db.select(db.itensPedidoTable)..where((t) => t.pedidoId.equals(pedidoId0009!));
    final items = await query.get();
    for (final item in items) {
      print('ID: ${item.id} | Nome: ${item.nomeProduto} | Qtd: ${item.quantidade} | Preço: ${item.valorUnitarioCentavos} | Criado em: ${item.createdAt} | Sync Status: ${item.syncStatus} | Deleted At: ${item.deletedAt}');
    }
    
    // 2. Listar outbox sync
    final outboxRows = await db.select(db.outboxSync).get();
    print('\n=== OUTBOX SYNC QUEUE (IDs 360-380) ===');
    for (final row in outboxRows) {
      if (row.id >= 360 && row.id <= 380) {
        print('ID: ${row.id} | Entity: ${row.entity} | EntityID: ${row.entityId} | Action: ${row.action} | Status: ${row.status} | Created At: ${row.createdAt}');
      }
    }
    
  } catch (e) {
    print('Erro: $e');
  } finally {
    await db.close();
  }
}
