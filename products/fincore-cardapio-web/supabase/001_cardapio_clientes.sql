-- ═══════════════════════════════════════════════════════════════════════
-- FINCORE Food — Cardápio Digital Web
-- Migration 001: Tabela cardapio_clientes
-- ═══════════════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS public.cardapio_clientes (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id        TEXT NOT NULL,
  nome             TEXT NOT NULL,
  whatsapp         TEXT NOT NULL,
  email            TEXT,
  cep              TEXT NOT NULL DEFAULT '',
  logradouro       TEXT NOT NULL DEFAULT '',
  numero           TEXT NOT NULL DEFAULT '',
  complemento      TEXT,
  bairro           TEXT NOT NULL DEFAULT '',
  cidade           TEXT NOT NULL DEFAULT '',
  uf               TEXT NOT NULL DEFAULT 'SP',
  referencia       TEXT,
  endereco_padrao  TEXT,
  cliente_local_id TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  ativo            BOOLEAN NOT NULL DEFAULT true,

  CONSTRAINT cardapio_clientes_user_unique UNIQUE (user_id, tenant_id)
);

CREATE INDEX IF NOT EXISTS idx_cardapio_clientes_tenant ON public.cardapio_clientes (tenant_id);
CREATE INDEX IF NOT EXISTS idx_cardapio_clientes_user ON public.cardapio_clientes (user_id);
CREATE INDEX IF NOT EXISTS idx_cardapio_clientes_whatsapp ON public.cardapio_clientes (whatsapp);

ALTER TABLE public.cardapio_clientes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cliente_select_own" ON public.cardapio_clientes;
CREATE POLICY "cliente_select_own" ON public.cardapio_clientes FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "cliente_insert_own" ON public.cardapio_clientes;
CREATE POLICY "cliente_insert_own" ON public.cardapio_clientes FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "cliente_update_own" ON public.cardapio_clientes;
CREATE POLICY "cliente_update_own" ON public.cardapio_clientes FOR UPDATE USING (auth.uid() = user_id);


