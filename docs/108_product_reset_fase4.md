# Planejamento Técnico: Backlog, Roadmap de Versões e Riscos (Fase 4)

> **Document ID**: 108  
> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
>
> Este documento rege o planejamento e backlog do monorepo: roadmap de releases, gates de homologação e a matriz de riscos.

---

## 1. Roadmap de Versões

* **Versão 1.0 (Fundação)**: Lançamento do PDV local funcional, Fila da Cozinha reativa, controle de CaixaDiario, Sync local em background e Control Center básico.
* **Versão 1.5 (Crescimento)**: Fichas técnicas de produtos, planejamento MRP e otimização geográfica de rotas de motoboys.
* **Versão 2.0 (Plataforma)**: Geração e confirmação automatizada de PIX Cloud, auto-atendimento web e assistente de IA WhatsApp.

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
