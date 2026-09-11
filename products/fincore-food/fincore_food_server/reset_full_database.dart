// ═══════════════════════════════════════════════════════════════════════════
// FINCORE Food — Reset Total do Banco Supabase
// ⚠️  OPERAÇÃO DESTRUTIVA — apaga TODOS os dados de negócio + Serverpod
// ═══════════════════════════════════════════════════════════════════════════
//
// Uso:
//   cd fincore_food_server
//   dart run reset_full_database.dart
//
// O que faz:
//   1. Conecta diretamente no PostgreSQL do Supabase
//   2. Apaga TODOS os dados de negócio (truncate em cascata)
//   3. Limpa as tabelas de infraestrutura do Serverpod
//   4. Reseta a versão de migration para forçar re-aplicação
//   5. Exibe contagem final de cada tabela para confirmar o reset
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:postgres/postgres.dart';

// ── Credenciais de Desenvolvimento ──────────────────────────────────────────
const _host     = 'db.nlaxdeqbordmovukyypk.supabase.co';
const _port     = 5432;
const _database = 'postgres';
const _user     = 'postgres';
const _password = 'GeR9cjvrXrujvL0R';

// ── Tabelas de negócio na ordem correta de FK (filhas antes das mães) ───────
const _tabelasNegocio = [
  // Financeiro e caixa
  'lancamento_financeiro',
  'sessao_caixa',

  // Estoque
  'movimentacao_estoque',
  'estoque_produto',

  // Produção / KDS
  'lote_insumo',
  'ordem_preparo',
  'print_job',

  // Pedidos
  'item_pedido',
  'pedido',

  // Clientes e entregas
  'local_entrega',
  'cliente',

  // Precificação
  'produto_tabela_precificacao',
  'categoria_tabela_precificacao',
  'item_tabela_precificacao',
  'tabela_precificacao',

  // Catálogo
  'produto',
  'categoria',

  // Formas de pagamento e taxa de entrega
  'forma_pagamento',
  'taxa_entrega',

  // Rotas / cache
  'route_cache',

  // IAM / Empresa
  'audit_log',
  'empresa_convite',
  'membro_empresa',
  'empresa_configuracao',
  'empresa',
  'usuario',
];

// ── Tabelas de infraestrutura do Serverpod ───────────────────────────────────
const _tabelasServerpod = [
  'serverpod_query_log',
  'serverpod_message_log',
  'serverpod_log',
  'serverpod_session_log',
  'serverpod_future_call',
  'serverpod_health_connection_info',
  'serverpod_health_metric',
  'serverpod_cloud_storage',
  'serverpod_cloud_storage_direct_upload',
  'serverpod_readwrite_test',
  'serverpod_runtime_settings',
  'serverpod_method',
  'serverpod_migrations',
];

void main() async {
  _header('FINCORE FOOD — RESET TOTAL DO BANCO SUPABASE');
  _aviso('⚠️  Esta operação apagará TODOS os dados do banco remoto!');
  _aviso('    Banco: $_host / $_database');
  _aviso('');
  _aviso('Pressione ENTER para confirmar ou Ctrl+C para cancelar...');
  stdin.readLineSync(); // aguarda ENTER

  late Connection conn;

  try {
    _step('Conectando ao banco PostgreSQL...');
    conn = await Connection.open(
      Endpoint(
        host: _host,
        port: _port,
        database: _database,
        username: _user,
        password: _password,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.require),
    );
    _ok('Conexão estabelecida!');
  } catch (e) {
    _erro('Falha ao conectar: $e');
    return;
  }

  try {
    // ────────────────────────────────────────────────────────────────────────
    // FASE 1: Desabilitar triggers e FKs para permitir truncate livre
    // ────────────────────────────────────────────────────────────────────────
    _step('Fase 1 — Desabilitando triggers e foreign key checks...');
    await conn.execute('SET session_replication_role = replica;');
    _ok('Triggers e FKs desabilitados para o reset.');

    // ────────────────────────────────────────────────────────────────────────
    // FASE 2: Dropar dinamicamente todas as tabelas do schema public
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
    
    // Dropar views também, se existirem
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
    // FASE 3: Dropar as tabelas do Serverpod que porventura estejam no schema public ou default
    // ────────────────────────────────────────────────────────────────────────
    _header('Fase 3 — Dropando tabelas do Serverpod no schema principal...');
    for (final tabela in _tabelasServerpod) {
      try {
        await conn.execute('DROP TABLE IF EXISTS "$tabela" CASCADE;');
        _ok('  ✅ Serverpod $tabela → dropada');
      } catch (e) {
        _erro('  ❌ Erro ao dropar $tabela: $e');
      }
    }

    // ────────────────────────────────────────────────────────────────────────
    // FASE 4: Reabilitar replication role
    // ────────────────────────────────────────────────────────────────────────
    _step('Fase 4 — Reabilitando triggers e FKs...');
    await conn.execute('SET session_replication_role = DEFAULT;');
    _ok('Triggers e FKs reabilitados.');

    // ────────────────────────────────────────────────────────────────────────
    // FASE 5: Verificação final — contar linhas em cada tabela de negócio
    // ────────────────────────────────────────────────────────────────────────
    _header('Fase 5 — Verificação final das contagens...');
    bool tudoVazio = true;

    for (final tabela in _tabelasNegocio) {
      try {
        final res = await conn.execute('SELECT COUNT(*) FROM public."$tabela"');
        final count = res.first[0] as int;
        if (count > 0) {
          _aviso('  ⚠️  $tabela → $count registros (NÃO VAZIA!)');
          tudoVazio = false;
        } else {
          _ok('  ✅ $tabela → 0 registros');
        }
      } catch (_) {
        // Tabela não existe — ok, não é crítico
      }
    }

    // ────────────────────────────────────────────────────────────────────────
    // FASE 6: Instruções para re-aplicar migrations
    // ────────────────────────────────────────────────────────────────────────
    _header('Próximos passos');
    if (tudoVazio) {
      _ok('🎉 Banco completamente zerado!');
      _info('');
      _info('Para re-aplicar as migrations do Serverpod, execute:');
      _info('  cd fincore_food_server');
      _info('  dart run bin\\main.dart --apply-migrations');
      _info('');
      _info('Em seguida, execute o seed de dados de teste:');
      _info('  dart run seed_test_data.dart');
    } else {
      _aviso('⚠️  Algumas tabelas ainda têm dados. Verifique os erros acima.');
    }

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
