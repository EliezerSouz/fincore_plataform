-- ═══════════════════════════════════════════════════════════════════
-- FINCORE Platform — Migration 004: Correção COMPLETA das Políticas RLS para Sync Bidirecional
-- Resolve o erro 42501 (Forbidden / RLS_POLICY_DENIED) no PUSH das tabelas
-- pedido, item_pedido, empresa, ordens_preparo, produto, categoria e cliente.
-- ═══════════════════════════════════════════════════════════════════

-- 1. POLÍTICAS PARA TABELA pedido
ALTER TABLE public.pedido ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cliente_web_select_pedido ON public.pedido;
DROP POLICY IF EXISTS cliente_web_insert_pedido ON public.pedido;
DROP POLICY IF EXISTS pedido_tenant_isolation ON public.pedido;
DROP POLICY IF EXISTS pedido_sync_all ON public.pedido;

CREATE POLICY pedido_sync_all ON public.pedido
  FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

-- 2. POLÍTICAS PARA TABELA item_pedido
ALTER TABLE public.item_pedido ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cliente_web_select_item_pedido ON public.item_pedido;
DROP POLICY IF EXISTS cliente_web_insert_item_pedido ON public.item_pedido;
DROP POLICY IF EXISTS item_pedido_tenant_isolation ON public.item_pedido;
DROP POLICY IF EXISTS item_pedido_sync_all ON public.item_pedido;

CREATE POLICY item_pedido_sync_all ON public.item_pedido
  FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

-- 3. POLÍTICAS PARA TABELA empresa
ALTER TABLE public.empresa ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS empresa_public_read ON public.empresa;
DROP POLICY IF EXISTS empresa_sync_all ON public.empresa;

CREATE POLICY empresa_sync_all ON public.empresa
  FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

-- 4. POLÍTICAS PARA TABELA ordens_preparo
ALTER TABLE public.ordens_preparo ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cliente_web_select_ordens_preparo ON public.ordens_preparo;
DROP POLICY IF EXISTS cliente_web_insert_ordens_preparo ON public.ordens_preparo;
DROP POLICY IF EXISTS ordens_preparo_sync_all ON public.ordens_preparo;

CREATE POLICY ordens_preparo_sync_all ON public.ordens_preparo
  FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

-- 5. POLÍTICAS PARA TABELA produto
ALTER TABLE public.produto ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS produto_public_read ON public.produto;
DROP POLICY IF EXISTS produto_sync_all ON public.produto;

CREATE POLICY produto_sync_all ON public.produto
  FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

-- 6. POLÍTICAS PARA TABELA categoria
ALTER TABLE public.categoria ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS categoria_public_read ON public.categoria;
DROP POLICY IF EXISTS categoria_sync_all ON public.categoria;

CREATE POLICY categoria_sync_all ON public.categoria
  FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

-- 7. POLÍTICAS PARA TABELA cliente
ALTER TABLE public.cliente ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS cliente_sync_all ON public.cliente;

CREATE POLICY cliente_sync_all ON public.cliente
  FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);
