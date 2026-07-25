# CONVENÇÕES DE REPOSITÓRIOS E PERSISTÊNCIA (REPOSITORIES CONVENTIONS) — SALGADERIA ERP

**Escopo:** Diretrizes de separação entre serviços de domínio, repositórios de dados e interfaces de UI.

---

## 1. REGRAS FUNDAMENTAIS DE REPOSITÓRIOS

*   **Regra 1: Repository é responsável exclusivamente pela persistência.**  
    O repositório realiza unicamente operações puras de I/O e CRUD (Create, Read, Update, Delete) no banco de dados (Serverpod ORM no backend ou Drift SQLite no frontend). Ele não possui regras de validação ou lógica conceitual de negócio.

*   **Regra 2: Service possui a regra de negócio.**  
    Validações de estoque, cálculos de faixas de desconto, verificações de capacidade e regras de SLA pertencem exclusivamente aos `Domain Services` (`PedidoService`, `EstoqueService`), que invocam os Repositórios para salvar ou carregar o estado da aplicação.

*   **Regra 3: UI NUNCA conversa com Banco de Dados ou Repositórios diretamente.**  
    Telas Flutter, Widgets e ViewModels jamais devem importar repositórios ou executar queries SQL/Drift diretamente. Elas interagem exclusivamente com os Endpoints e Services da Backend Platform.

*   **Regra 4: Repositório NUNCA conversa com a UI.**  
    Repositórios não possuem conhecimento de elementos de tela, widgets ou notificações de interface.

---

## 2. FLUXO DE COMUNICAÇÃO DE DADOS

```text
┌──────────┐           ┌──────────────────┐           ┌────────────────┐           ┌────────────────┐
│  VIEW    │ ───────▶  │  BACKEND API     │ ───────▶  │ DOMAIN SERVICE │ ───────▶  │   REPOSITORY   │
│ (UI/Win) │ ◄───────  │ (Serverpod EP)   │ ◄───────  │ (Regra de Neg) │ ◄───────  │ (DB Postgres)  │
└──────────┘           └──────────────────┘           └────────────────┘           └────────────────┘
```

---

*Convenções aprovadas para o ecossistema Salgaderia ERP.*
