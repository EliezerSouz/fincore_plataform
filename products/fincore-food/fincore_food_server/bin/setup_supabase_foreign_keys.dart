import 'package:postgres/postgres.dart';

void main() async {
  print('--- Supabase Database Scan & Foreign Key Constraints Creator ---');
  
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

  // Lista de tabelas que usam tenantId do tipo text que precisam ser migradas para uuid e ter chaves estrangeiras criadas.
  final tablesToLink = [
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
    'audit_logs',
  ];

  try {
    print('\n[1/3] Limpando todas as tabelas do Supabase em cascata para evitar dados órfãos...');
    
    // Esse comando limpa todas as tabelas e reseta sequências.
    final truncateSql = '''
      TRUNCATE TABLE 
        "eventos_empresa",
        "audit_logs",
        "produto_tabela_precificacao",
        "item_tabela_precificacao",
        "tabela_precificacao",
        "local_entrega",
        "cliente",
        "produto",
        "categoria",
        "forma_pagamento",
        "taxa_entrega",
        "empresa_configuracao",
        "membro_empresa",
        "empresa",
        "usuarios"
      CASCADE;
    ''';
    await conn.execute(truncateSql);
    print('  ✓ Todas as tabelas foram zeradas com sucesso!');

    print('\n[2/3] Removendo possíveis chaves estrangeiras anteriores se existirem (para evitar conflitos)...');
    for (final table in tablesToLink) {
      final constraintName = '${table}_tenant_fk';
      await conn.execute('ALTER TABLE "$table" DROP CONSTRAINT IF EXISTS "$constraintName" CASCADE;');
    }
    print('  ✓ Constraints antigas limpas!');

    print('\n[3/3] Alterando tipo de coluna tenantId para UUID e criando as chaves estrangeiras...');
    for (final table in tablesToLink) {
      print('  - Mapeando integridade referencial para a tabela: $table...');
      
      // 1. Modifica o tipo da coluna tenantId para UUID no PostgreSQL
      await conn.execute('ALTER TABLE "$table" ALTER COLUMN "tenantId" TYPE uuid USING "tenantId"::uuid;');
      
      // 2. Adiciona a constraint de Foreign Key referenciando a tabela empresa(id) com DELETE CASCADE
      final constraintName = '${table}_tenant_fk';
      await conn.execute('''
        ALTER TABLE "$table" 
        ADD CONSTRAINT "$constraintName" 
        FOREIGN KEY ("tenantId") 
        REFERENCES "empresa"("id") 
        ON DELETE CASCADE;
      ''');
      print('    ✓ Tabela "$table" vinculada via Foreign Key com "empresa" com sucesso!');
    }

    final tablesWithAudit = [
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

    print('\n[4/4] Mapeando chaves estrangeiras de auditoria (createdBy, updatedBy, deletedBy) para usuarios...');
    for (final table in tablesWithAudit) {
      print('  - Criando vínculos de auditoria para a tabela: $table...');
      
      // Remove antigas para evitar conflito
      await conn.execute('ALTER TABLE "$table" DROP CONSTRAINT IF EXISTS "${table}_created_by_fk" CASCADE;');
      await conn.execute('ALTER TABLE "$table" DROP CONSTRAINT IF EXISTS "${table}_updated_by_fk" CASCADE;');
      await conn.execute('ALTER TABLE "$table" DROP CONSTRAINT IF EXISTS "${table}_deleted_by_fk" CASCADE;');
      
      // Cria FKs referenciando usuarios(id)
      await conn.execute('''
        ALTER TABLE "$table" 
        ADD CONSTRAINT "${table}_created_by_fk" 
        FOREIGN KEY ("createdBy") 
        REFERENCES "usuarios"("id") 
        ON DELETE NO ACTION;
      ''');
      await conn.execute('''
        ALTER TABLE "$table" 
        ADD CONSTRAINT "${table}_updated_by_fk" 
        FOREIGN KEY ("updatedBy") 
        REFERENCES "usuarios"("id") 
        ON DELETE NO ACTION;
      ''');
      await conn.execute('''
        ALTER TABLE "$table" 
        ADD CONSTRAINT "${table}_deleted_by_fk" 
        FOREIGN KEY ("deletedBy") 
        REFERENCES "usuarios"("id") 
        ON DELETE SET NULL;
      ''');
      print('    ✓ Auditoria de "$table" vinculada com "usuarios" com sucesso!');
    }

    print('\n🎉 Varredura e criação de chaves estrangeiras concluídas no Supabase!');
    print('Agora a integridade referencial e os logs de auditoria estão vinculados e protegidos contra dados órfãos.');

  } catch (e, stack) {
    print('❌ Erro durante o mapeamento de integridade referencial: $e');
    print(stack);
  } finally {
    await conn.close();
    print('Connection closed.');
  }
}
