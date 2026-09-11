DO $$
BEGIN
    -- 1. Remover a FK que impedia o usuário de existir sem uma empresa se ela ainda existir
    IF EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_usuarios_tenant' AND table_name = 'usuarios'
    ) THEN
        ALTER TABLE "usuarios" DROP CONSTRAINT "fk_usuarios_tenant";
    END IF;

    -- 2. Torna o campo opcional e renomeia apenas se a coluna antiga "tenantId" existir E "activeTenantId" NÃO existir
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'usuarios' AND column_name = 'tenantId'
    ) AND NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'usuarios' AND column_name = 'activeTenantId'
    ) THEN
        ALTER TABLE "usuarios" ALTER COLUMN "tenantId" DROP NOT NULL;
        ALTER TABLE "usuarios" RENAME COLUMN "tenantId" TO "activeTenantId";
    END IF;

    -- 3. Garantir que activeTenantId é nullable caso já tenha sido renomeada
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'usuarios' AND column_name = 'activeTenantId'
    ) THEN
        ALTER TABLE "usuarios" ALTER COLUMN "activeTenantId" DROP NOT NULL;
    END IF;

    -- 4. Atualizar o índice que dependia do tenantId + username conjunto
    DROP INDEX IF EXISTS "usr_tenant_username_idx";
    CREATE UNIQUE INDEX IF NOT EXISTS "usr_username_unique_idx" ON "usuarios" ("username");

    -- 5. Garantir que a tabela membro_empresa tem as constraints corretas
    ALTER TABLE "membro_empresa" DROP CONSTRAINT IF EXISTS "membro_empresa_fk_empresa";
    ALTER TABLE "membro_empresa" DROP CONSTRAINT IF EXISTS "membro_empresa_fk_usuario";
    ALTER TABLE "membro_empresa" DROP CONSTRAINT IF EXISTS "fk_membro_empresa_tenant";
    ALTER TABLE "membro_empresa" DROP CONSTRAINT IF EXISTS "fk_membro_empresa_usuario";

    ALTER TABLE "membro_empresa"
      ADD CONSTRAINT "fk_membro_empresa_tenant"
      FOREIGN KEY ("tenantId") REFERENCES "empresa"("id") ON DELETE CASCADE;

    ALTER TABLE "membro_empresa"
      ADD CONSTRAINT "fk_membro_empresa_usuario"
      FOREIGN KEY ("usuarioId") REFERENCES "usuarios"("id") ON DELETE CASCADE;

    -- 6. Índice único para evitar duplicação de vínculo usuario-empresa
    DROP INDEX IF EXISTS "membro_empresa_usuario_tenant_unique_idx";
    CREATE UNIQUE INDEX IF NOT EXISTS "membro_empresa_usuario_tenant_unique_idx"
      ON "membro_empresa" ("usuarioId", "tenantId");
END $$;
