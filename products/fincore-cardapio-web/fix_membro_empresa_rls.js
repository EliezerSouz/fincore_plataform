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
  
  console.log('Fixing RLS policies on membro_empresa...');
  await client.query(`
    ALTER TABLE public.membro_empresa DISABLE ROW LEVEL SECURITY;
    GRANT ALL ON public.membro_empresa TO anon, authenticated, service_role;
  `);
  console.log('membro_empresa RLS disabled!');

  await client.end();
}

run();
