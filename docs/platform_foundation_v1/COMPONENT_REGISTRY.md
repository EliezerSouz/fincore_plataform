# Catálogo Oficial de Componentes (Component Registry) — FINCORE

Este catálogo registra todos os componentes homologados ou planejados para o **Fincore Design System**, definindo seu status, categoria, versão e ciclo de vida.

---

## 📋 Tabela de Componentes Cadastrados

| Componente | Nível | Status | Versão | Categoria | Responsável | Substitui / Observações |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **FincoreScaffold** | Level 3 | 🟡 Preview | `1.0.0` | Layout | Platform Team | Substitui `Scaffold` puro nas páginas corporativas. |
| **CrudSplitView** | Level 3 | 🟡 Preview | `1.0.0` | Layout | Platform Team | Consolida master/details de cadastros e cadastros ERP. |
| **FincoreToolbar** | Level 1 | 🟢 Stable | `1.0.0` | Navigation | Platform Team | Barra de ações unificada do topo de listagens. |
| **FincoreForm** | Level 1 | 🟡 Preview | `1.0.0` | Form | Platform Team | Motor de validação e focus. |
| **FincorePanel** | Level 1 | 🟢 Stable | `1.0.0` | Container | Design Team | Contêiner estrutural com bordas e sombras. |
| **FincoreCard** | Level 1 | 🟢 Stable | `1.0.0` | Container | Design Team | Card interativo com hover ativo. |
| **FincoreButton** | Level 1 | 🟢 Stable | `1.0.0` | Action | Design Team | Substitui variações como `PrimaryButton`/`MainButton`. |
| **FincoreTextField** | Level 1 | 🟢 Stable | `1.0.0` | Form | Platform Team | Input unificado com validação e placeholder tokenizado. |
| **FincoreSelect** | Level 1 | 🟡 Preview | `1.0.0` | Form | Platform Team | Dropdown de seleção customizado multi-tema. |
| **FincoreCheckbox**| Level 1 | 🟢 Stable | `1.0.0` | Form | Design Team | Seleção binária tokenizada. |
| **FincoreSwitch** | Level 1 | 🟢 Stable | `1.0.0` | Form | Design Team | Chave de alternância rápida tokenizada. |
| **FincoreDialog** | Level 1 | 🟡 Preview | `1.0.0` | Feedback | Platform Team | Modal de aviso e ação crítica. |
| **FincoreBadge** | Level 1 | 🟢 Stable | `1.0.0` | Feedback | Design Team | Chips de status de pagamento ou ordens. |
| **FincoreTimeline**| Level 1 | 🟡 Preview | `1.0.0` | Data Display| Platform Team | Histórico de preparo KDS e trilhas de auditoria. |
| **FincoreDataTable**| Level 1 | 🟡 Preview | `1.0.0` | Data Display| Platform Team | Tabela rica com paginação e ordenação local. |
| **FincoreAvatar** | Level 1 | 🟢 Stable | `1.0.0` | Display | Design Team | Foto/identificação do usuário do tenant. |
| **FincoreSearch** | Level 1 | 🟢 Stable | `1.0.0` | Action | Platform Team | Campo de busca integrado com delay/debounce. |
| **AppEmptyState** | Level 1 | 🟢 Stable | `1.0.0` | Feedback | Design Team | Substitui layouts vazios improvisados. |
| **AppLoading** | Level 1 | 🟢 Stable | `1.0.0` | Feedback | Design Team | Shimmer/Loading padronizado de transição de dados. |

---

## 🔄 Regra de Depreciação (Deprecation Policy)
Quando um componente passa para o status **Deprecated**, os desenvolvedores devem receber um warning no console do Flutter. O README.md do componente deve listar qual novo elemento o substitui (ex: `FincorePrimaryButton` deve ser substituído por `FincoreButton` com `variant: ButtonVariant.primary`).
Após 2 versões minor do Design System, o componente depreciado é marcado como **Removed** e excluído da base de código.
