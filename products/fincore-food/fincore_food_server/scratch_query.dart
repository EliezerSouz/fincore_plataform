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

  print('\n=== ROUTE CACHE ===');
  final cacheRows = await connection.execute('SELECT origin, destination, distance_meters, duration_seconds FROM route_cache');
  for (final row in cacheRows) {
    print('  Origem: ${row[0]} | Destino: ${row[1]} | Distância: ${row[2]}m | Duração: ${row[3]}s');
  }

  print('\n=== USUÁRIOS ===');
  final userRows = await connection.execute('SELECT id, email, nome FROM usuarios');
  for (final row in userRows) {
    print('  ID: ${row[0]} | Email: ${row[1]} | Nome: ${row[2]}');
  }

  print('\n=== MEMBROS DE EMPRESA ===');
  final membroRows = await connection.execute('SELECT id, "tenantId", "usuarioId", role, ativo FROM membro_empresa');
  for (final row in membroRows) {
    print('  ID: ${row[0]} | Tenant: ${row[1]} | Usuario: ${row[2]} | Role: ${row[3]} | Ativo: ${row[4]}');
  }

  await connection.close();
}
