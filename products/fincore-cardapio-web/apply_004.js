const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

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

    const file = '004_precificacao_view.sql';
    console.log(`Aplicando ${file}...`);
    const p = path.join(__dirname, 'supabase', file);
    const sql = fs.readFileSync(p, 'utf8');
    await client.query(sql);
    console.log(`✅ ${file} aplicado com sucesso!`);

    const testRes = await client.query(`SELECT * FROM vw_cardapio_precificacao LIMIT 10`);
    console.log('--- Teste da view de precificação ---', testRes.rows);

  } catch (e) {
    console.error('❌ Erro:', e);
  } finally {
    await client.end();
  }
}

run();
