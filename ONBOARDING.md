# ONBOARDING — Bem-vindo à FINCORE

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
│  ① [PLATFORM_CHARTER.md]  ➔ Visão estratégica e verticais da FINCORE. │
│  ② [docs/CONTRIBUTING.md] ➔ Padrões de branch, DoR, commits e PRs.     │
│  ③ [ENGINEERING_GUIDE.md] ➔ Regras de engenharia e uso ético de IA.     │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                              2. PLATAFORMA                             │
│                                                                        │
│  ④ [docs/MONOREPO_STRUCT] ➔ Matriz de acoplamento e dependências.      │
│  ⑤ [docs/NON_FUNC_REQS]   ➔ Performance, RTO/RPO e SLAs de latência.   │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                              3. PRODUTOS                               │
│                                                                        │
│  ⑥ [products/README.md]   ➔ Catálogo de produtos da plataforma.        │
│  ⑦ [products/fincore-food]➔ Landing do vertical FINCORE Food.          │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                              4. GOVERNANÇA                             │
│                                                                        │
│  ⑧ [docs/PRODUCT_MASTER]  ➔ Fonte oficial de verdade do Food.          │
│  ⑨ [docs/DESIGN_CHECKLIST]➔ Checklist mandatório de PRs de interface.  │
└────────────────────────────────────────────────────────────────┘
```

* **[PLATFORM_CHARTER.md](file:///f:/Eigent/fincore_platform/PLATFORM_CHARTER.md)**
* **[docs/CONTRIBUTING.md](file:///f:/Eigent/fincore_platform/docs/CONTRIBUTING.md)**
* **[ENGINEERING_GUIDE.md](file:///f:/Eigent/fincore_platform/ENGINEERING_GUIDE.md)**
* **[docs/MONOREPO_STRUCTURE.md](file:///f:/Eigent/fincore_platform/docs/MONOREPO_STRUCTURE.md)**
* **[docs/NON_FUNCTIONAL_REQUIREMENTS.md](file:///f:/Eigent/fincore_platform/docs/NON_FUNCTIONAL_REQUIREMENTS.md)**
* **[products/README.md](file:///f:/Eigent/fincore_platform/products/README.md)**
* **[products/fincore-food/README.md](file:///f:/Eigent/fincore_platform/products/fincore-food/README.md)**
* **[docs/PRODUCT_MASTER_PLAN.md](file:///f:/Eigent/fincore_platform/docs/PRODUCT_MASTER_PLAN.md)**
* **[docs/DESIGN_REVIEW_CHECKLIST.md](file:///f:/Eigent/fincore_platform/docs/DESIGN_REVIEW_CHECKLIST.md)**

---

## 🛠️ Passo Inicial para Começar

Após ler os documentos acima:
1. Acesse o **Backlog Mestre** localizado no item **⑧ [PRODUCT_MASTER_PLAN.md]** ou no sistema de gestão de projetos (Jira/GitHub Projects).
2. Localize a sua tarefa prioritária e certifique-se de que ela atende à **Definition of Ready (DoR)** antes de arrastá-la para desenvolvimento.
3. Crie o seu branch local a partir da `main` seguindo a convenção cadastrada no `CONTRIBUTING.md`.

*FINCORE Onboarding — Integrando talentos com governança de produto.*
