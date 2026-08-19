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

  print('\n=== CONEXÕES ATIVAS ===');
  final connRows = await connection.execute('''
    SELECT pid, age(clock_timestamp(), query_start), state, query 
    FROM pg_stat_activity 
    WHERE state != \'idle\' AND query NOT LIKE \'%pg_stat_activity%\'
  ''');
  for (final row in connRows) {
    print('  PID: \${row[0]} | Duração: \${row[1]} | Estado: \${row[2]} | Query: \${row[3]}');
  }

  print('\n=== TRAVAMENTOS (LOCKS) ===');
  final lockRows = await connection.execute('''
    SELECT
      blocked_locks.pid     AS blocked_pid,
      blocked_activity.query    AS blocked_statement,
      blocking_locks.pid    AS blocking_pid,
      blocking_activity.query   AS blocking_statement
    FROM  pg_catalog.pg_locks         blocked_locks
    JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
    JOIN pg_catalog.pg_locks         blocking_locks 
        ON blocking_locks.locktype = blocked_locks.locktype
        AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
        AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
        AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
        AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
        AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
        AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
        AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
        AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
        AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
        AND blocking_locks.pid != blocked_locks.pid
    JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
    WHERE NOT blocked_locks.granted
  ''');
  if (lockRows.isEmpty) {
    print('Nenhum lock pendente encontrado.');
  } else {
    for (final row in lockRows) {
      print('  Bloqueado PID: \${row[0]} | Query Bloqueada: \${row[1]} | Bloqueador PID: \${row[2]} | Query Bloqueadora: \${row[3]}');
    }
  }

  await connection.close();
}
