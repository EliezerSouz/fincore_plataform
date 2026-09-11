-- Migration 021: Planejamento de Produção + colunas de capacidade
-- FINCORE FOOD — 2026-08-27

DO $$
BEGIN

-- ── 1. Tabela de Planejamento de Produção ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.planejamento_producao (
  id                        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"                UUID        NOT NULL,
  "produtoId"               UUID        NOT NULL REFERENCES public.produto("id") ON DELETE RESTRICT ON UPDATE CASCADE,
  "dataPlano"               TIMESTAMPTZ NOT NULL,
  "quantidadePlanejada"     INTEGER     NOT NULL,
  "quantidadeProduzida"     INTEGER     NOT NULL DEFAULT 0,
  "capacidadeCampanha"      INTEGER     NOT NULL DEFAULT 0,
  status                    TEXT        NOT NULL DEFAULT 'planejada'
                              CHECK (status IN ('planejada','em_preparacao','em_producao','parcial','concluida','cancelada')),
  "motivoCancelamento"      TEXT,
  observacoes               TEXT,
  "operadorId"              UUID,
  "createdAt"               TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updatedAt"               TIMESTAMPTZ NOT NULL DEFAULT now(),
  "createdBy"               UUID        NOT NULL,
  "updatedBy"               UUID        NOT NULL,
  "deletedAt"               TIMESTAMPTZ,
  "deletedBy"               UUID,
  "syncVersion"             INTEGER     NOT NULL DEFAULT 1,
  "originDeviceId"          TEXT,
  "lastModifiedByDevice"    TEXT,
  "entityHash"              TEXT
);

CREATE INDEX IF NOT EXISTS planejamento_producao_tenant_produto_idx
  ON public.planejamento_producao ("tenantId", "produtoId");
CREATE INDEX IF NOT EXISTS planejamento_producao_data_idx
  ON public.planejamento_producao ("tenantId", "dataPlano" DESC);
CREATE INDEX IF NOT EXISTS planejamento_producao_status_idx
  ON public.planejamento_producao ("tenantId", status);

ALTER TABLE public.planejamento_producao ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "planejamento_producao_tenant_isolation" ON public.planejamento_producao;
CREATE POLICY "planejamento_producao_tenant_isolation" ON public.planejamento_producao
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.membro_empresa m
      WHERE m."tenantId" = planejamento_producao."tenantId"
        AND m."usuarioId"::text = auth.uid()::text
        AND m.ativo = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.membro_empresa m
      WHERE m."tenantId" = planejamento_producao."tenantId"
        AND m."usuarioId"::text = auth.uid()::text
        AND m.ativo = true
    )
  );

-- ── 2. Colunas de Capacidade em estoque_produto ───────────────────────────
ALTER TABLE public.estoque_produto
  ADD COLUMN IF NOT EXISTS "capacidadeCampanha"   INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.estoque_produto
  ADD COLUMN IF NOT EXISTS "estrategiaProducao"   TEXT    NOT NULL DEFAULT 'concentrada';
ALTER TABLE public.estoque_produto
  ADD COLUMN IF NOT EXISTS "tempoPreparacao"       INTEGER NOT NULL DEFAULT 0;

-- ── 3. Coluna de data de entrega prevista em pedido ───────────────────────
-- Permite calcular demanda futura e horário de início recomendado diretamente do pedido
ALTER TABLE public.pedido
  ADD COLUMN IF NOT EXISTS "dataHoraEntregaPrevista" TIMESTAMPTZ;

-- ── 4. Notificar PostgREST para recarregar schema ─────────────────────────
PERFORM pg_notify('pgrst', 'reload schema');

END $$;
