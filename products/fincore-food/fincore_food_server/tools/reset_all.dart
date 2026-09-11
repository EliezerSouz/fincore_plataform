// ═══════════════════════════════════════════════════════════════════════════
// FINCORE Food — Reset Completo de Ambiente (Supabase + Local + SQLite)
// ⚠️  OPERAÇÃO DESTRUTIVA — Limpa banco remoto, banco local Docker e arquivos locais
// ═══════════════════════════════════════════════════════════════════════════
//
// Uso:
//   cd products/fincore-food/fincore_food_server
//   dart run tools/reset_all.dart
//
// O que faz:
//   1. Conecta e zera o banco de dados Supabase na nuvem (remoto)
//   2. Conecta e zera o banco de dados PostgreSQL local (Docker na porta 8090)
//   3. Remove o arquivo SQLite local do Windows (fincore_v3.db)
//   4. Indica comandos para limpar emuladores e dispositivos móveis
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:path/path.dart' as p;

// ── Credenciais Supabase ────────────────────────────────────────────────────
const _supabaseHost     = 'db.nlaxdeqbordmovukyypk.supabase.co';
const _supabasePort     = 5432;
const _supabaseDatabase = 'postgres';
const _supabaseUser     = 'postgres';
const _supabasePassword = 'GeR9cjvrXrujvL0R';

// ── Credenciais Local (Docker) ──────────────────────────────────────────────
const _localHost     = 'localhost';
const _localPort     = 8090;
const _localDatabase = 'fincore_food';
const _localUser     = 'postgres';
const _localPassword = '-nijjTTsE4w_s9T_lJUH1WE62wnU4ZO5';

void main() async {
  _header('FINCORE FOOD — RESET AMBIENTAL COMPLETO');
  _aviso('⚠️  Esta operação vai apagar de forma irreversível:');
  _aviso('    - O banco de dados Supabase remoto');
  _aviso('    - O banco de dados local Docker (se ativo na porta 8090)');
  _aviso('    - O arquivo SQLite de cache local (fincore_v3.db) no Windows');
  _aviso('');
  _aviso('Pressione ENTER para confirmar ou Ctrl+C para cancelar...');
  stdin.readLineSync();

  // 1. Reset Supabase
  await _resetDatabase(
    name: 'SUPABASE REMOTO',
    host: _supabaseHost,
    port: _supabasePort,
    database: _supabaseDatabase,
    user: _supabaseUser,
    password: _supabasePassword,
    sslMode: SslMode.require,
  );

  // 2. Reset Postgres Local
  await _resetDatabase(
    name: 'POSTGRES LOCAL (DOCKER :8090)',
    host: _localHost,
    port: _localPort,
    database: _localDatabase,
    user: _localUser,
    password: _localPassword,
    sslMode: SslMode.disable,
  );

  // 3. Reset SQLite local do Windows (Drift)
  await _resetLocalSQLite();

  _header('PRÓXIMOS PASSOS');
  _ok('🎉 Ambiente de banco de dados e arquivos locais zerados!');
  _info('');
  _info('Se estiver testando em dispositivos móveis/emuladores, limpe os dados locais:');
  _info('  • Android Emulator: adb shell pm clear com.fincore.food');
  _info('  • iOS Simulator   : Vá em Hardware -> Erase All Content and Settings');
  _info('');
  _info('Para recriar a estrutura de tabelas do zero no Supabase/Local, execute:');
  _info('  dart run bin/main.dart --apply-migrations');
  _info('');
  _info('Após recriar as tabelas, lembre-se de rodar os scripts de sincronismo:');
  _info('  dart run fix_schema.dart');
  _info('  dart run fix_sync.dart');
  _info('');
  _info('Pronto para um novo ciclo de testes limpos! 🚀');
}

Future<void> _resetDatabase({
  required String name,
  required String host,
  required int port,
  required String database,
  required String user,
  required String password,
  required SslMode sslMode,
}) async {
  _step('Iniciando limpeza do $name...');
  late Connection conn;

  try {
    conn = await Connection.open(
      Endpoint(host: host, port: port, database: database, username: user, password: password),
      settings: ConnectionSettings(sslMode: sslMode, connectTimeout: const Duration(seconds: 5)),
    );
  } catch (e) {
    _aviso('   ⚠️ Não foi possível conectar ao $name: $e');
    _aviso('   Saltando limpeza deste banco.');
    return;
  }

  try {
    await conn.execute('SET session_replication_role = replica;');

    // Drop tables
    final tablesRes = await conn.execute('''
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    ''');
    
    int tablesCount = 0;
    for (final row in tablesRes) {
      final tab = row[0] as String;
      await conn.execute('DROP TABLE IF EXISTS public."$tab" CASCADE;');
      tablesCount++;
    }

    // Drop views
    final viewsRes = await conn.execute('''
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_type = 'VIEW'
    ''');
    
    for (final row in viewsRes) {
      final view = row[0] as String;
      await conn.execute('DROP VIEW IF EXISTS public."$view" CASCADE;');
      tablesCount++;
    }

    await conn.execute('SET session_replication_role = DEFAULT;');
    _ok('   ✅ Limpeza concluída: $tablesCount tabelas/views dropadas no $name.');
  } catch (e) {
    _erro('   ❌ Erro ao limpar tabelas do $name: $e');
  } finally {
    await conn.close();
  }
}

Future<void> _resetLocalSQLite() async {
  _step('Iniciando limpeza de arquivos locais do Windows...');
  final userProfile = Platform.environment['USERPROFILE'];
  if (userProfile == null) {
    _aviso('   ⚠️ USERPROFILE não encontrado. Saltando remoção de arquivos locais.');
    return;
  }

  // Caminhos prováveis do banco Drift local no Windows
  final paths = [
    p.join(userProfile, 'Documents', 'fincore_v3.db'),
    p.join(userProfile, 'Documents', 'fincore_v3.db-journal'),
    p.join(userProfile, 'Documents', 'fincore_v3.db-shm'),
    p.join(userProfile, 'Documents', 'fincore_v3.db-wal'),
  ];

  int deleted = 0;
  for (final path in paths) {
    final file = File(path);
    if (await file.exists()) {
      try {
        await file.delete();
        _ok('   ✅ Arquivo local removido: $path');
        deleted++;
      } catch (e) {
        _erro('   ❌ Erro ao remover arquivo local $path: $e');
      }
    }
  }

  if (deleted == 0) {
    _info('   ℹ️ Nenhum arquivo SQLite local (fincore_v3.db) foi encontrado na pasta de Documentos.');
  }
}

// ── Helpers de output ────────────────────────────────────────────────────────
void _header(String msg) => print('\n╔══ $msg ══╗');
void _step(String msg)   => print('\n➜  $msg');
void _ok(String msg)     => print('   $msg');
void _aviso(String msg)  => print('   $msg');
void _info(String msg)   => print('   $msg');
void _erro(String msg)   => print('   ✗ $msg');
