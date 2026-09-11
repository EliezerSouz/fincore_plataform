import 'package:postgres/postgres.dart';

void main() async {
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

  final tablesRes = await conn.execute('''
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    ORDER BY table_name
  ''');

  print('=== CONTAGEM DE LINHAS POR TABELA NO SUPABASE ===');
  int comDados = 0;
  for (final row in tablesRes) {
    final tabela = row[0] as String;
    try {
      final cRes = await conn.execute('SELECT COUNT(*) FROM public."$tabela"');
      final count = cRes.first[0] as int;
      if (count > 0) {
        print('  📌 $tabela: $count registros');
        comDados++;
      }
    } catch (_) {}
  }

  print('\nTotal de tabelas com dados: $comDados');
  await conn.close();
}
