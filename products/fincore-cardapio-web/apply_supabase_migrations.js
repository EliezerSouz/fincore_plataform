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
    console.log('Conectando ao banco PostgreSQL no Supabase...');
    await client.connect();
    console.log('Conectado com sucesso!');

    const files = [
      '001_cardapio_clientes.sql',
      '002_pedidos_web_rls.sql',
      '003_produtos_public_read.sql',
      '004_fix_sync_rls.sql'
    ];

    for (const f of files) {
      console.log(`Aplicando ${f}...`);
      const p = path.join(__dirname, 'supabase', f);
      const sql = fs.readFileSync(p, 'utf8');
      await client.query(sql);
      console.log(`✅ ${f} aplicado com sucesso!`);
    }

    // Testar as views criadas
    const resEmp = await client.query(`SELECT COUNT(*) FROM vw_cardapio_empresa`);
    const resProd = await client.query(`SELECT COUNT(*) FROM vw_cardapio_produtos`);
    console.log(`✨ Teste da view vw_cardapio_empresa: ${resEmp.rows[0].count} empresas.`);
    console.log(`✨ Teste da view vw_cardapio_produtos: ${resProd.rows[0].count} produtos visíveis.`);

    console.log('\n🎉 TODAS AS MIGRAÇÕES FORAM APLICADAS COM SUCESSO NO SUPABASE!');
  } catch (e) {
    console.error('❌ Erro na execução:', e);
  } finally {
    await client.end();
  }
}

run();
