# ADR-004: Ordenação Topológica Relacional no Outbox Sync Engine (Prevenção FK Violation 23503)

> **Document ID**: 305  
> **Version**: 1.0.0  
> **Status**: APPROVED  
> **Owner**: Principal Architect / Sync & Persistence Team  
> **Contexto**: Resolução da exceção PostgreSQL 23503 (`violates foreign key constraint`) durante a sincronização offline-first no `SyncEngine` (`fincore_core/lib/sync/sync_engine.dart`).

---

## 1. Contexto

A plataforma Fincore Food opera em arquitetura **offline-first**, onde transações criadas pelo usuário (cadastro de clientes, endereços de entrega, pedidos e ordens de preparo) são primeiramente gravadas no banco local SQLite via Drift e inseridas na fila transacional (`outbox_sync`).

Durante o processo de sincronização com a nuvem (Supabase / PostgreSQL remoto), observou-se que transações enfileiradas sequencialmente ou em lotes aleatórios geravam a exceção `PostgrestException(message: violates foreign key constraint "local_entrega_fk_0", code: 23503, details: Key (clienteId)=... is not present in table "cliente")`.

Esse erro ocorria porque a entidade Filha (`LocalEntrega`, que depende de um `Cliente.id`) tentava ser processada no Supabase antes da entidade Pai (`Cliente`) ter completado sua inserção remota no mesmo ciclo de push.

---

## 2. Decisão Tomada

Adotar **Ordenação Topológica por Prioridade Relacional** como padrão mandatório em todo o processamento da fila de saída (`outbox_sync`) no motor de sincronização (`SyncEngine`).

*   **Método Oficial de Priorização:** Foi implementado o método determinístico `_getEntityPriority(String entityType)` no `SyncEngine`.
*   **Hierarquia de Prioridades (1 a 20+):**
    1.  **Prioridade 1:** `empresa`, `empresa_configuracao` (Configurações raiz do Tenant)
    2.  **Prioridade 2–4:** `categoria`, `tabela_precificacao`, `taxa_entrega`, `forma_pagamento` (Dados Mestres Globais)
    3.  **Prioridade 6–7:** `cliente`, `produto` (Entidades Pai Fundamentais)
    4.  **Prioridade 10–12:** `pedido`, `mesa`, `caixa` (Entidades Transacionais Primárias)
    5.  **Prioridade 20+:** `local_entrega`, `item_tabela_precificacao`, `produto_tabela_precificacao`, `ordem_preparo`, `item_pedido` (Entidades Filhas Associativas)

---

## 3. Justificativa Técnica (Prós e Contras)

### 3.1 Vantagens (Prós)
*   **Integridade Relacional Garantida:** Nenhuma entidade com chave estrangeira (FK) é submetida ao Supabase antes da entidade Pai estar devidamente persistida, eliminando falhas 23503 na origem.
*   **Resiliência a Desconexões:** Mesmo que o operador crie centenas de registros em sequência no modo offline (Cliente + 3 Endereços + Pedido + Itens), ao reconectar à internet o push respeitará a ordem estrutural do banco.
*   **Zero Impacto na Performance Local:** A ordenação ocorre em memória em tempo de submissão no `SyncEngine` em milissegundos.

### 3.2 Desafios (Contras e Mitigações)
*   **Manutenção da Tabela de Prioridades:** Sempre que uma nova entidade com relacionamento de chave estrangeira for adicionada à plataforma Fincore, seu identificador de tabela DEVE ser mapeado na hierarquia de `_getEntityPriority` em `SyncEngine`.

---

## 4. Consequências e Conformidade FPOS

*   Qualquer novo repositório derivado de `SyncableRepository` que possua dependência FK deve ser verificado nos testes de integração para comprovar que sua prioridade numérica é superior à da sua entidade Pai.
*   O log de sincronização apresentará a sequência ordenada explicitamente durante a execução do `pushOutbox()`.
