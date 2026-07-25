# Plano Mestre de Produto (Product Master Plan) — FINCORE Food

> **Document ID**: 101  
> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
> **Owner**: Comitê de Produto & Engenharia FINCORE Food  
>
> Este documento centraliza o mapa de governança e as especificações de comportamento do vertical de alimentação.

---

## 🗺️ Mapa de Documentos Oficiais do Produto

Todo o ecossistema do FINCORE Food está consolidado nos documentos listados abaixo. Qualquer dúvida técnica, operacional ou de priorização no vertical de alimentos deve ser resolvida consultando esta estrutura:

```
┌────────────────────────────────────────────────────────────────────────┐
│                              ESTRATÉGIA                                │
│                                                                        │
│  ① [PRD-002: Product Principles]➔ Os 12 mandamentos de UX & Operação.  │
│  ② [PRD-003: Product Manifesto] ➔ Nossas 7 linhas vermelhas.           │
│  ③ [PRD-004: Product Metrics]   ➔ Métricas de faturamento e perdas.    │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                              ARQUITETURA                               │
│                                                                        │
│  ④ [PLT-007: Quality Attribs]   ➔ Requisitos técnicos por Capability.  │
│  ⑤ [PRD-005: Reset Fase 1]      ➔ Domínios, Workspaces e Control Ctr.  │
│  ⑥ [PRD-006: Reset Fase 2]      ➔ Personas, States, Motion e UX Erros. │
│  ⑦ [PRD-007: Reset Fase 3]      ➔ Eventos, RLS, Sync local e Outbox.   │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                               PLANOS & GOVERNANÇA                      │
│                                                                        │
│  ⑧ [PRD-008: Reset Fase 4]      ➔ Backlog Mestre, Roadmap e Riscos.    │
│  ⑨ [PRD-009: Design Checklist]  ➔ Checklist mandatório de PRs visual.  │
└────────────────────────────────────────────────────────────────────────┘
```

* **[PRD-002: Product Principles](file:///f:/Eigent/fincore_platform/docs/102_product_principles.md)**
* **[PRD-003: Product Manifesto](file:///f:/Eigent/fincore_platform/docs/103_product_manifesto.md)**
* **[PRD-004: Product Metrics](file:///f:/Eigent/fincore_platform/docs/104_product_metrics.md)**
* **[PLT-007: Quality Attributes](file:///f:/Eigent/fincore_platform/docs/007_quality_attributes.md)**
* **[PRD-005: Product Reset Fase 1](file:///f:/Eigent/fincore_platform/docs/105_product_reset_fase1.md)**
* **[PRD-006: Product Reset Fase 2](file:///f:/Eigent/fincore_platform/docs/106_product_reset_fase2.md)**
* **[PRD-007: Product Reset Fase 3](file:///f:/Eigent/fincore_platform/docs/107_product_reset_fase3.md)**
* **[PRD-008: Product Reset Fase 4](file:///f:/Eigent/fincore_platform/docs/108_product_reset_fase4.md)**
* **[PRD-009: Design Review Checklist](file:///f:/Eigent/fincore_platform/docs/109_design_review_checklist.md)**

---

## 🛠️ Decisões Arquiteturais e de Plataforma (ADRs)

Para compreender as escolhas de tecnologias e as decisões de engenharia compartilhadas que dão sustentação ao produto, consulte:

* **[ADR-001: Stack Tecnológica Oficial](file:///f:/Eigent/fincore_platform/docs/300_decisions/301_adr_001_official_technology_stack.md)** ➔ Definição da stack de linguagens, IDEs, bancos e o Princípio de Evolução Tecnológica.

---

## 🛠️ Manifesto de Transição de Engenharia do Food

Caro Desenvolvedor,

A construção das telas e códigos do FINCORE Food segue as seguintes regras de governança de produto:

1. **A regra permanente é soberana**: *Isso sobrevive em um produto vendido para 500 empresas?*
2. **CQRS e Outbox**: Mutações de faturamento e preparo devem utilizar obrigatoriamente a Outbox transacional. Alterações diretas sem Commands/Handlers serão reprovadas.
3. **Isolamento de Tenants**: Toda transação de banco de dados deve validar o identificador `tenantId` (localmente no Drift SQLite e em nuvem via RLS do Postgres).
4. **Nenhum PR sem Checklist**: PRs visuais exigem o atestado completo dos 10 itens do **[PRD-009: Design Review Checklist]** na descrição da entrega.

---

*Product Master Plan — FINCORE Food*
