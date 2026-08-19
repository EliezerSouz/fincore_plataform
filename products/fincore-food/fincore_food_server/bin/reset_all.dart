import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  print('====================================================');
  print('🚀 INICIANDO RESET COMPLETO (SUPABASE + SQLITE LOCAL)');
  print('====================================================');

  final endpoint = Endpoint(
    host: 'db.nlaxdeqbordmovukyypk.supabase.co',
    port: 5432,
    database: 'postgres',
    username: 'postgres',
    password: 'GeR9cjvrXrujvL0R',
  );

  try {
    print('\n[1/2] Conectando ao banco Supabase PostgreSQL...');
    final conn = await Connection.open(
      endpoint,
      settings: const ConnectionSettings(
        sslMode: SslMode.require,
      ),
    );
    print('✔ Conectado ao Supabase com sucesso!');

    final tables = [
      'empresa_configuracao',
      'categoria',
      'categorias',
      'membro_empresa',
      'membros_empresa',
      'tabela_precificacao',
      'tabelas_precificacao',
      'taxa_entrega',
      'taxas_entrega',
      'forma_pagamento',
      'formas_pagamento',
      'cliente',
      'clientes',
      'produto',
      'produtos',
      'local_entrega',
      'locais_entrega',
      'item_tabela_precificacao',
      'itens_tabela_precificacao',
      'produto_tabela_precificacao',
      'produtos_tabelas_precificacao',
      'empresa',
      'usuario',
      'outbox',
      'audit_logs',
      'custom_migrations',
    ];

    print('\n[2/2] Limpando tabelas de dados do Supabase...');
    for (final table in tables) {
      try {
        await conn.execute('TRUNCATE TABLE "$table" CASCADE;');
        print('  ✔ Tabela "$table" limpa.');
      } catch (e) {
        print('  ℹ Tabela "$table": $e');
      }
    }

    await conn.close();
    print('\n✅ Banco Supabase reseta com sucesso!');
  } catch (e) {
    print('✖ Erro ao acessar o Supabase: $e');
  }

  // Limpeza de SQLite local e Logs
  print('\n[3/3] Deletando banco SQLite local e logs do dispositivo...');
  final docsPaths = [
    'C:\\Users\\eliez\\OneDrive\\Documentos',
    'C:\\Users\\eliez\\Documents',
  ];

  for (final basePath in docsPaths) {
    final dbFile = File('$basePath\\fincore_v3.db');
    final dbJournal = File('$basePath\\fincore_v3.db-journal');
    final dbWal = File('$basePath\\fincore_v3.db-wal');
    final dbShm = File('$basePath\\fincore_v3.db-shm');
    final logsDir = Directory('$basePath\\logs');

    if (await dbFile.exists()) {
      await dbFile.delete();
      print('  ✔ Deletado: ${dbFile.path}');
    }
    if (await dbJournal.exists()) await dbJournal.delete();
    if (await dbWal.exists()) await dbWal.delete();
    if (await dbShm.exists()) await dbShm.delete();

    try {
      if (await logsDir.exists()) {
        await logsDir.delete(recursive: true);
        print('  ✔ Pasta de logs limpa: ${logsDir.path}');
      }
    } catch (e) {
      print('  ℹ Nao foi possivel apagar pasta de logs (${logsDir.path}): $e');
    }
  }

  print('\n====================================================');
  print('🎉 RESET COMPLETO CONCLUÍDO COM SUCESSO!');
  print('Você pode iniciar a aplicação limpa do zero agora.');
  print('====================================================');
  exit(0);
}
