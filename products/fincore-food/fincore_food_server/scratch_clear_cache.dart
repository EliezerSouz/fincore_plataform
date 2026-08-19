import 'package:postgres/postgres.dart';

void main() async {
  print('🔌 Conectando para limpar o cache...');
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
    settings: const PoolSettings(maxConnectionCount: 1, sslMode: SslMode.require, connectTimeout: Duration(seconds: 8)),
  );

  try {
    await pool.execute('DELETE FROM route_cache');
    print('✅ Cache de rotas (route_cache) limpo com sucesso!');
  } catch (e) {
    print('❌ Erro ao limpar cache: $e');
  } finally {
    await pool.close();
  }
}
