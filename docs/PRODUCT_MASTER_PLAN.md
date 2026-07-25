# PRODUCT MASTER PLAN — FINCORE Food
## Fonte Única de Verdade (Single Source of Truth) do Produto

**Comitê**: Principal Product Officer · Software Architect · Especialista ERP Food Service · UX Architect · Especialista Produção Alimentícia

---

* **Version**: 1.0.0
* **Status**: ❄️ Frozen (Congelado)
* **Change Log**:
  * `1.0.0` (2026-07-25): Consolidação inicial e congelamento dos documentos do vertical FINCORE Food (Principles, Manifesto, Metrics, Quality Attributes e Fases 1 a 4).

---

## 🗺️ Mapa de Documentos Oficiais do Produto

Todo o ecossistema do FINCORE Food está consolidado nos documentos listados abaixo. Qualquer dúvida técnica, operacional ou de priorização no vertical de alimentos deve ser resolvida consultando esta estrutura:

```
┌────────────────────────────────────────────────────────────────────────┐
│                              ESTRATÉGIA                                │
│                                                                        │
│  ① [PRODUCT_PRINCIPLES]   ➔ Os 12 mandamentos de UX & Operação.        │
│  ② [PRODUCT_MANIFESTO]    ➔ Nossas 7 linhas vermelhas inegociáveis.     │
│  ③ [PRODUCT_METRICS]      ➔ Métricas de faturamento e perdas do Food.   │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                              ARQUITETURA                               │
│                                                                        │
│  ④ [QUALITY_ATTRIBUTES]   ➔ Critérios não-funcionais por Capability.    │
│  ⑤ [PRODUCT_RESET_FASE1]  ➔ Domínios, Workspaces e Control Center.      │
│  ⑥ [PRODUCT_RESET_FASE2]  ➔ Personas, States, Motion e Exception UX.   │
│  ⑦ [PRODUCT_RESET_FASE3]  ➔ Eventos, RLS, Sync local e Outbox.         │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                               PLANOS & GOVERNANÇA                      │
│                                                                        │
│  ⑧ [PRODUCT_RESET_FASE4]  ➔ Backlog Mestre, Roadmap e Riscos do Food.  │
│  ⑨ [DESIGN_CHECKLIST]     ➔ Checklist mandatório de PRs de interface.  │
└────────────────────────────────────────────────────────────────────────┘
```

* **[PRODUCT_PRINCIPLES.md](file:///f:/Eigent/fincore_platform/docs/PRODUCT_PRINCIPLES.md)**
* **[PRODUCT_MANIFESTO.md](file:///f:/Eigent/fincore_platform/docs/PRODUCT_MANIFESTO.md)**
* **[PRODUCT_METRICS.md](file:///f:/Eigent/fincore_platform/docs/PRODUCT_METRICS.md)**
* **[QUALITY_ATTRIBUTES.md](file:///f:/Eigent/fincore_platform/docs/QUALITY_ATTRIBUTES.md)**
* **[PRODUCT_RESET_FASE1.md](file:///f:/Eigent/fincore_platform/docs/PRODUCT_RESET_FASE1.md)**
* **[PRODUCT_RESET_FASE2.md](file:///f:/Eigent/fincore_platform/docs/PRODUCT_RESET_FASE2.md)**
* **[PRODUCT_RESET_FASE3.md](file:///f:/Eigent/fincore_platform/docs/PRODUCT_RESET_FASE3.md)**
* **[PRODUCT_RESET_FASE4.md](file:///f:/Eigent/fincore_platform/docs/PRODUCT_RESET_FASE4.md)**
* **[DESIGN_REVIEW_CHECKLIST.md](file:///f:/Eigent/fincore_platform/docs/DESIGN_REVIEW_CHECKLIST.md)**

---

## 🛠️ Decisões Arquiteturais e de Plataforma (ADRs)

Para compreender as escolhas de tecnologias e as decisões de engenharia compartilhadas que dão sustentação ao produto, consulte:

* **[ADR-001: Stack Tecnológica Oficial](file:///f:/Eigent/fincore_platform/docs/decisions/ADR-001_official_technology_stack.md)** ➔ Definição da stack de linguagens, IDEs, bancos e o Princípio de Evolução Tecnológica.

---

## 🛠️ Manifesto de Transição de Engenharia do Food

Caro Desenvolvedor,

A construção das telas e códigos do FINCORE Food segue as seguintes regras de governança de produto:

1. **A regra permanente é soberana**: *Isso sobrevive em um produto vendido para 500 empresas?*
2. **CQRS e Outbox**: Mutações de faturamento e preparo devem utilizar obrigatoriamente a Outbox transacional. Alterações diretas sem Commands/Handlers serão reprovadas.
3. **Isolamento de Tenants**: Toda transação de banco de dados deve validar o identificador `tenantId` (localmente no Drift SQLite e em nuvem via RLS do Postgres).
4. **Nenhum PR sem Checklist**: PRs visuais exigem o atestado completo dos 10 itens do `DESIGN_REVIEW_CHECKLIST.md` na descrição da entrega.

---

*Product Master Plan — FINCORE Food*
