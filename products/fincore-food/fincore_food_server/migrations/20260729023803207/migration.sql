BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "audit_logs" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "audit_logs" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "entityName" text NOT NULL,
    "entityId" text NOT NULL,
    "userId" text NOT NULL,
    "action" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "diff" text,
    "deviceInfo" text,
    "origin" text,
    "reason" text,
    "syncVersion" bigint,
    "tenantId" text
);


--
-- MIGRATION VERSION FOR fincore_food
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('fincore_food', '20260729023803207', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260729023803207', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
