DO $$
BEGIN
  -- Adicionar coluna "canal" à tabela "tabela_precificacao" se não existir
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'tabela_precificacao' AND column_name = 'canal'
  ) THEN
    ALTER TABLE "tabela_precificacao" ADD COLUMN "canal" TEXT NOT NULL DEFAULT 'todos';
  END IF;
END $$;
