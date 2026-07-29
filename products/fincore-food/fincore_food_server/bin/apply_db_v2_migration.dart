import 'package:postgres/postgres.dart';

void main() async {
  print('--- Supabase Database Refactoring (v2.0 Architecture) ---');
  
  final host = 'db.nlaxdeqbordmovukyypk.supabase.co';
  final port = 5432;
  final database = 'postgres';
  final username = 'postgres';
  final password = 'GeR9cjvrXrujvL0R';

  print('Connecting to Supabase at $host:$port...');
  final conn = await Connection.open(
    Endpoint(
      host: host,
      port: port,
      database: database,
      username: username,
      password: password,
    ),
    settings: const ConnectionSettings(
      sslMode: SslMode.require,
    ),
  );

  print('Database connected successfully!');

  // Tabelas que participam do sync e auditoria
  final syncTables = [
    'empresa',
    'categoria',
    'produto',
    'cliente',
    'forma_pagamento',
    'local_entrega',
    'taxa_entrega',
    'tabela_precificacao',
    'item_tabela_precificacao',
    'produto_tabela_precificacao',
    'empresa_configuracao',
    'membro_empresa',
  ];

  try {
    // -------------------------------------------------------------
    // FASE 1: Alterar colunas de data para "timestamptz" (TimeZone)
    // -------------------------------------------------------------
    print('\n[1/5] Alterando colunas de timestamp para "timestamptz"...');
    
    // Lista explícita de tabela -> colunas de data
    final dateColumns = {
      'usuarios': ['criadoEm', 'atualizadoEm'],
      'eventos_empresa': ['ocorridoEm'],
      'audit_logs': ['timestamp'],
      'empresa': ['createdAt', 'updatedAt', 'deletedAt', 'vencimento'],
      'empresa_configuracao': ['createdAt', 'updatedAt', 'deletedAt'],
      'membro_empresa': ['convidadoEm', 'aceitoEm', 'createdAt', 'updatedAt', 'deletedAt'],
      'categoria': ['createdAt', 'updatedAt', 'deletedAt'],
      'produto': ['createdAt', 'updatedAt', 'deletedAt'],
      'cliente': ['createdAt', 'updatedAt', 'deletedAt', 'dataNascimento'],
      'forma_pagamento': ['createdAt', 'updatedAt', 'deletedAt'],
      'local_entrega': ['createdAt', 'updatedAt', 'deletedAt'],
      'taxa_entrega': ['createdAt', 'updatedAt', 'deletedAt'],
      'tabela_precificacao': ['createdAt', 'updatedAt', 'deletedAt', 'vigenciaInicio', 'vigenciaFim'],
      'item_tabela_precificacao': ['createdAt', 'updatedAt', 'deletedAt'],
      'produto_tabela_precificacao': ['createdAt', 'updatedAt', 'deletedAt', 'dataInicio', 'dataFim'],
    };

    for (final entry in dateColumns.entries) {
      final table = entry.key;
      for (final col in entry.value) {
        print('  - $table.$col ➔ timestamptz');
        await conn.execute('ALTER TABLE "$table" ALTER COLUMN "$col" TYPE timestamptz USING "$col" AT TIME ZONE \'UTC\';');
      }
    }
    print('  ✓ Timestamps convertidos!');

    // -------------------------------------------------------------
    // FASE 2: Criar Triggers de Automatização no PostgreSQL
    // -------------------------------------------------------------
    print('\n[2/5] Configurando Triggers de "syncVersion" e "updatedAt"...');
    
    // 1. Cria a função que auto-incrementa syncVersion e define updatedAt para UTC
    await conn.execute('''
      CREATE OR REPLACE FUNCTION auto_handle_sync_and_updated_at()
      RETURNS TRIGGER AS \$\$
      BEGIN
        NEW."syncVersion" = OLD."syncVersion" + 1;
        NEW."updatedAt" = NOW() AT TIME ZONE 'utc';
        RETURN NEW;
      END;
      \$\$ LANGUAGE plpgsql;
    ''');
    print('  ✓ Função plpgsql criada!');

    // 2. Aplica a trigger a cada tabela
    for (final table in syncTables) {
      final triggerName = 'trg_${table}_sync_update';
      print('  - Criando trigger para: $table');
      await conn.execute('DROP TRIGGER IF EXISTS "$triggerName" ON "$table";');
      await conn.execute('''
        CREATE TRIGGER "$triggerName"
        BEFORE UPDATE ON "$table"
        FOR EACH ROW
        WHEN (OLD.* IS DISTINCT FROM NEW.*) -- Executa apenas se houver mudanças reais
        EXECUTE FUNCTION auto_handle_sync_and_updated_at();
      ''');
    }
    print('  ✓ Triggers ativas!');

    // -------------------------------------------------------------
    // FASE 3: Unique constraint em configuração da empresa
    // -------------------------------------------------------------
    print('\n[3/5] Aplicando Unique constraint em empresa_configuracao("tenantId")...');
    await conn.execute('ALTER TABLE "empresa_configuracao" DROP CONSTRAINT IF EXISTS "empresa_config_tenant_unique";');
    await conn.execute('ALTER TABLE "empresa_configuracao" ADD CONSTRAINT "empresa_config_tenant_unique" UNIQUE ("tenantId");');
    print('  ✓ Constraint UNIQUE criada com sucesso!');

    // -------------------------------------------------------------
    // FASE 4: Criação de índices de otimização de sincronia
    // -------------------------------------------------------------
    print('\n[4/5] Criando índices compostos (tenantId, updatedAt)...');
    
    // Tabelas que filtram por tenant e updatedAt no Pull
    final pullTables = [
      'categoria',
      'produto',
      'cliente',
      'forma_pagamento',
      'local_entrega',
      'taxa_entrega',
      'tabela_precificacao',
      'item_tabela_precificacao',
      'produto_tabela_precificacao',
      'empresa_configuracao',
      'membro_empresa',
    ];

    for (final table in pullTables) {
      final idxName = 'idx_${table}_sync_composite';
      print('  - Criando índice $idxName para $table...');
      await conn.execute('DROP INDEX IF EXISTS "$idxName";');
      await conn.execute('CREATE INDEX "$idxName" ON "$table" USING btree ("tenantId", "updatedAt");');
    }
    
    // Índice de data simples para a tabela empresa
    await conn.execute('DROP INDEX IF EXISTS "idx_empresa_updated_at";');
    await conn.execute('CREATE INDEX "idx_empresa_updated_at" ON "empresa" USING btree ("updatedAt");');
    print('  ✓ Índices compostos de pull otimizados!');
    // -------------------------------------------------------------
    // FASE 5: RLS (Row Level Security) e Isolamento de Tenants
    // -------------------------------------------------------------
    print('\n[5/5] Ativando Row Level Security (RLS) no Supabase...');
    
    // 1. Cria a função que busca os tenants do usuário com SECURITY DEFINER (bypassando RLS)
    await conn.execute('''
      CREATE OR REPLACE FUNCTION get_user_tenants(user_id uuid)
      RETURNS TABLE("tenantId" text) AS \$\$
      BEGIN
        RETURN QUERY
        SELECT m."tenantId"::text
        FROM membro_empresa m
        WHERE m."usuarioId" = user_id AND m.ativo = true;
      END;
      \$\$ LANGUAGE plpgsql SECURITY DEFINER;
    ''');
    print('  ✓ Função get_user_tenants criada!');

    // Habilita RLS em todas as tabelas
    for (final table in syncTables) {
      print('  - RLS ativado para a tabela: $table');
      await conn.execute('ALTER TABLE "$table" ENABLE ROW LEVEL SECURITY;');
      
      final policyName = 'policy_${table}_tenant_isolation';
      await conn.execute('DROP POLICY IF EXISTS "$policyName" ON "$table";');
      
      if (table == 'empresa') {
        await conn.execute('''
          CREATE POLICY "$policyName" ON "empresa"
          USING (
            id::text IN (
              SELECT get_user_tenants(auth.uid())
            )
          );
        ''');
      } else if (table == 'membro_empresa') {
        await conn.execute('''
          CREATE POLICY "$policyName" ON "membro_empresa"
          USING (
            "usuarioId" = auth.uid() OR "tenantId"::text IN (
              SELECT get_user_tenants(auth.uid())
            )
          );
        ''');
      } else {
        await conn.execute('''
          CREATE POLICY "$policyName" ON "$table"
          USING (
            "tenantId"::text IN (
              SELECT get_user_tenants(auth.uid())
            )
          );
        ''');
      }
      print('    ✓ Política RLS criada!');
    }
    print('\n🎉 Reengenharia de banco v2.0 aplicada com sucesso no Supabase!');
  } catch (e, stack) {
    print('❌ Falha ao aplicar migração v2.0: $e');
    print(stack);
  } finally {
    await conn.close();
    print('Connection closed.');
  }
}
