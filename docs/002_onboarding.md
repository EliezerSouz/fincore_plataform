# Integração (Onboarding) — Bem-vindo à FINCORE

> **Document ID**: 002  
> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
>
> Este é o primeiro documento que qualquer colaborador (humano ou Inteligência Artificial) deve ler e compreender antes de realizar qualquer alteração física ou lógica neste monorepo.

---

## 📖 Trilha de Leitura Obrigatória (Onboarding Path)

Para compreender a filosofia da empresa, o design de interface e a engenharia distribuída offline-first, siga estritamente esta ordem de leitura na sua primeira semana de integração:

```
┌────────────────────────────────────────────────────────────────────────┐
│                              1. EMPRESA                                │
│                                                                        │
│  ① [PLT-001: Platform Charter]➔ Visão estratégica e verticais.        │
│  ② [ENG-002: Contributing]    ➔ Padrões de branch, DoR e PR flow.     │
│  ③ [ENG-001: Engineering Guide]➔ Regras de engenharia e uso de IA.     │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                              2. PLATAFORMA                             │
│                                                                        │
│  ④ [PLT-004: Monorepo Struct] ➔ Matriz de acoplamento e dependências.  │
│  ⑤ [PLT-006: Non-Func Reqs]   ➔ Performance, RTO/RPO e SLAs de lat.    │
│  ⑥ [ADR-001: Tech Stack]      ➔ Stack Tecnológica Oficial Postgres/Dart.│
│  ⑦ [PLT-005: Platform Capabs] ➔ Mapa executivo de capabilities.        │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                              3. PRODUTOS                               │
│                                                                        │
│  ⑧ [products/README.md]       ➔ Catálogo de produtos da plataforma.    │
│  ⑨ [products/fincore-food]    ➔ Landing do vertical FINCORE Food.      │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                              4. GOVERNANÇA                             │
│                                                                        │
│  ⑩ [PRD-001: Master Plan Food]➔ Fonte oficial de verdade do Food.      │
│  ⑪ [PRD-009: Design Checklist]➔ Checklist mandatório de PRs visual.    │
└────────────────────────────────────────────────────────────────────────┘
```

* **[PLT-001: Platform Charter](file:///f:/Eigent/fincore_platform/docs/001_platform_charter.md)**
* **[ENG-002: Contributing](file:///f:/Eigent/fincore_platform/docs/401_contributing.md)**
* **[ENG-001: Engineering Guide](file:///f:/Eigent/fincore_platform/docs/003_engineering_guide.md)**
* **[PLT-004: Monorepo Structure](file:///f:/Eigent/fincore_platform/docs/004_monorepo_structure.md)**
* **[PLT-006: Non-Functional Requirements](file:///f:/Eigent/fincore_platform/docs/006_non_functional_requirements.md)**
* **[ADR-001: Technology Stack](file:///f:/Eigent/fincore_platform/docs/300_decisions/301_adr_001_official_technology_stack.md)**
* **[PLT-005: Platform Capabilities](file:///f:/Eigent/fincore_platform/docs/005_platform_capabilities.md)**
* **[products/README.md](file:///f:/Eigent/fincore_platform/products/README.md)**
* **[products/fincore-food/README.md](file:///f:/Eigent/fincore_platform/products/fincore-food/README.md)**
* **[PRD-001: Product Master Plan](file:///f:/Eigent/fincore_platform/docs/101_product_master_plan.md)**
* **[PRD-009: Design Review Checklist](file:///f:/Eigent/fincore_platform/docs/109_design_review_checklist.md)**

---

## 🛠️ Passo Inicial para Começar

Após ler os documentos acima:
1. Acesse o **Backlog Mestre** localizado no item **⑩ [PRD-001: Product Master Plan]** ou no sistema de gestão de projetos (Jira/GitHub Projects).
2. Localize a sua tarefa prioritária e certifique-se de que ela atende à **Definition of Ready (DoR)** antes de arrastá-la para desenvolvimento.
3. Crie o seu branch local a partir da `master` seguindo a convenção cadastrada no **[ENG-002: Contributing]**.

*FINCORE Onboarding — Integrando talentos com governança de produto.*
