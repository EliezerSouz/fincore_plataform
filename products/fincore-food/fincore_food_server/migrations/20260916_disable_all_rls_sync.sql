DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Desabilita RLS em todas as tabelas de negócio da aplicação no Supabase
    -- garantindo sincronização sem erros de RLS 42501 (Forbidden / Row Level Security)
    FOR r IN (
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
          AND tablename NOT LIKE 'serverpod_%'
          AND tablename NOT LIKE '_custom_%'
    ) LOOP
        EXECUTE format('ALTER TABLE public.%I DISABLE ROW LEVEL SECURITY;', r.tablename);
    END LOOP;

    PERFORM pg_notify('pgrst', 'reload schema');
END $$;
