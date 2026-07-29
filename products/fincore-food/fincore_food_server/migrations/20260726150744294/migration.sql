BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "categoria" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "categoria" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" text NOT NULL,
    "parentId" uuid,
    "nome" text NOT NULL,
    "descricao" text NOT NULL,
    "ordemExibicao" bigint NOT NULL,
    "ativo" boolean NOT NULL,
    "icone" text,
    "cor" text,
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
CREATE INDEX "categoria_tenant_idx" ON "categoria" USING btree ("tenantId");
CREATE INDEX "categoria_parent_idx" ON "categoria" USING btree ("tenantId", "parentId");

--
-- ACTION DROP TABLE
--
DROP TABLE "cliente" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "cliente" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" text NOT NULL,
    "nome" text NOT NULL,
    "telefone" text NOT NULL,
    "email" text,
    "documento" text,
    "observacoes" text NOT NULL,
    "ativo" boolean NOT NULL,
    "apelido" text,
    "dataNascimento" timestamp without time zone,
    "aceitaWhatsapp" boolean NOT NULL,
    "aceitaMarketing" boolean NOT NULL,
    "preferenciaEntrega" text,
    "limiteCredito" bigint,
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
CREATE INDEX "cliente_tenant_tel_idx" ON "cliente" USING btree ("tenantId", "telefone");
CREATE INDEX "cliente_tenant_doc_idx" ON "cliente" USING btree ("tenantId", "documento");
CREATE INDEX "cliente_tenant_ativo_idx" ON "cliente" USING btree ("tenantId", "ativo");

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
    "entityHash" text
);

--
-- ACTION DROP TABLE
--
DROP TABLE "forma_pagamento" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "forma_pagamento" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" text NOT NULL,
    "nome" text NOT NULL,
    "tipo" text NOT NULL,
    "ordem" bigint NOT NULL,
    "ativo" boolean NOT NULL,
    "permiteTroco" boolean NOT NULL,
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
CREATE INDEX "forma_pag_tenant_idx" ON "forma_pagamento" USING btree ("tenantId");

--
-- ACTION DROP TABLE
--
DROP TABLE "item_tabela_precificacao" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "item_tabela_precificacao" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" text NOT NULL,
    "tabelaPrecificacaoId" uuid NOT NULL,
    "quantidadeMinima" bigint NOT NULL,
    "quantidadeMaxima" bigint,
    "valorUnitarioCentavos" bigint NOT NULL,
    "ordem" bigint NOT NULL,
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
CREATE INDEX "item_tabela_prec_idx" ON "item_tabela_precificacao" USING btree ("tenantId", "tabelaPrecificacaoId");

--
-- ACTION DROP TABLE
--
DROP TABLE "local_entrega" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "local_entrega" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" text NOT NULL,
    "clienteId" uuid NOT NULL,
    "nomeIdentificador" text NOT NULL,
    "logradouro" text NOT NULL,
    "numero" text NOT NULL,
    "bairro" text NOT NULL,
    "cidade" text NOT NULL,
    "cep" text NOT NULL,
    "referencia" text NOT NULL,
    "ativo" boolean NOT NULL,
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
CREATE INDEX "local_entrega_cliente_idx" ON "local_entrega" USING btree ("tenantId", "clienteId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "membro_empresa" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" uuid NOT NULL,
    "usuarioId" uuid NOT NULL,
    "role" text NOT NULL,
    "ativo" boolean NOT NULL,
    "convidadoEm" timestamp without time zone NOT NULL,
    "aceitoEm" timestamp without time zone,
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

--
-- ACTION DROP TABLE
--
DROP TABLE "produto" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "produto" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" text NOT NULL,
    "codigo" text,
    "nome" text NOT NULL,
    "descricao" text,
    "categoriaId" uuid NOT NULL,
    "unidadeVenda" text NOT NULL,
    "statusComercial" text NOT NULL,
    "tempoMedioMinutos" bigint NOT NULL,
    "controlaEstoque" boolean NOT NULL,
    "ordemProducao" bigint NOT NULL,
    "ativo" boolean NOT NULL,
    "sku" text,
    "codigoBarras" text,
    "imagem" text,
    "corEtiqueta" text,
    "metadata" text,
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
CREATE INDEX "produto_tenant_cat_idx" ON "produto" USING btree ("tenantId", "categoriaId");
CREATE INDEX "produto_tenant_ativo_idx" ON "produto" USING btree ("tenantId", "ativo");
CREATE INDEX "produto_tenant_cod_idx" ON "produto" USING btree ("tenantId", "codigo");

--
-- ACTION DROP TABLE
--
DROP TABLE "produto_tabela_precificacao" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "produto_tabela_precificacao" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" text NOT NULL,
    "produtoId" uuid NOT NULL,
    "tabelaPrecificacaoId" uuid NOT NULL,
    "ativo" boolean NOT NULL,
    "prioridade" bigint NOT NULL,
    "dataInicio" timestamp without time zone,
    "dataFim" timestamp without time zone,
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
CREATE INDEX "prod_tabela_prec_compound_idx" ON "produto_tabela_precificacao" USING btree ("tenantId", "produtoId", "tabelaPrecificacaoId");

--
-- ACTION DROP TABLE
--
DROP TABLE "tabela_precificacao" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "tabela_precificacao" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" text NOT NULL,
    "nome" text NOT NULL,
    "descricao" text NOT NULL,
    "tipoPolitica" text NOT NULL,
    "prioridade" bigint NOT NULL,
    "ativo" boolean NOT NULL,
    "vigenciaInicio" timestamp without time zone,
    "vigenciaFim" timestamp without time zone,
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
CREATE INDEX "tabela_prec_tenant_idx" ON "tabela_precificacao" USING btree ("tenantId");

--
-- ACTION DROP TABLE
--
DROP TABLE "taxa_entrega" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "taxa_entrega" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "tenantId" text NOT NULL,
    "nome" text NOT NULL,
    "tipoRegra" text NOT NULL,
    "bairro" text,
    "cepInicial" text,
    "cepFinal" text,
    "valorCentavos" bigint NOT NULL,
    "ativo" boolean NOT NULL,
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
CREATE INDEX "taxa_ent_tenant_idx" ON "taxa_entrega" USING btree ("tenantId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "categoria"
    ADD CONSTRAINT "categoria_fk_0"
    FOREIGN KEY("parentId")
    REFERENCES "categoria"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "item_tabela_precificacao"
    ADD CONSTRAINT "item_tabela_precificacao_fk_0"
    FOREIGN KEY("tabelaPrecificacaoId")
    REFERENCES "tabela_precificacao"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "local_entrega"
    ADD CONSTRAINT "local_entrega_fk_0"
    FOREIGN KEY("clienteId")
    REFERENCES "cliente"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "produto"
    ADD CONSTRAINT "produto_fk_0"
    FOREIGN KEY("categoriaId")
    REFERENCES "categoria"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "produto_tabela_precificacao"
    ADD CONSTRAINT "produto_tabela_precificacao_fk_0"
    FOREIGN KEY("produtoId")
    REFERENCES "produto"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "produto_tabela_precificacao"
    ADD CONSTRAINT "produto_tabela_precificacao_fk_1"
    FOREIGN KEY("tabelaPrecificacaoId")
    REFERENCES "tabela_precificacao"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR fincore_food
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('fincore_food', '20260726150744294', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260726150744294', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
