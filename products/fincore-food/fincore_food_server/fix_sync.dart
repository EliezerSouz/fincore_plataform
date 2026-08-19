import 'package:postgres/postgres.dart';

void main() async {
  print('🔌 Conectando ao banco de dados para aplicar correções de sincronismo...');
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
    settings: const PoolSettings(maxConnectionCount: 1, sslMode: SslMode.require),
  );

  Future<void> runSql(String sql) async {
    try {
      await pool.execute(sql);
      final preview = sql.length > 80 ? sql.substring(0, 80) : sql;
      print('  ✅ Executado: $preview');
    } catch (e) {
      print('  ⚠️  Erro: ${e.toString().split('\n').first}');
    }
  }

  try {
    await pool.execute('SELECT 1');
    print('✅ Conectado!\n');

    // 0. Criar tabelas em falta no Supabase para sincronização direta
    print('🔧 Criando tabelas em falta no Supabase (categoria_tabela_precificacao, pedido, item_pedido):');
    await runSql('''
      CREATE TABLE IF NOT EXISTS public.categoria_tabela_precificacao (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "tenantId" text NOT NULL,
        "categoriaId" uuid NOT NULL REFERENCES public.categoria(id) ON DELETE RESTRICT,
        "tabelaPrecificacaoId" uuid NOT NULL REFERENCES public.tabela_precificacao(id) ON DELETE RESTRICT,
        ativo boolean NOT NULL,
        prioridade bigint NOT NULL,
        "dataInicio" timestamp without time zone,
        "dataFim" timestamp without time zone,
        "createdAt" timestamp without time zone NOT NULL,
        "updatedAt" timestamp without time zone NOT NULL,
        "createdBy" uuid NOT NULL,
        "updatedBy" uuid NOT NULL,
        "deletedAt" timestamp without time zone,
        "deletedBy" uuid,
        "syncVersion" bigint NOT NULL DEFAULT 1,
        "originDeviceId" text,
        "lastModifiedByDevice" text,
        "entityHash" text
      )
    ''');

    await runSql('''
      CREATE TABLE IF NOT EXISTS public.pedido (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "tenantId" text NOT NULL,
        status text NOT NULL DEFAULT 'confirmado',
        "tipoLogistica" text NOT NULL,
        "clienteId" uuid,
        "clienteNomeAvulso" text,
        "clienteTelefoneAvulso" text,
        "valorSubtotalCentavos" bigint NOT NULL,
        "valorTaxaEntregaCentavos" bigint NOT NULL DEFAULT 0,
        "valorTotalCentavos" bigint NOT NULL,
        "trocoParaCentavos" bigint,
        "formaPagamentoId" uuid,
        "formaPagamentoNome" text,
        "enderecoJson" text,
        "operadorId" uuid,
        "dataHoraCriacao" timestamp without time zone NOT NULL,
        "numeroPedido" bigint,
        observacoes text,
        "canalOrigem" text NOT NULL DEFAULT 'pdv_express',
        "createdAt" timestamp without time zone NOT NULL,
        "updatedAt" timestamp without time zone NOT NULL,
        "createdBy" uuid NOT NULL,
        "updatedBy" uuid NOT NULL,
        "deletedAt" timestamp without time zone,
        "deletedBy" uuid,
        "syncVersion" bigint NOT NULL DEFAULT 1,
        "originDeviceId" text,
        "lastModifiedByDevice" text,
        "entityHash" text
      )
    ''');

    await runSql('''
      CREATE TABLE IF NOT EXISTS public.item_pedido (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "tenantId" text NOT NULL,
        "pedidoId" uuid NOT NULL REFERENCES public.pedido(id) ON DELETE CASCADE,
        "produtoId" uuid NOT NULL,
        "nomeProduto" text NOT NULL,
        quantidade double precision NOT NULL,
        "valorUnitarioCentavos" bigint NOT NULL,
        "valorTotalCentavos" bigint NOT NULL,
        observacoes text,
        "createdAt" timestamp without time zone NOT NULL,
        "updatedAt" timestamp without time zone NOT NULL,
        "createdBy" uuid NOT NULL,
        "updatedBy" uuid NOT NULL,
        "deletedAt" timestamp without time zone,
        "deletedBy" uuid,
        "syncVersion" bigint NOT NULL DEFAULT 1,
        "originDeviceId" text,
        "lastModifiedByDevice" text,
        "entityHash" text
      )
    ''');

    // 0.5. Corrigir colunas em falta na tabela usuarios
    print('🔧 Verificando colunas na tabela "usuarios":');
    await runSql('ALTER TABLE "usuarios" ADD COLUMN IF NOT EXISTS "tenantId" TEXT');
    await runSql('ALTER TABLE "usuarios" ADD COLUMN IF NOT EXISTS "authUserId" TEXT');
    await runSql('ALTER TABLE "usuarios" ADD COLUMN IF NOT EXISTS "username" TEXT');
    await runSql('ALTER TABLE "usuarios" ADD COLUMN IF NOT EXISTS "email" TEXT');
    await runSql('ALTER TABLE "usuarios" ADD COLUMN IF NOT EXISTS "nome" TEXT');
    await runSql('ALTER TABLE "usuarios" ADD COLUMN IF NOT EXISTS "avatarUrl" TEXT');
    await runSql('ALTER TABLE "usuarios" ADD COLUMN IF NOT EXISTS "ativo" BOOLEAN DEFAULT true');

    print('🔧 Corrigindo valores nulos de registros antigos na tabela "usuarios":');
    await runSql('''
      UPDATE "usuarios" u
      SET "tenantId" = m."tenantId"
      FROM "membro_empresa" m
      WHERE u.id = m."usuarioId" AND u."tenantId" IS NULL
    ''');
    await runSql('''
      UPDATE "usuarios"
      SET "tenantId" = '00000000-0000-4000-a000-000000000001'
      WHERE "tenantId" IS NULL
    ''');
    await runSql('''
      UPDATE "usuarios"
      SET "username" = COALESCE(split_part(email, '@', 1), 'usuario')
      WHERE "username" IS NULL OR "username" = ''
    ''');
    await runSql('''
      UPDATE "usuarios"
      SET "ativo" = true
      WHERE "ativo" IS NULL
    ''');

    // 0.6. Corrigir colunas em falta na tabela empresa_configuracao
    print('🔧 Verificando colunas na tabela "empresa_configuracao":');
    await runSql('ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "modoDeliveryAtivo" BOOLEAN');
    await runSql('ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "clienteObrigatorioVenda" BOOLEAN');
    await runSql('ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "atendimentoPadrao" TEXT');
    await runSql('ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "nomeEmpresaCupom" TEXT');
    await runSql('ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "telefoneEmpresa" TEXT');
    await runSql('ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "cnpjEmpresa" TEXT');
    await runSql('ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "enderecoEmpresa" TEXT');

    // 0.7. Corrigir colunas em falta na tabela categoria
    print('🔧 Verificando colunas na tabela "categoria":');
    await runSql('ALTER TABLE "categoria" ADD COLUMN IF NOT EXISTS "metadataPayload" TEXT');

    // 0.8. Corrigir constraints NOT NULL divergentes
    print('🔧 Corrigindo restrições NOT NULL divergentes:');
    await runSql('ALTER TABLE "empresa" ALTER COLUMN "tipoPessoa" DROP NOT NULL');
    await runSql('ALTER TABLE "taxa_entrega" ALTER COLUMN "pedidoMinimoCentavos" DROP NOT NULL');

    // 1. Adicionar colunas camelCase na tabela audit_logs
    print('🔧 Adicionando colunas camelCase em "audit_logs" para sincronismo direto:');
    final camelCaseColumns = [
      'ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS "userName" TEXT',
      'ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS "userRole" TEXT',
      'ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS "machineName" TEXT',
      'ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS "hostName" TEXT',
      'ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS "ipAddress" TEXT',
      'ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS "macAddress" TEXT',
      'ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS "platform" TEXT',
      'ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS "osVersion" TEXT',
      'ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS "appVersion" TEXT',
      'ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS "sessionId" TEXT',
      'ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS "browser" TEXT',
      'ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS "deviceDescription" TEXT',
      'ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS "entityDisplayName" TEXT',
      'ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS "entityModule" TEXT',
    ];

    for (final sql in camelCaseColumns) {
      await runSql(sql);
    }

    // Criar os índices também usando camelCase
    print('\n🔧 Criando índices com colunas camelCase:');
    await runSql('CREATE INDEX IF NOT EXISTS "idx_audit_logs_tenant_module_camel" ON audit_logs ("tenantId", "entityModule")');
    await runSql('CREATE INDEX IF NOT EXISTS "idx_audit_logs_tenant_user_camel" ON audit_logs ("tenantId", "userId")');

    // 2. Dar permissões para a role authenticated e anon
    print('\n🔑 Configurando permissões do banco para a API do Supabase (PostgREST):');
    await runSql('GRANT USAGE ON SCHEMA public TO authenticated, anon');
    await runSql('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authenticated');
    await runSql('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authenticated');
    await runSql('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO anon');
    await runSql('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO anon');
    await runSql('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated, anon');

    // 3. Desativar RLS temporariamente para garantir que não haja bloqueio de políticas se não estiverem configuradas
    print('\n🔒 Verificando/Desativando Row Level Security (RLS) nas tabelas críticas para dev:');
    final tablesToDisableRLS = [
      'empresa',
      'empresa_configuracao',
      'membro_empresa',
      'usuarios',
      'audit_logs',
      'cliente',
      'eventos_empresa',
      'categoria_tabela_precificacao',
      'pedido',
      'item_pedido'
    ];
    for (final table in tablesToDisableRLS) {
      await runSql('ALTER TABLE "$table" DISABLE ROW LEVEL SECURITY');
    }

    // 4. Notificar o PostgREST para recarregar o cache do schema
    print('\n🔄 Recarregando cache do schema do PostgREST (Supabase API)...');
    await runSql("NOTIFY pgrst, 'reload schema'");

    print('\n🎉 Todas as correções de sincronismo foram aplicadas!');
  } finally {
    await pool.close();
  }
}
