-- Migration para adicionar a coluna valorTaxaServicoCentavos e atualizar a constraint pedido_total_consistente no Supabase PostgreSQL.

ALTER TABLE public.pedido 
  ADD COLUMN IF NOT EXISTS "valorTaxaServicoCentavos" INTEGER NOT NULL DEFAULT 0 CHECK ("valorTaxaServicoCentavos" >= 0);

ALTER TABLE public.pedido 
  DROP CONSTRAINT IF EXISTS pedido_total_consistente;

ALTER TABLE public.pedido 
  ADD CONSTRAINT pedido_total_consistente 
  CHECK ("valorTotalCentavos" = "valorSubtotalCentavos" + "valorTaxaEntregaCentavos" + COALESCE("valorTaxaServicoCentavos", 0));
