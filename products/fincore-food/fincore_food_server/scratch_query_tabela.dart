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

  final tabelaId = 'b16a5eea-e713-4d92-ad9a-bdadeabc1f56';

  print('\n=== BANCO REMOTO: produto_tabela_precificacao ===');
  final prodRows = await connection.execute(
    'SELECT * FROM produto_tabela_precificacao WHERE "tabelaPrecificacaoId" = \$1',
    parameters: [tabelaId],
  );
  if (prodRows.isEmpty) {
    print('Nenhum vínculo direto com produto encontrado na nuvem para a tabela $tabelaId.');
  } else {
    for (final row in prodRows) {
      print('Vínculo Produto: ID: ${row[0]} | ProdutoID: ${row[2]} | TabelaID: ${row[3]} | Ativo: ${row[4]}');
    }
  }

  print('\n=== BANCO REMOTO: categoria_tabela_precificacao ===');
  // Nota: vamos verificar se a tabela é categoria_tabela_precificacao
  try {
    final catRows = await connection.execute(
      'SELECT * FROM categoria_tabela_precificacao WHERE "tabelaPrecificacaoId" = \$1',
      parameters: [tabelaId],
    );
    if (catRows.isEmpty) {
      print('Nenhum vínculo com categoria encontrado na nuvem para a tabela $tabelaId.');
    } else {
      for (final row in catRows) {
        print('Vínculo Categoria: ID: ${row[0]} | CategoriaID: ${row[2]} | TabelaID: ${row[3]} | Ativo: ${row[4]}');
      }
    }
  } catch (e) {
    print('Erro ao consultar categoria_tabela_precificacao na nuvem: $e');
  }

  await connection.close();
}
