---
Title: 019 Project Memory
Status: Archived
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# FINCORE PROJECT MEMORY — MEMÓRIA VIVA DO PROJETO
## Registro Histórico Oficial das Grandes Decisões Estratégicas

> **Document ID**: 019_Project_Memory
> **Version**: 1.0.0
> **Status**: ✍️ Ativo — **APPEND ONLY. Nunca apagar. Nunca sobrescrever. Apenas adicionar.**
> **Owner**: CTO + Chief Architect (ambos assinam toda entrada)
> **Depende de**: 018_Project_Why (o "porquê" estático), ADRs 300_decisions/ (evidência técnica)
> **Relacionados**: CHANGELOG.md (o que mudou), 018_Why (por que usamos X), 013_State (onde estamos)
> **Obrigatoriedade**: 🟡 CONTEXTUAL — Leia antes de propor reverter qualquer decisão histórica.

---

## 🎯 POR QUE ESTE DOCUMENTO EXISTE?

> O **CHANGELOG** registra **o que mudou** (v0.3.0 → v0.4.0, features X e Y adicionadas).
>
> O **018_Why** registra **por que usamos X** (motivação estática das escolhas de stack).
>
> O **019_Project_Memory** registra **por que aquilo mudou** — os pivôs, os abandonos, as reversões, os grandes "e se?" que o time decidiu agir.

```
CHANGELOG     → O que mudou tecnicamente entre versões
018_Why       → Por que escolhemos nossa stack original
019_Memory    → Por que pivotamos, abandonamos ou revertemos decisões ao longo do tempo
```

> **Regra de Ouro**: Este documento é o **antídoto contra o ciclo de retrabalho**.
>
> ```
> Sem memória   → alguém propõe reverter decisão A
>              → time debate por 3 semanas
>              → revertem
>              → 2 meses depois descobrem por que A foi escolhida
>              → voltam para A
>              → 5 meses desperdiçados
>
> Com memória   → alguém propõe reverter decisão A
>              → abre 019_Memory, lê a entrada de A
>              → entende o contexto original
>              → ou descarta a proposta (contexto ainda válido)
>              → ou justifica por que o contexto MUDOU
>              → decisão tomada em 1 hora com evidência
> ```

---

## 📋 COMO LER ESTE DOCUMENTO

Cada entrada segue sempre este formato:

```
DATA
Evento: [PIVOT | ABANDONO | ADOÇÃO | REVERSÃO | UPGRADE | REESTRUTURAÇÃO]
Decisão tomada
Contexto que levou a isso
Alternativas que foram consideradas
Por que esta e não outra
Impacto observado (preenchido retroativamente)
Quem decidiu
```

As entradas são **cronológicas** e **imutáveis**.
Só se adiciona. Nunca se edita o passado.

---

## 📜 SEÇÃO 1 — FUNDAÇÃO (2026 Jan–Mar)

---

### 🔵 MEM-001 | Jan 2026 | ADOÇÃO
**Evento**: Escolha da Stack Principal

**Decisão tomada**:
```
Flutter + Dart para Frontend (Desktop + Tablet)
Serverpod para Backend (Dart nativo)
Drift para ORM local (SQLite)
PostgreSQL para banco remoto
```

**Contexto que levou a isso**:
O projeto FINCORE nasceu com um problema específico: sistemas de food service em regiões com conectividade instável (interior do Brasil). A operação não pode parar se a internet cair. Precisávamos de uma stack **offline-first por design**, não offline-first como afterthought.

**Alternativas consideradas**:
| Alternativa | Por que rejeitada |
|---|---|
| React + Electron | Runtime pesado (~200MB), duas codebases (desktop + mobile), TypeScript ≠ backend |
| Firebase + Flutter | Firebase é cloud-first. Offline é limitado e não transacional. Lock-in severo. |
| Supabase + Flutter | Mesma crítica do Firebase. Offline real requer arquitetura manual complexa. |
| Next.js Web App | Não roda offline real. Depende do browser. PDV não pode depender de Chrome. |

**Por que Flutter/Dart/Serverpod**:
Um único desenvolvedor Dart escreve Frontend E Backend sem trocar de contexto. Pricing Engine roda igual local (Dart) e remoto (Serverpod/Dart). Compilação nativa x64. Sem runtime externo na máquina do cliente.

**Impacto observado**: Confirma. Pricing Engine compartilhado entre app e servidor sem duplicação de lógica.

**Quem decidiu**: Fundador + Arquiteto Principal (decisão unânime).

---

### 🔵 MEM-002 | Jan 2026 | ADOÇÃO
**Evento**: Adoção de Clean Architecture + DDD + Ports & Adapters

**Decisão tomada**:
```
fincore_core → Domain (Entities, Use Cases, Ports)
fincore_data → Infrastructure (Drift, Serverpod adapters)
Nenhuma lógica de negócio fora de fincore_core
```

**Contexto que levou a isso**:
O FINCORE foi projetado para sobreviver 10+ anos com times trocando. A única forma de garantir isso é domínio completamente isolado de infraestrutura. Um ORM que muda (Drift → outro) não pode quebrar Use Cases.

**Alternativas consideradas**:
| Alternativa | Por que rejeitada |
|---|---|
| Arquitetura em camadas simples (MVC) | Domain vaza para Controller. Troca de banco = reescrever business logic. |
| MVVM flat | Sem separação de domínio. ViewModels acumulam lógica. Testabilidade zero. |

**Por que Clean Architecture**:
Domain é 100% testável sem banco, sem UI, sem rede. Uma Use Case tem contratos formais (Ports). Trocar Drift por outro ORM = reescrever apenas fincore_data. Domínio intocado.

**Impacto observado**: Pricing Engine tem 95% de cobertura de teste por ser pure Dart Domain.

**Quem decidiu**: Arquiteto Principal.

---

### 🔵 MEM-003 | Fev 2026 | ADOÇÃO
**Evento**: Adoção de Multi-Tenant nativo com tenantId obrigatório em toda entidade

**Decisão tomada**:
```
Toda entidade de domínio herda de BaseEntity com tenantId obrigatório
BaseRepository injeta tenantId automaticamente em todo query
Nenhuma query sem WHERE tenantId = ? é permitida
```

**Contexto que levou a isso**:
O FINCORE foi concebido desde o dia 1 para ser licenciado como SaaS para múltiplos estabelecimentos food service. Adicionar Multi-Tenant depois de construído é reescrever 100% do banco. Era agora ou nunca.

**Alternativas consideradas**:
| Alternativa | Por que rejeitada |
|---|---|
| Schema separation por tenant (banco separado) | Inviável operacionalmente: 500 tenants = 500 bancos PostgreSQL |
| Sem multi-tenant (single tenant por deploy) | Impossibilita modelo SaaS. Deploy por cliente = DevOps por cliente. |

**Por que tenantId em row-level**:
Simplicidade operacional. Um único banco. Queries simples. Row-Level Security no Postgres como camada extra de proteção. Escalável até milhares de tenants sem infra adicional.

**Impacto observado**: Toda entidade criada já tem tenantId. Nenhum vazamento cross-tenant registrado até o momento.

**Quem decidiu**: Arquiteto Principal + CTO (impacto de segurança requer aprovação dupla).

---

### 🔵 MEM-004 | Mar 2026 | ADOÇÃO
**Evento**: Adoção do Padrão Outbox + Sync para replicação offline→nuvem

**Decisão tomada**:
```
Toda escrita local gera entrada na OutboxSync table
Worker background processa Outbox e replica para Serverpod
Serverpod replica para PostgreSQL remoto
Conflito de sync → LWW (Last Write Wins) com timestamp do device
```

**Contexto que levou a isso**:
O modelo Offline-First exige que pedidos criados sem internet cheguem ao servidor eventualmente, sem perda, sem duplicação, na ordem correta.

**Alternativas consideradas**:
| Alternativa | Por que rejeitada |
|---|---|
| REST síncrono direto | Bloqueia UI se sem internet. Um pedido falha = operação para. |
| Firebase Realtime Sync | Firebase cloud-first. Offline é melhor esforço, não garantido. |
| WebSocket streaming | Depende de conexão estável. O problema exato que estamos resolvendo. |

**Por que Outbox Pattern**:
Padrão industrial consolidado (usado por sistemas bancários). Garante exactly-once delivery com retry seguro. Totalmente assíncrono. UI não bloqueia.

**Impacto observado**: Em validação (Sync Worker em desenvolvimento ativo).

**Quem decidiu**: Arquiteto Principal.

---

## 📜 SEÇÃO 2 — REFINAMENTO DA ARQUITETURA (2026 Abr–Jun)

---

### 🟡 MEM-005 | Abr 2026 | REESTRUTURAÇÃO
**Evento**: Reorganização da estrutura de packages do monorepo

**Decisão tomada**:
```
Antes:  src/ com tudo misturado

Depois: packages/ com separação explícita por responsabilidade

packages/
  fincore_core/        → Domain puro (Zero dependências externas)
  fincore_data/        → Infrastructure (Drift, HTTP adapters)
  fincore_pricing/     → Pricing Engine isolado
  fincore_sync/        → Outbox + Sync Worker
  fincore_server/      → Serverpod endpoints
```

**Contexto que levou a isso**:
Com o crescimento do codebase, a ausência de boundaries explícitos entre camadas começou a gerar imports ilegais (Domain importando Infrastructure diretamente). A reestruturação em packages do Dart resolve isso com imports impossíveis por construção.

**Alternativas consideradas**:
| Alternativa | Por que rejeitada |
|---|---|
| Convenção sem packages (pastas apenas) | Nada impede import ilegal. Depende de disciplina humana. |
| Microservices separados | Overhead operacional enorme para time pequeno. |

**Por que packages Dart**:
`import 'package:fincore_core/...'` de dentro de `fincore_data` é legal. O contrário geraria erro de dependência circular imediatamente. Boundaries enforçados pelo compilador, não por convenção.

**Impacto observado**: Zero imports ilegais desde a reestruturação.

**Quem decidiu**: Arquiteto Principal.

---

### 🟡 MEM-006 | Mai 2026 | REFINAMENTO
**Evento**: Decisão de adotar o Drift como única fonte de verdade local

**Decisão tomada**:
```
Drift SQLite = Fonte Primária de Verdade (Source of Truth) local
PostgreSQL remoto = Réplica autoritativa depois de sync completo
Serverpod = Intermediário de sync, nunca de operação crítica online-required
```

**Contexto que levou a isso**:
Testes de campo mostraram que internet no establishment vai e vem. O sistema que depende de resposta do servidor para confirmar um pedido falha 5-10x por turno. Isso é inaceitável operacionalmente.

**Alternativas consideradas**:
| Alternativa | Por que rejeitada |
|---|---|
| Drift como cache apenas | Operação sempre online-dependent. Inaceitável para PDV. |
| Apenas PostgreSQL via Serverpod | Falha com internet ruim. |

**Por que Drift como Source of Truth**:
Pedido criado = escrito em Drift = confirmado para o usuário. O sync é concern separado, não bloqueante. Sistema funciona identicamente com ou sem internet.

**Impacto observado**: Confirma a decisão. Nenhum pedido perdido por falha de rede em validações.

**Quem decidiu**: CTO + Arquiteto Principal (mudança de paradigma = aprovação dupla obrigatória).

---

## 📜 SEÇÃO 3 — GOVERNANÇA E DOCUMENTAÇÃO (2026 Jul)

---

### 🟢 MEM-007 | Jul 2026 | ADOÇÃO
**Evento**: Implantação do Framework de Governança Documental FINCORE

**Decisão tomada**:
```
Criação do sistema de documentação com hierarquia formal:

000 → Constituição (Lei Suprema, FROZEN)
001 → Operating System (Governança, FROZEN)
005 → Development Playbook (Processo)
006 → Decision Tree (Regras de decisão)
013 → Project State (Estado atual — atualização semanal)
017 → Architecture Atlas (Diagramas visuais)
018 → Project Why (Motivações permanentes)
019 → Project Memory (este documento — histórico de decisões)
AI_RULES.md → Regras obrigatórias para IA
```

**Contexto que levou a isso**:
Com o projeto usando modelos de IA (Claude, Gemini, GPT) como pair programmers, ficou evidente que IAs sem contexto documental formal produzem arquitetura inconsistente. Uma IA sem restrições pode criar um novo padrão em cada sessão, quebrando a coerência do projeto.

Além disso, a saída de membros do time original levantou a questão: **"Como alguém continua o projeto sem depender de mim?"**. A resposta é: documentação que substitui a memória humana.

**Alternativas consideradas**:
| Alternativa | Por que rejeitada |
|---|---|
| Wiki no Notion/Confluence | Desconectada do código. Fica desatualizada. |
| READMEs nos packages | Fragmentado. Sem ordem de leitura. Sem governança. |
| Nenhuma documentação formal | O projeto morre quando o criador original sai. |

**Por que docs/ no repositório**:
Documentação vive junto com o código. Toda PR que muda código pode mudar doc no mesmo commit. Nenhuma ferramenta externa. Git é o source of truth de ambos.

**Impacto observado**: Em validação (implantação recente).

**Quem decidiu**: CTO + Arquiteto Principal + Engineering Manager (decisão estratégica de governança).

---

## 📜 SEÇÃO 4 — ENTRADAS FUTURAS

> As entradas abaixo são **reservadas** para registro de futuras decisões.
> Preencha conforme os eventos ocorram.

---

### ⬜ TEMPLATE PARA NOVAS ENTRADAS

```markdown
### [COR] MEM-XXX | [Mês Ano] | [PIVOT | ABANDONO | ADOÇÃO | REVERSÃO | UPGRADE | REESTRUTURAÇÃO]
**Evento**: [Título da decisão]

**Decisão tomada**:
[O que foi decidido]

**Contexto que levou a isso**:
[O que aconteceu que forçou ou motivou esta decisão]

**Alternativas consideradas**:
| Alternativa | Por que rejeitada |
|---|---|
| [Alternativa A] | [Motivo] |

**Por que [opção escolhida]**:
[Argumento central da decisão]

**Impacto observado**: [Preencher retroativamente depois de 3-6 meses]

**Quem decidiu**: [Nomes/papéis]
```

---

## 🔴 REGRAS MANDATÓRIAS DESTE DOCUMENTO

```
1. APPEND ONLY.
   Nunca editar entradas existentes.
   Nunca deletar entradas.
   Apenas adicionar novas entradas ao final da seção correspondente.

2. NEUTRALIDADE.
   Registrar o que aconteceu, não o que deveria ter acontecido.
   Sem julgamentos. Sem "eu avisei".

3. CONTEXTO COMPLETO.
   Toda entrada DEVE incluir:
   - Alternativas consideradas
   - Por que foram rejeitadas
   - Quem decidiu
   Entrada sem esses três campos é inválida.

4. IMPACTO RETROATIVO.
   O campo "Impacto observado" pode ser preenchido depois.
   Mas DEVE ser preenchido quando houver dados suficientes.

5. NENHUMA REVERSÃO SEM LEITURA.
   Antes de propor reverter qualquer decisão registrada aqui,
   quem propõe DEVE citar a entrada correspondente e explicar
   por que o contexto original não se aplica mais.
```

---

---

## 📜 SEÇÃO 4 — EVOLUTION RESET (2026 Jul)

---

### 🟢 MEM-008 | Jul 2026 | REESTRUTURAÇÃO
**Evento**: Execution Reset + Adoção do FINCORE Evolution Framework (FEF)

**Decisão tomada**:
```
1. A estratégia de execução do desenvolvimento foi oficialmente resetada.
   De: desenvolvimento por módulos técnicos (M1, M2, M3...)
   Para: desenvolvimento por Customer Lifecycle + Capabilities

2. Adotado o FINCORE Evolution Framework (FEF v2.0) como documento
   guardião permanente da evolução do produto.

3. Definido o Customer Lifecycle oficial (LC-0 a LC-6) como modelo
   de crescimento do produto SaaS.

4. Criado o Capability Map com 12 Capabilities (8 Core + 4 Supporting)
   com IDs semânticos (CAP.SALES, CAP.FINANCE, etc.).

5. A Jornada Zero (LC-1) foi definida como primeira entrega oficial:
   VISITOR → REGISTERED → COMPANY_CREATED → PENDING → ACTIVE.

6. Declaração do Comitê Executivo:
   "Arquitetura Estratégica Aprovada. Autorizado o início do
   desenvolvimento conforme o Execution Reset e o FEF.
   Fase de definição estratégica encerrada."
```

**Contexto que levou a isso**:
Auditoria de 2026-07-25 revelou que o projeto acumulou telas impecáveis sem persistência real. PDV Express simula venda em memória. KDS usa dados mock. Nenhuma persona consegue executar uma tarefa completa ponta-a-ponta. O desenvolvimento por módulos técnicos criou partes perfeitas que não se conectam em um produto utilizável.

O CTO identificou que a abordagem correta é desenvolver por jornadas completas de persona, não por módulos técnicos — alinhando-se ao Princípio 6 da Constitution que já previa: "O desenvolvimento é guiado por jornada de persona + caso de uso, não por nome de módulo."

**Alternativas consideradas**:
| Alternativa | Por que rejeitada |
|---|---|
| Continuar com módulos técnicos | Produz mais telas sem fluxo real. Não entrega valor. |
| Reescrever a arquitetura | Arquitetura já é sólida (82%). Problema é a ordem de entrega. |
| Lançar o que existe como MVP | PDV sem persistência não é MVP. É protótipo que não serve ao cliente. |
| Criar mais documentação estratégica | Risco de documentar indefinidamente sem entregar produto. |

**Por que Execution Reset + FEF**:
O FEF responde "Como o FINCORE evolui para sempre?" — não apenas "Como implementamos agora?". O Evolution Model, Capability Map e Integration Rule criam um método permanente que qualquer desenvolvedor ou IA pode seguir sem precisar reinventar o processo. A mudança de estratégia não viola nenhum dos 14 Princípios da Constitution — ela os aplica corretamente.

**Impacto observado**: Preencher após 3-6 meses de execução.

**Quem decidiu**: Comitê Executivo Internacional de Engenharia de Software + CTO (aprovação unânime — 2026-07-26).

**Documentos gerados**:
- `docs/020_FINCORE_Evolution_Framework.md` (FEF v2.0)
- `docs/EXECUTION_RESET_2026-07-26.md`

---

> **Última atualização**: 2026-07-26
> **Próxima revisão**: Adicionar entrada a cada nova decisão estratégica.
> **Mantenedor**: CTO responsável pela integridade histórica deste documento.
