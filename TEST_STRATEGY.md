# TEST STRATEGY — SALGADERIA ERP
## ESTRATÉGIA DE TESTES E GARANTIA DE QUALIDADE

**Data:** 2026-07-24  
**Objetivo:** Definir as diretrizes, níveis e cenários de testes automatizados e manuais para garantir resiliência, segurança e correto funcionamento offline/online da Plataforma de Backend e do cliente Desktop.

---

## 1. PIRÂMIDE E NÍVEIS DE TESTES

```text
                     / \
                    /   \       Acceptance & E2E Tests (Manual UI + Flutuar)
                   /-----\
                  /       \     Migration & Backward Compatibility Tests
                 /---------\
                /           \   Offline & Sync Tests (Resiliência SQLite/Postgres)
               /-------------\
              /               \ Integration Tests (Serverpod APIs + DB)
             /-----------------\
            /                   \ Unit Tests (Domain Services & Shared Models)
           /---------------------\
```

---

## 2. MATRIZ DE COBERTURA DE TESTES POR MÓDULO

| Módulo do ERP | Teste Unitário (Unit) | Teste de Integração (Integration) | Resiliência Offline (Offline/Sync) | Teste de Carga (Stress) | Aceitação (Acceptance) |
|---|:---:|:---:|:---:|:---:|:---:|
| **Clientes (CRM)** | ✔ | ✔ | ✔ | — | ✔ |
| **Produtos & Preços** | ✔ | ✔ | ✔ | — | ✔ |
| **Pedidos & Orçamentos** | ✔ | ✔ | ✔ | ✔ | ✔ |
| **Estoque & Reserva Canônica** | ✔ | ✔ | ✔ | ✔ | ✔ |
| **MRP & Lotes de Produção** | ✔ | ✔ | — | ✔ | ✔ |
| **Agenda Operacional (Fritura)** | ✔ | ✔ | — | ✔ | ✔ |
| **Expedição & Saída** | ✔ | ✔ | — | — | ✔ |
| **Financeiro & Despesas** | ✔ | ✔ | — | — | ✔ |
| **Workers & Scheduler Cloud** | ✔ | ✔ | — | ✔ | — |
| **Integrador WhatsApp & IA** | ✔ | ✔ | — | ✔ | ✔ |

---

## 3. ESPECIFICAÇÃO DOS NÍVEIS DE TESTE

### 3.1 Testes Unitários (Unit Tests)
*   **Foco:** Testar as regras de negócio puras nos `Domain Services` (`EstoqueService`, `MRPService`, `AgendaService`) e validações no pacote `salgaderia_shared`.
*   **Ferramentas:** `test` (Dart test framework), `mockito`.
*   **Meta de Cobertura:** **Mínimo de 80%** de cobertura de código na camada de domínio do backend.

### 3.2 Testes de Integração (Integration Tests)
*   **Foco:** Validar a comunicação entre os endpoints do Serverpod, o ORM e o banco de dados PostgreSQL (Supabase/Docker local).
*   **Ferramentas:** `serverpod_test`.

### 3.3 Testes de Sincronização & Resiliência Offline (Offline & Sync Tests)
*   **Foco:** Testar o comportamento da aplicação em cenários de queda de internet e reconexão.

### 3.4 Testes de Migração de Banco de Dados (Migration Tests)
*   **Foco:** Garantir que novas migrations de banco de dados não quebrem instâncias existentes em produção (em bancos vazios e populados).

### 3.5 Testes de Compatibilidade Retroativa (Backward Compatibility Tests)
*   **Foco:** Garantir a convivência harmoniosa entre clientes instalados legados (Desktop Windows N-1) e a Backend Platform (Versão N).

### 3.6 Testes de Carga e Stress (Stress & Performance Tests)
*   **Foco:** Garantir que o servidor suporta múltiplos webhooks assíncronos e sincronizações concorrentes sem travar.

### 3.7 Testes de Aceitação do Usuário (Acceptance Tests)
*   **Foco:** Validação visual e de fluxo operacional no Flutter Desktop Windows antes de cada término de fase.

---

## 4. AMBIENTE E EXECUÇÃO NOS PIPELINES

- **Pull Requests:** Todo PR deve executar automaticamente a suíte de testes unitários e de integração no CI (GitHub Actions). PRs com falhas ou cobertura abaixo de 80% são bloqueados para merge.
- **Antes de cada Marco de Validação de Fase:** Execução obrigatória dos testes de resiliência offline, testes de migração em banco populado e build do Windows 100% verificado.
