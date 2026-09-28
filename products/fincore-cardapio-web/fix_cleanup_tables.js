const { Client } = require('pg');

const config = {
  host: 'db.nlaxdeqbordmovukyypk.supabase.co',
  port: 5432,
  user: 'postgres',
  password: 'GeR9cjvrXrujvL0R',
  database: 'postgres',
  ssl: { rejectUnauthorized: false },
  connectionTimeoutMillis: 10000,
};

async function run() {
  const client = new Client(config);
  try {
    console.log('Conectando ao banco Supabase PostgreSQL...');
    await client.connect();

    // 1. Remover tabelas plurais redundantes que foram criadas por engano
    const redundantTables = ['pedidos', 'produtos', 'categorias', 'empresas', 'clientes', 'itens_pedido'];
    for (const tbl of redundantTables) {
      console.log(`Removendo tabela redundante se existir: ${tbl}...`);
      await client.query(`DROP TABLE IF EXISTS public.${tbl} CASCADE;`);
    }

    // 2. Verificar tabelas reais do sistema Windows
    const res = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
      ORDER BY table_name;
    `);
    console.log('Tabelas BASE reais do sistema:', res.rows.map(r => r.table_name));

    // 3. Garantir views conectando direto nas tabelas reais do Windows (produto, categoria, empresa)
    console.log('Recriando views apontando EXCLUSIVAMENTE para as tabelas reais do sistema Windows...');

    await client.query(`
      -- View pública de empresa (tabela 'empresa')
      CREATE OR REPLACE VIEW public.vw_cardapio_empresa AS
        SELECT
          id                AS tenant_id,
          "nomeFantasia"    AS nome_fantasia,
          "razaoSocial"     AS razao_social,
          "telefone"        AS whatsapp,
          NULL::jsonb       AS metadata_payload
        FROM public.empresa
        WHERE "deletedAt" IS NULL;

      -- View pública de produtos (tabelas 'produto' e 'categoria')
      CREATE OR REPLACE VIEW public.vw_cardapio_produtos AS
        SELECT
          p.id,
          p."tenantId"         AS tenant_id,
          p.nome,
          p.descricao,
          p."categoriaId"      AS categoria_id,
          p.imagem,
          p."corEtiqueta"      AS cor_etiqueta,
          p."unidadeVenda"     AS unidade_venda,
          p.metadata,
          p.ativo,
          p."statusComercial"  AS status_comercial,
          p."ordemProducao"    AS ordem_producao,
          c.nome               AS categoria_nome,
          c.icone              AS categoria_icone,
          c.cor                AS categoria_cor,
          c."ordemExibicao"    AS categoria_ordem
        FROM public.produto p
        JOIN public.categoria c ON c.id = p."categoriaId"
        WHERE p.ativo = true
          AND p."deletedAt" IS NULL
          AND c.ativo = true
          AND c."deletedAt" IS NULL
        ORDER BY c."ordemExibicao", p."ordemProducao";
    `);

    // 4. RLS na tabela REAL 'pedido' e 'item_pedido'
    await client.query(`
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
    `);

    console.log('✅ Limpeza concluída! Tabelas redundantes removidas e RLS configurado nas tabelas reais.');

  } catch (e) {
    console.error('❌ Erro:', e);
  } finally {
    await client.end();
  }
}

run();
