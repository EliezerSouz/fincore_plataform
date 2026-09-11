// Script para aplicar o definition.sql (DDL total inicial) no banco Supabase
// Executar com: dart run apply_definition_sql.dart

import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  final host = Platform.environment['DB_HOST'] ?? 'db.nlaxdeqbordmovukyypk.supabase.co';
  final port = int.tryParse(Platform.environment['DB_PORT'] ?? '5432') ?? 5432;
  final dbName = Platform.environment['DB_NAME'] ?? 'postgres';
  final user = Platform.environment['DB_USER'] ?? 'postgres';
  final password = Platform.environment['DB_PASSWORD'] ?? 'GeR9cjvrXrujvL0R';

  print('🔌 Conectando ao banco Supabase: $host:$port/$dbName');

  final conn = await Connection.open(
    Endpoint(
      host: host,
      port: port,
      database: dbName,
      username: user,
      password: password,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );

  print('✅ Conectado. Carregando definition.sql...');
  
  final file = File('migrations/20260814152831799/definition.sql');
  if (!await file.exists()) {
    print('❌ Arquivo migrations/20260814152831799/definition.sql não encontrado!');
    await conn.close();
    exit(1);
  }

  final sqlContent = await file.readAsString();

  print('🚀 Executando DDL do schema inicial statement por statement...');
  
  // Fazer o split simples por ponto e vírgula
  // Nota: Não fazemos split dentro de blocos de funções ou triggers se existirem,
  // mas o definition.sql do Serverpod contém apenas CREATE TABLE, CREATE INDEX, etc.,
  // que são comandos simples separados por ponto e vírgula.
  final statements = sqlContent
      .split(';')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty && s != 'BEGIN' && s != 'COMMIT')
      .toList();

  try {
    await conn.execute('BEGIN;');
    int executed = 0;
    for (final statement in statements) {
      if (statement.startsWith('--') && !statement.contains('\n')) continue;
      await conn.execute(statement);
      executed++;
    }
    await conn.execute('COMMIT;');
    print('✅ DDL aplicado com sucesso! $executed statements executados.');
  } catch (e) {
    print('❌ ERRO ao aplicar DDL: $e');
    try { await conn.execute('ROLLBACK;'); } catch (_) {}
    await conn.close();
    exit(1);
  }

  await conn.close();
  exit(0);
}
