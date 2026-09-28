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
  
  console.log('Disabling RLS on all tables...');
  await client.query(`
    DO $$ 
    DECLARE 
      r RECORD;
    BEGIN
      FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'ALTER TABLE public.' || quote_ident(r.tablename) || ' DISABLE ROW LEVEL SECURITY;';
        EXECUTE 'GRANT ALL ON public.' || quote_ident(r.tablename) || ' TO anon, authenticated, service_role;';
      END LOOP;
    END $$;
  `);
  console.log('All tables RLS disabled and granted ALL!');

  await client.end();
}

run();
