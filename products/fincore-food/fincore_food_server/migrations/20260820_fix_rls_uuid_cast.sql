DO $$
BEGIN

-- Corrigir políticas RLS que comparam m."usuarioId" (que pode ser TEXT no Supabase)
-- com auth.uid() (que retorna UUID), adicionando cast explícito.
-- Erro original: "operator does not exist: uuid = text"

-- 1. estoque_produto
ALTER TABLE public.estoque_produto ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "estoque_produto_tenant_isolation" ON public.estoque_produto;
CREATE POLICY "estoque_produto_tenant_isolation" ON public.estoque_produto FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.membro_empresa m
    WHERE m."tenantId"::text = estoque_produto."tenantId"::text
      AND m."usuarioId"::text = auth.uid()::text
      AND m.ativo = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.membro_empresa m
    WHERE m."tenantId"::text = estoque_produto."tenantId"::text
      AND m."usuarioId"::text = auth.uid()::text
      AND m.ativo = true
  ));

-- 2. movimentacao_estoque
ALTER TABLE public.movimentacao_estoque ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "movimentacao_estoque_tenant_isolation" ON public.movimentacao_estoque;
CREATE POLICY "movimentacao_estoque_tenant_isolation" ON public.movimentacao_estoque FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.membro_empresa m
    WHERE m."tenantId"::text = movimentacao_estoque."tenantId"::text
      AND m."usuarioId"::text = auth.uid()::text
      AND m.ativo = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.membro_empresa m
    WHERE m."tenantId"::text = movimentacao_estoque."tenantId"::text
      AND m."usuarioId"::text = auth.uid()::text
      AND m.ativo = true
  ));

-- 3. sessao_caixa
ALTER TABLE public.sessao_caixa ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "sessao_caixa_tenant_isolation" ON public.sessao_caixa;
CREATE POLICY "sessao_caixa_tenant_isolation" ON public.sessao_caixa FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.membro_empresa m
    WHERE m."tenantId"::text = sessao_caixa."tenantId"::text
      AND m."usuarioId"::text = auth.uid()::text
      AND m.ativo = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.membro_empresa m
    WHERE m."tenantId"::text = sessao_caixa."tenantId"::text
      AND m."usuarioId"::text = auth.uid()::text
      AND m.ativo = true
  ));

-- 4. lancamento_financeiro
ALTER TABLE public.lancamento_financeiro ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "lancamento_financeiro_tenant_isolation" ON public.lancamento_financeiro;
CREATE POLICY "lancamento_financeiro_tenant_isolation" ON public.lancamento_financeiro FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.membro_empresa m
    WHERE m."tenantId"::text = lancamento_financeiro."tenantId"::text
      AND m."usuarioId"::text = auth.uid()::text
      AND m.ativo = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.membro_empresa m
    WHERE m."tenantId"::text = lancamento_financeiro."tenantId"::text
      AND m."usuarioId"::text = auth.uid()::text
      AND m.ativo = true
  ));

-- 5. pedido
ALTER TABLE public.pedido ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS pedido_tenant_isolation ON public.pedido;
CREATE POLICY pedido_tenant_isolation ON public.pedido FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.membro_empresa m
    WHERE m."tenantId"::text = pedido."tenantId"::text
      AND m."usuarioId"::text = auth.uid()::text
      AND m.ativo = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.membro_empresa m
    WHERE m."tenantId"::text = pedido."tenantId"::text
      AND m."usuarioId"::text = auth.uid()::text
      AND m.ativo = true
  ));

-- 6. item_pedido
ALTER TABLE public.item_pedido ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS item_pedido_tenant_isolation ON public.item_pedido;
CREATE POLICY item_pedido_tenant_isolation ON public.item_pedido FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.membro_empresa m
    WHERE m."tenantId"::text = item_pedido."tenantId"::text
      AND m."usuarioId"::text = auth.uid()::text
      AND m.ativo = true
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.membro_empresa m
    WHERE m."tenantId"::text = item_pedido."tenantId"::text
      AND m."usuarioId"::text = auth.uid()::text
      AND m.ativo = true
  ));

PERFORM pg_notify('pgrst', 'reload schema');

END $$;
