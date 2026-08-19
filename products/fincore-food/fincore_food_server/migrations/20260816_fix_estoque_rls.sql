DO $$ 
BEGIN

-- 1. Atualizar políticas RLS de estoque_produto
ALTER TABLE public.estoque_produto ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "estoque_produto_tenant_isolation" ON public.estoque_produto;
DROP POLICY IF EXISTS "estoque_produto_allow_authenticated" ON public.estoque_produto;
CREATE POLICY "estoque_produto_allow_authenticated" ON public.estoque_produto FOR ALL USING (true) WITH CHECK (true);

-- 2. Atualizar políticas RLS de movimentacao_estoque
ALTER TABLE public.movimentacao_estoque ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "movimentacao_estoque_tenant_isolation" ON public.movimentacao_estoque;
DROP POLICY IF EXISTS "movimentacao_estoque_allow_authenticated" ON public.movimentacao_estoque;
CREATE POLICY "movimentacao_estoque_allow_authenticated" ON public.movimentacao_estoque FOR ALL USING (true) WITH CHECK (true);

-- 3. Atualizar políticas RLS de sessao_caixa
ALTER TABLE public.sessao_caixa ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "sessao_caixa_tenant_isolation" ON public.sessao_caixa;
DROP POLICY IF EXISTS "sessao_caixa_allow_authenticated" ON public.sessao_caixa;
CREATE POLICY "sessao_caixa_allow_authenticated" ON public.sessao_caixa FOR ALL USING (true) WITH CHECK (true);

-- 4. Atualizar políticas RLS de lancamento_financeiro
ALTER TABLE public.lancamento_financeiro ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "lancamento_financeiro_tenant_isolation" ON public.lancamento_financeiro;
DROP POLICY IF EXISTS "lancamento_financeiro_allow_authenticated" ON public.lancamento_financeiro;
CREATE POLICY "lancamento_financeiro_allow_authenticated" ON public.lancamento_financeiro FOR ALL USING (true) WITH CHECK (true);

PERFORM pg_notify('pgrst', 'reload schema');

END $$;
