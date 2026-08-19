DO $$ 
BEGIN
  -- 1. Garantir que a coluna tenantId exista e seja UUID em usuarios
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'usuarios' AND column_name = 'tenantId') THEN
    ALTER TABLE "usuarios" ADD COLUMN "tenantId" UUID;
  ELSE
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'usuarios' AND column_name = 'tenantId' AND data_type = 'text') THEN
      ALTER TABLE "usuarios" ALTER COLUMN "tenantId" TYPE UUID USING "tenantId"::UUID;
    END IF;
  END IF;

  -- 2. FK em empresa_convite -> empresa(id)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'empresa_convite') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_empresa_convite_tenant') THEN
      ALTER TABLE "empresa_convite" 
      ADD CONSTRAINT "fk_empresa_convite_tenant" 
      FOREIGN KEY ("tenantId") 
      REFERENCES "empresa"("id") 
      ON DELETE RESTRICT 
      ON UPDATE CASCADE;
    END IF;
  END IF;

  -- 3. FK em usuarios -> empresa(id) (opcional / SET NULL)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'usuarios') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_usuarios_tenant') THEN
      ALTER TABLE "usuarios" 
      ADD CONSTRAINT "fk_usuarios_tenant" 
      FOREIGN KEY ("tenantId") 
      REFERENCES "empresa"("id") 
      ON DELETE SET NULL 
      ON UPDATE CASCADE;
    END IF;
  END IF;
END $$;
