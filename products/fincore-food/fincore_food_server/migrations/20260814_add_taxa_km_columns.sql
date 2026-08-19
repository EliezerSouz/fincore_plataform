-- Custom migration to add taxaEntregaPorKm and valorPorKmCentavos columns if they are missing
ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "taxaEntregaPorKm" boolean;
ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "valorPorKmCentavos" bigint;
