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

  print('Executando DDL em estoque_produto e movimentacao_estoque...');
  try {
    await connection.execute('ALTER TABLE "estoque_produto" ADD COLUMN IF NOT EXISTS "quantidadeSeguranca" integer DEFAULT 0');
    await connection.execute('ALTER TABLE "estoque_produto" ADD COLUMN IF NOT EXISTS "quantidadeCritica" integer DEFAULT 0');
    await connection.execute('ALTER TABLE "estoque_produto" ADD COLUMN IF NOT EXISTS "capacidadeCampanha" integer DEFAULT 0');
    await connection.execute('ALTER TABLE "estoque_produto" ADD COLUMN IF NOT EXISTS "tempoPreparacao" integer DEFAULT 0');
    await connection.execute('ALTER TABLE "estoque_produto" ADD COLUMN IF NOT EXISTS "estrategiaProducao" text DEFAULT \'concentrada\'');

    await connection.execute('ALTER TABLE "movimentacao_estoque" ADD COLUMN IF NOT EXISTS "dataEntregaPrevista" timestamp without time zone');

    print('Notificando PostgREST para limpar o cache de schema (NOTIFY pgrst, \'reload schema\')...');
    await connection.execute("NOTIFY pgrst, 'reload schema'");
    print('Notificação enviada com sucesso!');
  } catch (e) {
    print('Erro ao executar DDL ou notificar: $e');
  }

  print('\nVerificando colunas da tabela "estoque_produto"...');
  try {
    final rows = await connection.execute(
      "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'estoque_produto'"
    );
    for (final row in rows) {
      print('  Coluna: ${row[0]} | Tipo: ${row[1]}');
    }
  } catch (e) {
    print('Erro ao listar colunas: $e');
  }

  await connection.close();
}
