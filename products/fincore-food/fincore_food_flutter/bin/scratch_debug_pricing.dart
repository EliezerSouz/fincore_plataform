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
    final products = [
      (id: 'd005143d-1d5d-4255-a4b1-1d3299c33f23', nome: 'Mini Coxinha de Frango'),
      (id: '89866d43-ff55-415e-9bb1-c89fdc65200e', nome: 'Mini Cigarrete'),
      (id: '64c6db12-9103-4bc8-a662-730df2408a68', nome: 'Mini Kibe'),
    ];

    print('\n=== SIMULANDO PREÇOS VIA SQL DIRETO ===');
    for (final p in products) {
      print('\nProduto: ${p.nome} (ID: ${p.id})');
      
      // 1. Buscar tabelas associadas ao produto
      final assocs = await db.customSelect(
        "SELECT * FROM produtos_tabelas_precificacao_table WHERE produto_id = '${p.id}' AND ativo = 1"
      ).get();
      
      if (assocs.isEmpty) {
        print('  [ERRO] Nenhuma tabela de precificação vinculada para este produto.');
        continue;
      }
      
      // 2. Obter as tabelas comerciais correspondentes
      for (final assoc in assocs) {
        final tabelaId = assoc.read<String>('tabela_precificacao_id');
        final tabelaRows = await db.customSelect(
          "SELECT * FROM tabelas_precificacao_table WHERE id = '$tabelaId' AND ativo = 1"
        ).get();
        
        if (tabelaRows.isEmpty) {
          print('  [ERRO] Tabela de precificação ID $tabelaId inativa ou não encontrada.');
          continue;
        }
        
        final tabela = tabelaRows.first;
        final tabelaNome = tabela.read<String>('nome');
        print('  Tabela Associada: "$tabelaNome" (ID: $tabelaId)');
        
        // 3. Buscar faixas/itens de precificação desta tabela
        final faixas = await db.customSelect(
          "SELECT * FROM itens_tabela_precificacao_table WHERE tabela_precificacao_id = '$tabelaId' ORDER BY quantidade_minima ASC"
        ).get();
        
        if (faixas.isEmpty) {
          print('    [ERRO] Nenhuma faixa cadastrada para a tabela "$tabelaNome".');
          continue;
        }
        
        // 4. Testar a faixa de preço para diferentes quantidades
        for (final testQty in [25, 50, 100]) {
          int? precoFinal;
          String faixaDesc = '';
          
          for (final f in faixas) {
            final min = f.read<int>('quantidade_minima');
            final max = f.readNullable<int>('quantidade_maxima');
            final valor = f.read<int>('valor_unitario_centavos');
            
            if (testQty >= min && (max == null || testQty <= max)) {
              precoFinal = valor;
              faixaDesc = '[$min a ${max ?? 'inf'}]';
              break;
            }
          }
          
          if (precoFinal != null) {
            print('    Quantidade: $testQty -> Preço resolvido: R\$ ${(precoFinal / 100).toStringAsFixed(2)} na faixa $faixaDesc');
          } else {
            // Fallback: primeiro item
            final fallbackVal = faixas.first.read<int>('valor_unitario_centavos');
            print('    Quantidade: $testQty -> [FALLBACK] Preço resolvido: R\$ ${(fallbackVal / 100).toStringAsFixed(2)}');
          }
        }
      }
    }
  } catch (e) {
    print('Erro geral: $e');
  } finally {
    await db.close();
  }
}
