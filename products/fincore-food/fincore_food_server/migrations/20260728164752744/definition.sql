BEGIN;

--
-- Class AuditLog as table audit_logs
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
-- Class Categoria as table categoria
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
-- Class Cliente as table cliente
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
-- Class Empresa as table empresa
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
-- Class EmpresaConfiguracao as table empresa_configuracao
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
-- Class EventoEmpresa as table eventos_empresa
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
-- Class FormaPagamento as table forma_pagamento
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
-- Class ItemTabelaPrecificacao as table item_tabela_precificacao
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
-- Class LocalEntrega as table local_entrega
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
-- Class MembroEmpresa as table membro_empresa
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
-- Class Produto as table produto
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
-- Class ProdutoTabelaPrecificacao as table produto_tabela_precificacao
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
-- Class TabelaPrecificacao as table tabela_precificacao
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
-- Class TaxaEntrega as table taxa_entrega
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
-- Class Usuario as table usuarios
--
CREATE TABLE "usuarios" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "email" text NOT NULL,
    "nome" text NOT NULL,
    "criadoEm" timestamp without time zone NOT NULL,
    "atualizadoEm" timestamp without time zone NOT NULL
);

--
-- Class CloudStorageEntry as table serverpod_cloud_storage
--
CREATE TABLE "serverpod_cloud_storage" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    "expiration" timestamp without time zone,
    "byteData" bytea NOT NULL,
    "verified" boolean NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_path_idx" ON "serverpod_cloud_storage" USING btree ("storageId", "path");
CREATE INDEX "serverpod_cloud_storage_expiration" ON "serverpod_cloud_storage" USING btree ("expiration");

--
-- Class CloudStorageDirectUploadEntry as table serverpod_cloud_storage_direct_upload
--
CREATE TABLE "serverpod_cloud_storage_direct_upload" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_upload_storage_path" ON "serverpod_cloud_storage_direct_upload" USING btree ("storageId", "path");

--
-- Class FutureCallEntry as table serverpod_future_call
--
CREATE TABLE "serverpod_future_call" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    "identifier" text
);

-- Indexes
CREATE INDEX "serverpod_future_call_time_idx" ON "serverpod_future_call" USING btree ("time");
CREATE INDEX "serverpod_future_call_serverId_idx" ON "serverpod_future_call" USING btree ("serverId");
CREATE INDEX "serverpod_future_call_identifier_idx" ON "serverpod_future_call" USING btree ("identifier");

--
-- Class ServerHealthConnectionInfo as table serverpod_health_connection_info
--
CREATE TABLE "serverpod_health_connection_info" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "active" bigint NOT NULL,
    "closing" bigint NOT NULL,
    "idle" bigint NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_connection_info_timestamp_idx" ON "serverpod_health_connection_info" USING btree ("timestamp", "serverId", "granularity");

--
-- Class ServerHealthMetric as table serverpod_health_metric
--
CREATE TABLE "serverpod_health_metric" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    "value" double precision NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_metric_timestamp_idx" ON "serverpod_health_metric" USING btree ("timestamp", "serverId", "name", "granularity");

--
-- Class LogEntry as table serverpod_log
--
CREATE TABLE "serverpod_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "reference" text,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "logLevel" bigint NOT NULL,
    "message" text NOT NULL,
    "error" text,
    "stackTrace" text,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_log_sessionLogId_idx" ON "serverpod_log" USING btree ("sessionLogId");

--
-- Class MessageLogEntry as table serverpod_message_log
--
CREATE TABLE "serverpod_message_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "serverId" text NOT NULL,
    "messageId" bigint NOT NULL,
    "endpoint" text NOT NULL,
    "messageName" text NOT NULL,
    "duration" double precision NOT NULL,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

--
-- Class MethodInfo as table serverpod_method
--
CREATE TABLE "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" USING btree ("endpoint", "method");

--
-- Class DatabaseMigrationVersion as table serverpod_migrations
--
CREATE TABLE "serverpod_migrations" (
    "id" bigserial PRIMARY KEY,
    "module" text NOT NULL,
    "version" text NOT NULL,
    "timestamp" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_migrations_ids" ON "serverpod_migrations" USING btree ("module");

--
-- Class QueryLogEntry as table serverpod_query_log
--
CREATE TABLE "serverpod_query_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "query" text NOT NULL,
    "duration" double precision NOT NULL,
    "numRows" bigint,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON "serverpod_query_log" USING btree ("sessionLogId");

--
-- Class ReadWriteTestEntry as table serverpod_readwrite_test
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);

--
-- Class RuntimeSettings as table serverpod_runtime_settings
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);

--
-- Class SessionLogEntry as table serverpod_session_log
--
CREATE TABLE "serverpod_session_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "module" text,
    "endpoint" text,
    "method" text,
    "duration" double precision,
    "numQueries" bigint,
    "slow" boolean,
    "error" text,
    "stackTrace" text,
    "authenticatedUserId" bigint,
    "isOpen" boolean,
    "touched" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" USING btree ("serverId");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" USING btree ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" USING btree ("isOpen");

--
-- Foreign relations for "categoria" table
--
ALTER TABLE ONLY "categoria"
    ADD CONSTRAINT "categoria_fk_0"
    FOREIGN KEY("parentId")
    REFERENCES "categoria"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "eventos_empresa" table
--
ALTER TABLE ONLY "eventos_empresa"
    ADD CONSTRAINT "eventos_empresa_fk_0"
    FOREIGN KEY("tenantId")
    REFERENCES "empresa"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- Foreign relations for "item_tabela_precificacao" table
--
ALTER TABLE ONLY "item_tabela_precificacao"
    ADD CONSTRAINT "item_tabela_precificacao_fk_0"
    FOREIGN KEY("tabelaPrecificacaoId")
    REFERENCES "tabela_precificacao"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "local_entrega" table
--
ALTER TABLE ONLY "local_entrega"
    ADD CONSTRAINT "local_entrega_fk_0"
    FOREIGN KEY("clienteId")
    REFERENCES "cliente"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "membro_empresa" table
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
-- Foreign relations for "produto" table
--
ALTER TABLE ONLY "produto"
    ADD CONSTRAINT "produto_fk_0"
    FOREIGN KEY("categoriaId")
    REFERENCES "categoria"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "produto_tabela_precificacao" table
--
ALTER TABLE ONLY "produto_tabela_precificacao"
    ADD CONSTRAINT "produto_tabela_precificacao_fk_0"
    FOREIGN KEY("produtoId")
    REFERENCES "produto"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "produto_tabela_precificacao"
    ADD CONSTRAINT "produto_tabela_precificacao_fk_1"
    FOREIGN KEY("tabelaPrecificacaoId")
    REFERENCES "tabela_precificacao"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_log" table
--
ALTER TABLE ONLY "serverpod_log"
    ADD CONSTRAINT "serverpod_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_message_log" table
--
ALTER TABLE ONLY "serverpod_message_log"
    ADD CONSTRAINT "serverpod_message_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_query_log" table
--
ALTER TABLE ONLY "serverpod_query_log"
    ADD CONSTRAINT "serverpod_query_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
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
