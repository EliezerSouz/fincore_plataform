import 'package:postgres/postgres.dart';

void main() async {
  print('Revertendo versão da migration no banco...');
  final pool = Pool.withEndpoints(
    [
      Endpoint(
        host: 'db.nlaxdeqbordmovukyypk.supabase.co',
        port: 5432,
        database: 'postgres',
        username: 'postgres',
        password: 'GeR9cjvrXrujvL0R',
      ),
    ],
    settings: const PoolSettings(maxConnectionCount: 1, sslMode: SslMode.require),
  );

  await pool.execute(
    "UPDATE serverpod_migrations SET version = '20260729115730835', timestamp = now() WHERE module = 'fincore_food'",
  );

  final rows = await pool.execute('SELECT module, version FROM serverpod_migrations ORDER BY module');
  print('Estado atual de serverpod_migrations:');
  for (final r in rows) {
    print('  ${r[0]}: ${r[1]}');
  }

  await pool.close();
  print('Concluído!');
}
