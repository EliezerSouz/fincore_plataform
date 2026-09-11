// Script para aplicar a migration 20260821_iam_multitenant_desacoplamento.sql
// no banco Supabase via Postgres connection.
// Executar com: dart run apply_iam_migration.dart

import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  // Ler variáveis de ambiente configuradas no servidor
  final host = Platform.environment['DB_HOST'] ?? 'aws-0-sa-east-1.pooler.supabase.com';
  final port = int.tryParse(Platform.environment['DB_PORT'] ?? '5432') ?? 5432;
  final dbName = Platform.environment['DB_NAME'] ?? 'postgres';
  final user = Platform.environment['DB_USER'] ?? 'postgres.nlaxdeqbordmovukyypk';
  final password = Platform.environment['DB_PASSWORD'];
  
  if (password == null || password.isEmpty) {
    print('❌ Variável DB_PASSWORD não configurada. Configure-a antes de rodar este script.');
    exit(1);
  }

  print('🔌 Conectando ao banco Supabase: $host:$port/$dbName');

  final conn = await Connection.open(
    Endpoint(
      host: host,
      port: port,
      database: dbName,
      username: user,
      password: password,
    ),
    settings: ConnectionSettings(sslMode: SslMode.require),
  );

  print('✅ Conectado. Aplicando migration IAM Multi-Tenant...\n');

  try {
    // 1. Verificar se a coluna ainda se chama "tenantId" ou já foi renomeada
    final result = await conn.execute(
      "SELECT column_name FROM information_schema.columns "
      "WHERE table_name = 'usuarios' AND column_name = 'tenantId';",
    );
    
    if (result.isEmpty) {
      print('ℹ️ Coluna "tenantId" não encontrada em usuarios — migration pode já ter sido aplicada.');
      print('   Verificando se "activeTenantId" existe...');
      final checkActive = await conn.execute(
        "SELECT column_name FROM information_schema.columns "
        "WHERE table_name = 'usuarios' AND column_name = 'activeTenantId';",
      );
      if (checkActive.isNotEmpty) {
        print('✅ "activeTenantId" já existe. Migration já foi aplicada anteriormente.');
        await conn.close();
        exit(0);
      }
    }

    await conn.execute('BEGIN;');
    
    // 2. Remover FK rígida que causava o erro de onboarding
    print('1️⃣  Removendo FK "fk_usuarios_tenant"...');
    await conn.execute('ALTER TABLE "usuarios" DROP CONSTRAINT IF EXISTS "fk_usuarios_tenant";');
    
    // 3. Torna o campo opcional (se tenantId existir)
    final checkTenant = await conn.execute(
      "SELECT column_name FROM information_schema.columns "
      "WHERE table_name = 'usuarios' AND column_name = 'tenantId';",
    );
    final checkActiveCol = await conn.execute(
      "SELECT column_name FROM information_schema.columns "
      "WHERE table_name = 'usuarios' AND column_name = 'activeTenantId';",
    );

    if (checkTenant.isNotEmpty && checkActiveCol.isEmpty) {
      print('2️⃣  Tornando "tenantId" nullable em usuarios...');
      await conn.execute('ALTER TABLE "usuarios" ALTER COLUMN "tenantId" DROP NOT NULL;');
      print('3️⃣  Renomeando "tenantId" → "activeTenantId" em usuarios...');
      await conn.execute('ALTER TABLE "usuarios" RENAME COLUMN "tenantId" TO "activeTenantId";');
    } else if (checkActiveCol.isNotEmpty) {
      print('ℹ️  Coluna "activeTenantId" já existe em usuarios. Pulando rename.');
    }
    
    // 5. Atualizar índice
    print('4️⃣  Atualizando índice de usuarios...');
    await conn.execute('DROP INDEX IF EXISTS "usr_tenant_username_idx";');
    await conn.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS "usr_username_unique_idx" ON "usuarios" ("username");'
    );

    // 6. Corrigir constraints de membro_empresa
    print('5️⃣  Atualizando constraints de membro_empresa...');
    await conn.execute('ALTER TABLE "membro_empresa" DROP CONSTRAINT IF EXISTS "membro_empresa_fk_empresa";');
    await conn.execute('ALTER TABLE "membro_empresa" DROP CONSTRAINT IF EXISTS "membro_empresa_fk_usuario";');
    await conn.execute('ALTER TABLE "membro_empresa" DROP CONSTRAINT IF EXISTS "fk_membro_empresa_tenant";');
    await conn.execute('ALTER TABLE "membro_empresa" DROP CONSTRAINT IF EXISTS "fk_membro_empresa_usuario";');
    
    await conn.execute(
      'ALTER TABLE "membro_empresa" ADD CONSTRAINT "fk_membro_empresa_tenant" '
      'FOREIGN KEY ("tenantId") REFERENCES "empresa"("id") ON DELETE CASCADE;'
    );
    await conn.execute(
      'ALTER TABLE "membro_empresa" ADD CONSTRAINT "fk_membro_empresa_usuario" '
      'FOREIGN KEY ("usuarioId") REFERENCES "usuarios"("id") ON DELETE CASCADE;'
    );
    
    // 7. Índice único para membro_empresa
    print('6️⃣  Criando índice único em membro_empresa...');
    await conn.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS "membro_empresa_usuario_tenant_unique_idx" '
      'ON "membro_empresa" ("usuarioId", "tenantId");'
    );

    await conn.execute('COMMIT;');
    
    print('\n✅ Migration IAM Multi-Tenant aplicada com sucesso!');
    print('   - FK fk_usuarios_tenant removida');
    print('   - Coluna renomeada: tenantId → activeTenantId (nullable)');
    print('   - Índice atualizado em usuarios');
    print('   - Constraints atualizadas em membro_empresa');

  } catch (e) {
    print('\n❌ ERRO ao aplicar migration: $e');
    try { await conn.execute('ROLLBACK;'); } catch (_) {}
    await conn.close();
    exit(1);
  }

  await conn.close();
  exit(0);
}
