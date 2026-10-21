-- ═══════════════════════════════════════════════════════════════════
-- Migration: 005_avaliacoes_pedidos.sql
-- Módulo de Pós-Venda, NPS e Avaliação de Pedidos (FINCORE Food Service)
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.avaliacoes_pedidos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  pedido_id UUID,
  numero_pedido VARCHAR(50),
  cliente_nome VARCHAR(255),
  cliente_telefone VARCHAR(50),
  nota INTEGER NOT NULL CHECK (nota >= 1 AND nota <= 5),
  tags JSONB DEFAULT '[]'::jsonb,
  comentario TEXT,
  origem VARCHAR(50) DEFAULT 'cardapio_web',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_avaliacoes_tenant_id ON public.avaliacoes_pedidos(tenant_id);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_pedido_id ON public.avaliacoes_pedidos(pedido_id);
CREATE INDEX IF NOT EXISTS idx_avaliacoes_created_at ON public.avaliacoes_pedidos(created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS idx_avaliacoes_unique_pedido ON public.avaliacoes_pedidos (tenant_id, pedido_id) WHERE pedido_id IS NOT NULL;

ALTER TABLE public.avaliacoes_pedidos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS avaliacoes_pedidos_insert_public ON public.avaliacoes_pedidos;
DROP POLICY IF EXISTS avaliacoes_pedidos_select_all ON public.avaliacoes_pedidos;

-- Permite inserção pública (cliente avalia sem barreiras)
CREATE POLICY avaliacoes_pedidos_insert_public
  ON public.avaliacoes_pedidos
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- Permite leitura de avaliações
CREATE POLICY avaliacoes_pedidos_select_all
  ON public.avaliacoes_pedidos
  FOR SELECT
  TO anon, authenticated
  USING (true);
