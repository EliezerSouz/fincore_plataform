BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "audit_logs" (
    "id" bigserial PRIMARY KEY,
    "entityName" text NOT NULL,
    "entityId" text NOT NULL,
    "userId" text NOT NULL,
    "action" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "diff" text,
    "deviceInfo" text,
    "origin" text,
    "reason" text
);

--
-- ACTION ALTER TABLE
--
ALTER TABLE "empresa" ADD COLUMN "segmento" text;
--
-- ACTION DROP TABLE
--
DROP TABLE "empresa_configuracao" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "empresa_configuracao" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" text NOT NULL,
    "timezone" text NOT NULL,
    "locale" text NOT NULL,
    "currency" text NOT NULL,
    "printerConfig" text,
    "pixKey" text,
    "taxaServico" double precision NOT NULL,
    "usarWhatsApp" boolean NOT NULL,
    "logoUrl" text,
    "tema" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "createdBy" uuid NOT NULL,
    "updatedBy" uuid NOT NULL,
    "deletedAt" timestamp without time zone,
    "deletedBy" uuid,
    "syncVersion" bigint NOT NULL,
    "originDeviceId" text,
    "lastModifiedByDevice" text,
    "entityHash" text,
    "printerCaixa" text,
    "printerCozinha" text,
    "printerBalcao" text,
    "printerExpedicao" text,
    "autoPrintCaixa" boolean NOT NULL,
    "autoPrintCozinha" boolean NOT NULL,
    "autoPrintBalcao" boolean NOT NULL,
    "autoPrintExpedicao" boolean NOT NULL,
    "viasCliente" bigint NOT NULL,
    "viasCozinha" bigint NOT NULL,
    "viasBalcao" bigint NOT NULL,
    "viasExpedicao" bigint NOT NULL,
    "larguraPapel" bigint NOT NULL,
    "cortarPapel" boolean NOT NULL,
    "abrirGaveta" boolean NOT NULL,
    "imprimirQRCode" boolean NOT NULL,
    "imprimirCopiaCola" boolean NOT NULL,
    "imprimirLogo" boolean NOT NULL,
    "imprimirRodape" boolean NOT NULL,
    "mensagemRodape" text NOT NULL,
    "pixFavorecido" text,
    "pixBanco" text,
    "pixTipo" text NOT NULL,
    "pixCidade" text NOT NULL,
    "nomeEmpresaCupom" text,
    "telefoneEmpresa" text,
    "cnpjEmpresa" text,
    "enderecoEmpresa" text
);

--
-- ACTION ALTER TABLE
--
--
-- ACTION ALTER TABLE
--
--
-- ACTION ALTER TABLE
--
ALTER TABLE "produto_tabela_precificacao" DROP CONSTRAINT "produto_tabela_precificacao_fk_0";
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "eventos_empresa"
    ADD CONSTRAINT "eventos_empresa_fk_0"
    FOREIGN KEY("tenantId")
    REFERENCES "empresa"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "membro_empresa"
    ADD CONSTRAINT "membro_empresa_fk_0"
    FOREIGN KEY("tenantId")
    REFERENCES "empresa"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "membro_empresa"
    ADD CONSTRAINT "membro_empresa_fk_1"
    FOREIGN KEY("usuarioId")
    REFERENCES "usuarios"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "produto_tabela_precificacao"
    ADD CONSTRAINT "produto_tabela_precificacao_fk_0"
    FOREIGN KEY("produtoId")
    REFERENCES "produto"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- MIGRATION VERSION FOR fincore_food
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('fincore_food', '20260728164752744', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260728164752744', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
