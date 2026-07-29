BEGIN;

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
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "createdBy" text NOT NULL,
    "updatedBy" text NOT NULL,
    "deletedAt" timestamp without time zone
);

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
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "createdBy" text NOT NULL,
    "updatedBy" text NOT NULL,
    "deletedAt" timestamp without time zone
);

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
    "createdBy" text NOT NULL,
    "updatedBy" text NOT NULL,
    "deletedAt" timestamp without time zone
);

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
    "createdBy" text NOT NULL,
    "updatedBy" text NOT NULL,
    "deletedAt" timestamp without time zone
);

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
    "createdBy" text NOT NULL,
    "updatedBy" text NOT NULL,
    "deletedAt" timestamp without time zone
);

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
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "createdBy" text NOT NULL,
    "updatedBy" text NOT NULL,
    "deletedAt" timestamp without time zone
);

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
    "createdBy" text NOT NULL,
    "updatedBy" text NOT NULL,
    "deletedAt" timestamp without time zone
);

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
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "createdBy" text NOT NULL,
    "updatedBy" text NOT NULL,
    "deletedAt" timestamp without time zone
);

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
    "createdBy" text NOT NULL,
    "updatedBy" text NOT NULL,
    "deletedAt" timestamp without time zone
);


--
-- MIGRATION VERSION FOR fincore_food
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('fincore_food', '20260726144717368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260726144717368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
