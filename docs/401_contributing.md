# Diretrizes de Contribuição (Contributing Guidelines)

> **Document ID**: 401  
> **Version**: 1.0.0  
> **Status**: ❄️ Frozen (Congelado)  
>
> Este documento rege o Git Flow, padrão de commits e processos de revisão de código para qualquer colaborador do monorepo da FINCORE Platform.

---

## 1. Branching Strategy (Git Flow Simplificado)

Adotamos a convenção de branchs curtos a partir da branch principal:
* Branch Principal: `master` (ou `main`).
* Feature branchs: `feature/capability-[ID_CAPABILITY]-[nome_curto]` (ex: `feature/capability-1-pdv-express`).
* Hotfix branchs: `hotfix/capability-[ID_CAPABILITY]-[nome_curto]` (ex: `hotfix/capability-6-pix-timeout`).

---

## 2. Conventional Commits (Convenções de Commits)

Todos os commits devem seguir a especificação de commits convencionais:
* **`feat(...)`**: Introdução de nova funcionalidade (ex: `feat(food): criar controlador pdv express`).
* **`fix(...)`**: Correção de bug (ex: `fix(sync): corrigir timeout de reenvio outbox`).
* **`chore(...)`**: Alterações de setup, documentação ou dependências (ex: `chore(platform): atualizar onboarding`).
* **`test(...)`**: Alterações exclusivas de testes locais.

---

## 3. Definition of Ready (DoR) e Pull Request (PR) Flow

### 3.1 Definition of Ready (DoR)
Uma funcionalidade está pronta para desenvolvimento apenas quando:
1. A Capability associada está devidamente identificada.
2. Os critérios de aceitação de UX e Estados estão documentados.
3. Não há dependências bloqueantes abertas.

### 3.2 PR Gate Requirements
Para que um Pull Request seja aprovado e mesclado:
* Todos os testes automáticos devem passar com 100% de sucesso.
* O PR deve responder afirmativamente a todos os itens do **[PRD-009: Design Review Checklist](file:///f:/Eigent/fincore_platform/docs/109_design_review_checklist.md)** se possuir alterações visuais.
* O código deve estar alinhado com o **[ENG-001: Engineering Guide](file:///f:/Eigent/fincore_platform/docs/003_engineering_guide.md)** (inclusive o Princípio da Reimplementação Consciente).

---

*Contributing Guidelines — FINCORE Platform*
