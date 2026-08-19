BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "empresa" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "empresa" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "razaoSocial" text NOT NULL,
    "nomeFantasia" text NOT NULL,
    "documentoFiscal" text NOT NULL,
    "email" text NOT NULL,
    "telefone" text NOT NULL,
    "status" text NOT NULL,
    "plano" text NOT NULL,
    "timezone" text NOT NULL,
    "locale" text NOT NULL,
    "currency" text NOT NULL,
    "country" text NOT NULL,
    "createdFrom" text NOT NULL,
    "vencimento" timestamp without time zone,
    "segmento" text,
    "tipoPessoa" text NOT NULL,
    "inscricaoEstadual" text,
    "inscricaoMunicipal" text,
    "regimeTributario" text,
    "cep" text,
    "logradouro" text,
    "numero" text,
    "complemento" text,
    "bairro" text,
    "cidade" text,
    "estado" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "createdBy" uuid NOT NULL,
    "updatedBy" uuid NOT NULL,
    "deletedAt" timestamp without time zone,
    "deletedBy" uuid,
    "syncVersion" bigint NOT NULL,
    "originDeviceId" text,
    "lastModifiedByDevice" text,
    "entityHash" text
);

-- Indexes
CREATE UNIQUE INDEX "empresa_documento_fiscal_unique_idx" ON "empresa" USING btree ("documentoFiscal");
CREATE UNIQUE INDEX "empresa_email_unique_idx" ON "empresa" USING btree ("email");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "empresa_configuracao" DROP COLUMN IF EXISTS "timezone";
ALTER TABLE "empresa_configuracao" DROP COLUMN IF EXISTS "locale";
ALTER TABLE "empresa_configuracao" DROP COLUMN IF EXISTS "currency";
ALTER TABLE "empresa_configuracao" DROP COLUMN IF EXISTS "pixCidade";
ALTER TABLE "empresa_configuracao" DROP COLUMN IF EXISTS "nomeEmpresaCupom";
ALTER TABLE "empresa_configuracao" DROP COLUMN IF EXISTS "telefoneEmpresa";
ALTER TABLE "empresa_configuracao" DROP COLUMN IF EXISTS "cnpjEmpresa";
ALTER TABLE "empresa_configuracao" DROP COLUMN IF EXISTS "enderecoEmpresa";
ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "modoDeliveryAtivo" boolean;
ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "clienteObrigatorioVenda" boolean;
ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "atendimentoPadrao" text;
ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "margemSegurancaMinutos" bigint;
ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "taxaEntregaPorKm" boolean;
ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "valorPorKmCentavos" bigint;
ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "mercadoPagoAtivo" boolean;
ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "openPixAtivo" boolean;
ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "asaasAtivo" boolean;
ALTER TABLE "empresa_configuracao" ADD COLUMN IF NOT EXISTS "ifoodAtivo" boolean;
--
-- ACTION CREATE TABLE
--
CREATE TABLE IF NOT EXISTS "empresa_convite" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" uuid NOT NULL,
    "email" text NOT NULL,
    "role" text NOT NULL,
    "status" text NOT NULL,
    "expiracaoEm" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "createdBy" uuid NOT NULL,
    "updatedBy" uuid NOT NULL,
    "deletedAt" timestamp without time zone,
    "deletedBy" uuid,
    "syncVersion" bigint NOT NULL,
    "originDeviceId" text,
    "lastModifiedByDevice" text,
    "entityHash" text
);

-- Indexes
CREATE INDEX IF NOT EXISTS "convite_tenant_idx" ON "empresa_convite" USING btree ("tenantId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE IF NOT EXISTS "historicos_ordem_preparo" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" text NOT NULL,
    "ordemPreparoId" text NOT NULL,
    "titulo" text NOT NULL,
    "descricao" text NOT NULL,
    "operadorNome" text NOT NULL,
    "criadaEm" timestamp without time zone NOT NULL,
    "versao" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "createdBy" uuid NOT NULL,
    "updatedBy" uuid NOT NULL,
    "deletedAt" timestamp without time zone,
    "deletedBy" uuid,
    "syncVersion" bigint NOT NULL,
    "originDeviceId" text,
    "lastModifiedByDevice" text,
    "entityHash" text
);

-- Indexes
CREATE INDEX IF NOT EXISTS "hist_ordem_preparo_tenant_ordem_idx" ON "historicos_ordem_preparo" USING btree ("tenantId", "ordemPreparoId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE IF NOT EXISTS "lotes_insumo" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" text NOT NULL,
    "produtoId" text NOT NULL,
    "codigoLote" text,
    "quantidadeInicial" bigint NOT NULL,
    "quantidadeDisponivel" bigint NOT NULL,
    "quantidadeReservada" bigint NOT NULL,
    "unidade" text NOT NULL,
    "dataValidade" timestamp without time zone,
    "dataEntrada" timestamp without time zone NOT NULL,
    "statusLote" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "createdBy" uuid NOT NULL,
    "updatedBy" uuid NOT NULL,
    "deletedAt" timestamp without time zone,
    "deletedBy" uuid,
    "syncVersion" bigint NOT NULL,
    "originDeviceId" text,
    "lastModifiedByDevice" text,
    "entityHash" text
);

-- Indexes
CREATE INDEX IF NOT EXISTS "lotes_insumo_tenant_produto_idx" ON "lotes_insumo" USING btree ("tenantId", "produtoId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE IF NOT EXISTS "ordens_preparo" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" text NOT NULL,
    "pedidoId" text NOT NULL,
    "itensJson" text NOT NULL,
    "status" text NOT NULL,
    "prioridade" text NOT NULL,
    "operadorId" text,
    "criadaEm" timestamp without time zone NOT NULL,
    "iniciadaEm" timestamp without time zone,
    "concluidaEm" timestamp without time zone,
    "canceladaEm" timestamp without time zone,
    "tempoEstimadoSegundos" bigint NOT NULL,
    "observacoes" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "createdBy" uuid NOT NULL,
    "updatedBy" uuid NOT NULL,
    "deletedAt" timestamp without time zone,
    "deletedBy" uuid,
    "syncVersion" bigint NOT NULL,
    "originDeviceId" text,
    "lastModifiedByDevice" text,
    "entityHash" text
);

-- Indexes
CREATE INDEX IF NOT EXISTS "ordens_preparo_tenant_status_idx" ON "ordens_preparo" USING btree ("tenantId", "status");
CREATE INDEX IF NOT EXISTS "ordens_preparo_tenant_pedido_idx" ON "ordens_preparo" USING btree ("tenantId", "pedidoId");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "taxa_entrega" ADD COLUMN IF NOT EXISTS "pedidoMinimoCentavos" bigint NOT NULL DEFAULT 0;
ALTER TABLE "taxa_entrega" ADD COLUMN IF NOT EXISTS "prazoEstimado" text;
ALTER TABLE "taxa_entrega" ADD COLUMN IF NOT EXISTS "observacoes" text;
--
-- ACTION DROP TABLE
--
DROP TABLE "usuarios" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "usuarios" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" text NOT NULL,
    "authUserId" text,
    "username" text NOT NULL,
    "email" text,
    "nome" text NOT NULL,
    "avatarUrl" text,
    "ativo" boolean NOT NULL,
    "criadoEm" timestamp without time zone NOT NULL,
    "atualizadoEm" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX IF NOT EXISTS "usr_tenant_username_idx" ON "usuarios" USING btree ("tenantId", "username");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "empresa_convite" DROP CONSTRAINT IF EXISTS "empresa_convite_fk_0";
ALTER TABLE ONLY "empresa_convite"
    ADD CONSTRAINT "empresa_convite_fk_0"
    FOREIGN KEY("tenantId")
    REFERENCES "empresa"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR fincore_food
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('fincore_food', '20260814152831799', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260814152831799', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
