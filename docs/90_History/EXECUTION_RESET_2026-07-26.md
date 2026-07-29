---
Title: Execution Reset 2026-07-26
Status: Archived
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# EXECUTION RESET — FINCORE PLATFORM v2.0
## Replanejamento Oficial da Estratégia de Execução

> **Document ID**: EXECUTION_RESET_2026-07-26_v2
> **Emitido por**: Comitê Executivo Internacional de Engenharia de Software
> **Data**: 2026-07-26
> **Aprovação CTO**: ✅ APROVADO (nota 9.8/10 → revisado para 9.9–10)
> **Aprovação Comitê Executivo**: ✅ APROVADO — "Arquitetura Estratégica Aprovada. Autorizado o início do desenvolvimento conforme o Execution Reset e o FEF."
> **Status**: ✅ APROVADO E VIGENTE
> **Referências**: 000_Constitution, 001_FPOS, 020_FEF, 005_Playbook, 006_Decision_Tree, 018_Why
> **Registrado**: MEM-008 em 019_Project_Memory.md

---

## O QUE MUDA E O QUE NÃO MUDA

### Aprovado — imutável

```
✅ Toda a governança: Constitution, FPOS, FEF, Playbook, ADRs
✅ Arquitetura técnica: Flutter + Serverpod + Drift + PostgreSQL
✅ Multi-Tenant nativo (tenantId em todas as tabelas de negócio)
✅ Offline-First + Outbox + SyncEngine
✅ Supabase Auth como IdP + Serverpod como autorização
✅ Máquina de estados da empresa (preparada para Stripe/MP)
✅ Modelo multi-empresa: usuário pertence ao FINCORE, não ao tenant
✅ Wizard 3 passos para criação de empresa (conversão > formulário único)
```

### Mudado pela revisão — nova estratégia

```
🔄 Orientação por MÓDULOS → orientação por CUSTOMER LIFECYCLE + CAPABILITIES
🔄 Orientação por TELAS → orientação por ESTADOS (DDD correto)
🔄 "Dashboard Inicial" → "Workspace Setup" (configure primeiro, trabalhe depois)
🔄 Onboarding termina no login → Onboarding termina no PRIMEIRO PEDIDO (7/7)
🔄 Flutter Web "recomendado" → decisão Flutter Web ADIADA (Landing ≠ ERP)
🔄 Jornadas isoladas → Customer Lifecycle (modelo completo LC-0 a LC-6)
```

---

## SEPARAÇÃO ARQUITETURAL: LANDING ≠ ERP

```
fincore-ecosystem/
├── landing/    → LC-0 Discovery. Stack: DECISÃO ADIADA (sem acoplamento ao ERP).
├── erp/        → LC-1 a LC-6. Flutter Desktop + Flutter Web (decisão futura).
├── admin/      → Backoffice FINCORE. Stack: DECISÃO ADIADA.
└── api/        → Serverpod + PostgreSQL. Toda lógica de negócio.
```

**Regra**: Landing é Marketing. ERP é Produto. São aplicações independentes.

---

## MÁQUINA DE ESTADOS OFICIAL DO CLIENTE

```
VISITOR
  ↓ (Cria conta: email + senha)
REGISTERED
  ↓ (Conclui Wizard: cria empresa + tenant)
COMPANY_CREATED   → empresa.status: PENDENTE_ATIVACAO
  ↓ (Admin FINCORE aprova manualmente)
PENDING           → acesso limitado (só status page)
  ↓ (Ativação manual)
ACTIVE            → empresa ativa. Acesso ao ERP liberado.
  ↓ (Completa Workspace Setup)
SETUP             → Categorias → Produtos → Clientes → Usuários
  ↓ (Conclui todos os passos)
READY             → Progress: 7/7. "Pronto para vender!"
  ↓ (Primeiro pedido realizado)
OPERATING         → Onboarding 100% concluído.

Exceções:
ACTIVE|SETUP|READY|OPERATING → SUSPENDED (inadimplência > 5 dias)
  → ACTIVE (regularizou)
  → CANCELLED (> 30 dias suspenso)
CANCELLED → PENDING_ACTIVATION (reativação comercial)
```

**Cada transição**: publica EventoEmpresa (imutável) + log auditoria + email transacional.

---

## WORKSPACE SETUP (substitui Dashboard Inicial)

```
┌─────────────────────────────────────────────────────────────────┐
│  WORKSPACE SETUP — Progresso: 3/7 passos (42%)                 │
│  ▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░  42%                               │
│                                                                 │
│  ✅ 1. Empresa criada                    (automático)           │
│  ✅ 2. Conta ativada                     (admin FINCORE)        │
│  ✅ 3. Primeiro login realizado                                 │
│  ○  4. Categorias cadastradas            (0 cadastradas)       │
│  ○  5. Produtos cadastrados              (0 cadastrados)       │
│  ○  6. Primeiro cliente cadastrado       (0 clientes)          │
│  ○  7. Primeira venda realizada          → ONBOARDING COMPLETO │
└─────────────────────────────────────────────────────────────────┘
```

**Filosofia**: Dashboard operacional completo só existe quando há dados reais.
**Onboarding Completo = Primeiro Pedido** (não o login).

---

## CUSTOMER LIFECYCLE COMPLETO

| LC | Nome | Escopo | Versão |
|---|---|---|---|
| **LC-0** | Discovery | Landing Page | app independente — adiado |
| **LC-1** | Onboarding | Signup → Login → Empresa ativa | **v0.4.0 ← AGORA** |
| **LC-2** | Setup | Workspace Setup + Cadastros | v0.5.0 |
| **LC-3** | Operating | PDV real + KDS real + Primeiro Pedido | v0.6.0 |
| **LC-4** | Managing | Fechamento financeiro | v0.7.0 |
| **LC-5** | Growing | Dashboard + Analytics | v0.8.0 |
| **LC-6** | Renewing | Billing + planos | v1.0.0 |

**Regra permanente**: Cada LC fecha 100% antes do próximo começar. (Constitution P12)

---

## JORNADA ZERO — ESCOPO TÉCNICO (LC-1)

**Estado inicial**: VISITOR | **Estado final**: ACTIVE

### Casos de Uso Oficiais

```
[CAP.IAM][CU-J0-001]    CriarConta              VISITOR → REGISTERED
[CAP.TENANT][CU-J0-002] CriarEmpresaWizard      REGISTERED → COMPANY_CREATED
[CAP.IAM][CU-J0-003]    ConfirmarEmail          (opcional fase 1)
[CAP.IAM][CU-J0-004]    Login                   → sessão com tenantId
[CAP.TENANT][CU-J0-005] ConsultarStatusEmpresa  PENDING screen
[CAP.TENANT][CU-J0-006] AtivarEmpresa           PENDING → ACTIVE (SUPERADMIN)
[CAP.TENANT][CU-J0-007] CalcularProgressoSetup  3/7 passos = 42%
```

### Novas Entidades

```dart
// GLOBAL — sem tenantId (requer ADR-JZ-002)
class Usuario { String id; String email; String nome; }

// JUNÇÃO — multi-empresa nativo
class MembroEmpresa {
  String usuarioId; String tenantId; RoleEmpresa role; bool ativo;
}

// LOG IMUTÁVEL — append-only
class EventoEmpresa {
  String tenantId; String tipo; String geradoPor; DateTime ocorridoEm;
}
```

### Telas Novas (ERP — app.fincore.com)

```
SignupPage             (VISITOR → REGISTERED)
OnboardingWizardPage   (Passo 1: empresa + segmento | Passo 2: CNPJ + tel | Passo 3: papel)
PendingApprovalPage    (PENDING — polling status 30s)
LoginPage              (qualquer estado autenticado)
WorkspaceSetupPage     (ACTIVE — checklist 7 passos + KPI %)
```

### Telas Novas (ADMIN — admin.fincore.com)

```
EmpresasPendentesPage  (lista para ativar)
AtivarEmpresaPage      (aprovação com log de auditoria)
```

### Segurança

| Camada | Mecanismo |
|---|---|
| Identidade | Supabase Auth (JWT) |
| Autorização | Serverpod Middleware (valida JWT em todo request) |
| Isolamento | PostgreSQL RLS (tenant A nunca acessa dados do B) |
| SuperAdmin | JWT claim `role: superadmin` — bypass controlado |
| Audit | EventoEmpresa + log — toda ação rastreada e imutável |

### ADRs Obrigatórios Antes do Código

```
ADR-JZ-001: Supabase Auth como IdP (impacta CAP.IAM, CAP.PLATFORM)
ADR-JZ-002: modelo `usuarios` global sem tenantId (impacta CAP.TENANT, Constitution P2)
```

### Definition of Done — Jornada Zero (20 critérios)

```
FUNCIONAL:
□ Usuário acessa ERP no browser sem instalar nada
□ Signup em < 30 segundos (email + senha)
□ Wizard 3 passos: empresa criada em < 2 minutos
□ Tela "Pendente" exibe status em polling de 30s
□ Admin FINCORE ativa empresa via painel admin
□ Usuário recebe email de ativação automático
□ Login com JWT funciona sem erro
□ WorkspaceSetupPage: 3/7 passos, 42%
□ Logout → login → estado preservado

TÉCNICO:
□ AuthMiddleware: request sem JWT → 401
□ AuthMiddleware: JWT de outro tenant → 403
□ RLS: SELECT filtrado por tenantId (teste de invasão)
□ EventoEmpresa criado em cada transição de estado
□ Nenhuma senha ou JWT logado em console

TESTES:
□ Unitários: CU-J0-001 a CU-J0-007 passando
□ Integração: fluxo completo VISITOR → ACTIVE
□ Segurança: tenant A não acessa dados do tenant B
□ Regressão: cliente_usecases_test.dart passando

QUALIDADE:
□ Zero dados mock visíveis ao usuário final
□ Emails transacionais chegando (testado em ambiente real)
```

---

## CRONOGRAMA

```
SEMANA 1 — Governança (sem código)
  Dia 1:  Aprovar ADR-JZ-001 (Supabase Auth)
  Dia 2:  Aprovar ADR-JZ-002 (usuarios global)
  Dia 2:  Atualizar 013_Project_State.md
  Dia 3:  Resolver build_runner (hotfix urgente)
  Dia 4:  Configurar ambiente ERP web (Flutter target)

SEMANA 2 — Backend
  CAP.IAM + CAP.TENANT: domínio + UseCases + Endpoints
  AuthMiddleware JWT no Serverpod
  EventoEmpresa log imutável

SEMANA 3 — Frontend (ERP)
  SignupPage + OnboardingWizardPage
  PendingApprovalPage + LoginPage
  WorkspaceSetupPage (checklist + KPI %)

SEMANA 4 — Integração + DoD
  Testes: unitários + integração + segurança
  Emails transacionais
  DoD: todos os 20 critérios verificados
  Tag: v0.4.0-lc1-jornada-zero
```

---

*Aprovado em 2026-07-26. Fase estratégica encerrada. Desenvolvimento autorizado.*
*Ver também: 020_FINCORE_Evolution_Framework.md para o método de evolução permanente.*
