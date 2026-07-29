---
Title: Project Operating System
Status: Active
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# FINCORE — PROJECT OPERATING SYSTEM (FPOS) v1.1
## Sistema Operacional Oficial do Projeto — Governança Permanente

> **Document ID**: 001_Project_Operating_System (FPOS-LEVEL 1)
> **Version**: 1.1.0 (atualizado 2026-07-25 — adição de 017, 018, 019, AI_RULES e hierarquia Governance)
> **Status**: ❄️ FROZEN (Congelado — alterações estruturais apenas por ADR)
> **Owner**: Comitê Executivo Permanente FINCORE
> **Depende de**: [000_Project_Constitution](file:///f:/Eigent/fincore_platform/docs/000_Project_Constitution.md) (LEIA ESTE PRIMEIRO)
> **Related**: 005_Development_Playbook, 006_Decision_Tree, 013_Project_State, 015_Glossary, 016_FAQ, 017_Architecture_Atlas, 018_Project_Why, 019_Project_Memory, AI_RULES
> **Obrigatoriedade**: 🔴 MANDATÓRIO. Todo novo membro (humano ou IA) lê este documento ANTES de qualquer outra coisa. Não há exceção.

---

## O QUE É ESTE DOCUMENTO?

> **Um Sistema Operacional orienta o funcionamento de um computador.** Ele sabe qual processo executar primeiro, onde cada arquivo mora, quem tem permissão para quê, como um programa nasce, como ele morre. O FPOS (FINCORE Project Operating System) faz a mesma coisa — mas para o desenvolvimento de software.
>
> **Assim como o Windows não deixa dois processos escreverem no mesmo arquivo ao mesmo tempo, o FPOS não deixa dois desenvolvedores criarem padrões conflitantes no código.** Assim como o Linux tem hierarquia de pastas (`/etc`, `/usr`, `/var`), o FPOS tem hierarquia oficial de documentos.

**Objetivo declarado**: Em 10 anos, qualquer pessoa (criador original, novo dev, estagiário, consultoria externa, ou mesmo uma nova IA) deve conseguir assumir o desenvolvimento do FINCORE APENAS lendo a documentação oficial — **sem precisar fazer NENHUMA pergunta a nenhum ser humano sobre o que é, como funciona, ou como evoluir o projeto**.

---

# PARTE 1 — ESTRUTURA IDEAL DE DOCUMENTAÇÃO (Reorganização Proposta)

## 1.1 Análise Crítica da Estrutura Atual

A estrutura atual (`000_documentation_manifesto.md`, `001_platform_charter.md`, `002_onboarding.md`, `100_...`, `120_...`, `300_decisions/`) tem qualidade técnica individual alta (cada documento é bem escrito). Entretanto ela sofre de **4 problemas arquiteturais de governança**:

| Problema | Impacto |
|---|---|
| 1. **Não há ordem de leitura obrigatória explícita** | Novo desenvolvedor abre `docs/`, vê 37 arquivos e não sabe por onde começar. Perde 3 horas. |
| 2. **Sem mapa de dependências documental** | Não sabe se PRD-120 depende de 121 ou vice-versa. |
| 3. **Sem boot sequence por perfil** | Product Owner e novo Arquiteto leem documentos em ORDENS DIFERENTES. Hoje ambos leem a mesma sequência. |
| 4. **Sem documento "guarda-chuva"** (este FPOS) que defina regras dos documentos | Cada documento define suas próprias regras de Status/Frozen. Não há consistência. |

## 1.2 Estrutura Ideal Proposta (com semântica por faixa numérica)

A partir de hoje, a numeração de documentos passa a ter o seguinte **significado oficial por faixa** (igual endereço IP tem classe A/B/C):

```
docs/
│
│   ════════════════════════════════════════════
│   HIERARQUIA OFICIAL DE GOVERNANÇA FINCORE
│   ════════════════════════════════════════════
│
│       FILOSOFIA (o que somos)
│          ↓
│       GOVERNANÇA (como decidimos)
│          ↓
│       OPERATING SYSTEM (como funcionamos)
│          ↓
│       PLAYBOOK + DECISION TREE (como desenvolvemos)
│          ↓
│       ROADMAP + PRDs (o que construímos)
│          ↓
│       CÓDIGO
│
│   ════════════════════════════════════════════
│
├── 000 ── LAYER FILOSOFIA / CONSTITUIÇÃO (FROZEN — sem alteração casual)
│   ├── 000_Project_Constitution.md            ← LEI SUPREMA (já existe)
│   └── AI_RULES.md                            ← REGRAS PARA IA (obrigatório para todo modelo)
│
├── 001 ── LAYER GOVERNANÇA (FROZEN)
│   └── 001_Project_Operating_System.md        ← ESTE DOCUMENTO
│
├── 002 - 004 ── LAYER BOOTSTRAP & ONBOARDING
│   ├── 002_Project_Bootstrap.md               ← Como rodar projeto do 0 em 20 min
│   ├── 003_Engineering_Guide.md               ← (existe atualmente, mantém)
│   └── 004_Monorepo_Structure.md              ← (existe atualmente, mantém)
│
├── 005 - 009 ── LAYER ENGINEERING (processo e decisão)
│   ├── 005_Development_Playbook.md            ← Ciclo vida completo funcionalidade
│   ├── 006_Decision_Tree_&_Mandatory_Rules.md ← Árvore decisão + regras obrigatórias
│   ├── 007_Documentation_Guide.md             ← Como criar documento novo corretamente
│   └── 008_Code_Standards.md                  ← Futuro: unificar lint, padrão nomes, etc
│
├── 010 - 014 ── LAYER PROCESSO DE ENGENHARIA
│   ├── 010_Git_Workflow.md
│   ├── 011_Release_Process.md
│   ├── 012_Roadmap_&_Milestones.md            ← Roadmap oficial + milestones
│   └── 013_Project_State.md                   ← ⭐ ESTADO ATUAL (atualização semanal obrigatória)
│
├── 015 - 019 ── LAYER MEMÓRIA & CONHECIMENTO VIVO
│   ├── 015_Project_Glossary.md                ← Todas palavras-chave
│   ├── 016_Project_FAQ.md                     ← Perguntas frequentes
│   ├── 017_Architecture_Atlas.md              ← ⭐ DIAGRAMAS VISUAIS da arquitetura
│   ├── 018_Project_Why.md                     ← ⭐ POR QUE usamos cada tecnologia
│   └── 019_Project_Memory.md                  ← ⭐ HISTÓRICO das grandes decisões
│
├── 090 - 099 ── LAYER QUALIDADE & DOF (mantém atuais)
│   ├── 090_engineering_process.md             ← (existe)
│   ├── 091_definition_of_done.md              ← (existe, FROZEN)
│   └── 095_documentation_standards.md         ← (existe)
│
├── 100 - 199 ── LAYER PRODUTO E DOMÍNIO (mantém atuais: 100-125 + futuros)
│   ├── 100_platform_core_architecture.md
│   ├── 101_product_master_plan.md
│   ...
│   ├── 120 - 125 — Domínios (Configuration, Pricing, Operational Flows)
│   └── [126-199 reservados para futuros domínios: KDS, Financeiro, Estoque...]
│
├── 300_decisions/ ── ADRs (mantém estrutura atual com templates)
├── auditorias/ ── Relatórios trimestrais (ex: AUDITORIA_COMITE_EXECUTIVO_2026_07_25.md)
├── implementation/
│   └── reports/milestone-XX/implementation_report.md (mantém)
├── templates/ (mantém: ADR, PRD, Implementation Report)
└── Archive/ (documento obsoleto NUNCA apaga — move para cá com data)
```

**Justificativa técnica desta reorganização**: Empresas como Microsoft/Google/Amazon padronizam camadas documentais por número assim como nós padronizamos classes de endereço IP. Isto elimina ambiguidade. O número do documento já diz sua natureza antes de abrir o arquivo.

---

# PARTE 2 — ORDEM OBRIGATÓRIA DE LEITURA (Sequência Universal)

> **REGRA § 2.1**: Nenhum ser humano ou IA pode interagir com código, dados, PRD ou backlog sem ter completado a sequência abaixo até o ponto correspondente ao seu perfil.

| Ordem | Documento | Obrigatório para | Tempo de Leitura Estimado |
|---|---|---|---|
| **1° OBRIGATÓRIO SEM EXCEÇÃO** | [000_Project_Constitution](file:///f:/Eigent/fincore_platform/docs/000_Project_Constitution.md) | TODOS (dev, PO, estagiário, IA, consultoria, dono) | 12 min |
| **2° OBRIGATÓRIO SEM EXCEÇÃO** | [AI_RULES](file:///f:/Eigent/fincore_platform/docs/AI_RULES.md) | **QUALQUER MODELO DE IA** (leitura antes de tocar em qualquer arquivo) | 8 min |
| **3° OBRIGATÓRIO SEM EXCEÇÃO** | [001_Project_Operating_System (ESTE)](file:///f:/Eigent/fincore_platform/docs/001_Project_Operating_System.md) | TODOS | 18 min |
| **4° OBRIGATÓRIO** | [013_Project_State](file:///f:/Eigent/fincore_platform/docs/013_Project_State.md) | TODOS — ler para saber onde estamos HOJE | 5 min |
| **5° OBRIGATÓRIO** | [002_onboarding](file:///f:/Eigent/fincore_platform/docs/002_onboarding.md) | TODOS (exceto IA pura de documentação) | 25 min |
| **6° OBRIGATÓRIO** | [005_Development_Playbook](file:///f:/Eigent/fincore_platform/docs/005_Development_Playbook.md) | Desenvolvedores, Arquitetos, QA | 15 min |
| **7° OBRIGATÓRIO** | [006_Decision_Tree](file:///f:/Eigent/fincore_platform/docs/006_Decision_Tree.md) | Desenvolvedores, Arquitetos, PO, Dono | 10 min |
| **8° OBRIGATÓRIO** | [020_FINCORE_Evolution_Framework](file:///f:/Eigent/fincore_platform/docs/020_FINCORE_Evolution_Framework.md) | TODOS — define como o produto evolui e a Integration Rule | 15 min |
| **9° (perfil produto)** | [015_Project_Glossary](file:///f:/Eigent/fincore_platform/docs/015_Project_Glossary.md) + 103_product_manifesto | PO, Dono, Vendas | 12 min |
| **10° (perfil arquitetura)** | [017_Architecture_Atlas](file:///f:/Eigent/fincore_platform/docs/017_Architecture_Atlas.md) + [100_platform_core_architecture](file:///f:/Eigent/fincore_platform/docs/100_platform_core_architecture.md) | Arquiteto, Tech Lead, Dev Senior+ | 45 min |
| **11° (contexto histórico)** | [018_Project_Why](file:///f:/Eigent/fincore_platform/docs/018_Project_Why.md) + [019_Project_Memory](file:///f:/Eigent/fincore_platform/docs/019_Project_Memory.md) | Todos — antes de propor qualquer mudança de tecnologia/arquitetura | 20 min |

> **Checklist de Comprovação**: Todo novo membro, ao terminar a leitura até seu ponto obrigatório, cria um PR contendo **1 arquivo `docs/onboarding/[SEU_NOME].md`** com data e lista dos documentos que leu. Isto serve como trilha de auditoria de conhecimento. IAs colocam o nome do modelo: `onboarding/CLAUDE-3-SONNET-v2_20260725.md`.

---

# PARTE 3 — BOOT SEQUENCE POR PERFIL

Cada perfil de membro tem **sequência diferente** de documentos a ler (PO não precisa saber detalhe de Drift SQLite; arquiteto não precisa ler glossário de persona primeiro).

```
╔════════════════════════════════════════════════════════════════════════════════════╗
║                       BOOT SEQUENCE OFICIAL POR PERFIL                              ║
╠════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                    ║
║  ┌──────────────────────────────────────────────────────────────────────────────┐  ║
║  │ PERFIL: NOVO DESENVOLVEDOR JÚNIOR (0-6 meses experiência)                    │  ║
║  ├──────────────────────────────────────────────────────────────────────────────┤  ║
║  │ 000 Constitution → 001 FPOS → 002 Bootstrap → Rodar projeto localmente      │  ║
║  │   → (sucesso? build rodando?)                                                │  ║
║  │      → 005 Playbook → 006 Decision Tree → 091 Definition of Done            │  ║
║  │         → 125_operational_flows (Fluxos 1-3 + Personas)                     │  ║
║  │            → Atribui primeiro ticket de BAIXA prioridade (item 17-21)        │  ║
║  └──────────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                    ║
║  ┌──────────────────────────────────────────────────────────────────────────────┐  ║
║  │ PERFIL: NOVO ARQUITETO / TECH LEAD                                           │  ║
║  ├──────────────────────────────────────────────────────────────────────────────┤  ║
║  │ 000 Constitution → 001 FPOS → 003 Eng Guide → 004 Monorepo Structure         │  ║
║  │   → 100 Platform Core Architecture → 120-123 Domínios Pricing                │  ║
║  │      → 125 Operational Flows → Auditoria_2026_07_25 (estado atual)           │  ║
║  │         → 005 Playbook + 006 Decision Tree (estudar ciclos)                  │  ║
║  │            → Realiza 1 code review de PR existente sem escrever nada ainda   │  ║
║  └──────────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                    ║
║  ┌──────────────────────────────────────────────────────────────────────────────┐  ║
║  │ PERFIL: PRODUCT OWNER / DONO DA EMPRESA                                      │  ║
║  ├──────────────────────────────────────────────────────────────────────────────┤  ║
║  │ 000 Constitution (só princípios negócio p3) → 001 FPOS (Partes 7, 10)         │  ║
║  │   → 103 Product Manifesto → 101 Master Plan → 125 Operational Flows          │  ║
║  │      → 013 Project Status (atual) → Backlog 21 itens (Prioridade 1→21)       │  ║
║  │         → Começa homologação: Luiza Jornada-A validar item 1-8               │  ║
║  └──────────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                    ║
║  ┌──────────────────────────────────────────────────────────────────────────────┐  ║
║  │ PERFIL: ESTAGIÁRIO (16-20 anos, aprendendo)                                 │  ║
║  ├──────────────────────────────────────────────────────────────────────────────┤  ║
║  │ 000 Constitution (resumo 1 página) → 002 Bootstrap                          │  ║
║  │   → Roda projeto, explora UI → Aprende Dart/Flutter tutoriais internos       │  ║
║  │      → 015 Glossário inteiro (memoriza) → 125 Personas (só ler, sem tocar)   │  ║
║  │         → Tarefas de documentação primeiro (corrigir FAQ, Glossário)         │  ║
║  └──────────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                    ║
║  ┌──────────────────────────────────────────────────────────────────────────────┐  ║
║  │ PERFIL: INTELIGÊNCIA ARTIFICIAL (qualquer modelo que edite arquivos)         │  ║
║  ├──────────────────────────────────────────────────────────────────────────────┤  ║
║  │ ⭐ AI_RULES.md ← LEIA ESTE PRIMEIRO. OBRIGATÓRIO. SEM EXCEÇÃO.              │  ║
║  │   → 000 Constitution → 001 FPOS (este, completo)                            │  ║
║  │      → 013 Project State ← Onde estamos hoje                                │  ║
║  │         → 005 Playbook → 006 Decision Tree COMPLETA                         │  ║
║  │            → 017 Architecture Atlas (se tarefa envolve arquitetura)         │  ║
║  │               → 018 Why + 019 Memory (antes de propor reversão)             │  ║
║  │                  → 015 Glossário → Código relevante                         │  ║
║  │                     → Executa APENAS o que foi solicitado (ver AI_RULES)    │  ║
║  └──────────────────────────────────────────────────────────────────────────────┘  ║
╚════════════════════════════════════════════════════════════════════════════════════╝
```

---

# PARTE 4 & 7 — CICLO DE VIDA FUNCIONALIDADE

→ **DETALHADO EM ARQUIVO SEPARADO**: [005_Development_Playbook.md](file:///f:/Eigent/fincore_platform/docs/005_Development_Playbook.md) (resumo abaixo no diagrama):

```
IDÉIA (qualquer origem: cliente, dono, dev, IA)
  ↓ (passa por 006 Decision Tree: "Existe PRD?")
DISCUSSÃO INFORMAL (máx 30 min) + documento de ideia
  ↓ (PO decide "vale a pena formalizar?")
CRIAR PRD OFICIAL (100-199 ou 125 + caso de uso CU-XXX + persona P-X)
  ↓ (review PO + Arquiteto → PO assina)
ALINHA DEPENDÊNCIA ARQUITETURAL → (006 Árvore: "muda arquitetura? Sim → ADR")
CRIAR ADR (se precisar) → Comitê Executivo aprova
  ↓ (agora podemos tocar no domínio)
DOMÍNIO: Modelar Entidade / Value Object / Aggregate Root + Testes unidade domínio
  ↓ (domínio passa 100% testes)
REPOSITÓRIO: Implementar (Drift local + Serverpod YAML + Índices + RLS)
  ↓ (teste integração repositório)
USE CASE: Transação atômica (aggregate root + outbox + eventos)
  ↓ (teste integração use case)
CONTROLLER (lado apresentação): PdvExpressController / KdsController etc
  ↓ (teste widget)
UI: Flutter (Design System + Semantics + Breakpoints)
  ↓
TESTES FINAIS: Domínio > 90%, Widget > 70%, 1 teste E2E caso de uso
  ↓
ATUALIZA DOCUMENTAÇÃO CORRESPONDENTE (se alterou fluxo → atualiza PRD-125)
  ↓
ATUALIZA CHANGELOG (unreleased)
  ↓
CODE REVIEW (2 aprovações, 1 sendo senior+) + CI verde
  ↓
MERGE → Automaticamente gera release notes
  ↓
HOMOLOGAÇÃO CLIENTE PILOTO (persona correspondente valida o CU)
  ↓
FECHA item do backlog correspondente + atualiza 013_Project_Status
```

---

# PARTE 5 & 6 — DECISION TREE + REGRAS OBRIGATÓRIAS

→ **DETALHADO EM ARQUIVO SEPARADO**: [006_Decision_Tree.md](file:///f:/Eigent/fincore_platform/docs/006_Decision_Tree.md)

---

# PARTE 8 — FLUXO DE LEITURA RÁPIDA POR PERFIL

| Pergunta que você tem | Perfil | Abra este documento |
|---|---|---|
| "Quais são as leis que ninguém pode quebrar nunca?" | Qualquer um | 000_Project_Constitution Art 3° — 14 Princípios |
| "Por onde começo hoje?" | Dev Júnior | 002_Bootstrap + Depois item 1 backlog |
| "Como a Maria inicia uma venda? E o João?" | PO / Dev / QA | PRD-125 Operational Flows → Fluxo 1 e 2 |
| "Preciso criar uma feature nova. O que faço primeiro?" | Qualquer um | 006 Decision Tree topo → Começa da raiz |
| "Qual o formato oficial de um PRD? E de um ADR?" | Dev / PO / Arquiteto | templates/prd_template.md + templates/adr_template.md |
| "Em qual estado o projeto está HOJE?" | Dono / Investidor | Último relatório auditorias/AUDITORIA_COMITE_EXECUTIVO_*.md → Seção 20 Estado Produto |
| "Não entendi essa palavra: Aggregate Root, Outbox Pattern, TenantId?" | Qualquer um | 015_Project_Glossary (busca por termo) |
| "Como organizo a pasta de um novo package?" | Dev | 004_Monorepo_Structure + 003_Engineering_Guide |
| "Posso começar a tela primeiro e depois fazer domínio?" | Dev | 006 Decision Tree + Regra Obrigatória #1 → NÃO |
| "Cliente tem CPF obrigatório? E Pedido tem FK Cliente obrigatória?" | Dev / QA | PRD-120 + PRD-125 CU-V05 + Decision Tree seção 3 |

---

# PARTE 9 — ÁRVORE DEPENDÊNCIAS DOCUMENTAL COMPLETA

```
000 CONSTITUTION (LEVEL 0)
└── 001 FPOS (LEVEL 1) — DEPENDE DE 000
    ├── LAYER BOOTSTRAP (002-004)
    │   ├── 002_Bootstrap ── depende: 000, 001
    │   ├── 003_Engineering_Guide ── depende: 000, 001, 004
    │   └── 004_Monorepo_Structure ── depende: 000, 001
    ├── LAYER GOVERNANÇA (005-009)
    │   ├── 005_Development_Playbook ── depende: 000, 001, 091_DoD
    │   ├── 006_Decision_Tree ── depende: 000, 001, 005, 300_decisions
    │   ├── 007_Documentation_Guide ── depende: 000, 001, 095
    │   └── 008_Code_Standards ── depende: 000, 001, 003
    ├── LAYER PROCESSO (010-014)
    │   ├── 010_Git_Workflow ── depende: 005 Playbook
    │   ├── 011_Release_Process ── depende: 005, 010
    │   ├── 012_Roadmap ── depende: 101_Master_Plan, Auditoria última
    │   ├── 013_Project_Status ── depende: Auditoria última + Backlog
    │   └── 014_Architecture_Map ── depende: 100, 120-125
    ├── LAYER REFERÊNCIA (015-019)
    │   ├── 015_Glossary ── depende: todos documentos (é compilado)
    │   └── 016_FAQ ── depende: todos
    └── LAYER PRODUTO/DOMÍNIO (100-199)
        ├── 100_Core_Arch ── depende: 000, 003, 004
        ├── 101_Master_Plan (Roadmap original) ── depende: 103, 102
        ├── 120_Domain_Config ── depende: 100
        ├── 121/122/123_Pricing ── dependem: 120, 100
        ├── 124_Seed_Data ── depende: 120, 121
        └── 125_Operational_Flows ── depende: 100, 120, 121-123 (MAIS IMPORTANTE PRODUTO)
```

**Como usar esta árvore**: Se você está alterando Pricing (122) e tem dúvida, NÃO precisa ler 002_Bootstrap. Mas SEMPRE precisa ler 000 (Constitution) + 100 (Core Arch) + 120 (Domain Config).

---

# PARTE 10 — ÍNDICE MESTRE OFICIAL (Master Index)

Cada documento do projeto OBRIGATORIAMENTE possui estes 6 metadados (header oficial):

| Campo | Explicação | Exemplo |
|---|---|---|
| **Document ID** | Nome arquivo sem .md + versão | 001_Project_Operating_System_v1.0 |
| **Owner** | Cargo (não nome pessoa) que é responsável atualizar | Comitê Executivo |
| **Obrigatoriedade** | 🔴 MANDATÓRIO, 🟡 CONTEXTUAL, 🟢 OPTATIVO | 🔴 |
| **Quando atualizar** | Evento gatilho que exige revisão | A cada nova release major + após auditoria trimestral |
| **Dependências** | Quais documentos tem que existir e estar atualizados ANTES deste | 000 Constitution, 005, 006 |
| **Documentos Relacionados** | Leitura complementar recomendada | 125 Fluxos, Auditoria última |

Lista atualizada 2026-07-25:

| ID (curto) | Nome | Owner | Obrigatoriedade | Quando Atualizar |
|---|---|---|---|---|
| 000 | Project Constitution | Comitê Executivo | 🔴 | Nunca exceto ADR-000 |
| 001 | FPOS (este) | Comitê Executivo | 🔴 | Após cada auditoria trimestral |
| 002 | Bootstrap | Tech Lead | 🔴 | Sempre que dependências pubspec mudam |
| 003 | Engineering Guide | Tech Lead | 🔴 | Quando mudar packages/estrutura |
| 004 | Monorepo Structure | Arquiteto | 🔴 | Quando criar novo package |
| 005 | Development Playbook | Eng Manager | 🔴 | Quando mudar ciclo vida funcionalidade |
| 006 | Decision Tree + Rules | Eng Manager + PO | 🔴 | Quando adicionar nova regra obrigatória |
| 091 | Definition of Done | QA + Tech Lead | 🔴 | Apenas por ADR |
| 100 | Core Architecture | Arquiteto Chefe | 🔴 | Apenas por ADR |
| 120 | Domain Config | Arquiteto + PO | 🔴 | Quando alterar Master Data |
| 121-123 | Pricing Domains | Arquiteto | 🟡 | Quando alterar políticas preço |
| 125 | Operational Flows | PO + Comitê Executivo | 🔴 | SEMPRE que alterar qualquer fluxo PDV/KDS/Financeiro |
| 015 | Glossary | Todos atualizam (revisão QA) | 🟡 | Quando adicionar nova palavra-chave no projeto |
| 016 | FAQ | Product Owner | 🟡 | Quando pergunta repetir 3x em reuniões |
| ADRs (300+) | Arquiteto proponente | 🟡 Quando for alterar arquitetura | No momento da DECISÃO, não depois |
| Auditorias (cada 3 meses) | Comitê Executivo convoca | 🔴 | Obrigatorio gerar a cada 90 dias |

---

# PARTE 11 — PADRÕES DE EVOLUÇÃO E ANTI-OBSOLESCÊNCIA

## 11.1 Como novas features entram
Toda nova feature:
1. **Nasce no PRD-125 como novo CU-XXX** (não nasce no código, não nasce em board)
2. **Referencia persona P-X obrigatório**
3. **Backlog recebe item com tag [CU-XXX-JORNADA-Y]**
4. **Ordena backlog por prioridade linear 1→21 existente**. Não "insere no meio sem justificativa formal".

## 11.2 Como documentos antigos são arquivados
Quando um documento é substituído (ex: 108_product_reset_fase4 substituído por 012_Roadmap novo):
```
PASSO 1: Adiciona no documento antigo linha topo:
> ❌ DOCUMENTO OBSOLETO desde 2026-07-25. Substituído por: docs/012_Roadmap_&_Milestones.md. Arquivado referência histórica.

PASSO 2: Move para pasta docs/Archive/ com nome:
        Archive/20260725_108_product_reset_fase4_OBSOLETE.md

PASSO 3: Atualiza FPOS (este arquivo) Parte 10 Master Index → linha marcada [OBSOLETO] + link para substituto.
```

> **REGRA § 11.3**: NUNCA apaga documento. NUNCA usa `git rm` em arquivo de `docs/`. Tudo que já existiu de decisão fica no histórico para evitar "esqueci porque tínhamos decidido isto em 2025".

## 11.3 Como evitar documentação obsoleta
**Trilha de verificação trimestral (junto com Auditoria):**
1. Para CADA documento no Master Index (Parte 10), o Owner oficial confere: "Os fatos aqui ainda são verdadeiros HOJE?"
2. Se não for verdade: ou atualiza, ou marca como obsoleto e arquiva.
3. IA de governança pode rodar este checklist automaticamente comparando PRD vs código vs auditoria.

---

# PARTE 12 — MECANISMOS ANTI-PERDA DE CONHECIMENTO

## 12.1 Protocolo "Onboarding Reverso"
Cada vez que alguém deixa o projeto (resignação, troca de cargo, fim de consultoria), ele é OBRIGADO a entregar um documento `offboarding/[DATA]_[NOME].md` de 2 páginas contendo:

- "3 coisas que eu sei hoje e que não estão documentadas em nenhum lugar" → Nós adicionamos ao Glossary/FAQ imediatamente.
- "2 decisões que eu discordei e o motivo" → Anexamos como histórico no ADR correspondente.
- "1 sugestão que eu daria ao próximo que assume meu cargo" → Vira FAQ.

## 12.2 Diário de Bordo Obrigatório para Arquitetura
Toda reunião com decisão de arquitetura ou produto não trivial (mais de 30 min) gera:
- 1 arquivo em `implementation/meeting_notes/YYYYMMDD_[TEMA].md`
- Com data + participantes + **3 linhas de DECISÕES TOMADAS com justificativa**
- Se a decisão for arquitetural, cria ADR anexando link da ata.

## 12.3 "Bus Factor = 1 é Crime"
Bus Factor = número mínimo de pessoas que tem que sair para parar o projeto. No FINCORE **o Bus Factor de NENHUM cargo pode ser menor que 2**. Se hoje só 1 pessoa sabe:
- Como gerar release? → Prioridade #1 backlog: "Documentar Release Process em 011 + treinar membro X".
- Como configurar impressora ESC/POS? → Prioridade #2: FAQ + passo a passo + vídeo 2 min.

---

## CRITÉRIO DE SUCESSO DESTE FPOS

O FPOS (este documento) cumpre sua missão se a seguinte afirmação for VERDADEIRA todo dia:

> **"Pego um estagiário novo de 17 anos que nunca viu Flutter, dou acesso ao repositório e 8 horas de tempo. Ao fim ele: (1) consegue rodar o projeto localmente; (2) sabe me dizer o que é o FINCORE e qual a missão; (3) sabe qual documento ler para qualquer pergunta que ele tenha; (4) NÃO precisou me mandar NENHUMA mensagem no WhatsApp para conseguir isto. Tudo veio da documentação oficial."**

Se esta afirmação for falsa → **O FPOS está incompleto. Prioridade #1 do backlog de governança é fechar a lacuna até que seja verdadeira.**

---

**Documento ID**: `FPOS-001-v1.0.0-FROZEN-20260725`
**Owner Oficial**: Comitê Executivo Permanente FINCORE
**Próxima Revisão Obrigatória**: 2026-10-25 (após próxima auditoria trimestral)
