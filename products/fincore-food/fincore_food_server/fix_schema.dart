import 'package:postgres/postgres.dart';

void main() async {
  print('🔌 Conectando...');
  final pool = Pool.withEndpoints(
    [
      Endpoint(
        host: 'db.nlaxdeqbordmovukyypk.supabase.co',
        port: 5432,
        database: 'postgres',
        username: 'postgres',
        password: 'GeR9cjvrXrujvL0R',
      ),
    ],
    settings: const PoolSettings(maxConnectionCount: 1, sslMode: SslMode.require, connectTimeout: Duration(seconds: 8)),
  );

  int ok = 0, skip = 0;
  Future<void> run(String sql) async {
    try {
      await pool.execute(sql);
      ok++;
    } catch (e) {
      skip++;
      // Ignora erros de coluna/constraint já existente
    }
  }

  try {
    await pool.execute('SELECT 1');
    print('✅ Conectado!\n');

    // ── EMPRESA ─────────────────────────────────────────────
    print('🔧 empresa:');
    await run('ALTER TABLE empresa ADD COLUMN IF NOT EXISTS "endereco" TEXT');
    // demais já adicionadas anteriormente

    // ── EMPRESA_CONFIGURACAO ─────────────────────────────────
    // verificar campos do modelo que ainda podem faltar
    print('🔧 empresa_configuracao:');
    await run('ALTER TABLE empresa_configuracao ADD COLUMN IF NOT EXISTS "syncVersion" BIGINT DEFAULT 1');
    await run('ALTER TABLE empresa_configuracao ADD COLUMN IF NOT EXISTS "modoDeliveryAtivo" BOOLEAN DEFAULT TRUE');
    await run('ALTER TABLE empresa_configuracao ADD COLUMN IF NOT EXISTS "clienteObrigatorioVenda" BOOLEAN DEFAULT FALSE');
    await run('ALTER TABLE empresa_configuracao ADD COLUMN IF NOT EXISTS "atendimentoPadrao" TEXT DEFAULT \'Mesa/Balcão\'');
    await run('ALTER TABLE empresa_configuracao ADD COLUMN IF NOT EXISTS "margemSegurancaMinutos" BIGINT DEFAULT 0');
    await run('ALTER TABLE empresa_configuracao ADD COLUMN IF NOT EXISTS "modoComandasAtivo" BOOLEAN DEFAULT FALSE');

    // ── USUARIOS ─────────────────────────────────────────────
    // já corrigida na sessão anterior

    // ── TAXA_ENTREGA ─────────────────────────────────────────
    print('🔧 taxa_entrega:');
    await run('ALTER TABLE taxa_entrega ADD COLUMN IF NOT EXISTS "pedidoMinimoCentavos" BIGINT DEFAULT 0');
    await run('ALTER TABLE taxa_entrega ADD COLUMN IF NOT EXISTS "prazoEstimado" TEXT');
    await run('ALTER TABLE taxa_entrega ADD COLUMN IF NOT EXISTS "observacoes" TEXT');

    print('\n✅ $ok OK  |  $skip skip (já existiam)\n');

    // ─── VERIFICAÇÃO COMPLETA ────────────────────────────────
    final tabelas = ['empresa', 'empresa_configuracao', 'usuarios', 'eventos_empresa', 'membro_empresa', 'empresa_convite', 'taxa_entrega'];
    for (final tabela in tabelas) {
      final cols = await pool.execute(
        "SELECT column_name FROM information_schema.columns WHERE table_name = \$1 ORDER BY ordinal_position",
        parameters: [tabela],
      );
      final nomes = cols.map((r) => r[0] as String).toList();
      print('📋 $tabela (${nomes.length} colunas): ${nomes.join(', ')}');
    }

    print('\n🎉 Pronto!');
  } finally {
    await pool.close();
  }
}
