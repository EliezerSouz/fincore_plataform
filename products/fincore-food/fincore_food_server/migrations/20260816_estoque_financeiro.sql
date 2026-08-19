DO $$ 
BEGIN

-- 1. ESTOQUE DE PRODUTOS ACABADOS
CREATE TABLE IF NOT EXISTS public.estoque_produto (
  id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"              UUID        NOT NULL,
  "produtoId"             UUID        NOT NULL REFERENCES public.produto("id") ON DELETE CASCADE ON UPDATE CASCADE,
  "quantidadeAtual"       INTEGER     NOT NULL DEFAULT 0,
  "quantidadeReservada"   INTEGER     NOT NULL DEFAULT 0,
  "quantidadeMinima"      INTEGER     NOT NULL DEFAULT 0,
  "quantidadeMaxima"      INTEGER     NOT NULL DEFAULT 9999,
  "quantidadeProducaoLote" INTEGER    NOT NULL DEFAULT 100,
  "diasCoberturaAlvo"     INTEGER     NOT NULL DEFAULT 3,
  unidade                 TEXT        NOT NULL DEFAULT 'un',
  "createdAt"             TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updatedAt"             TIMESTAMPTZ NOT NULL DEFAULT now(),
  "createdBy"             UUID        NOT NULL,
  "updatedBy"             UUID        NOT NULL,
  "deletedAt"             TIMESTAMPTZ,
  "deletedBy"             UUID,
  "syncVersion"           INTEGER     NOT NULL DEFAULT 1,
  "originDeviceId"        TEXT,
  "lastModifiedByDevice"  TEXT,
  "entityHash"            TEXT,
  UNIQUE ("tenantId", "produtoId")
);

ALTER TABLE public.estoque_produto ADD COLUMN IF NOT EXISTS "quantidadeReservada" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.estoque_produto ADD COLUMN IF NOT EXISTS "quantidadeProducaoLote" INTEGER NOT NULL DEFAULT 100;
ALTER TABLE public.estoque_produto ADD COLUMN IF NOT EXISTS "diasCoberturaAlvo" INTEGER NOT NULL DEFAULT 3;

CREATE INDEX IF NOT EXISTS estoque_produto_tenant_produto_idx ON public.estoque_produto ("tenantId", "produtoId");

ALTER TABLE public.estoque_produto ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "estoque_produto_tenant_isolation" ON public.estoque_produto;
DROP POLICY IF EXISTS "estoque_produto_allow_authenticated" ON public.estoque_produto;
CREATE POLICY "estoque_produto_allow_authenticated" ON public.estoque_produto FOR ALL USING (true) WITH CHECK (true);


-- 2. MOVIMENTAÇÕES DE ESTOQUE
CREATE TABLE IF NOT EXISTS public.movimentacao_estoque (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"          UUID        NOT NULL,
  "produtoId"         UUID        NOT NULL,
  "pedidoId"          UUID,
  tipo                TEXT        NOT NULL,
  quantidade          INTEGER     NOT NULL,
  "quantidadeAntes"   INTEGER     NOT NULL,
  "quantidadeDepois"  INTEGER     NOT NULL,
  motivo              TEXT        NOT NULL DEFAULT '',
  "operadorId"        UUID,
  "dataHora"          TIMESTAMPTZ NOT NULL DEFAULT now(),
  "createdAt"         TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updatedAt"         TIMESTAMPTZ NOT NULL DEFAULT now(),
  "createdBy"         UUID        NOT NULL,
  "updatedBy"         UUID        NOT NULL,
  "deletedAt"         TIMESTAMPTZ,
  "deletedBy"         UUID,
  "syncVersion"       INTEGER     NOT NULL DEFAULT 1,
  "originDeviceId"    TEXT,
  "lastModifiedByDevice" TEXT,
  "entityHash"        TEXT
);

CREATE INDEX IF NOT EXISTS mov_estoque_produto_idx ON public.movimentacao_estoque ("tenantId", "produtoId");
CREATE INDEX IF NOT EXISTS mov_estoque_pedido_idx ON public.movimentacao_estoque ("tenantId", "pedidoId");
CREATE INDEX IF NOT EXISTS mov_estoque_data_idx ON public.movimentacao_estoque ("tenantId", "dataHora" DESC);

ALTER TABLE public.movimentacao_estoque ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "movimentacao_estoque_tenant_isolation" ON public.movimentacao_estoque;
DROP POLICY IF EXISTS "movimentacao_estoque_allow_authenticated" ON public.movimentacao_estoque;
CREATE POLICY "movimentacao_estoque_allow_authenticated" ON public.movimentacao_estoque FOR ALL USING (true) WITH CHECK (true);


-- 3. SESSÕES DE CAIXA
CREATE TABLE IF NOT EXISTS public.sessao_caixa (
  id                          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"                  UUID        NOT NULL,
  "operadorId"                UUID        NOT NULL,
  "operadorNome"              TEXT        NOT NULL DEFAULT 'Operador',
  status                      TEXT        NOT NULL DEFAULT 'aberta',
  "dataAbertura"              TIMESTAMPTZ NOT NULL DEFAULT now(),
  "dataFechamento"            TIMESTAMPTZ,
  "valorAberturaCentavos"     INTEGER     NOT NULL DEFAULT 0,
  "valorFechamentoCentavos"   INTEGER,
  "totalVendasCentavos"       INTEGER     NOT NULL DEFAULT 0,
  "totalDespesasCentavos"     INTEGER     NOT NULL DEFAULT 0,
  "diferencaCentavos"         INTEGER,
  observacoes                 TEXT,
  "createdAt"                 TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updatedAt"                 TIMESTAMPTZ NOT NULL DEFAULT now(),
  "createdBy"                 UUID        NOT NULL,
  "updatedBy"                 UUID        NOT NULL,
  "deletedAt"                 TIMESTAMPTZ,
  "deletedBy"                 UUID,
  "syncVersion"               INTEGER     NOT NULL DEFAULT 1,
  "originDeviceId"            TEXT,
  "lastModifiedByDevice"      TEXT,
  "entityHash"                TEXT
);

CREATE INDEX IF NOT EXISTS sessao_caixa_tenant_status_idx ON public.sessao_caixa ("tenantId", status);

ALTER TABLE public.sessao_caixa ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "sessao_caixa_tenant_isolation" ON public.sessao_caixa;
DROP POLICY IF EXISTS "sessao_caixa_allow_authenticated" ON public.sessao_caixa;
CREATE POLICY "sessao_caixa_allow_authenticated" ON public.sessao_caixa FOR ALL USING (true) WITH CHECK (true);


-- 4. LANÇAMENTOS FINANCEIROS
CREATE TABLE IF NOT EXISTS public.lancamento_financeiro (
  id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenantId"            UUID        NOT NULL,
  "sessaoCaixaId"       UUID        NOT NULL REFERENCES public.sessao_caixa("id") ON DELETE RESTRICT,
  "pedidoId"            UUID,
  tipo                  TEXT        NOT NULL,
  "formaPagamentoId"    UUID,
  "formaPagamentoNome"  TEXT,
  "valorCentavos"       INTEGER     NOT NULL,
  descricao             TEXT        NOT NULL DEFAULT '',
  "operadorId"          UUID,
  "dataHora"            TIMESTAMPTZ NOT NULL DEFAULT now(),
  "createdAt"           TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updatedAt"           TIMESTAMPTZ NOT NULL DEFAULT now(),
  "createdBy"           UUID        NOT NULL,
  "updatedBy"           UUID        NOT NULL,
  "deletedAt"           TIMESTAMPTZ,
  "deletedBy"           UUID,
  "syncVersion"         INTEGER     NOT NULL DEFAULT 1,
  "originDeviceId"      TEXT,
  "lastModifiedByDevice" TEXT,
  "entityHash"          TEXT
);

CREATE INDEX IF NOT EXISTS lancamento_sessao_idx ON public.lancamento_financeiro ("tenantId", "sessaoCaixaId");

ALTER TABLE public.lancamento_financeiro ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "lancamento_financeiro_tenant_isolation" ON public.lancamento_financeiro;
DROP POLICY IF EXISTS "lancamento_financeiro_allow_authenticated" ON public.lancamento_financeiro;
CREATE POLICY "lancamento_financeiro_allow_authenticated" ON public.lancamento_financeiro FOR ALL USING (true) WITH CHECK (true);

END $$;
