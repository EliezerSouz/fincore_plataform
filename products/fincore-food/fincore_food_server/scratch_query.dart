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

  print('Buscando logs de erro do Serverpod...');
  final logRows = await connection.execute('SELECT "time", "message", "error", "stackTrace" FROM serverpod_log ORDER BY id DESC LIMIT 5');
  for (final row in logRows) {
    print('-----------------------------------------');
    print('Hora: ${row[0]}');
    print('Mensagem: ${row[1]}');
    print('Erro: ${row[2]}');
    print('Stack: ${row[3]}');
  }

  print('\nBuscando membros...');
  final membroRows = await connection.execute('SELECT "tenantId", "usuarioId", ativo FROM membro_empresa');
  for (final row in membroRows) {
    print('Membro Tenant: ${row[0]}, Usuario: ${row[1]}, Ativo: ${row[2]}');
  }

  await connection.close();
}
