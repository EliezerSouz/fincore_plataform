import 'package:postgres/postgres.dart';

void main() async {
  print('Conectando ao banco Supabase PostgreSQL...');
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

  print('\n=== EMPRESAS ===');
  final empRows = await connection.execute('SELECT id, "razaoSocial", status, email FROM empresa');
  for (final row in empRows) {
    print('  ID: ${row[0]} | Razao: ${row[1]} | Status: ${row[2]} | Email: ${row[3]}');
  }

  print('\n=== COLUMNS DEFAULT ===');
  final colRows = await connection.execute("SELECT column_name, column_default FROM information_schema.columns WHERE table_name = 'empresa' AND column_name = 'status'");
  for (final row in colRows) {
    print('  Column: ${row[0]} | Default: ${row[1]}');
  }

  print('\n=== TRIGGERS ===');
  final trigRows = await connection.execute("SELECT trigger_name, event_manipulation, event_object_table, action_statement FROM information_schema.triggers");
  for (final row in trigRows) {
    print('  Trigger: ${row[0]} | Event: ${row[1]} | Table: ${row[2]} | Action: ${row[3]}');
  }

  print('\n=== USUÁRIOS ===');
  final userRows = await connection.execute('SELECT * FROM usuarios LIMIT 5');
  for (final row in userRows) {
    print('  Row: ${row.toColumnMap()}');
  }

  print('\n=== MEMBROS DE EMPRESA ===');
  final membroRows = await connection.execute('SELECT id, "tenantId", "usuarioId", role, ativo FROM membro_empresa');
  for (final row in membroRows) {
    print('  ID: ${row[0]} | Tenant: ${row[1]} | Usuario: ${row[2]} | Role: ${row[3]} | Ativo: ${row[4]}');
  }

  await connection.close();
}
