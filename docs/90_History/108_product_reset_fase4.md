---
Title: Product Reset Fase 4
Status: Archived
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# Planejamento Técnico: Backlog, Roadmap de Versões e Riscos (Fase 4)

> **Document ID**: 108  
> **Version**: 1.3.0  
> **Status**: ✍️ Revisado (Ativo)  
>
> Este documento rege o planejamento e backlog do monorepo: roadmap de releases, gates de homologação e a matriz de riscos.

---

## 1. Roadmap de Versões (Milestones)

O roadmap da FINCORE Platform foi estruturado em marcos de entrega (Milestones) que acompanham a ordem lógica de dependência de domínio e técnica, garantindo que o contexto de tenant (Empresa) e autenticação esteja disponível antes do desenvolvimento de cadastros mestres e fluxos transacionais.

* **MILESTONE 1: Engineering Bootstrap** [CONCLUÍDO]
  * Estruturação inicial do monorepo, linters, testes iniciais e pipelines.
* **MILESTONE 2: Application Shell** [CONCLUÍDO]
  * UI Base, Design System consolidado (`fincore_design_system`) e shell de navegação do app.
* **MILESTONE 3: Platform Core** [CONCLUÍDO]
  * Domínios e infraestrutura core (Empresa, Tenant, Usuários, Configurações do sistema, Drift SQLite local, Serverpod API/DB remoto, BaseRepository estruturado com filtros nativos por Tenant, Outbox transacional e Sync inicial).
* **MILESTONE 4: Master Data & Pricing**
  * Domínios de apoio operacional e precificação: Categorias, Produtos, Tabelas de Precificação, Itens de Precificação, Associação N:N, Clientes, Endereços, Taxas e Formas de Pagamento. Habilita o faturamento e vendas.
* **MILESTONE 5: PDV Express**
  * Tela de vendas reativa com atalhos funcionais, Stepper interativo de fluxo de checkout livre e o motor de cálculo (`PricingEngine`) integrado às faixas de preço ativas.
* **MILESTONE 6: Produção**
  * KDS reativo (Fila da Cozinha), controle de estoque de insumos e rastreamento de ordens de preparo.
* **MILESTONE 7: Financeiro**
  * Fluxo de CaixaDiário, conciliação de métodos de pagamento, troco e relatórios contábeis de faturamento/perdas.
* **MILESTONE 8: Dashboard**
  * Dashboard de analytics operacional com metas de negócio e métricas do Control Center unificado.

---

## 🧩 Princípio de Desenvolvimento Incremental

A implementação da FINCORE Platform seguirá prioritariamente o fluxo de dependência lógica do negócio e da arquitetura distribuída:

```text
Platform Core ➔ Cadastros ➔ Operação (PDV) ➔ Gestão
```

### Regras de Ouro de Engenharia:
1. **Seguir rigorosamente a documentação da FINCORE Platform.**
2. **Construir os módulos na ordem natural de implantação de um cliente.**
3. **Validar a arquitetura completa (Flutter ➔ Domínio ➔ Persistência ➔ Sincronização ➔ Servidor) desde os primeiros cadastros.**

### O Princípio da Entrega Completa:
> **Todo módulo implementado deverá nascer completo.**

Cada domínio desenvolvido só será considerado concluído quando funcionar de ponta a ponta em todas as camadas arquiteturais da plataforma:

```text
Flutter UI ➔ Controller/ViewModel ➔ Use Cases ➔ Contrato de Repositório ➔ Implementação de Repositório ➔ DAO ➔ Drift (SQLite Local) ➔ Outbox/Sync ➔ Serverpod API ➔ Banco Remoto (Postgres)
```

Isso assegura que o contexto de `tenantId` e auditoria (`createdBy`, `updatedBy`, `createdAt`, `updatedAt`) fornecido pela Fundação esteja disponível nativamente em todos os modelos de cadastros mestres e pedidos desde a sua criação, reduzindo retrabalho e inconsistências no banco de dados distribuído.

---

## 2. Release Gates (Portões de Homologação)

* **Gate v1.0 (Fundação)**:
  * Suíte de testes locais com 100% de sucesso.
  * Cobertura de testes unitários locais >85%.
  * Simulação de 50 vendas offline sem perda de dados locais.
  * Tempo de inicialização (boot) local < 1.5s.
  * Latência de digitação no PDV Express < 15 segundos.

---

## 3. Backlog Mestre (Sprint 1 e Sprints Futuros)

A hierarquia de tarefas segue a convenção: **Épico ➔ Business Capability ➔ Feature ➔ Task**.

### Épicos Prioritários da v1.0 (Fundação)

* **Épico I: Refatoração Clean Architecture & State Machines (Capability ①)**
  * **Task 1.1**: Desenvolver o controlador `PdvExpressController` (Máquina de Estados). (Tamanho: **M**)
  * **Task 1.2**: Implementar atalhos de teclado (`F1` a `F12`) e borda ativa de foco Laranja Forno de 2px. (Tamanho: **S**)
* **Épico II: Acessibilidade e Painel de Cozinha (Capability ③)**
  * **Task 2.1**: Implementar o algoritmo LIFO de devolução na classe `EstornarLoteEstoqueUseCase`. (Tamanho: **M**)
  * **Task 2.2**: Implementar Modo Cozinha com fontes com aumento de 150% e área de toque touch de 64x64dp. (Tamanho: **S**)
* **Épico III: Isolamento de Tenants e Sync Outbox (Capability ⑨)**
  * **Task 3.1**: Desenvolver a tabela local `outbox_sync` no Drift SQLite. (Tamanho: **S**)
  * **Task 3.2**: Implementar o worker `SyncService` de reenvio de outbox local. (Tamanho: **L**)
  * **Task 3.3**: Replicar a coluna `tenantId` nas transações SQLite do Drift. (Tamanho: **M**)

---

## 4. Registro de Riscos (Risk Register)

* **Risco 1: Concorrência de Sync Offline** (Probabilidade Média / Impacto Alto) -> Mitigação: Aplicação automática da **Policy A** (Operação Vence) para cozinha e **Policy D** (Last-Write Wins) para clientes.
* **Risco 2: Gargalo no SQLite Local** (Probabilidade Baixa / Impacto Médio) -> Mitigação: Limpeza automática de logs antigos locais após 90 dias.
* **Risco 3: Falha física no spooler térmico** (Probabilidade Alta / Impacto Médio) -> Mitigação: Spooler local desacoplado e botão Reimprimir [F9] visível.
* **Risco 4: Vazamento de Tenant em Nuvem** (Probabilidade Baixa / Impacto Crítico) -> Mitigação: Teste de invasão automatizado na pipeline de CI/CD simulando chaves JWT aleatórias.
