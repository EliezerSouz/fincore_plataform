import 'dart:io';
import 'package:drift/native.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';

/// Script para limpar duplicatas de itens_pedido no banco local.
/// Para cada pedido, mantém apenas o item mais RECENTE de cada produtoId,
/// hard-deletando todos os outros.
void main() async {
  final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\eliez';
  final dbPath = p.join(userProfile, 'Documents', 'fincore_v3.db');

  print('Banco de dados: $dbPath');
  if (!File(dbPath).existsSync()) {
    print('Erro: banco não encontrado!');
    return;
  }

  final db = FincoreDatabase(NativeDatabase(File(dbPath)));

  try {
    // Busca todos os itens não deletados
    final allItems = await (db.select(db.itensPedidoTable)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();

    // Agrupa por (pedidoId, produtoId)
    final Map<String, List<ItemPedidoData>> groups = {};
    for (final item in allItems) {
      final key = '${item.pedidoId}__${item.produtoId}';
      groups.putIfAbsent(key, () => []).add(item);
    }

    int deletedCount = 0;
    for (final entry in groups.entries) {
      final items = entry.value;
      if (items.length > 1) {
        print('\n⚠️  Duplicatas encontradas para chave: ${entry.key}');
        print('   Total: ${items.length} itens');
        // Mantém o primeiro (mais recente, pois ordenamos DESC)
        final toKeep = items.first;
        final toDelete = items.skip(1).toList();
        print('   ✅ Mantendo: ${toKeep.id} (createdAt: ${toKeep.createdAt})');
        for (final dup in toDelete) {
          print('   🗑️  Deletando: ${dup.id} (createdAt: ${dup.createdAt})');
          await (db.delete(db.itensPedidoTable)
                ..where((t) => t.id.equals(dup.id)))
              .go();
          deletedCount++;
        }
      }
    }

    if (deletedCount == 0) {
      print('\n✅ Nenhuma duplicata encontrada.');
    } else {
      print('\n✅ Limpeza concluída. Total de duplicatas removidas: $deletedCount');
    }

    // Exibe estado final
    print('\n=== ESTADO FINAL DOS ITENS (por pedido) ===');
    final finalItems = await (db.select(db.itensPedidoTable)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    
    final Map<String, List<ItemPedidoData>> byPedido = {};
    for (final item in finalItems) {
      byPedido.putIfAbsent(item.pedidoId, () => []).add(item);
    }
    for (final entry in byPedido.entries) {
      print('\nPedido ${entry.key.substring(0, 8)}...');
      for (final item in entry.value) {
        print('  - ${item.nomeProduto} x${item.quantidade} | ID: ${item.id.substring(0, 8)}...');
      }
    }
  } finally {
    await db.close();
  }
}
