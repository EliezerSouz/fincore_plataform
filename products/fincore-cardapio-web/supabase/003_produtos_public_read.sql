-- ═══════════════════════════════════════════════════════════════════════
-- FINCORE Food — Cardápio Digital Web
-- Migration 003: Leitura pública de produtos, categorias e empresas
-- ═══════════════════════════════════════════════════════════════════════

-- Habilitar RLS e Leitura Pública
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'produto') THEN
    ALTER TABLE public.produto ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "produto_public_read" ON public.produto;
    CREATE POLICY "produto_public_read" ON public.produto FOR SELECT USING (ativo = true AND "deletedAt" IS NULL);
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'categoria') THEN
    ALTER TABLE public.categoria ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "categoria_public_read" ON public.categoria;
    CREATE POLICY "categoria_public_read" ON public.categoria FOR SELECT USING (ativo = true AND "deletedAt" IS NULL);
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'empresa') THEN
    ALTER TABLE public.empresa ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "empresa_public_read" ON public.empresa;
    CREATE POLICY "empresa_public_read" ON public.empresa FOR SELECT USING ("deletedAt" IS NULL);
  END IF;
END $$;

-- ─── View pública de empresas do cardápio ────────────────────────────
CREATE OR REPLACE VIEW public.vw_cardapio_empresa AS
  SELECT
    id                AS tenant_id,
    "nomeFantasia"    AS nome_fantasia,
    "razaoSocial"     AS razao_social,
    "telefone"        AS whatsapp,
    NULL::jsonb       AS metadata_payload
  FROM public.empresa
  WHERE "deletedAt" IS NULL;

-- ─── View pública de produtos do cardápio ────────────────────────────
CREATE OR REPLACE VIEW public.vw_cardapio_produtos AS
  SELECT
    p.id,
    p."tenantId"         AS tenant_id,
    p.nome,
    p.descricao,
    p."categoriaId"      AS categoria_id,
    p.imagem,
    p."corEtiqueta"      AS cor_etiqueta,
    p."unidadeVenda"     AS unidade_venda,
    p.metadata,
    p.ativo,
    p."statusComercial"  AS status_comercial,
    p."ordemProducao"    AS ordem_producao,
    c.nome               AS categoria_nome,
    c.icone              AS categoria_icone,
    c.cor                AS categoria_cor,
    c."ordemExibicao"    AS categoria_ordem
  FROM public.produto p
  JOIN public.categoria c ON c.id = p."categoriaId"
  WHERE p.ativo = true
    AND p."deletedAt" IS NULL
    AND c.ativo = true
    AND c."deletedAt" IS NULL
  ORDER BY c."ordemExibicao", p."ordemProducao";

