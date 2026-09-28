-- ═══════════════════════════════════════════════════════════════════════
-- FINCORE Food — Cardápio Digital Web
-- Migration 004: View de Tabelas de Precificação por Quantidade
-- ═══════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW public.vw_cardapio_precificacao AS
  SELECT
    itp.id,
    itp."tenantId"                  AS tenant_id,
    itp."tabelaPrecificacaoId"       AS tabela_id,
    ptp."produtoId"                 AS produto_id,
    ctp."categoriaId"               AS categoria_id,
    itp."quantidadeMinima"::int      AS qtd_minima,
    itp."quantidadeMaxima"::int      AS qtd_maxima,
    itp."valorUnitarioCentavos"::int AS valor_unitario_centavos,
    itp.ordem::int                  AS ordem
  FROM public.item_tabela_precificacao itp
  JOIN public.tabela_precificacao tp ON tp.id = itp."tabelaPrecificacaoId" AND tp.ativo = true AND tp."deletedAt" IS NULL
  LEFT JOIN public.produto_tabela_precificacao ptp ON ptp."tabelaPrecificacaoId" = tp.id AND ptp.ativo = true AND ptp."deletedAt" IS NULL
  LEFT JOIN public.categoria_tabela_precificacao ctp ON ctp."tabelaPrecificacaoId" = tp.id AND ctp.ativo = true AND ctp."deletedAt" IS NULL
  WHERE itp."deletedAt" IS NULL;

-- Permitir leitura pública da view de precificação
GRANT SELECT ON public.vw_cardapio_precificacao TO anon, authenticated;
