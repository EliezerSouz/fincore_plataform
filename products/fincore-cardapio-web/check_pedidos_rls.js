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

  console.log('=== POLÍTICAS EM PEDIDO ===');
  const resPed = await client.query(`SELECT policyname, cmd, roles, qual, with_check FROM pg_policies WHERE tablename = 'pedido'`);
  console.log(resPed.rows);

  console.log('\n=== POLÍTICAS EM ITEM_PEDIDO ===');
  const resItem = await client.query(`SELECT policyname, cmd, roles, qual, with_check FROM pg_policies WHERE tablename = 'item_pedido'`);
  console.log(resItem.rows);

  await client.end();
}

run();
