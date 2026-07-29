---
Title: AI Rules
Status: Active
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# AI_RULES — REGRAS OBRIGATÓRIAS PARA INTELIGÊNCIA ARTIFICIAL
## Protocolo Oficial para Qualquer Modelo de IA que Trabalhe no FINCORE

> **Document ID**: AI_RULES
> **Version**: 1.0.0
> **Status**: ❄️ FROZEN (Alteração apenas por ADR com aprovação do CTO)
> **Owner**: CTO + Chief Architect
> **Obrigatoriedade**: 🔴 MANDATÓRIO para QUALQUER modelo de IA (Claude, Gemini, GPT, outros).
> **Localização**: Raiz do repositório — primeiro documento que qualquer agente de IA deve ler.

---

## ⚠️ POR QUE ESTE DOCUMENTO EXISTE?

O FINCORE usa modelos de IA como pair programmers ativos.
Isso é uma vantagem competitiva. Mas introduz um risco específico:

```
IA sem contexto = IA perigosa.

Uma IA "prestativa" que não conhece as regras do projeto vai:
  → criar uma nova pasta de componentes "porque parece mais organizado"
  → usar um pattern diferente "porque é mais moderno"
  → duplicar uma abstração existente "porque não encontrou a original"
  → refatorar código que estava certo "porque viu uma oportunidade"

Nenhuma dessas ações é maliciosa.
Todas destroem a consistência arquitetural do projeto.
```

Este documento existe para que qualquer IA, de qualquer fabricante, em qualquer sessão,
opere dentro dos mesmos limites que um desenvolvedor sênior do FINCORE operaria.

---

## 📋 PROTOCOLO OBRIGATÓRIO DE BOOT (Leia ANTES de qualquer ação)

### PASSO 1 — Leitura Obrigatória de Contexto

Antes de escrever UMA linha de código, leia nesta ordem EXATA:

```
┌─────────────────────────────────────────────────────────────────┐
│  SEQUÊNCIA DE LEITURA OBRIGATÓRIA                               │
│                                                                 │
│  NÍVEL 0 — FILOSOFIA                                            │
│  └── 000_Project_Constitution.md    ← Lei suprema              │
│                                                                 │
│  NÍVEL 1 — GOVERNANÇA                                           │
│  └── 001_Project_Operating_System.md ← Como tudo funciona      │
│                                                                 │
│  NÍVEL 2 — ESTADO ATUAL                                         │
│  └── 013_Project_State.md           ← Onde estamos HOJE        │
│                                                                 │
│  NÍVEL 3 — PROCESSO                                             │
│  ├── 005_Development_Playbook.md    ← Como desenvolvemos       │
│  └── 006_Decision_Tree.md           ← Como decidimos           │
│                                                                 │
│  NÍVEL 4 — CONTEXTO HISTÓRICO (se necessário)                   │
│  ├── 018_Project_Why.md             ← Por que escolhemos X     │
│  └── 019_Project_Memory.md          ← Por que pivotamos        │
│                                                                 │
│  NÍVEL 5 — ARQUITETURA VISUAL (se alterando arquitetura)        │
│  └── 017_Architecture_Atlas.md      ← Diagramas do sistema     │
│                                                                 │
│  NÍVEL 6 — CÓDIGO                                               │
│  └── Leia os arquivos relevantes    ← Só agora                 │
└─────────────────────────────────────────────────────────────────┘
```

### PASSO 2 — Identificação da Tarefa

Antes de agir, responda INTERNAMENTE:

```
1. Qual é a tarefa exata solicitada?
2. Qual é o arquivo afetado?
3. Existe padrão estabelecido para isso no projeto?
4. Onde está esse padrão no codebase?
5. A tarefa envolve alterar arquitetura? → SE SIM → parar e confirmar com humano.
```

### PASSO 3 — Execução Restrita

Execute APENAS o que foi solicitado. Nada mais.

---

## 🚫 NUNCA — LISTA COMPLETA DE PROIBIÇÕES

### PROIBIÇÃO CATEGORIA A — ARQUITETURA (Severidade: CRÍTICA)

```
NUNCA criar nova pasta de pacote sem ADR aprovado.
NUNCA mover arquivos entre pastas sem aprovação explícita.
NUNCA criar novo padrão arquitetural.
NUNCA criar nova camada não existente na arquitetura.
NUNCA alterar a estrutura de packages (fincore_core, fincore_data, etc.).
NUNCA adicionar dependência externa (pubspec.yaml) sem confirmação.
NUNCA criar arquivo em local diferente do padrão estabelecido.
```

**Por que**: Arquitetura é a coluna vertebral do projeto. Uma mudança arquitetural feita por IA
sem aprovação humana pode invalidar semanas de trabalho e criar inconsistências invisíveis.

---

### PROIBIÇÃO CATEGORIA B — PADRÕES (Severidade: ALTA)

```
NUNCA criar novo padrão de naming não existente no projeto.
NUNCA criar nova abstração se já existe uma para o mesmo propósito.
NUNCA duplicar componente, classe, use case ou repository existente.
NUNCA usar pattern diferente do estabelecido no 005_Development_Playbook.
NUNCA criar BaseClass nova sem aprovação (já existem BaseEntity, BaseRepository, etc.).
NUNCA mudar convenção de nomenclatura de arquivos.
```

**Por que**: Inconsistência de padrões é dívida técnica silenciosa.
Dois padrões para a mesma coisa = confusão garantida para o próximo desenvolvedor.

---

### PROIBIÇÃO CATEGORIA C — ESCOPO (Severidade: MÉDIA)

```
NUNCA refatorar código não relacionado à tarefa solicitada.
NUNCA "melhorar" código que não foi pedido para melhorar.
NUNCA reorganizar imports que estão corretos.
NUNCA renomear variáveis/métodos "porque fica mais claro".
NUNCA adicionar comentários onde não foram pedidos.
NUNCA remover comentários existentes.
NUNCA alterar formatação de código existente que não está na tarefa.
```

**Por que**: Mudanças de escopo aumentam o diff do PR. Dificultam code review.
Introduzem regressões em código que estava funcionando. A tarefa define os limites.

---

### PROIBIÇÃO CATEGORIA D — DECISÕES (Severidade: ALTA)

```
NUNCA tomar decisão de design sem apresentar as opções ao humano.
NUNCA assumir que uma decisão "óbvia" dispensa confirmação.
NUNCA criar solução alternativa à solicitada sem comunicar.
NUNCA ignorar um ADR existente que contraindique a ação.
NUNCA sugerir migração de tecnologia como parte de uma tarefa pequena.
```

**Por que**: Decisões de design têm consequências de longo prazo.
O contexto que parece óbvio para a IA pode ignorar restrições humanas não documentadas.

---

## ✅ SEMPRE — LISTA DE OBRIGAÇÕES

### OBRIGAÇÃO CATEGORIA 1 — SEGUIR PADRÕES EXISTENTES

```
SEMPRE identificar o padrão existente antes de criar qualquer coisa.
SEMPRE seguir o padrão existente, mesmo que pareça "menos elegante".
SEMPRE nomear arquivos seguindo a convenção do diretório onde está criando.
SEMPRE usar as abstrações existentes (BaseEntity, BaseRepository, etc.).
SEMPRE colocar código no pacote correto (domain em fincore_core, infra em fincore_data).
```

---

### OBRIGAÇÃO CATEGORIA 2 — TRANSPARÊNCIA

```
SEMPRE comunicar ANTES de agir se a tarefa parecer envolver mudança arquitetural.
SEMPRE listar os arquivos que serão afetados antes de fazer mudanças.
SEMPRE confirmar interpretação da tarefa se houver ambiguidade.
SEMPRE indicar se a tarefa solicitada contradiz um padrão estabelecido.
SEMPRE reportar quando encontrar código inconsistente com o padrão (sem corrigir sem permissão).
```

---

### OBRIGAÇÃO CATEGORIA 3 — VERIFICAÇÃO

```
SEMPRE verificar se existe teste para o código alterado.
SEMPRE manter ou adicionar testes para qualquer código criado.
SEMPRE verificar se a mudança afeta o contrato de um Port (interface de domínio).
SEMPRE verificar se tenantId está presente em toda entidade nova.
SEMPRE verificar se o Use Case criado tem entrada correspondente no Decision Tree (006).
```

---

### OBRIGAÇÃO CATEGORIA 4 — DOCUMENTAÇÃO

```
SEMPRE atualizar 013_Project_State.md se a tarefa completar uma milestone.
SEMPRE sugerir atualização de 019_Project_Memory.md se uma decisão estratégica for tomada.
SEMPRE referenciar ADR relevante ao propor mudança arquitetural.
SEMPRE manter docstrings existentes ao modificar código.
```

---

## 🎯 REGRAS ESPECÍFICAS POR TIPO DE TAREFA

### Se a tarefa é: "Criar um novo Use Case"

```
1. Leia 005_Development_Playbook.md seção Use Cases
2. Leia 006_Decision_Tree.md para verificar se existe decisão relacionada
3. Identifique o Use Case existente mais similar
4. Copie a ESTRUTURA EXATA (não o conteúdo)
5. Implemente seguindo o mesmo padrão
6. Crie teste correspondente
7. Atualize 013_Project_State.md se for parte de milestone
```

### Se a tarefa é: "Criar uma nova Entity"

```
1. Confirme que a Entity vai em fincore_core/domain/entities/
2. Confirme que herda de BaseEntity (tenantId obrigatório)
3. Confirme que tem ID do tipo EntityId (não String puro)
4. Confirme que é imutável (final fields, copyWith)
5. Crie o DAO correspondente em fincore_data SE necessário
6. Nunca coloque lógica de negócio fora da Entity
```

### Se a tarefa é: "Criar um novo Repository"

```
1. Port (interface) vai em fincore_core/domain/ports/
2. Implementação vai em fincore_data/infrastructure/repositories/
3. Confirme que herda de BaseRepository
4. Confirme que todo método injeta tenantId automaticamente
5. Confirme que a implementação usa Drift (não SQL direto)
```

### Se a tarefa é: "Adicionar campo a uma Entity existente"

```
1. Adicione na Entity (fincore_core)
2. Adicione no DAO Drift correspondente (fincore_data)
3. Crie migration Drift se necessário
4. Atualize todos os copyWith e construtores
5. Atualize os testes existentes
6. NUNCA adicionar campo sem verificar impacto no sync Outbox
```

### Se a tarefa é: "Alterar o Pricing Engine"

```
⚠️ ATENÇÃO MÁXIMA ⚠️
O Pricing Engine é o componente mais crítico do sistema.
1. Leia fincore_pricing COMPLETAMENTE antes de alterar
2. Confirme que a mudança não afeta outras das 7 políticas
3. Confirme que os testes existentes continuam passando
4. Adicione testes para o novo comportamento
5. Confirme com humano ANTES de commitar
```

### Se a tarefa é: "Alterar arquitetura"

```
⛔ PARE.
Tarefas que alteram arquitetura NÃO são executadas sem ADR aprovado.
1. Comunique ao humano que a tarefa requer ADR
2. Descreva a mudança proposta
3. Liste as alternativas
4. Aguarde aprovação formal
5. Só então execute
```

---

## 🗂️ MAPA DE RESPONSABILIDADES (Onde cada coisa mora)

```
fincore_core/
├── domain/
│   ├── entities/      → Entidades de domínio (BusinessLogic pura)
│   ├── use_cases/     → Casos de uso (orquestração)
│   ├── ports/         → Interfaces (contratos para infra)
│   ├── value_objects/ → Objetos de valor (validação)
│   └── events/        → Eventos de domínio

fincore_data/
├── infrastructure/
│   ├── repositories/  → Implementações dos Ports
│   ├── drift/         → Tabelas, DAOs, migrations
│   └── mappers/       → Conversão Entity ↔ DAO

fincore_pricing/
└── ...                → Pricing Engine ISOLADO (não misturar com outros packages)

fincore_sync/
└── ...                → Outbox Worker APENAS

products/
└── fincore_shell/     → UI Flutter (não contém lógica de negócio)
```

---

## ⚡ CHECKLIST RÁPIDO (Use antes de cada ação)

```
□ Li os documentos obrigatórios (000, 001, 005, 006, 013)?
□ Entendi o padrão existente para esta tarefa?
□ A tarefa envolve mudança arquitetural? (SE SIM → parar)
□ Identifiquei TODOS os arquivos afetados?
□ Vou criar algo que já existe? (SE SIM → usar o existente)
□ Vou mudar algo fora do escopo da tarefa? (SE SIM → não fazer)
□ Os testes serão mantidos/atualizados?
□ tenantId está em toda nova entidade?
□ O código vai para o package correto?
□ Há alguma ambiguidade que preciso confirmar com o humano?
```

---

## 📊 MATRIZ DE AUTONOMIA

| Ação | Autonomia da IA | Requer Confirmação |
|---|---|---|
| Escrever novo Use Case (padrão existente) | ✅ Pode fazer | Não |
| Criar nova Entity (padrão existente) | ✅ Pode fazer | Não |
| Adicionar campo a Entity existente | ⚠️ Cuidado | Confirmar impacto no sync |
| Criar novo package Dart | ❌ Não pode | ADR obrigatório |
| Mover arquivo de pasta | ❌ Não pode | Aprovação explícita |
| Adicionar dependência (pubspec.yaml) | ❌ Não pode | Aprovação explícita |
| Alterar Pricing Engine | ⚠️ Cuidado | Confirmar antes de commit |
| Refatorar código não solicitado | ❌ Não pode | Nunca |
| Criar novo padrão arquitetural | ❌ Não pode | ADR obrigatório |
| Renomear pasta | ❌ Não pode | ADR obrigatório |
| Alterar BaseEntity/BaseRepository | ❌ Não pode | ADR obrigatório |
| Escrever/atualizar testes | ✅ Pode fazer | Não |
| Atualizar 013_Project_State.md | ✅ Deve fazer | Após milestone |

---

> **Este documento foi criado para proteger o FINCORE de inconsistências introduzidas por IA.**
> **Qualquer IA que trabalhe neste projeto e não siga estas regras está causando dano ao projeto.**
> **A IA mais valiosa para o FINCORE não é a mais "criativa". É a mais disciplinada.**

---

> **Versão**: 1.0.0
> **Criado**: 2026-07-25
> **Última atualização**: 2026-07-25
> **Próxima revisão**: Atualizar quando houver novos padrões ou novas categorias de tarefas.
