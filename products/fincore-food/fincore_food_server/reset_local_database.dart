// ═══════════════════════════════════════════════════════════════════════════
// FINCORE Food — Reset Total do Banco LOCAL (Docker PostgreSQL porta 8090)
// ⚠️  OPERAÇÃO DESTRUTIVA — apaga TODOS os dados
// ═══════════════════════════════════════════════════════════════════════════
//
// Uso:
//   cd fincore_food_server
//   dart run reset_local_database.dart
//
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:postgres/postgres.dart';

// ── Credenciais do banco LOCAL (Docker) ─────────────────────────────────────
const _host     = 'localhost';
const _port     = 8090;
const _database = 'fincore_food';
const _user     = 'postgres';
const _password = '-nijjTTsE4w_s9T_lJUH1WE62wnU4ZO5';

void main() async {
  _header('FINCORE FOOD — RESET TOTAL DO BANCO LOCAL (Docker :8090)');
  _aviso('⚠️  Esta operação apagará TODOS os dados do banco local!');
  _aviso('    Banco: $_host:$_port / $_database');
  _aviso('');
  _aviso('Pressione ENTER para confirmar ou Ctrl+C para cancelar...');
  stdin.readLineSync();

  late Connection conn;

  try {
    _step('Conectando ao banco PostgreSQL local...');
    conn = await Connection.open(
      Endpoint(
        host: _host,
        port: _port,
        database: _database,
        username: _user,
        password: _password,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
    _ok('Conexão estabelecida!');
  } catch (e) {
    _erro('Falha ao conectar: $e');
    _aviso('');
    _aviso('Certifique-se de que o Docker está rodando e o container postgres está ativo.');
    _aviso('Execute: docker compose up -d postgres');
    return;
  }

  try {
    // ────────────────────────────────────────────────────────────────────────
    // FASE 1: Desabilitar triggers e FKs
    // ────────────────────────────────────────────────────────────────────────
    _step('Fase 1 — Desabilitando triggers e foreign key checks...');
    await conn.execute('SET session_replication_role = replica;');
    _ok('Triggers e FKs desabilitados para o reset.');

    // ────────────────────────────────────────────────────────────────────────
    // FASE 2: Dropar todas as tabelas do schema public
    // ────────────────────────────────────────────────────────────────────────
    _header('Fase 2 — Dropando dinamicamente todas as tabelas do schema public...');

    final tablesRes = await conn.execute('''
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    ''');

    int tabelasLimpas = 0;
    for (final row in tablesRes) {
      final tabela = row[0] as String;
      try {
        await conn.execute('DROP TABLE IF EXISTS public."$tabela" CASCADE;');
        _ok('  ✅ Tabela $tabela → dropada');
        tabelasLimpas++;
      } catch (e) {
        _erro('  ❌ Erro ao dropar tabela $tabela: $e');
      }
    }

    // Dropar views também
    final viewsRes = await conn.execute('''
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_type = 'VIEW'
    ''');

    for (final row in viewsRes) {
      final view = row[0] as String;
      try {
        await conn.execute('DROP VIEW IF EXISTS public."$view" CASCADE;');
        _ok('  ✅ View $view → dropada');
        tabelasLimpas++;
      } catch (e) {
        _erro('  ❌ Erro ao dropar view $view: $e');
      }
    }

    _ok('$tabelasLimpas tabelas e views dropadas no total.');

    // ────────────────────────────────────────────────────────────────────────
    // FASE 3: Reabilitar replication role
    // ────────────────────────────────────────────────────────────────────────
    _step('Fase 3 — Reabilitando triggers e FKs...');
    await conn.execute('SET session_replication_role = DEFAULT;');
    _ok('Triggers e FKs reabilitados.');

    // ────────────────────────────────────────────────────────────────────────
    // FASE 4: Verificação — confirmar schema vazio
    // ────────────────────────────────────────────────────────────────────────
    _header('Fase 4 — Verificação final...');
    final checkRes = await conn.execute('''
      SELECT COUNT(*) FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    ''');
    final remaining = checkRes.first[0] as int;

    if (remaining == 0) {
      _ok('🎉 Schema public completamente vazio!');
    } else {
      _aviso('⚠️  Ainda restam $remaining tabelas no schema public.');
    }

    // ────────────────────────────────────────────────────────────────────────
    // FASE 5: Próximos passos
    // ────────────────────────────────────────────────────────────────────────
    _header('Próximos passos');
    _ok('🎉 Banco local completamente zerado!');
    _info('');
    _info('Para re-aplicar as migrations do Serverpod, execute:');
    _info('  cd fincore_food_server');
    _info('  dart run bin\\main.dart --apply-migrations');
    _info('');
    _info('Em seguida, execute o seed de dados de teste:');
    _info('  dart run seed_test_data.dart');

  } catch (e, st) {
    _erro('Erro durante o reset: $e');
    _erro('Stack: $st');
    try {
      await conn.execute('SET session_replication_role = DEFAULT;');
    } catch (_) {}
  } finally {
    await conn.close();
    _ok('Conexão fechada.');
  }
}

// ── Helpers de output ────────────────────────────────────────────────────────
void _header(String msg) => print('\n╔══ $msg ══╗');
void _step(String msg)   => print('\n➜  $msg');
void _ok(String msg)     => print('   $msg');
void _aviso(String msg)  => print('   $msg');
void _info(String msg)   => print('   $msg');
void _erro(String msg)   => print('   ✗ $msg');
