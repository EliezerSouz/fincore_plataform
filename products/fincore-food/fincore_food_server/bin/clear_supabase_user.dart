import 'package:postgres/postgres.dart';

void main() async {
  final emailToClear = 'eliezerssouz@gmail.com';
  print('--- Supabase Cascaded User Data Cleanup ---');
  print('Target User Email: $emailToClear');
  
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
    // 1. Buscar o ID do usuário no auth.users
    final userResult = await conn.execute(
      r'SELECT id FROM auth.users WHERE email = $1',
      parameters: [emailToClear],
    );

    if (userResult.isEmpty) {
      print('❌ User not found in auth.users for email: $emailToClear');
      return;
    }

    final userId = userResult.first.first as String;
    print('✓ Found User ID: $userId');

    // 2. Buscar os tenants associados a esse usuário na tabela membro_empresa
    final tenantResult = await conn.execute(
      r'SELECT "tenantId" FROM membro_empresa WHERE "usuarioId" = $1',
      parameters: [userId],
    );

    final tenants = tenantResult.map((row) => row.first as String).toList();
    print('✓ Associated Tenants found: $tenants');

    // Iniciando transação de exclusão
    await conn.runTx((session) async {
      print('\nStarting transaction to delete user data...');

      // Deleta dados associados aos tenants encontrados
      for (final tenantId in tenants) {
        print('Deleting data for Tenant ID: $tenantId...');

        final tenantTables = [
          'eventos_empresa',
          'audit_logs',
          'produto_tabela_precificacao',
          'item_tabela_precificacao',
          'tabela_precificacao',
          'local_entrega',
          'cliente',
          'produto',
          'categoria',
          'forma_pagamento',
          'taxa_entrega',
          'empresa_configuracao',
          'membro_empresa',
        ];

        for (final table in tenantTables) {
          // Usamos aspas duplas no tenantId pois o PostgreSQL do Serverpod usa CamelCase nas colunas
          final query = 'DELETE FROM "$table" WHERE "tenantId" = \$1';
          print('  - Deleting from $table...');
          await session.execute(query, parameters: [tenantId]);
        }

        // Deleta a empresa em si
        print('  - Deleting from empresa...');
        await session.execute(
          r'DELETE FROM "empresa" WHERE "id" = $1',
          parameters: [tenantId],
        );
      }

      // Deleta qualquer log restante associado diretamente ao userId
      print('Deleting leftover audit logs for User ID: $userId...');
      await session.execute(
        r'DELETE FROM "audit_logs" WHERE "userId" = $1',
        parameters: [userId],
      );

      // Deleta da tabela membro_empresa associado ao userId
      print('Deleting leftovers from membro_empresa for User ID: $userId...');
      await session.execute(
        r'DELETE FROM "membro_empresa" WHERE "usuarioId" = $1',
        parameters: [userId],
      );

      // Deleta da tabela usuarios
      print('Deleting from public.usuarios...');
      await session.execute(
        r'DELETE FROM "usuarios" WHERE "id" = $1',
        parameters: [userId],
      );

      // Deleta do auth.users do Supabase
      print('Deleting from auth.users (Supabase Auth)...');
      await session.execute(
        r'DELETE FROM auth.users WHERE id = $1',
        parameters: [userId],
      );
    });

    print('\n🎉 All user data, associated tenants, and auth account cleared successfully from Supabase!');
  } catch (e, stack) {
    print('❌ Failed to clean up user data: $e');
    print(stack);
  } finally {
    await conn.close();
    print('Connection closed.');
  }
}
