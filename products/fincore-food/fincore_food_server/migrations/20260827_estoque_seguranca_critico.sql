-- Migration: Adicionar colunas de estoque crítico e segurança no Supabase
-- Target Table: estoque_produto

ALTER TABLE "estoque_produto" ADD COLUMN IF NOT EXISTS "quantidadeSeguranca" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "estoque_produto" ADD COLUMN IF NOT EXISTS "quantidadeCritica" INTEGER NOT NULL DEFAULT 0;

-- Notifica o PostgREST para recarregar o schema e refletir as alterações no schema público do Supabase
NOTIFY pgrst, 'reload schema';
