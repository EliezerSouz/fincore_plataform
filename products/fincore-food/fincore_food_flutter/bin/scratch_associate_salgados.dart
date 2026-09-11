import 'dart:io';
import 'package:drift/native.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

void main() async {
  final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\eliez';
  final dbPath = p.join(userProfile, 'Documents', 'fincore_v3.db');
  
  final tenantId = 'c28d0e3b-2cae-46ab-9251-b53e1adbb58a';
  final createdBy = 'd4717204-d8f3-4099-b2f7-ab4f0ad07744';
  final tabelaId = 'b16a5eea-e713-4d92-ad9a-bdadeabc1f56';
  
  final productIds = [
    'd005143d-1d5d-4255-a4b1-1d3299c33f23', // Mini Coxinha de Frango
    '89866d43-ff55-415e-9bb1-c89fdc65200e', // Mini Cigarrete
    '64c6db12-9103-4bc8-a662-730df2408a68', // Mini Kibe
    '8d569344-1614-4e84-a8c0-209411b5ed3a', // Mini Bolinha de Queijo
  ];

  print('=== 1. INSERINDO ASSOCIAÇÕES NO BANCO LOCAL SQLite ===');
  if (!File(dbPath).existsSync()) {
    print('Erro: Banco local não encontrado.');
    return;
  }
  
  final db = FincoreDatabase(NativeDatabase(File(dbPath)));
  
  try {
    for (final prodId in productIds) {
      final id = const Uuid().v4();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      
      // Inserir na tabela local produtos_tabelas_precificacao_table
      await db.customStatement('''
        INSERT OR REPLACE INTO produtos_tabelas_precificacao_table (
          id, tenant_id, created_at, updated_at, created_by, updated_by,
          sync_status, sync_version, produto_id, tabela_precificacao_id,
          ativo, prioridade
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''', [
        id, tenantId, now, now, createdBy, createdBy,
        'pending', 1, prodId, tabelaId,
        1, 0
      ]);
      print('Inserida associação local para Produto ID: $prodId');
    }
  } catch (e) {
    print('Erro no banco local: $e');
  } finally {
    await db.close();
  }

  print('\n=== 2. INSERINDO ASSOCIAÇÕES NO BANCO REMOTO Supabase ===');
  try {
    final connection = await Connection.open(
      Endpoint(
        host: 'db.nlaxdeqbordmovukyypk.supabase.co',
        port: 5432,
        database: 'postgres',
        username: 'postgres',
        password: 'GeR9cjvrXrujvL0R',
      ),
      settings: const ConnectionSettings(sslMode: SslMode.require),
    );

    for (final prodId in productIds) {
      final id = const Uuid().v4();
      
      await connection.execute('''
        INSERT INTO produto_tabela_precificacao (
          id, "tenantId", "produtoId", "tabelaPrecificacaoId",
          ativo, prioridade, "createdAt", "updatedAt", "createdBy", "updatedBy", "syncVersion"
        ) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, NOW(), NOW(), \$7, \$7, 1)
        ON CONFLICT (id) DO NOTHING
      ''', parameters: [
        id, tenantId, prodId, tabelaId,
        true, 0, createdBy
      ]);
      print('Inserida associação remota para Produto ID: $prodId');
    }

    await connection.close();
    print('Associações inseridas no Supabase com sucesso!');
  } catch (e) {
    print('Erro no banco remoto: $e');
  }
}
