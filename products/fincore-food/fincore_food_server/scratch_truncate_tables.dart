import 'package:postgres/postgres.dart';

const _tabelasNegocio = [
  'lancamento_financeiro',
  'sessao_caixa',
  'movimentacao_estoque',
  'estoque_produto',
  'lote_insumo',
  'ordem_preparo',
  'print_job',
  'item_pedido',
  'pedido',
  'local_entrega',
  'cliente',
  'produto_tabela_precificacao',
  'categoria_tabela_precificacao',
  'item_tabela_precificacao',
  'tabela_precificacao',
  'produto',
  'categoria',
  'forma_pagamento',
  'taxa_entrega',
  'route_cache',
  'audit_logs',
  'empresa_convite',
  'membro_empresa',
  'empresa_configuracao',
  'empresa',
  'usuarios',
];

void main() async {
  print('🔌 Conectando ao banco PostgreSQL...');
  final conn = await Connection.open(
    Endpoint(
      host: 'db.nlaxdeqbordmovukyypk.supabase.co',
      port: 5432,
      database: 'postgres',
      username: 'postgres',
      password: 'GeR9cjvrXrujvL0R',
    ),
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );
  print('✅ Conexão estabelecida!');

  try {
    print('Fase 1 — Desabilitando triggers e foreign key checks...');
    await conn.execute('SET session_replication_role = replica;');
    print('Triggers e FKs desabilitados para o reset.');

    print('Fase 2 — Truncando tabelas de negócio...');
    for (final tabela in _tabelasNegocio) {
      try {
        await conn.execute('TRUNCATE TABLE public."$tabela" CASCADE;');
        print('  ✅ Tabela $tabela → truncada');
      } catch (e) {
        print('  ❌ Erro ao truncar tabela $tabela: $e');
      }
    }

    print('Fase 3 — Reabilitando triggers e FKs...');
    await conn.execute('SET session_replication_role = DEFAULT;');
    print('Triggers e FKs reabilitados.');

    print('🎉 Tabelas de negócio limpas com sucesso!');
  } catch (e) {
    print('❌ Erro geral: $e');
  } finally {
    await conn.close();
    print('Conexão fechada.');
  }
}
