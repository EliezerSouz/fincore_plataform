# PRODUCT RESET 1.0 — FASE 3 (REVISÃO FINAL)
## Arquitetura Técnica, CQRS, Multi-Tenancy e Engenharia Distribuída

**Comitê**: Principal Software Architect · CTO SaaS · Especialista Sistemas Offline First · Especialista Flutter/Serverpod/Drift · Especialista Clean Architecture · Especialista PostgreSQL

**Data**: 2026-07-25
**Revisão**: Final — Fase 3 congelada
**Status**: ✅ APROVADO — Documento Mestre — Fase 3 de 5

---

# PARTE 1 — CQRS, DOMAIN EVENTS E AUDIT LOG

> [!IMPORTANT]
> **Esclarecimento Conceitual**: Para evitar complexidade acidental e sobrecarga de processamento, o sistema **não** reconstrói estados dinâmicos recalculando todo o histórico de eventos (Event Sourcing).
> Em vez disso, utilizamos **CQRS (Segregação de Leitura e Escrita)** combinando **Domain Events** para propagação reativa e um **Audit Log** imutável para rastreabilidade e governança.

## 1.1 O Pipeline de Execução de Commands

Todo Command disparado na camada de apresentação (Workspaces) passa obrigatoriamente por 6 etapas sequenciais e isoladas:

1. **Command**: Objeto contendo o payload e um `commandId` (UUID) mandatório.
2. **Validator**: Validação sintática (ex: formato de data, campos em branco) e lógica (ex: estoque disponível).
3. **Policy (Permissions)**: Validação de autorização baseada nas feature flags ativas e no perfil do usuário logado.
4. **Handler**: Orquestrador que executa a transação no banco de dados Drift.
5. **Repository**: Persiste a alteração na tabela de Projeção correspondente e na fila local.
6. **Event / Audit Log**: Dispara um evento de domínio em memória (ex: `PedidoCriadoEvent`) e grava uma linha imutável de log de auditoria no SQLite.

---

# PARTE 2 — MULTI-TENANCY E SEGURANÇA DE DADOS

O isolamento de dados de diferentes empresas (tenants) é garantido tanto localmente quanto na nuvem.

## 2.1 Row-Level Security (RLS)
* O PostgreSQL do backend Serverpod implementa **Row-Level Security (RLS)** em todas as tabelas transacionais baseada no tenant logado no token JWT de autenticação do operador:
  ```sql
  ALTER TABLE pedido ENABLE ROW LEVEL SECURITY;
  CREATE POLICY tenant_isolation_policy ON pedido
    FOR ALL
    USING (tenant_id = current_setting('app.current_tenant_id'));
  ```

## 2.2 Isolamento Rígido Local (SQLite/Drift)
* Todas as tabelas do Drift local possuem uma coluna `tenantId` obrigatória. Repositórios injetam implicitamente o filtro do tenant ativo no escopo da transação local.

---

# PARTE 3 — PROTOCOLO DE SINCRONISMO OFFLINE-FIRST

O motor de sincronização (`SyncService`) opera em segundo plano de forma tolerante a falhas.

## 3.1 Idempotência (Deduplicação de Ações)
* Todo command recebe um `commandId` único (UUID v4) gerado na UI.
* O banco de dados do servidor (Postgres) possui uma tabela de controle `processamento_comandos` com restrição de chave primária no `command_id` para evitar duplicidade de escrita em reenvios de pacotes por oscilação de rede.

## 3.2 Outbox Pattern (Garantia de Entrega de Saída)
* A gravação do pedido e a gravação da tarefa correspondente na tabela local `outbox_sync` são executadas dentro da **mesma transação atômica** do SQLite.
* O `SyncService` consome a tabela `outbox_sync` e deleta a outbox local apenas ao receber o ACK do Serverpod.

## 3.3 Inbound Queue (Fila de Entrada)
* Atualizações de catálogo e preços vindas da Nuvem são persistidas localmente na tabela `inbound_sync` e processadas sequencialmente para atualizar as projeções sem bloquear o main isolate.

## 3.4 Políticas de Retry e Backoff Exponencial
* Em caso de falha de conexão, o sincronismo tenta novamente em intervalos progressivos: 5s, 30s, 2m, 10m. Se persistir, entra em modo crítico manual exigindo interação do operador.

---

# PARTE 4 — VERSIONAMENTO E EVOLUÇÃO

Sistemas offline-first distribuídos dependem de versionamento estrito.
* **Versionamento de Dados (Revisões)**: Toda tabela transacional possui a coluna `versao` (inteiro incremental, `versao++` a cada escrita). O servidor detecta conflito se a versão recebida for menor que a ativa no Postgres.
* **Versionamento de Esquemas de Eventos**: Eventos armazenados possuem um campo `esquemaVersao` (ex: `v1`, `v2`) resolvido com Upcasters na deserialização local.

---

# PARTE 5 — OBSERVABILIDADE E RASTREABILIDADE (Observability)

* **CorrelationId (ID de Correlação)**: Todo fluxo iniciado na UI recebe um UUID `correlationId` que é repassado em logs, comandos e payloads das APIs.
* **Logs Estruturados**: Logs em `execucao.log` e `sincronizacao.log` gravados em formato JSON padronizado.

---

*Fase 3 de Arquitetura — Eigent Reset*
*Assinado pelo Comitê e Congelado.*
