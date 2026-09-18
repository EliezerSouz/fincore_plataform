DO $$ 
BEGIN

-- 1. estoque_produto: permitir sincronização de estoque via app local
ALTER TABLE public.estoque_produto DISABLE ROW LEVEL SECURITY;

-- 2. movimentacao_estoque: permitir sincronização de movimentações via app local
ALTER TABLE public.movimentacao_estoque DISABLE ROW LEVEL SECURITY;

-- 3. planejamento_producao: permitir sincronização de planos de produção via app local
ALTER TABLE public.planejamento_producao DISABLE ROW LEVEL SECURITY;

PERFORM pg_notify('pgrst', 'reload schema');

END $$;
