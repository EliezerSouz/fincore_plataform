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

  console.log('=== PRODUTOS E SEUS TENANTS ===');
  const resProd = await client.query(`
    SELECT p.id, p."tenantId", p.nome, e."nomeFantasia"
    FROM public.produto p
    LEFT JOIN public.empresa e ON e.id = p."tenantId"::uuid
  `);
  console.log(resProd.rows);

  console.log('\n=== CATEGORIAS E SEUS TENANTS ===');
  const resCat = await client.query(`
    SELECT c.id, c."tenantId", c.nome, e."nomeFantasia"
    FROM public.categoria c
    LEFT JOIN public.empresa e ON e.id = c."tenantId"::uuid
  `);
  console.log(resCat.rows);

  await client.end();
}

run();
