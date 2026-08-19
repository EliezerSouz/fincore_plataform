import 'dart:io';
import 'package:drift/native.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Script para soft-deletar no Supabase os itens duplicados que foram
/// removidos do banco local mas ainda existem na nuvem sem deletedAt.
void main() async {
  // Carregar .env
  await dotenv.load(fileName: p.join(
    'f:\\Eigent\\fincore_platform\\products\\fincore-food\\fincore_food_flutter',
    '.env',
  ));
  
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    print('Erro: SUPABASE_URL ou SUPABASE_ANON_KEY não configurado no .env');
    return;
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  final supabase = Supabase.instance.client;

  // IDs duplicados identificados no banco local que devem ser soft-deletados no Supabase
  final duplicateIds = [
    '13c80a98-7b8e-4a51-901e-d94c0c3f8e0b',
    '8513a7b3-967b-4e8b-8914-fe2a18f3d86f',
    '19bc2dfd-9f2e-4888-927d-70da30f9230f',
    'd542a556-ecfb-468c-9c6a-9f7c67712f81',
  ];

  print('Soft-deletando ${duplicateIds.length} itens duplicados no Supabase...\n');
  
  int successCount = 0;
  for (final id in duplicateIds) {
    try {
      final result = await supabase
          .from('item_pedido')
          .update({'deletedAt': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
      print('✅ Soft-deleted: $id');
      successCount++;
    } catch (e) {
      print('❌ Erro ao soft-deletar $id: $e');
    }
  }
  
  print('\n✅ Total soft-deletados: $successCount/${duplicateIds.length}');
  
  // Verificar estado atual no Supabase
  print('\n=== Verificando itens do pedido 38a5c662... no Supabase ===');
  try {
    final rows = await supabase
        .from('item_pedido')
        .select()
        .eq('pedidoId', '38a5c662-646d-45b6-b0fa-cddabe83b643');
    
    for (final row in rows) {
      print('ID: ${row['id']} | Nome: ${row['nomeProduto']} | deletedAt: ${row['deletedAt']}');
    }
  } catch (e) {
    print('Erro ao verificar Supabase: $e');
  }
}
