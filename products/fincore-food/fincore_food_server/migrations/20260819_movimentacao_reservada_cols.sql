DO $$
BEGIN

-- Adicionar colunas de reserva para movimentacao_estoque no Supabase
ALTER TABLE public.movimentacao_estoque ADD COLUMN IF NOT EXISTS "quantidadeReservadaAntes" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.movimentacao_estoque ADD COLUMN IF NOT EXISTS "quantidadeReservadaDepois" INTEGER NOT NULL DEFAULT 0;

-- Recarregar schema do PostgRest
PERFORM pg_notify('pgrst', 'reload schema');

END $$;
