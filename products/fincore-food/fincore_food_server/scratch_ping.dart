import 'package:postgres/postgres.dart';

void main() async {
  print('Conectando ao Supabase...');
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

  print('Medindo latência de consultas (50 iterações)...');
  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < 50; i++) {
    await connection.execute('SELECT 1');
  }
  stopwatch.stop();

  final totalTime = stopwatch.elapsedMilliseconds;
  final avgTime = totalTime / 50;
  print('\n=== RESULTADO ===');
  print('Tempo total para 50 consultas: ${totalTime}ms');
  print('Latência média por consulta: ${avgTime.toStringAsFixed(2)}ms');

  await connection.close();
}
