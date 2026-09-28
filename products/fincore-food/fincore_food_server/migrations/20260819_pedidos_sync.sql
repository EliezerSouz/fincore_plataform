-- Schema remoto mínimo para o canal oficial de sync (Supabase SDK).
-- Todos os nomes seguem exatamente os payloads camelCase do Flutter.

CREATE TABLE IF NOT EXISTS public.pedido (
  id UUID PRIMARY KEY,
  "tenantId" UUID NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('rascunho', 'confirmado', 'em_preparo', 'pronto', 'entregue', 'cancelado')),
  "tipoLogistica" TEXT NOT NULL,
  "clienteId" UUID,
  "clienteNomeAvulso" TEXT,
  "clienteTelefoneAvulso" TEXT,
  "valorSubtotalCentavos" INTEGER NOT NULL CHECK ("valorSubtotalCentavos" >= 0),
  "valorTaxaEntregaCentavos" INTEGER NOT NULL DEFAULT 0 CHECK ("valorTaxaEntregaCentavos" >= 0),
  "valorTaxaServicoCentavos" INTEGER NOT NULL DEFAULT 0 CHECK ("valorTaxaServicoCentavos" >= 0),
  "valorTotalCentavos" INTEGER NOT NULL CHECK ("valorTotalCentavos" >= 0),
  "trocoParaCentavos" INTEGER,
  "formaPagamentoId" UUID,
  "formaPagamentoNome" TEXT,
  "enderecoJson" TEXT,
  "operadorId" UUID,
  "dataHoraCriacao" TIMESTAMPTZ NOT NULL,
  "numeroPedido" INTEGER,
  observacoes TEXT,
  "canalOrigem" TEXT NOT NULL DEFAULT 'pdv_express',
  "syncVersion" INTEGER NOT NULL DEFAULT 1,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "createdBy" UUID NOT NULL,
  "updatedBy" UUID NOT NULL,
  "deletedAt" TIMESTAMPTZ,
  "deletedBy" UUID,
  CONSTRAINT pedido_total_consistente CHECK ("valorTotalCentavos" = "valorSubtotalCentavos" + "valorTaxaEntregaCentavos" + COALESCE("valorTaxaServicoCentavos", 0)),
  CONSTRAINT pedido_numero_tenant_unique UNIQUE ("tenantId", "numeroPedido")
);

CREATE TABLE IF NOT EXISTS public.item_pedido (
  id UUID PRIMARY KEY,
  "tenantId" UUID NOT NULL,
  "pedidoId" UUID NOT NULL REFERENCES public.pedido(id) ON DELETE RESTRICT,
  "produtoId" UUID NOT NULL,
  "nomeProduto" TEXT NOT NULL,
  quantidade NUMERIC NOT NULL CHECK (quantidade > 0),
  "valorUnitarioCentavos" INTEGER NOT NULL CHECK ("valorUnitarioCentavos" >= 0),
  "valorTotalCentavos" INTEGER NOT NULL CHECK ("valorTotalCentavos" >= 0),
  observacoes TEXT,
  "syncVersion" INTEGER NOT NULL DEFAULT 1,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT now(),
  "createdBy" UUID NOT NULL,
  "updatedBy" UUID NOT NULL,
  "deletedAt" TIMESTAMPTZ,
  "deletedBy" UUID,
  CONSTRAINT item_pedido_total_consistente CHECK ("valorTotalCentavos" = round(quantidade * "valorUnitarioCentavos"))
);

CREATE INDEX IF NOT EXISTS pedido_tenant_updated_idx ON public.pedido ("tenantId", "updatedAt");
CREATE INDEX IF NOT EXISTS item_pedido_tenant_pedido_idx ON public.item_pedido ("tenantId", "pedidoId");

ALTER TABLE public.pedido ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.item_pedido ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS pedido_tenant_isolation ON public.pedido;
DROP POLICY IF EXISTS item_pedido_tenant_isolation ON public.item_pedido;
CREATE POLICY pedido_tenant_isolation ON public.pedido FOR ALL
  USING (EXISTS (SELECT 1 FROM public.membro_empresa m WHERE m."tenantId"::text = pedido."tenantId"::text AND m."usuarioId"::text = auth.uid()::text AND m.ativo = true))
  WITH CHECK (EXISTS (SELECT 1 FROM public.membro_empresa m WHERE m."tenantId"::text = pedido."tenantId"::text AND m."usuarioId"::text = auth.uid()::text AND m.ativo = true));
CREATE POLICY item_pedido_tenant_isolation ON public.item_pedido FOR ALL
  USING (EXISTS (SELECT 1 FROM public.membro_empresa m WHERE m."tenantId"::text = item_pedido."tenantId"::text AND m."usuarioId"::text = auth.uid()::text AND m.ativo = true))
  WITH CHECK (EXISTS (SELECT 1 FROM public.membro_empresa m WHERE m."tenantId"::text = item_pedido."tenantId"::text AND m."usuarioId"::text = auth.uid()::text AND m.ativo = true));
