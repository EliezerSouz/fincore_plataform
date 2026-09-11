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

  print('=== COLUNAS DA TABELA audit_logs ===');
  final res = await conn.execute('''
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'audit_logs'
  ''');
  for (final row in res) {
    print('  ${row[0]} : ${row[1]}');
  }

  print('\n=== COLUNAS DA TABELA empresa ===');
  final resEmp = await conn.execute('''
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'empresa'
  ''');
  for (final row in resEmp) {
    print('  ${row[0]} : ${row[1]}');
  }

  print('\n=== COLUNAS DA TABELA usuarios ===');
  final resUsr = await conn.execute('''
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'usuarios'
  ''');
  for (final row in resUsr) {
    print('  ${row[0]} : ${row[1]}');
  }

  await conn.close();
}
