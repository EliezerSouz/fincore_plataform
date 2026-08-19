# Relatório de Dívida Técnica (Technical Debt Report) — FINCORE

Este documento cataloga as dívidas técnicas ativas na plataforma ao final do Sprint 0 de Consolidação e propõe a ordem de remediação.

---

## 🛠️ Inventário de Dívidas Técnicas Ativas

### 1. Dívida Visuais: Widgets com Constantes de Cores
- **Componente**: Telas e subviews em `lib/src/shared/presentation/widgets/`.
- **Descrição**: O uso de `FincoreColors.textPrimary` e `FincoreColors.border` em constructors const previne que estes campos respondam ao modo de tema alternado (claro/escuro) sem recarregamento de página.
- **Prioridade**: **Alta**
- **Ação corretiva**: Remover o modificador `const` e migrar gradualmente para `context.tokens` durante a Fase B.

### 2. Dívida de Estrutura: Multiplicidade de Lógica de Busca em Split-Views
- **Componente**: Telas de cadastros (`usuarios_page.dart`, `clientes_page.dart`, `categorias_page.dart`).
- **Descrição**: Cada página reconstrói localmente a split-view, o estado de vazio (empty state) e controle de carregamento (loading).
- **Prioridade**: **Alta**
- **Ação corretiva**: Unificar tudo sob o componente `CrudSplitView` que será desenvolvido no início da Fase B.

### 3. Dívida de Performance: Índices no SQLite
- **Componente**: Drift database definitions (`fincore_database.dart`).
- **Descrição**: Algumas tabelas do PDV Express possuem buscas por texto sem índices locais explícitos indexados.
- **Prioridade**: **Média**
- **Ação corretiva**: Adicionar migração Drift indexando campos de busca.

---

## 📉 Impacto e Plano de Mitigação

A dívida técnica identificada não impede a liberação comercial estável da versão 1.0 (Platform Foundation V1), pois a Bridge de compatibilidade isola o sistema de bugs em produção. No entanto, ela representa um custo adicional de desenvolvimento para novas telas. A mitigação ocorrerá de forma gradual durante a **Fase B** através do Quality Gate exigido em Pull Requests.
