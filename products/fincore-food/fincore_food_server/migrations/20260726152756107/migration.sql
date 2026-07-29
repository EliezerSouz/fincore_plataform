BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "usuarios" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "email" text NOT NULL,
    "nome" text NOT NULL,
    "criadoEm" timestamp without time zone NOT NULL,
    "atualizadoEm" timestamp without time zone NOT NULL
);


--
-- MIGRATION VERSION FOR fincore_food
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('fincore_food', '20260726152756107', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260726152756107', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
