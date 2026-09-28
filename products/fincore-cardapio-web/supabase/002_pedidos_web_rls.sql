-- ═══════════════════════════════════════════════════════════════════════
-- FINCORE Food — Cardápio Digital Web
-- Migration 002: RLS na tabela pedido para clientes web
-- ═══════════════════════════════════════════════════════════════════════

-- Habilitar RLS nas tabelas 'pedido' (singular) e 'pedidos' (plural) se existirem
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'pedido') THEN
    ALTER TABLE public.pedido ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS "cliente_web_select_pedido" ON public.pedido;
    CREATE POLICY "cliente_web_select_pedido" ON public.pedido
      FOR SELECT USING (
        "clienteId"::text IN (
          SELECT id::text FROM public.cardapio_clientes WHERE user_id = auth.uid()
        )
      );

    DROP POLICY IF EXISTS "cliente_web_insert_pedido" ON public.pedido;
    CREATE POLICY "cliente_web_insert_pedido" ON public.pedido
      FOR INSERT WITH CHECK (
        "clienteId"::text IN (
          SELECT id::text FROM public.cardapio_clientes WHERE user_id = auth.uid()
        )
        AND "canalOrigem" = 'cardapio_web'
      );
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'pedidos') THEN
    ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS "cliente_web_select_pedidos" ON public.pedidos;
    CREATE POLICY "cliente_web_select_pedidos" ON public.pedidos
      FOR SELECT USING (
        cliente_id::text IN (
          SELECT id::text FROM public.cardapio_clientes WHERE user_id = auth.uid()
        )
      );

    DROP POLICY IF EXISTS "cliente_web_insert_pedidos" ON public.pedidos;
    CREATE POLICY "cliente_web_insert_pedidos" ON public.pedidos
      FOR INSERT WITH CHECK (
        cliente_id::text IN (
          SELECT id::text FROM public.cardapio_clientes WHERE user_id = auth.uid()
        )
        AND canal_origem = 'cardapio_web'
      );
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'item_pedido') THEN
    ALTER TABLE public.item_pedido ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS "cliente_web_select_item_pedido" ON public.item_pedido;
    CREATE POLICY "cliente_web_select_item_pedido" ON public.item_pedido
      FOR SELECT USING (
        "pedidoId"::text IN (
          SELECT p.id::text FROM public.pedido p
          JOIN public.cardapio_clientes cc ON cc.id::text = p."clienteId"::text
          WHERE cc.user_id = auth.uid()
        )
      );

    DROP POLICY IF EXISTS "cliente_web_insert_item_pedido" ON public.item_pedido;
    CREATE POLICY "cliente_web_insert_item_pedido" ON public.item_pedido
      FOR INSERT WITH CHECK (
        "pedidoId"::text IN (
          SELECT p.id::text FROM public.pedido p
          JOIN public.cardapio_clientes cc ON cc.id::text = p."clienteId"::text
          WHERE cc.user_id = auth.uid()
        )
      );
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'ordens_preparo') THEN
    ALTER TABLE public.ordens_preparo ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS "cliente_web_select_ordens_preparo" ON public.ordens_preparo;
    CREATE POLICY "cliente_web_select_ordens_preparo" ON public.ordens_preparo
      FOR SELECT USING (
        "pedidoId"::text IN (
          SELECT p.id::text FROM public.pedido p
          JOIN public.cardapio_clientes cc ON cc.id::text = p."clienteId"::text
          WHERE cc.user_id = auth.uid()
        )
      );

    DROP POLICY IF EXISTS "cliente_web_insert_ordens_preparo" ON public.ordens_preparo;
    CREATE POLICY "cliente_web_insert_ordens_preparo" ON public.ordens_preparo
      FOR INSERT WITH CHECK (
        "pedidoId"::text IN (
          SELECT p.id::text FROM public.pedido p
          JOIN public.cardapio_clientes cc ON cc.id::text = p."clienteId"::text
          WHERE cc.user_id = auth.uid()
        )
      );
  END IF;
END $$;


