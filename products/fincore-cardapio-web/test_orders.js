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
  try {
    await client.connect();
    console.log('--- Inspecting Empresas in Supabase ---');

    const eRes = await client.query(`SELECT id, "nomeFantasia", "razaoSocial" FROM public.empresa`);
    console.log('Empresas no banco:', eRes.rows);

    const vwRes = await client.query(`SELECT * FROM public.vw_cardapio_empresa`);
    console.log('Empresas na view vw_cardapio_empresa:', vwRes.rows);

  } catch (err) {
    console.error('Error:', err);
  } finally {
    await client.end();
  }
}

run();
