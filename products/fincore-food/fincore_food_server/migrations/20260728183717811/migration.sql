BEGIN;

--
-- ACTION ALTER TABLE
--
CREATE UNIQUE INDEX "empresa_documento_fiscal_unique_idx" ON "empresa" USING btree ("documentoFiscal");
CREATE UNIQUE INDEX "empresa_email_unique_idx" ON "empresa" USING btree ("email");

--
-- MIGRATION VERSION FOR fincore_food
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('fincore_food', '20260728183717811', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260728183717811', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
