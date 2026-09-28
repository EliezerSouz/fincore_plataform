const { Client } = require('pg');

const config = {
  host: 'db.nlaxdeqbordmovukyypk.supabase.co',
  port: 5432,
  user: 'postgres',
  password: 'GeR9cjvrXrujvL0R',
  database: 'postgres',
  ssl: { rejectUnauthorized: false },
};

async function run() {
  const client = new Client(config);
  await client.connect();

  console.log('=== CARDAPIO_CLIENTES ===');
  const resCc = await client.query(`SELECT id, user_id, tenant_id, nome, whatsapp FROM public.cardapio_clientes`);
  console.log(resCc.rows);

  console.log('\n=== ITENS_PEDIDO DA SOLANGE SALGADOS (64f61559-2c0c-46e0-8411-3aa299541fdf) ===');
  const resItemSol = await client.query(`
    SELECT ip.id, ip."pedidoId", ip."produtoId", ip."nomeProduto", ip."tenantId", p."clienteNomeAvulso"
    FROM public.item_pedido ip
    LEFT JOIN public.pedido p ON p.id = ip."pedidoId"
    WHERE ip."tenantId" = '64f61559-2c0c-46e0-8411-3aa299541fdf'
  `);
  console.log(resItemSol.rows);

  console.log('\n=== ORDENS_PREPARO DA SOLANGE SALGADOS (64f61559-2c0c-46e0-8411-3aa299541fdf) ===');
  const resOpSol = await client.query(`
    SELECT op.id, op."pedidoId", op."tenantId", op.observacoes
    FROM public.ordens_preparo op
    WHERE op."tenantId" = '64f61559-2c0c-46e0-8411-3aa299541fdf'
  `);
  console.log(resOpSol.rows);

  await client.end();
}

run();
