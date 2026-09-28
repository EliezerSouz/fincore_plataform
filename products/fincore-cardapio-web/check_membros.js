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

  console.log('=== MEMBRO_EMPRESA ===');
  const res = await client.query(`SELECT * FROM public.membro_empresa`);
  console.log(res.rows);

  await client.end();
}

run();
