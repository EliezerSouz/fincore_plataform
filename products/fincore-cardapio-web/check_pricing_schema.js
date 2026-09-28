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
    await client.connect();

    const tabs = await client.query(`SELECT * FROM tabela_precificacao`);
    console.log('=== TABELAS DE PRECIFICAÇÃO ===', tabs.rows);

    const itens = await client.query(`SELECT * FROM item_tabela_precificacao ORDER BY "quantidadeMinima"::int`);
    console.log('=== ITENS DA TABELA DE PRECIFICAÇÃO ===', itens.rows);

    const catTabs = await client.query(`SELECT * FROM categoria_tabela_precificacao`);
    console.log('=== CATEGORIA TABELA PRECIFICAÇÃO ===', catTabs.rows);

    const prodTabs = await client.query(`SELECT * FROM produto_tabela_precificacao`);
    console.log('=== PRODUTO TABELA PRECIFICAÇÃO ===', prodTabs.rows);

  } catch (e) {
    console.error('❌ Erro:', e);
  } finally {
    await client.end();
  }
}

run();
