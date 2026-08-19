DO $$ 
BEGIN
  -- Adicionar colunas fiscais e cadastrais na tabela empresa no Supabase
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'empresa') THEN
    ALTER TABLE "empresa" ADD COLUMN IF NOT EXISTS "tipoPessoa" TEXT NOT NULL DEFAULT 'JURIDICA';
    ALTER TABLE "empresa" ADD COLUMN IF NOT EXISTS "inscricaoEstadual" TEXT;
    ALTER TABLE "empresa" ADD COLUMN IF NOT EXISTS "inscricaoMunicipal" TEXT;
    ALTER TABLE "empresa" ADD COLUMN IF NOT EXISTS "regimeTributario" TEXT;
    ALTER TABLE "empresa" ADD COLUMN IF NOT EXISTS "endereco" TEXT;
  END IF;
END $$;
