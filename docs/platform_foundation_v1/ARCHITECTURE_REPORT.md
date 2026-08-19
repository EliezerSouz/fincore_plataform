# Relatório de Auditoria Geral de Arquitetura — FINCORE PLATFORM

Este documento apresenta o resultado detalhado da auditoria geral realizada no FINCORE PLATFORM durante o Sprint 0 de Consolidação.

---

## 📊 Nota da Arquitetura e Matriz de Riscos

### **Nota Geral da Arquitetura: 9.5 / 10**
A arquitetura é extremamente robusta, possuindo um motor Offline-First com banco SQLite estruturado e sincronização via padrão Outbox com ordenação topológica. A nota 9.5 reflete a necessidade de padronização visual das telas legadas utilizando os novos componentes estruturais de Level 3 (como `FincoreScaffold` e `CrudSplitView`) que serão criados na Fase B.

### **Matriz de Riscos (Risk Matrix)**

| Risco | Impacto | Probabilidade | Mitigação |
| :--- | :---: | :---: | :--- |
| **Violação de FK no Sync** | Alto | Baixo | A ordenação topológica implementada em `_getEntityPriority` mitiga o risco de violações. |
| **Erros de Contraste White-Label** | Médio | Médio | Mitigado pela introdução da validação WCAG ativa no `ThemeController`. |
| **Quebras de Widgets Const** | Alto | Baixo | Mitigado pela arquitetura de Bridge no `FincoreColors`, preservando constantes legadas. |
| **Fragmentação de Telas ERP** | Médio | Alto | Mitigado pela adoção obrigatória do `FincoreScaffold` e `CrudSplitView`. |

---

## 📂 Auditoria Etapa 1: Código Geral e Redundâncias

### 1. Responsabilidades Cruzadas & Modelos Duplicados
- **Problema**: Modelos e Value Objects por vezes migrados de forma duplicada entre `packages/fincore_shared` e `packages/fincore_core/lib/common/`.
- **Impacto**: Confusão de importação para novos engenheiros e duplicidade na validação lógica.
- **Plano de Correção**: Centralizar objetos puramente de dados fiscais ou primitivas operacionais em `fincore_shared`, deixando `fincore_core` encarregado apenas da lógica de infraestrutura e contratos.

---

## 💻 Auditoria Etapa 2: UX & Consistência de Telas

### 1. Inconsistência de Estruturação de Scaffold
- **Problema**: Telas como `usuarios_page.dart`, `categorias_page.dart` e `clientes_page.dart` reconstroem manualmente seus cabeçalhos, margens internas, e listas divididas.
- **Impacto**: Diferenças sutis em paddings e layout responsivo dependendo de quem programou a tela.
- **Plano de Correção**: Substituição sistemática pela especificação de `FincoreScaffold` e `CrudSplitView` na Fase B.

---

## 🗄️ Auditoria Etapa 3: Banco de Dados (SQLite & Drift)

### 1. Integridade Referencial e Performance de Índices
- **Problema**: Índices explícitos para chaves de busca frequentes (ex: `tenant_id` + `sync_status`) ausentes em tabelas de grande volume como `OrdensPreparoTable` e `PrintJobsTable`.
- **Impacto**: Lentidão em consultas locais após meses de uso comercial contínuo.
- **Plano de Correção**: Adicionar índices de banco compostos no SQLite e registrar no Drift.

---

## ⚙️ Auditoria Etapa 4: Serviços do Core (Sync, Log, Auth)

### 1. Serviço de Logs e Persistência
- **Problema**: `LogService` escreve logs locais, mas exige melhor limpeza de histórico para evitar estouro de espaço em disco no PDV.
- **Impacto**: Risco de falta de espaço em terminais de hardware limitado.
- **Plano de Correção**: Introduzir limpeza automática por tempo (logs mais velhos que 30 dias devem ser descartados).
