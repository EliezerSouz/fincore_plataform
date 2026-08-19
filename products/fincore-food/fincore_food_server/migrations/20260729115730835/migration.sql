BEGIN;

--
-- ACTION ALTER TABLE
--
CREATE UNIQUE INDEX "empresa_config_tenant_unique" ON "empresa_configuracao" USING btree ("tenantId");

--
-- MIGRATION VERSION FOR fincore_food
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('fincore_food', '20260729115730835', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260729115730835', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
