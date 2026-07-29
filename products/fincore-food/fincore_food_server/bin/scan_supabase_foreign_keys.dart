import 'package:postgres/postgres.dart';

void main() async {
  print('--- Supabase Database Constraint Scanner ---');
  
  final host = 'db.nlaxdeqbordmovukyypk.supabase.co';
  final port = 5432;
  final database = 'postgres';
  final username = 'postgres';
  final password = 'GeR9cjvrXrujvL0R';

  print('Connecting to Supabase at $host:$port...');
  final conn = await Connection.open(
    Endpoint(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
    ),
    settings: const ConnectionSettings(
      sslMode: SslMode.require,
    ),
  );

  print('Database connected successfully!\n');

  try {
    final query = '''
      SELECT
          tc.table_name AS local_table, 
          kcu.column_name AS local_column, 
          ccu.table_name AS foreign_table,
          ccu.column_name AS foreign_column,
          tc.constraint_name
      FROM 
          information_schema.table_constraints AS tc 
          JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
          JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
      WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'
      ORDER BY local_table, local_column;
    ''';

    final results = await conn.execute(query);

    if (results.isEmpty) {
      print('⚠️ Nenhuma Foreign Key (Chave Estrangeira) ativa encontrada no schema "public".');
    } else {
      print('====================================================================================================');
      print('| TABELA ORIGEM                 | COLUNA ORIGEM        | TABELA DESTINO        | COLUNA DESTINO    |');
      print('====================================================================================================');
      for (final row in results) {
        final localTable = (row[0] as String).padRight(30);
        final localCol = (row[1] as String).padRight(20);
        final foreignTable = (row[2] as String).padRight(22);
        final foreignCol = (row[3] as String).padRight(16);
        print('| $localTable | $localCol | $foreignTable | $foreignCol |');
      }
      print('====================================================================================================');
      print('Total de Chaves Estrangeiras ativas detectadas: ${results.length}');
    }
  } catch (e, stack) {
    print('❌ Erro ao escanear restrições do banco: $e');
    print(stack);
  } finally {
    await conn.close();
    print('\nConnection closed.');
  }
}
