import 'package:postgres/postgres.dart';

void main() async {
  print('--- Supabase Audit Logs Migration (Add missing columns) ---');
  
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

  print('Database connected successfully!');

  try {
    print('Dropping old "audit_logs" table...');
    await conn.execute('DROP TABLE IF EXISTS audit_logs CASCADE;');
    
    print('Creating "audit_logs" table with UUID key...');
    await conn.execute('''
      CREATE TABLE audit_logs (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "entityName" text NOT NULL,
        "entityId" text NOT NULL,
        "userId" text NOT NULL,
        "action" text NOT NULL,
        "timestamp" timestamp without time zone NOT NULL,
        "diff" text,
        "deviceInfo" text,
        "origin" text,
        "reason" text,
        "syncVersion" bigint,
        "tenantId" text
      );
    ''');
    print('  ✓ Recreated successfully!');
    print('\nMigration completed! audit_logs is now fully compatible with the sync service.');
  } catch (e) {
    print('Failed to execute migration: $e');
  } finally {
    await conn.close();
    print('Connection closed.');
  }
}
