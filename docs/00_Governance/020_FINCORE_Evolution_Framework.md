---
Title: FINCORE Evolution Framework
Status: Active
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# FINCORE EVOLUTION FRAMEWORK (FEF) v2.0
## O Guardião da Evolução Permanente do Produto

> **Document ID**: 020_FINCORE_Evolution_Framework
> **Version**: 2.0.0
> **Status**: ❄️ FROZEN — alterações apenas por ADR + voto unânime do Comitê Executivo
> **Owner**: Principal Architect (Technical) + Product Owner (Business)
> **Posição na Pirâmide**: NÍVEL 1 — abaixo da Constitution (000), acima dos PRDs (100-199)
> **Aprovação CTO**: ✅ APROVADO — 2026-07-26 (nota 9.9–10)
> **Aprovação Comitê Executivo**: ✅ APROVADO — 2026-07-26
> **Declaração**: "Arquitetura Estratégica Aprovada. Autorizado o início do desenvolvimento conforme o Execution Reset e o FEF."
> **Depende de**: 000_Constitution, 001_FPOS
> **Obrigatoriedade**: 🔴 MANDATÓRIO — lido antes de qualquer nova funcionalidade, ADR ou backlog item

---

## REGRA PERMANENTE (2026-07-26)

> Nenhum novo documento de governança será criado, salvo quando surgir uma necessidade arquitetural concreta.
> Todo esforço migra para implementar Jornadas, validar arquitetura na prática e evoluir Capabilities conforme o FEF.
> Registrar apenas ADRs, PRDs e atualizações naturais dos documentos existentes.

---

## POR QUE ESTE DOCUMENTO EXISTE?

> A Constitution define os princípios imutáveis.
> O FPOS define como o projeto é conduzido.
> O Execution Reset define a estratégia atual de execução.
>
> O **FINCORE Evolution Framework** responde uma pergunta diferente e mais duradoura:
>
> **"Como o FINCORE evolui para sempre?"**

---

## PARTE 1 — O EVOLUTION MODEL

### 1.1 A Hierarquia Oficial de Evolução (5 Níveis)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     FINCORE EVOLUTION MODEL v2.0                            │
└─────────────────────────────────────────────────────────────────────────────┘

  NÍVEL 0 ── GOVERNANCE
  │  Constitution · FPOS · FEF · ADRs
  │  Decide: Comitê Executivo — Voto Unânime
  │  Frequência: nunca / raramente
  ↓
  NÍVEL 1 ── CUSTOMER LIFECYCLE (LC)
  │  LC-0 Discovery → LC-1 Onboarding → LC-2 Setup →
  │  LC-3 Operating → LC-4 Managing → LC-5 Growing → LC-6 Renewing
  │  Decide: CTO + PO | Frequência: anual / por estratégia
  ↓
  NÍVEL 2 ── BUSINESS CAPABILITIES
  │  CAP.IAM · CAP.TENANT · CAP.CATALOG · CAP.PRICING ·
  │  CAP.CUSTOMERS · CAP.SALES · CAP.KITCHEN · CAP.INVENTORY ·
  │  CAP.FINANCE · CAP.DELIVERY · CAP.ANALYTICS · CAP.PLATFORM
  │  Decide: Principal Architect + PO | Frequência: semestral
  ↓
  NÍVEL 3 ── BUSINESS JOURNEYS
  │  Jornada Zero · Jornada 1 · Jornada 2 ...
  │  Decide: Product Owner | Frequência: por ciclo (meses)
  ↓
  NÍVEL 4 ── FEATURES / USE CASES
  │  CU-J0-001 CriarConta · CU-V05 CadastrarCliente · etc.
  │  Decide: PO + Tech Lead | Frequência: por sprint (semanas)
  ↓
  NÍVEL 5 ── TASKS
     [CAP.SALES][CU-V03-J3] Criar tabela pedidos no Drift
     Decide: Desenvolvedor | Frequência: diário
```

> **Regra inviolável**: Nenhum nível inferior contradiz um nível superior.

---

## PARTE 2 — MATURITY MODEL

### 2.1 Os 5 Níveis de Maturidade

| Nível | Nome | Definição | Critério de Entrada |
|---|---|---|---|
| **M1** | **PLANNING** | Domínio identificado. Design em curso. Sem código. | Capability aparece no FEF |
| **M2** | **FOUNDATION** | Entidades + Repositórios existem. Sem UI funcional. | Domain models + BaseRepository OK |
| **M3** | **OPERATIONAL** | Fluxo ponta-a-ponta para o caso principal. | 1+ Jornada homologada pela persona |
| **M4** | **PRODUCTION** | Cliente piloto real. Zero bugs críticos. Estável > 30 dias. | Cliente real em produção 30+ dias |
| **M5** | **ENTERPRISE** | Escalável, analytics, alertas, automação, SLA documentado. | 10+ empresas reais + SLA |

### 2.2 Estado de Maturidade Atual (2026-07-26)

| Capability | Maturidade | Justificativa |
|---|---|---|
| CAP.PLATFORM | M3 | Core 82% funcional. Sync, DI, Audit OK. RLS pendente. |
| CAP.IAM | M1 | Planejado. Jornada Zero (LC-1). |
| CAP.TENANT | M1 | Planejado. Jornada Zero (LC-1). |
| CAP.CATALOG | M2 | Entidades + Repos OK. UI não conectada. |
| CAP.PRICING | M2→M3 | Engine 99% FROZEN. UI de gestão não conectada. |
| CAP.CUSTOMERS | M2 | UseCases criados. UI não conectada. |
| CAP.SALES | M1→M2 | UI impecável mas sem persistência. Pedido não existe. |
| CAP.KITCHEN | M1→M2 | KDS UI pronto. Dados mock. Sem integração real. |
| CAP.INVENTORY | M1 | LoteInsumo parcial. EstornoUseCase OK mas isolado. |
| CAP.FINANCE | M1 | Não existe. Bloqueado por CAP.SALES. |
| CAP.DELIVERY | M1 | Não iniciado. |
| CAP.ANALYTICS | M1 | Não iniciado. Bloqueado por CAP.FINANCE. |

---

## PARTE 3 — CAPABILITY MAP OFICIAL

### 3.1 Core vs Supporting

```
CORE (sem elas o produto não existe):
  CAP.PLATFORM  CAP.IAM  CAP.TENANT  CAP.CATALOG
  CAP.PRICING   CAP.CUSTOMERS  CAP.SALES  CAP.FINANCE

SUPPORTING (ampliam o valor do produto):
  CAP.KITCHEN  CAP.INVENTORY  CAP.DELIVERY  CAP.ANALYTICS
```

> **Regra**: Core Capabilities bloqueiam o produto. Supporting Capabilities aumentam retenção. O produto sobrevive sem Supporting, não sobrevive sem Core.

### 3.2 Dependency Graph

```
CAP.PLATFORM (base de tudo — presente em todos os LCs)
     |
   CAP.IAM ──────────────────────────────────────────────┐
     |                                                    |
   CAP.TENANT ────────────────────────────────────────────┤
     |                                                    |
   CAP.CATALOG ──→ CAP.PRICING ──────────────────────────┤
     |                                  |                 |
   CAP.CUSTOMERS ─────────────→ CAP.SALES ───────────────┘
                                    |         |        |
                              CAP.KITCHEN  CAP.INV  CAP.FINANCE
                                    |         |           |
                              CAP.DELIVERY ←──┘      CAP.ANALYTICS
```

`A → B` significa "B depende de A". Não inicie B antes de A estar em M3 (OPERATIONAL).

### 3.3 Capabilities Detalhadas

---

#### `CAP.PLATFORM` | Core | M3 | ✅ Funcional
**Business Owner**: CTO | **Technical Owner**: Principal Architect | **LC**: Todos

| Métrica | Valor |
|---|---|
| Cobertura de testes | ~65% |
| Dívida técnica | Backoff exponencial · RLS · 3 tabelas Pedido faltando |
| ADRs abertos | 0 |
| Bloqueada? | Não |

```
TenantContext ✅ · BaseRepository ✅ · Outbox+Sync ✅ · AuditService ✅
DI ✅ · Drift 14 tabelas 🟡 · Serverpod endpoints 🔴 · RLS 🔴 · AuthMiddleware ○
```

---

#### `CAP.IAM` — Identity & Access | Core | M1 | ○ Planejado
**Business Owner**: Product Owner | **Technical Owner**: Principal Architect | **LC**: LC-1 → todos

```
[CU-J0-001] CriarConta (email+senha)   ○ Jornada Zero
[CU-J0-003] ConfirmarEmail              ○ Jornada Zero
[CU-J0-004] Login / Logout              ○ Jornada Zero
RecuperarSenha                          ○ Backlog LC-2
Google OAuth / SSO                      ○ Backlog LC-2
Multi-fator (2FA)                       ○ Backlog LC-4
Convites por Email                      ○ Backlog LC-2
RBAC granular                           ○ Backlog LC-4
```

---

#### `CAP.TENANT` — Tenant Management | Core | M1 | ○ Planejado
**Business Owner**: CTO + PO | **Technical Owner**: Principal Architect | **LC**: LC-1, LC-6

```
[CU-J0-002] CriarEmpresaWizard (3 passos)    ○ Jornada Zero
[CU-J0-006] AtivarEmpresa (Admin FINCORE)    ○ Jornada Zero
[CU-J0-007] WorkspaceSetupProgress (7/7)     ○ Jornada Zero
[CU-J0-005] ConsultarStatusEmpresa           ○ Jornada Zero
Suspender / Cancelar Empresa                 ○ Backlog LC-6
Multi-empresa (Matriz/Filial)                ○ Backlog LC-5
Gestão de Planos / Billing                   ○ Backlog LC-6
```

**Máquina de estados**: `PENDENTE_ATIVACAO → TRIAL → ATIVO → SUSPENSO → CANCELADO → PENDENTE_ATIVACAO`

---

#### `CAP.CATALOG` — Catálogo | Core | M2 | ✅ Domínio OK / UI pendente
**Business Owner**: PO | **Technical Owner**: Tech Lead Backend | **LC**: LC-2, LC-3

| Métrica | Valor |
|---|---|
| Cobertura | ~60% (domínio) |
| Dívida técnica | UI não conectada ao repositório real |
| Bloqueada? | Não — M2 alcançado |

```
Categorias CRUD ✅ · Produtos CRUD ✅ · BuscarProduto ○ · FotoProduto ○
```

---

#### `CAP.PRICING` — Motor de Preços | Core | M2→M3 | ✅ FROZEN
**Business Owner**: PO | **Technical Owner**: Tech Lead Backend — **FROZEN** | **LC**: LC-2, LC-3

> ⚠️ **FROZEN**: Nenhuma alteração sem ADR unânime. Cobertura 95.65%. 47 testes passando.

```
TabelasPrecificacao ✅ · ItensFaixas ✅ · AssociacaoN:N ✅ · Prioridade ✅ · Canal ✅
```

---

#### `CAP.CUSTOMERS` — Gestão de Clientes | Core | M2 | ✅ UseCases OK / UI pendente
**Business Owner**: PO | **Technical Owner**: Tech Lead Backend | **LC**: LC-2, LC-3

| Métrica | Valor |
|---|---|
| Cobertura | cliente_usecases_test.dart criado e passando |
| Dívida técnica | UI não conectada aos UseCases reais |
| Bloqueada? | Não — M2 alcançado |

```
CadastrarCliente ✅ · EditarCliente ✅ · ExcluirSoftDelete ✅ · BuscarCliente ✅
Endereços (LocalEntrega) 🟡 · HistóricoCompras ○ · CRM ○
```

---

#### `CAP.SALES` — PDV / Ponto de Venda | Core | M1→M2 | 🟡 UI OK / sem persistência
**Business Owner**: PO | **Technical Owner**: Tech Lead Full-Stack | **LC**: LC-3

| Métrica | Valor |
|---|---|
| Cobertura | ~0% (EntidadePedido não existe) |
| Dívida técnica | CRÍTICA — PDV simula em memória. clienteId NOT NULL pendente. |
| ADRs abertos | 1 pendente |
| Bloqueada? | Sim — aguarda LC-1 (Jornada Zero) fechar |

```
AbrirCaixa 🔴 · SelecionarCliente 🔴 · MontarPedido 🟡 · Undo4s ✅
EntidadePedido (Aggregate Root) 🔴 CRÍTICO · PricingEngine 🟡 (não integrado)
TransacaoAtomica7passos 🔴 · Pagamento 🔴 · CupomESCPOS 🔴 · FecharCaixa 🔴
```

---

#### `CAP.KITCHEN` — KDS | Supporting | M1→M2 | 🟡 UI OK / mock
**Business Owner**: PO | **Technical Owner**: Tech Lead Frontend | **LC**: LC-3

```
KDS3Colunas 🟡 · TimerAtraso 🟡 · IniciarPreparo 🔴 · MarcarPronto 🔴
EstornoLIFO ✅ · ModoCozinha 🔴 · AgendaOperacional ○ (crítico food service)
```

---

#### `CAP.INVENTORY` — Estoque | Supporting | M1 | 🔴 Não iniciado
**Business Owner**: PO | **Technical Owner**: Tech Lead Backend | **LC**: LC-3

```
EstoqueTripartite (Físico/Reservado/Disponível) 🔴 · EntradaEstoque 🔴
BaixaAutomaticaPorPedido 🔴 · EstornoLIFO ✅ (UseCase OK, não integrado)
AlertaMinimoEstoque ○ · MRP/SugestaoCompra ○
```

---

#### `CAP.FINANCE` — Financeiro | Core | M1 | 🔴 Bloqueado por CAP.SALES
**Business Owner**: CTO + PO | **Technical Owner**: Tech Lead Backend | **LC**: LC-4

```
LancamentoFinanceiro 🔴 · FechamentoCaixa 🔴 · RelatorioDia 🔴
ConciliacaoFormasPagamento 🔴 · ExportacaoContabil ○
```

---

#### `CAP.DELIVERY` — Expedição | Supporting | M1 | 🔴 Não iniciado
**Business Owner**: PO | **Technical Owner**: A definir | **LC**: LC-3 futuro

---

#### `CAP.ANALYTICS` — Inteligência | Supporting | M1 | 🔴 Bloqueado por CAP.FINANCE
**Business Owner**: CTO + PO | **Technical Owner**: A definir | **LC**: LC-5

---

## PARTE 4 — CAPABILITY MATRIX

| Capability | LC-0 | LC-1 | LC-2 | LC-3 | LC-4 | LC-5 | LC-6 |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| CAP.PLATFORM | ○ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| CAP.IAM | ○ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| CAP.TENANT | ○ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| CAP.CATALOG | | | ✅ | ✅ | ✅ | ✅ | |
| CAP.PRICING | | | ✅ | ✅ | ✅ | ✅ | |
| CAP.CUSTOMERS | | | ✅ | ✅ | ✅ | ✅ | |
| CAP.SALES | | | | ✅ | ✅ | ✅ | |
| CAP.KITCHEN | | | | ✅ | ✅ | | |
| CAP.INVENTORY | | | | ✅ | ✅ | ✅ | |
| CAP.FINANCE | | | | | ✅ | ✅ | ✅ |
| CAP.DELIVERY | | | | ✅ | ✅ | | |
| CAP.ANALYTICS | | | | | | ✅ | ✅ |

**Legenda**: ✅ Capability ativa | ○ Infraestrutura | vazio = não relevante neste estágio

---

## PARTE 5 — A INTEGRATION RULE

**Lei permanente**: toda nova funcionalidade responde estas 7 perguntas na ordem. Sem atalho.

```
P1: Em qual CAPABILITY (CAP.XX)?
    → Não existe? Propor nova via ADR.

P2: Em qual LIFECYCLE STAGE (LC-N)?
    → LC anterior 100% homologado?
      NÃO → PARE. Finalizar LC anterior primeiro. (Constitution P12)

P3: Existe JOURNEY correspondente neste LC?
    → NÃO → Criar Jornada (PRD novo).

P4: Existe CASO DE USO OFICIAL (CU-XXX)?
    → NÃO → Criar em PRD-125 com Persona + Pré/Pós-condições.

P5: Altera ARQUITETURA?
    → SIM → ADR obrigatório antes de qualquer código.

P6: Há DEPENDÊNCIA TÉCNICA não satisfeita?
    → SIM → A dependência é prioridade agora. Esta feature espera.

P7: Criar backlog item com formato:
    [CAP.XX][CU-YYY-JN] Nome da Funcionalidade (Verbo)
    Capability / LC Stage / Persona / Use Case / DoD
    → Agora pode codar. ✅
```

---

## PARTE 6 — FEATURE LIFECYCLE

```
IDEA → SPECIFIED → DESIGNED → IN_DEVELOPMENT → IN_REVIEW → IN_TESTING
                                                                  |
                                                            HOMOLOGATED → RELEASED → STABLE
                                                                                       |
                                                                              DEPRECATED → DISCONTINUED
```

| Estado | Responsável | Critério |
|---|---|---|
| IDEA | Qualquer | Frase de 1 linha com "por quê" |
| SPECIFIED | Product Owner | PRD + CU + Integration Rule respondida |
| DESIGNED | Comitê Engenharia | ADR aprovado (se arquitetural) |
| IN_DEVELOPMENT | Desenvolvedor | Sprint ativa |
| IN_REVIEW | Tech Lead | PR aberto, code review |
| IN_TESTING | QA / Dev | Testes de integração passando |
| HOMOLOGATED | **Persona real** | DoD 100% — usuário real testou |
| RELEASED | DevOps | Deploy produção. Tag de versão. |
| STABLE | Automático | 30 dias sem bug crítico |
| DEPRECATED | Comitê Executivo | Substituída. 90 dias de aviso. |
| DISCONTINUED | Comitê Executivo | Removida. PRD → Archive/. MEM registrado. |

---

## PARTE 7 — EVOLUTION GATES

Um LC Stage só avança quando **todos os portões estiverem fechados**:

```
LC-1 → LC-2:
  □ Signup + Login funcional ponta-a-ponta
  □ Empresa criada + ativada pelo admin FINCORE
  □ AuthMiddleware validando JWT em todo request
  □ Tenant isolation testado (tenant A não acessa dados do B)
  □ Workspace Setup exibindo progresso 3/7

LC-2 → LC-3:
  □ Jornada Zero homologada por usuário real
  □ CAP.CATALOG: Categorias + Produtos com UI real conectada
  □ CAP.PRICING: PricingEngine com dados reais
  □ CAP.CUSTOMERS: UI de Clientes conectada aos UseCases reais

LC-3 → LC-4:
  □ Pedido real com persistência ponta-a-ponta
  □ PDV: 5 vendas reais sem intervenção dev (P1 Maria)
  □ KDS: 10 ordens processadas sem mock (P2 João)
  □ Workspace Setup 7/7 — Primeiro Pedido realizado

LC-4 → LC-5:
  □ Caixa diário abre e fecha com totais corretos
  □ LançamentoFinanceiro automático por pedido
  □ Relatório do Dia exportável
  □ P4 Luiza fecha caixa sozinha, sem intervenção dev

LC-5 → LC-6:
  □ Dashboard operacional com dados reais
  □ 1+ alerta automático funcionando
  □ Cliente piloto real em produção há 30+ dias
```

---

## PARTE 8 — DEPRECATION PROCESS

```
1. DETECÇÃO   → Feature candidata identificada
2. PROPOSTA   → Comitê de Produto: justificativa + impacto nos usuários
3. COMUNICAÇÃO → Marcada DEPRECATED · Usuários notificados 90 dias antes
4. ARCHIVING  → PRD → docs/Archive/ · Código: // DEPRECATED: ver ADR-XXX
5. REMOVAL    → Código removido · PR referência · Testes atualizados
               → Capability Map atualizado · MEM-XXX em 019_Project_Memory
```

---

## PARTE 9 — COMO USAR NO DIA A DIA

| Cenário | Ação |
|---|---|
| Quero adicionar funcionalidade nova | → Integration Rule (Parte 5) |
| Quero saber o que falta em Sales | → CAP.SALES no Capability Map (Parte 3) |
| Quero saber se posso começar o Financeiro | → Evolution Gates LC-3→LC-4 (Parte 7) |
| Feature precisa ser removida | → Deprecation Process (Parte 8) |
| Novo desenvolvedor quer entender o produto | → Customer Lifecycle + Capability Matrix |
| Investidor quer ver o roadmap | → Evolution Model + Capability Matrix |

---

## PARTE 10 — DECLARAÇÃO DE ADOÇÃO PERMANENTE

> **A partir de 2026-07-26, toda nova funcionalidade, ADR, sprint ou release referencia:**
>
> 1. A **Capability** (CAP.XX)
> 2. O **LC Stage** (LC-N)
> 3. A **Jornada** correspondente
> 4. O **Caso de Uso** oficial (CU-XXX)
>
> **Feature sem esses 4 elementos = rejeitada antes de entrar no backlog.**
>
> O FINCORE não desenvolve módulos.
> O FINCORE evolui **Capabilities** para servir o **Customer Lifecycle**.

---

## ASSINATURA OFICIAL

| Cargo | Decisão | Data |
|---|---|---|
| CTO | ✅ APROVADO (9.9–10) | 2026-07-26 |
| Comitê Executivo | ✅ APROVADO — Fase estratégica encerrada. Desenvolvimento autorizado. | 2026-07-26 |

*Registrado como MEM-008 em 019_Project_Memory.md*
*Próxima revisão estrutural: apenas quando surgir necessidade arquitetural concreta.*
