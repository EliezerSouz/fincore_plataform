import 'package:postgres/postgres.dart';

void main() async {
  print('🔌 Conectando ao banco Supabase PostgreSQL...');
  final conn = await Connection.open(
    Endpoint(
      host: 'db.nlaxdeqbordmovukyypk.supabase.co',
      port: 5432,
      database: 'postgres',
      username: 'postgres',
      password: 'GeR9cjvrXrujvL0R',
    ),
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );
  print('✅ Conexão estabelecida!');

  try {
    print('\nFase 1 — Desabilitando triggers e foreign key checks...');
    await conn.execute('SET session_replication_role = replica;');
    print('Triggers e FKs desabilitados.');

    print('\nFase 2 — Buscando e truncando TODAS as tabelas do schema public...');
    final tablesRes = await conn.execute('''
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    ''');

    int limpadas = 0;
    for (final row in tablesRes) {
      final tabela = row[0] as String;
      // Não truncar tabelas de migrations do serverpod se existirem
      if (tabela.startsWith('serverpod_') || tabela == '_custom_applied_migrations') continue;
      try {
        await conn.execute('TRUNCATE TABLE public."$tabela" CASCADE;');
        print('  ✅ $tabela → truncada');
        limpadas++;
      } catch (e) {
        print('  ❌ $tabela → erro: $e');
      }
    }

    print('\nFase 3 — Reabilitando triggers e FKs...');
    await conn.execute('SET session_replication_role = DEFAULT;');
    print('Triggers e FKs reabilitados.');

    print('\n🎉 $limpadas tabelas zeradas com sucesso no Supabase!');
  } catch (e) {
    print('❌ Erro geral: $e');
  } finally {
    await conn.close();
    print('Conexão fechada.');
  }
}
