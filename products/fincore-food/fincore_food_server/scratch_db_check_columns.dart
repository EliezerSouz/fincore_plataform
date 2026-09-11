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

  final tables = [
    'membro_empresa',
    'estoque_produto',
    'movimentacao_estoque',
    'sessao_caixa',
    'lancamento_financeiro',
    'pedido',
    'item_pedido',
    'usuarios'
  ];

  print('\n=== VERIFICANDO COLUNAS ===');
  for (final table in tables) {
    final rows = await connection.execute('''
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_schema = 'public' 
        AND table_name = \$1 
        AND column_name IN ('tenantId', 'usuarioId', 'userId', 'activeTenantId')
    ''', parameters: [table]);
    
    print('Tabela: $table');
    if (rows.isEmpty) {
      print('  Nenhuma coluna correspondente encontrada.');
    } else {
      for (final row in rows) {
        print('  Coluna: ${row[0]} | Tipo: ${row[1]}');
      }
    }
  }

  await connection.close();
}
