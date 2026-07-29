---
Title: 006 Decision Tree
Status: Archived
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# FINCORE DECISION TREE & MANDATORY RULES v1.0
## Árvore Oficial de Decisões + Regras Obrigatórias Inquebráveis

> **Document ID**: 006_Decision_Tree (FPOS Layer Governança)
> **Version**: 1.0.0
> **Status**: ❄️ FROZEN
> **Owner**: Engineering Manager + Product Owner (ambos são curadores)
> **Depende de**: 000_Constitution, 001_FPOS, 005_Development_Playbook
> **Relacionados**: 300_decisions/ (ADRs), 125_Operational_Flows, 091_DoD
> **Obrigatoriedade**: 🔴 MANDATÓRIO para QUALQUER decisão no projeto, por menor que seja. **Não tome nenhuma decisão sem consultar esta árvore antes.**

---

## OBJETIVO DESTE DOCUMENTO

> **80% das decisões erradas em projetos de software não são de tecnologia. São de "não saber qual pergunta fazer primeiro".** O desenvolvedor quer implementar uma feature. Ele pula direto pro código. Esquece de perguntar: "isto altera arquitetura? Existe caso de uso oficial? Isto depende de outra coisa primeiro?".
>
> Esta Decision Tree existe para **perguntar por você**. Ela garante que você não pule etapa. Se chegar até o final e a resposta for "sim, pode codar", então o risco de dívida técnica é zero.

---

# PARTE 1: ÁRVORE DE DECISÃO (Comece SEMPRE pelo Nó Raiz)

```
                         ╔══════════════════════════════════════╗
                         ║                                      ║
                         ║   🌳 NÓ RAIZ - QUALQUER DECISÃO    ║
                         ║   "Eu quero fazer/algo/mudar algo"  ║
                         ║                                      ║
                         ╚══════════════════════════════════════╝
                                            │
                ┌───────────────────────────┴───────────────────────────┐
                │                                                         │
                ▼                                                         ▼
╔═══════════════════════════════════╗        ╔══════════════════════════════════════╗
║ PERGUNTA 1:                      ║        ║ PERGUNTA 1-B:                       ║
║ "Isso é uma ALTERAÇÃO DE         ║        ║ "Isso é uma NOVA FUNCIONALIDADE?"    ║
║ ARQUITETURA EXISTENTE?"          ║        ║ (módulo / feature / caso de uso)    ║
║ (Ex: Mudar agregado, adicionar   ║        ║ (Ex: Cadastrar fornecedor novo,     ║
║ tabela, mudar SyncEngine,        ║        ║ tela financeiro, nova forma de pgto)║
║ mudar de Flutter p/ React)       ║        ║                                      ║
╚═══════════════════╤═══════════════╝        ╚═══════════════════╤══════════════════╝
                    │ SIM                                            │
                    ▼                                                ▼
     ╔═══════════════════════════════════╗         ╔══════════════════════════════════╗
     ║  🔴 CRIAR ADR OBRIGATÓRIO         ║         ║ PERGUNTA 2:                      ║
     ║  (Nível 2 da Pirâmide Verdade)   ║         ║ "Existe CASO DE USO OFICIAL      ║
     ║  Template: templates/adr_template║         ║  CU-XXX no PRD-125 + PERSONA     ║
     ║  → salvar em 300_decisions/      ║         ║  P-X associado?"                 ║
     ║  → Comitê Executivo vota UNÂNIME ║         ╚═══════════════════╤══════════════════╝
     ║  → Aprovado? SIM avança. NÃO:    ║                             │
     ║  decisão CANCELADA, não codar.   ║                  ┌──────────┴───────────┐
     ╚═══════════════════╤═══════════════╝                  │ NÃO                 │ SIM
                         ▼ (depois ADR aprovado)             ▼                     ▼
          ┌─────────────────────────────────────┐   ╔══════════════════╗    ╔══════════════════════════╗
          │ Segue para PERGUNTA 2 abaixo        ║   ║ 🟡 CRIAR CU NOVO║    ║ PERGUNTA 3:               ║
          │ (mesma branch da nova func abaixo)  ║   ║ no PRD-125      ║    ║ "A JORNADA COMPLETA DA   ║
          └─────────────────────┬───────────────┘   ║ + persona P-X   ║    ║ PERSONA ANTERIOR no      ║
                                │                   ║ + PO assina     ║    ║ roadmap já está FECHADA  ║
                                │                   ╚════════╤═════════╝    ║ 100%?" (J-A antes J-B)   ║
                                │                            │              ╚══════════════╤═════════════╝
                                │                            │                            │
                                │                            │                   ┌────────┴────────┐
                                │                            ▼ (CU criado)       │ NÃO              │ SIM
                                │              ╔══════════════════════════════╗  │                  │
                                │              ║  Volta para PERGUNTA 3       ║  ▼                  ▼
                                │              │  (agora existe CU oficial)  ║  ╔════════════════╗  ╔════════════════════════╗
                                │              ╚══════════════════════════════╝  ║ 🔴 PARE TUDO     ║  ║ PERGUNTA 4:             ║
                                │                                               ║ Imediatamente!   ║  ║ "Esta feature requer   ║
                                │                                               ║ Volte para       ║  ║ ALGUMA OUTRA ENTIDADE  ║
                                │                                               ║ jornada anterior ║  ║ QUE AINDA NÃO EXISTE?" ║
                                │                                               ║ e finalize ela   ║  ║ (ex: estoque depende    ║
                                │                                               ║ primeiro.        ║  ║ de PedidoConfirmado)   ║
                                │                                               ╚════════════════════╝  ╚═══════╤════════════════════╝
                                │                                                                             │
                                │                                                              ┌──────────────┴──────────────┐
                                │                                                              │ SIM                          │ NÃO
                                │                                                              ▼                              ▼
                                │                                               ╔═════════════════════════════╗   ╔═══════════════════════════════╗
                                │                                               ║ 🔴 VERIFICA DEPENDÊNCIA:    ║   ║  PERGUNTA 5:                 ║
                                │                                               ║ Entidade que depende        ║   ║  "Esta implementação          ║
                                │                                               ║ existe PRIMEIRO?            ║   ║   vai contrariar              ║
                                │                                               ║                             ║   ║   a 000_Constitution /       ║
                                │                                               ║ NÃO → Volte 1 ciclo atrás   ║   ║   o 091_Definition_of_Done?"  ║
                                │                                               ║ e implemente a dependência  ║   ║   (ex: UI antes domínio?)     ║
                                │                                               ║ primeiro.                   ║   ╚═══════╤═══════════════════════╝
                                │                                               ╚═════════════════════════════╝           │
                                │                                                                                 ┌─────┴─────┐
                                │                                                                                 │ SIM       │ NÃO
                                │                                                                                 ▼           ▼
                                │                                                                   ╔══════════════════╗  ╔══════════════════════════════════╗
                                │                                                                   ║ 🔴 DECISÃO       ║  ║ 🟢 PODE IMPLEMENTAR              ║
                                │                                                                   ║ CONTRARIADA!     ║  ║ Siga o Ciclo de Vida do          ║
                                │                                                                   ║ Não pode codar.  ║  ║ 005_Development_Playbook,        ║
                                │                                                                   ║ Corrija antes.   ║  ║ Etapa 6 DOMÍNIO → 18 FECHAMENTO. ║
                                │                                                                   ╚════════════════════╝  ╚══════════════════════════════════╝
                                │
                                └───────┐
                                        ▼
                          ╔══════════════════════════════════════════════════╗
                          ║   RESUMO: SE CHEGUEI ATÉ AQUI, POSSO CODAR?    ║
                          ║   SIM → SE:                                      ║
                          ║   (1) Se arq mudou → ADR existe e foi APROVADO  ║
                          ║   (2) CU-XXX existe no PRD-125 + Persona P-X    ║
                          ║   (3) Jornada anterior FECHOU 100%              ║
                          ║   (4) Dependências existem PRIMEIRO              ║
                          ║   (5) Nada contraria Constituição / DoD          ║
                          ╚══════════════════════════════════════════════════╝
```

---

# PARTE 2: EXEMPLOS DE PERCURSOS CORRETOS E INCORRETOS

## Caso 1: "Quero implementar Tela Financeiro primeiro porque é mais fácil"

| Nó | Pergunta | Resposta | Ação |
|---|---|---|---|
| P1 | Isto é mudança arquitetura? | Não | → Pular |
| P2 | Existe CU no PRD-125? | Sim CU-F02 | → Segue |
| P3 | Jornada anterior (J-B Maria Atende) fechou? | NÃO. Item 21 do backlog ainda não fechou | → **🔴 PARE TUDO.** Volta para jornada B. Não faz Financeiro agora. |

✅ Percurso correto: Decisão bloqueada. Não implementa Financeiro sem Jornada-B fechar. Isto evita retrabalho.

## Caso 2: "Quero refatorar SyncEngine para usar Isolates"

| Nó | Pergunta | Resposta | Ação |
|---|---|---|---|
| P1 | Isto é mudança arquitetura? | **SIM.** SyncEngine é dependência transversal. | → **Cria ADR-002.** Descreve 3 alternativas: Sem Isolate / Single Isolate / Worker Pool. Comitê Executivo vota. |
| Pós ADR | Aprovado? | Sim | → Segue P2 em diante, implementa. |

## Caso 3: "Ideia nova: Chat de suporte interno dentro do app."

| Nó | Pergunta | Resposta | Ação |
|---|---|---|---|
| P1 | Arquitetura? | Não | → Pula |
| P2 | Existe CU no PRD-125? | **NÃO.** Chat interno não tem persona nem caso de uso. | → Cria CU-V39 + persona (P2 João atendimento?) + PO valida. **SÓ DEPOIS** volta para árvore. |

---

# PARTE 3: 21 REGRAS OBRIGATÓRIAS INQUEBRÁVEIS (Violador = Revert Imediato)

## 🟥 Seção A: Modelagem e Domínio (NUNCA quebre estas)

| ID | Regra | Motivo | Consequência de quebrar |
|---|---|---|---|
| A-01 | **ClienteId no Pedido é FK NOT NULL sempre.** | "Cliente primeiro, Pedido depois". Pedido sem cliente é órfão e quebra relatórios/CRM/precificação/entrega. | Migração destrutiva impossível + 6 meses de retrabalho |
| A-02 | **Toda tabela tem tenantId como primeira coluna + índice + RLS.** | Multi-Tenant é nativo, não feature posterior. | Data leak entre clientes = problema jurídico |
| A-03 | **Aggregate Root = 1 transação por Use Case.** | DDD Aggregate princípio transacional. | Inconsistência: Pedido salvo mas ItemPedido não salvo |
| A-04 | **NUNCA crie tabela nova sem caso de uso CU-XXX associado.** | Entidades existem para suportar operação real, não existem por si mesmas. | "Tabelas órfãs" → confusão e dívida técnica |
| A-05 | **Todo evento relevante de negócio é imutável e gravado em EventStore / CQRS style.** | Auditoria + reconstrução de estado. | "Não sei quem cancelou o pedido ontem" |

## 🟧 Seção B: Ordem de Implementação (Ordem é tudo)

| ID | Regra | Motivo |
|---|---|---|
| B-01 | **Nunca implemente UI antes do Domínio.** | UI bonita sem persistência real = protótipo que vira produto quebrado. |
| B-02 | **Nunca implemente Módulo (Estoque/Financeiro/KDS) antes da JORNADA ANTERIOR correspondente estar 100% homologada.** | Financeiro só existe com evento PedidoConfirmado. Estoque só existe com reserva de pedido. KDS só existe se Maria vender primeiro. |
| B-03 | **Ordem de implementação do Wizard PDV é IMUTÁVEL:** Step 0 Cliente OBRIG → Step 0.5 LocalEntrega → Step 1 Catálogo → Step 2 Pagamento → Step 3 Confirmação. Step 0 não pode ser pulado nem movido para fim. | Evita erro clássico operacional: "Montei todo pedido, esqueci cliente". Pedido órfão. |
| B-04 | **Backlog é executado em ORDEM ESTRITA de prioridade 1→2→3.** Não escolhemos "o que dá vontade hoje". | Jornadas são sequenciais: Luiza tem que cadastrar cliente ANTES de Maria poder selecionar cliente. Ordem importa. |
| B-05 | **Document First, Code Last.** PRD + ADR existem SEMPRE antes do primeiro arquivo .dart ser criado. | Se codamos antes de pensar, codamos errado. Tempo gasto pensando = 10x menos tempo gasto refatorando. |

## 🟩 Seção C: Governança e Processo

| ID | Regra | Motivo |
|---|---|---|
| C-01 | **Qualquer decisão arquitetural SEM ADR = Decisão Não Existe Oficialmente.** | Não aceitamos "a gente decidiu na reunião mas não tem por escrito". 2 anos depois ninguém lembra porquê. |
| C-02 | **Todo item de backlog COMEÇA com `[CU-XXX-JORNADA-X]`.** Exemplo correto: `[CU-V05-JORNADA-A] Cadastrar Cliente Completo`. Exemplo errado (rejeitado): `Implementar repositório`. | Força pensamento em caso de uso + persona. Ticket que não começa assim é automaticamente fechado. |
| C-03 | **Nenhum PR mergeia sem 2 aprovações + CI verde (testes + analyze 0 warnings + lint).** | Qualidade = responsabilidade do time, não de uma pessoa. |
| C-04 | **Nunca apague documento da pasta docs/. Arquive em Archive/ com data + justificativa.** | Histórico é conhecimento. "Apagar ADR antigo" = "esquecer porquê rejeitamos aquela ideia ruim que vamos tentar de novo daqui a 2 anos". |
| C-05 | **Nunca pule a etapa HOMOLOGAÇÃO COM A PERSONA REAL.** Não é dev que valida. Não é PO. É a PESSOA que vai usar a feature todos os dias. | "Funciona na minha máquina" ≠ "Funciona para a Maria atendendo 50 clientes por dia na cozinha quente e barulhenta". |

## 🟦 Seção D: Qualidade e Teste

| ID | Regra | Motivo |
|---|---|---|
| D-01 | **Cobertura mínima da camada DOMÍNIO = 90%.** Não negocia. | Domínio é coração do ERP. Se PricingEngine calcula errado R$ 0,01 por coxinha, no fim do mês são milhares em prejuízo. |
| D-02 | **Todo Use Case transacional tem que passar no "Teste Reinício 3x":** Após sucesso, reinicie o app 3 vezes. O dado continua lá 100%? Se não → feature incompleta. | A maior dor do usuário hoje é "pedido some ao reiniciar app". Isto NUNCA pode acontecer. |
| D-03 | **Undo Pattern 4s obrigatório em toda operação destrutiva.** (Cancelar venda, excluir cliente, concluir ordem). | Erro humano é comum em operação de caixa pressionada. Desfazível é sempre melhor do que desculpa. |
| D-04 | **Nunca use Mock em teste E2E de jornada transacional.** Crie cliente real, venda real, impressão real, KDS real. Use dados fake de seed mas caminho real. | Mock de repositório = "passou no teste mas falhou na produção". |
| D-05 | **Todo ticket tem pelo menos 1 Critério de Aceitação que valida "Pós reinício do app dado persiste".** | Obriga pensar em persistência desde o começo, não como afterthought. |

## 🟪 Seção E: Anti-Perda de Conhecimento

| ID | Regra | Motivo |
|---|---|---|
| E-01 | **Bus Factor ≥ 2 para TODO cargo crítico.** (Release, Arquitetura, PO, Homologação). Se só 1 pessoa sabe, treinar segunda é prioridade #1. | "Se essa pessoa for atropelada por ônibus amanhã, projeto morre?" → se sim, temos problema. |
| E-02 | **Reunião de decisão (arq/produto) com duração > 30 min SEMPRE gera ata em `implementation/meeting_notes/YYYYMMDD_tema.md` com 3 linhas de decisões.** | "A gente tinha decidido isto na semana passada" — não, tinha decidido NADA se não tem ata. |
| E-03 | **Offboarding obrigatório:** Qualquer um saindo do projeto entrega documento 2 páginas com "3 coisas não documentadas + 2 discordâncias + 1 sugestão pro próximo". Imediatamente adicionado em Glossary/FAQ. | Pessoas saem. Conhecimento pode ficar. |
| E-04 | **Auditoria Trimestral Obrigatória.** A cada 90 dias, geramos novo relatório `auditorias/AUDITORIA_COMITE_EXECUTIVO_YYYY_MM_DD.md` comparando PRD vs realidade + plano de correção. | "O que não é medido não é gerenciado". Este documento que você está lendo hoje já é o resultado desta regra. |
| E-05 | **Todo novo conceito/terminologia no código ou docs → atualiza Glossário 015 no mesmo PR.** | Palavra nova sem definição oficial = ambiguidade para IAs e novos devs. |

---

# PARTE 4: FLUXO RÁPIDO "ESTOU COM DÚVIDA" — PERGUNTAS E RESPOSTAS

| Situação | O que eu faço? |
|---|---|
| "Não sei se isto é mudança arquitetural ou não" | Assuma que SIM por padrão. Cria ADR curto. |
| "Quero adicionar uma tabela mas não sei qual CU-XXX usar" | Não crie tabela. Volte para PRD-125 e crie CU primeiro. |
| "A jornada B ainda não fechou e eu já terminei minha tarefa da jornada B" | Ajude alguém da jornada B a fechar os itens pendentes. NÃO comece jornada C ou D. |
| "PO pediu implementação urgente 'pra ontem' sem PRD" | Mostre ao PO esta Decision Tree (B-05 Document First). Negocie 1 hora para formalizar CU antes. |
| "Comitê Executivo não tem tempo de aprovar meu ADR hoje" | Espera. Não codar sem aprovação. |
| "Recebi PR que viola regra A-01 (Pedido sem Cliente FK)" | REJEITA imediatamente. Não precisa nem ler o resto. Explica o motivo apontando para esta regra. |
| "Não sei qual o próximo item do backlog" | Abra a lista. Pegue o item com MENOR número de prioridade que ainda está TODO. É esse. Não escolha outro. |

---

## ASSINATURA DE COMPROMISSO

> **Ao criar sua primeira PR no FINCORE, você implicitamente concorda que:**
> 1. Leu a 000 Constitution.
> 2. Leu o 001 FPOS completo.
> 3. Leu este 006 Decision Tree e seguiu a árvore para a decisão atual.
> 4. Seu código não viola nenhuma das 21 regras obrigatórias acima.
>
> **Se uma destas afirmações for falsa → seu PR pode ser revertido a qualquer momento sem aviso prévio, por qualquer membro do comitê.**

---

**Owner Atualização**: Engineering Manager + PO
**Próxima Revisão Obrigatória**: 2026-10-25
**Documento ID**: `FPOS-DECISION-006-v1.0-FROZEN`
