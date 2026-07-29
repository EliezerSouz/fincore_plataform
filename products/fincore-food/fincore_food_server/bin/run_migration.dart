import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  print('--- Supabase Migration Runner ---');
  
  final host = 'db.nlaxdeqbordmovukyypk.supabase.co';
  final port = 5432;
  final database = 'postgres';
  final username = 'postgres';
  final password = 'GeR9cjvrXrujvL0R';

  print('Connecting to $host:$port...');
  
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

  print('Database connected!');

  try {
    final file = File('migrations/20260728000000000_create_audit_logs.sql');
    if (!await file.exists()) {
      print('Migration file not found at migrations/20260728000000000_create_audit_logs.sql');
      return;
    }

    final sql = await file.readAsString();
    final statements = sql.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty);
    for (final statement in statements) {
      print('Executing: $statement');
      await conn.execute(statement);
    }
    
    print('Migration completed successfully! audit_logs table created on Supabase!');
  } catch (e) {
    print('Failed to execute migration: $e');
  } finally {
    await conn.close();
    print('Connection closed.');
  }
}
