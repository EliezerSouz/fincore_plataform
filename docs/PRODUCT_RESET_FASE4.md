# PRODUCT RESET 1.0 — FASE 4 (REVISÃO FINAL)
## Backlog Mestre por Capabilities, Roadmap e Plano de Migração Técnica

**Comitê**: Principal Product Officer · CTO SaaS · Principal Software Architect · Especialista em Engenharia de Produto · Especialista em Growth SaaS B2B

**Data**: 2026-07-25
**Revisão**: Final — Fase 4 congelada
**Status**: ✅ APROVADO — Documento Mestre — Fase 4 de 5

---

# PARTE 1 — ROADMAP DE VERSÕES (Lançamentos Estratégicos)

* **Versão 1.0 (Fundação)**: Core operacional e infraestrutura de plataforma para funcionamento local.
* **Versão 1.5 (Crescimento)**: Fichas técnicas, motor de rotas de logística e DRE financeiro.
* **Versão 2.0 (Plataforma)**: Canais externos (Omnichannel: Web/WhatsApp IA/API) e automações cloud.
* **Versão 3.0 (Escala)**: Multi-Franquias, App Entregador e Analytics preditivo.

---

## 1.1 Release Gates (Portões de Homologação)

* **Gate v1.0 (Fundação)**:
  * Suite de testes locais com 100% de sucesso e cobertura >85%.
  * Desconexão offline de 50 vendas simuladas com zero perda de dados.
  * Latência de faturamento de pedidos no PDV Express < 15 segundos.
  * Métrica de crash-free local no Windows > 99.9%.
  * Isolamento de RLS atestado sem vazamentos.

---

# PARTE 2 — HIERARQUIA DO BACKLOG MESTRE

A estrutura segue a cadeia: **Épico ➔ Business Capability ➔ Feature ➔ Task (Tamanho & Dependência)**.

## ① Receber Pedidos (Comercial / PDV)
* **Feature 1.1: Máquina de Estados do PDV Express**
  * **Task 1.1.1**: Desenvolver o controlador `PdvExpressController` (State Machine).
    * *Estimativa*: **M** | *Depende de*: Nenhuma
  * **Task 1.1.2**: Implementar atalhos de teclado (`F1` a `F12`) e borda ativa de foco Laranja Forno de 2px.
    * *Estimativa*: **S** | *Depende de*: Task 1.1.1
* **Feature 1.2: Endereçamento Desacoplado**
  * **Task 1.2.1**: Modificar o schema Drift local (`Pedidos`) para incluir colunas completas de endereço.
    * *Estimativa*: **M** | *Depende de*: Nenhuma

## ③ Produzir (Cozinha)
* **Feature 3.1: Algoritmo LIFO de Devolução de Insumos**
  * **Task 3.1.1**: Implementar o algoritmo LIFO de devolução na classe de caso de uso `EstornarLoteEstoqueUseCase`.
    * *Estimativa*: **M** | *Depende de*: Nenhuma
* **Feature 3.2: Modo Cozinha (Acessibilidade)**
  * **Task 3.2.1**: Implementar aumento dinâmico de 150% nas fontes e área de toque touch de 64x64dp.
    * *Estimativa*: **S** | *Depende de*: Nenhuma

## ⑨ Administrar (Control Center / Plataforma)
* **Feature 9.1: Motor de Sincronismo Offline-First (Outbox)**
  * **Task 9.1.1**: Desenvolver a tabela local `outbox_sync` no Drift SQLite.
    * *Estimativa*: **S** | *Depende de*: Nenhuma
  * **Task 9.1.2**: Implementar o worker `SyncService` para monitoramento de pacotes na Outbox.
    * *Estimativa*: **L** | *Depende de*: Task 9.1.1
* **Feature 9.2: Idempotência de Transações**
  * **Task 9.2.1**: Implementar UUID `commandId` mandatório nas payloads dos comandos.
    * *Estimativa*: **S** | *Depende de*: Task 9.1.2
* **Feature 9.3: Isolamento de Tenants (RLS)**
  * **Task 9.3.1**: Configurar a Row-Level Security no Postgres da nuvem.
    * *Estimativa*: **L** | *Depende de*: Nenhuma
  * **Task 9.3.2**: Replicar a coluna `tenantId` nas transações SQLite do Drift.
    * *Estimativa*: **M** | *Depende de*: Task 9.3.1

---

# PARTE 3 — REGISTRO DE RISCOS (Risk Register)

* **Risco 1: Concorrência de Sync Offline** (Probabilidade Média / Impacto Alto) -> Mitigação: Aplicação automática da **Policy A** (Operação Vence) para cozinha e **Policy D** (Last-Write Wins) para clientes.
* **Risco 2: Gargalo no SQLite Local** (Probabilidade Baixa / Impacto Médio) -> Mitigação: Limpeza automática de logs antigos locais após 90 dias.
* **Risco 3: Falha física no spooler térmico** (Probabilidade Alta / Impacto Médio) -> Mitigação: Spooler local desacoplado e botão Reimprimir [F9] visível.
* **Risco 4: Vazamento de Tenant em Nuvem** (Probabilidade Baixa / Impacto Crítico) -> Mitigação: Teste de invasão automatizado na pipeline de CI/CD simulando chaves JWT aleatórias.

---

*Fase 4 de Backlog e Roadmap — Eigent Reset*
*Assinado pelo Comitê e Congelado.*
