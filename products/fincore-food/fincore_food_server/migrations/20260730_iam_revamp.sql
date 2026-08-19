-- Migration IAM Revamp: Usuarios & Empresa Convites no Supabase
ALTER TABLE IF EXISTS "usuarios" ADD COLUMN IF NOT EXISTS "tenantId" TEXT;
ALTER TABLE IF EXISTS "usuarios" ADD COLUMN IF NOT EXISTS "authUserId" TEXT;
ALTER TABLE IF EXISTS "usuarios" ADD COLUMN IF NOT EXISTS "username" TEXT;
ALTER TABLE IF EXISTS "usuarios" ALTER COLUMN "email" DROP NOT NULL;
ALTER TABLE IF EXISTS "usuarios" ADD COLUMN IF NOT EXISTS "ativo" BOOLEAN DEFAULT true;

-- Indice unico composto por tenant_id e username
CREATE UNIQUE INDEX IF NOT EXISTS "usr_tenant_username_idx" ON "usuarios" ("tenantId", "username");

-- Tabela de Convites de Acesso (Empresa Convite)
CREATE TABLE IF NOT EXISTS "empresa_convite" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId" UUID NOT NULL,
  "email" TEXT NOT NULL,
  "role" TEXT NOT NULL,
  "status" TEXT NOT NULL,
  "expiracaoEm" TIMESTAMPTZ NOT NULL,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "createdBy" UUID NOT NULL,
  "updatedBy" UUID NOT NULL,
  "deletedAt" TIMESTAMPTZ,
  "deletedBy" UUID,
  "syncVersion" INT NOT NULL DEFAULT 1,
  "originDeviceId" TEXT,
  "lastModifiedByDevice" TEXT,
  "entityHash" TEXT
);

CREATE INDEX IF NOT EXISTS "convite_tenant_idx" ON "empresa_convite" ("tenantId");
