BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "audit_logs" ADD COLUMN "syncVersion" bigint;

--
-- MIGRATION VERSION FOR fincore_food
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('fincore_food', '20260729020506179', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260729020506179', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
