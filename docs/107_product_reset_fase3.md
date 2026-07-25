# Engenharia e Arquitetura Distribuída: CQRS, RLS e Sincronismo (Fase 3)

> **Document ID**: PRD-007  
> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
>
> Este documento rege a infraestrutura distribuída do monorepo: fluxo de commands/events, segurança Postgres e robustez de rede.

---

## 1. CQRS, Domain Events e Logs de Auditoria

* **Sem Event Sourcing Puro**: O sistema **não** reconstrói o estado operacional de tabelas recalculando todo o histórico de eventos, evitando latência local. O estado canônico é guardado em Projeções comuns.
* **Audit Log Imutável**: Um log cronológico estruturado em JSON é mantido localmente para auditoria de mutações críticas.
* **Pipeline de Execução de Commands**:
  ```
  Command ➔ Validator ➔ Policy (Permissions) ➔ Handler ➔ Repository ➔ Event/Audit Log
  ```

---

## 2. Multi-Tenancy e Isolamento de Dados

* **PostgreSQL Row-Level Security (RLS)**:
  Toda tabela na nuvem bloqueia acessos transversais baseando-se no `tenant_id` embutido no JWT do usuário.
  ```sql
  ALTER TABLE pedido ENABLE ROW LEVEL SECURITY;
  CREATE POLICY tenant_isolation_policy ON pedido FOR ALL USING (tenant_id = current_setting('app.current_tenant_id'));
  ```
* **Filtro Local (SQLite)**: As tabelas Drift locais possuem a coluna `tenantId` e repositórios filtram automaticamente as queries locais no escopo do inquilino ativo.

---

## 3. Protocolo de Sincronismo Offline-First

* **Outbox Pattern Atômico**: A mutação de banco de dados do pedido e o registro da tarefa pendente na outbox `outbox_sync` ocorrem dentro da mesma transação local SQLite.
* **Garantia de Idempotência**: O backend Serverpod Deduplica reenvios de pacotes de rede usando uma tabela `processamento_comandos` com restrição de chave primária baseada no `commandId` (UUID) gerado na UI do cliente.
* **Retry com Backoff Exponencial**: Em falhas de requisição por queda de rede, as tentativas ocorrem em intervalos crescentes: 5s, 30s, 2m, 10m.
