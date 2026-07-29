BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "eventos_empresa" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" uuid NOT NULL,
    "tipo" text NOT NULL,
    "payload" text,
    "geradoPor" text NOT NULL,
    "ocorridoEm" timestamp without time zone NOT NULL
);


--
-- MIGRATION VERSION FOR fincore_food
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('fincore_food', '20260726170830144', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260726170830144', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
