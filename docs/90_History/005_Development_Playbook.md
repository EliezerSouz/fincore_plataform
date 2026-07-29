---
Title: 005 Development Playbook
Status: Archived
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# FINCORE DEVELOPMENT PLAYBOOK v1.0
## Manual Oficial do Ciclo de Vida Completo de uma Funcionalidade

> **Document ID**: 005_Development_Playbook (FPOS Layer Governança)
> **Version**: 1.0.0
> **Status**: ❄️ FROZEN
> **Owner**: Comitê de Engenharia (Engineering Manager + Tech Lead)
> **Depende de**: 000_Constitution, 001_FPOS, 091_Definition_of_Done
> **Relacionados**: 006_Decision_Tree, 125_Operational_Flows (CU-XXX)
> **Obrigatoriedade**: 🔴 MANDATÓRIO para TODO desenvolvedor. Todo código novo obedece este fluxo.

---

## OBJETIVO DESTE PLAYBOOK

> **90% dos bugs de produto e 70% da dívida técnica de um ERP não vêm de código mal escrito. Vêm da ordem ERRADA de desenvolvimento.** Alguém desenhou a tela primeiro. Alguém criou a tabela Financeiro antes do Pedido existir. Alguém implementou Dashboard sem dado real. Resultado: o "protótipo bonito" vira produto e o caos se instaura.
>
> Este Playbook existe para **garantir a ordem correta**. Não há exceções. Não há "agilizar pulando etapa". O tempo gasto lendo este documento hoje se paga 10x em menos retrabalho daqui a 3 meses.

---

# CAPÍTULO 1: COMO UMA FUNCIONALIDADE NASCE (Ordem de Criação)

## 1.1 O Ciclo Completo (18 Etapas Obrigatórias)

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 0 : IDÉIA (Ainda não é Projeto)                              │
│  Origem: Qualquer lugar: cliente piloto, dono, dev, reunião, IA, suporte.              │
│  Saída Esperada: Uma frase de 1 linha explicando "por quê".                             │
│  ERRO COMUM: Começar desenhando UI neste ponto. PROIBIDO.                              │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 1 : DISCUSSÃO (30 min máximo)                                │
│  Pessoas: PO + 1 dev senior (só 2 pessoas, não encher reunião).                        │
│  Perguntas obrigatórias da discussão:                                                  │
│   • "Para QUEM é esta feature? Qual persona? P1 Maria? P4 Luiza?"                      │
│   • "Em QUAL CASO DE USO (CU) do PRD-125 isto se encaixa? Não existe? → Criar novo."  │
│   • "Esta feature resolve um problema REAL de hoje ou algo 'bom ter'?"                 │
│  Saída: PO decide "SIM formalizar" ou "NÃO arquivar como ideia".                       │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼ (SE PO DISSER SIM → FORMALIZAR)
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 2 : CASO DE USO NO PRD-125 OBRIGATÓRIO                      │
│  Ação: Criar/Atualizar PRD-125 Fluxos Operacionais → adicionar nova linha:            │
│        ID=CU-V37, Persona=P4 Luiza, Descrição="X", Pré-condições, Pós-condições.      │
│  Nome do Caso de Uso SEMPRE começa com verbo:                                          │
│    ✅ "Cadastrar Cliente" / "Editar Produto" / "Iniciar Venda"                         │
│    ❌ "Cliente" (não é ação) / "Sistema de Preço" (é módulo não ação)                  │
│  Saída: CU-XXX oficial criado em PRD-125 com Status ✒️ Ativo.                          │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 3 : ÁRVORE DE DECISÃO (006 Decision Tree)                   │
│  Ação: Pegar documento 006 e seguir a partir do NÓ RAIZ.                               │
│  Pergunta Central da ETAPA 3: "Isto altera a arquitetura do sistema?"                  │
│  • SIM → Cria ADR obrigatório. Vai para Etapa 4.                                       │
│  • NÃO → Pula para Etapa 5 direto.                                                     │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼ (Se mudança arquitetural)
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 4 : ADR (Architecture Decision Record)                      │
│  Template: docs/templates/adr_template.md → salvar em docs/300_decisions/              │
│  Campos Obrigatórios:                                                                  │
│   • Contexto (onde estou hoje)                                                         │
│   • Decisão (o que decidimos)                                                          │
│   • 3 Alternativas consideradas + pq rejeitamos cada uma                               │
│   • Consequências POSITIVAS + Consequências NEGATIVAS                                  │
│   • Assinatura do Comitê Executivo                                                     │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 5 : BACKLOG ITEM (Board)                                     │
│  Cria item no GitHub Projects / Trello / Jira com formato OBRIGATÓRIO:                 │
│  ┌────────────────────────────────────────────────────────────────────────────┐        │
│  │ TÍTULO: [CU-V37-JORNADA-D] Nome da Funcionalidade (Verbo Infinitivo)      │        │
│  │ Persona: P-X Nome (ex: P4 Luiza Gestora)                                  │        │
│  │ Caso de Uso: PRD-125 → CU-V37                                             │        │
│  │ Prioridade: Número linear 1-21 do backlog oficial                         │        │
│  │ Critério de Aceitação: 3-5 bullet points ✅️ que definem "pronto"         │        │
│  └────────────────────────────────────────────────────────────────────────────┘        │
│  REGRA: Backlog é ordem estrita. Executamos o item 1 primeiro, depois 2, etc.         │
│  NUNCA pegamos o item 17 antes do 8 fechar por completo.                              │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼ (Agora SIM — podemos escrever código)
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 6 : DOMÍNIO (PRIMEIRO código a tocar)                       │
│  Ordem de implementação DENTRO da camada domínio:                                     │
│   1. Entidade / Value Object (ex: Cliente, EnderecoValue, PrecoFracionadoPolicy)      │
│   2. Aggregate Root (se for novo aggregate: Pedido, Caixa, ProducaoLote)              │
│   3. Domain Service (ex: PricingEngine)                                               │
│   4. Testes unitários do domínio → 95%+ cobertura OBRIGATÓRIO aqui.                   │
│  ERRO COMUM: Criar Repository ANTES de Entity. Ordem é Entity primeiro.               │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 7 : INFRAESTRUTURA / REPOSITÓRIOS                           │
│  Ordem:                                                                                │
│   1. Drift (SQLite local): criar tabela .drift com tenantId + índices + RLS policy    │
│   2. Serverpod YAML (nuvem): model + endpoint (se for transacional 3 primeiros)       │
│   3. Repository Implementation (extends BaseRepository<T>) com Outbox integrado       │
│   4. Teste integração repositório (insere → consulta → deleta logicamente)           │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 8 : USE CASE (Ação do Usuário = Transação)                  │
│  Importante: Use Case = **1 caso de uso do CU = 1 transação atômica**.                 │
│  Regra atômica NÃO NEGOCIÁVEL (Princípio SAC do DDD):                                  │
│   • 1 Use Case executa APENAS 1 operação de gravação no repositório do Aggregate Root │
│   • Alterações em 2 agregados diferentes = 2 use cases + eventos + Outbox.           │
│  Exemplo: CriarPedidoUseCase → salva Pedido + grava EventoPedido CRIADO + Outbox.     │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 9 : SUBSCRIBERS / REATORES (Event-Driven)                   │
│  Após Use Case publicar Evento (Outbox Pattern):                                      │
│   • PedidoConfirmadoEvent → Subscriber OrdemPreparoService (gera KDS ordem)          │
│   • PedidoConfirmadoEvent → Subscriber EstoqueReservaService                         │
│   • PedidoConfirmadoEvent → Subscriber LancamentoFinanceiroService                   │
│   • Todos os subscribers são FIRE-AND-FORGET + retry exponencial.                    │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 10 : CONTROLLER (Camada de Aplicação / Apresentação)       │
│  Exemplos: PdvExpressController, ClientesPageController, KdsController.              │
│  Regra Clean Architecture: Controller NÃO usa Repository DIRETO.                      │
│  Controller usa SOMENTE Use Cases através de portas interfaces.                       │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 11 : UI (Flutter Widgets & Pages)                           │
│  ⚠️ AVISO SÉRIO: ESTA É A ÚLTIMA CAMADA QUE VOCÊ CRIA, NÃO A PRIMEIRA.               │
│  Regras Obrigatórias UI:                                                               │
│   • Usa apenas Componentes do `fincore_design_system` (Buttons, Cards, Dialogs)     │
│   • Acessibilidade: Semantics + minFontSize 1.0 + contrast min 4.5:1                  │
│   • Undo Pattern em operações destrutivas (4s toast)                                  │
│   • Wizard do PDV SEMPRE começa com Step 0 Selecionar Cliente OBRIGATÓRIO.           │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 12 : TESTES FINAIS (Antes do PR)                            │
│  CheckList obrigatório de cobertura por feature nova:                                │
│  • [ ] Teste unitário do domínio > 90%                                                │
│  • [ ] Teste widget das 3 principais telas/fluxos do CU                               │
│  • [ ] Teste integração repositório + 1 transação                                    │
│  • [ ] 1 teste E2E completo (ex: abre app → cadastra cliente → seleciona → venda)    │
│  • [ ] Teste Offline: desliga internet, executa CU → liga internet → sync acontece   │
│  • [ ] Teste Reinício: após sucesso o dado continua lá após reiniciar app 3x         │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 13 : ATUALIZA DOCUMENTAÇÃO CORRESPONDENTE                  │
│  IMPORTANTE: ⚠️ Se você implementou o código mas NÃO atualizou os documentos abaixo  │
│              a feature NÃO está pronta. É considerada incompleta.                     │
│                                                                                       │
│  Verifique e atualize, se aplicável:                                                  │
│   • [ ] Se alterou fluxo de venda/KDS/financeiro → ATUALIZA PRD-125                  │
│   • [ ] Se adicionou entidade Master Data nova → ATUALIZA PRD-120 Domain Config     │
│   • [ ] Se adicionou palavra-chave → ATUALIZA 015_Project_Glossary.md                │
│   • [ ] Se é pergunta recorrente → ATUALIZA 016_Project_FAQ.md                        │
│   • [ ] Adiciona CHANGELOG Unreleased [CU-XXX] descrição curta + pessoa.            │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 14 : CODE REVIEW (2 Aprovações Mínimas)                     │
│  Validador 1 (Obrigatório): Tech Lead ou Arquitetoro → foco em arquitetura/camadas.  │
│  Validador 2 (Obrigatório): QA + Dev sênior → foco em edge cases/segurança/testes.   │
│  Nenhum PR mergeia sem CI VERDE (testes + analyze 0 warnings + lint).                │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 15 : MERGE + RELEASE AUTOMÁTICA                             │
│  Merge para `main` aciona release CI: gera versão semântica, atualiza changelog,     │
│  cria tag Git + compila binários Windows/Linux/macOS release.                         │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 16 : HOMOLOGAÇÃO NO AMBIENTE QA                             │
│  Quem valida: **A PERSONA REAL correspondente (ex: P1 Maria = atendente do piloto).**│
│  NÃO é dev que valida. NÃO é PO que valida sem cliente.                               │
│  Critério: Persona executa o Caso de Uso CU-XXX 3x consecutivas com 100% de sucesso. │
│  Se personou acha "isto estranho" → volta para Etapa 2 (revisar CU) ou 6 (revisar UI).│
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 17 : DEPLOY PRODUÇÃO CLIENTE PILOTO                        │
│  10% de rollout gradual → 1 cliente primeiro → 1 dia observação → geral.             │
└──────────────────────────────────────────┬────────────────────────────────────────────┘
                                           ▼
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                     ETAPA 18 : FECHAR CICLO (Rastreador)                              │
│   • Marca item backlog como [CONCLUÍDO - HOMOLOGADO]                                  │
│   • Atualiza 013_Project_Status.md com o novo status da jornada                      │
│   • Atualiza Relatório Trimestral Auditoria (próxima rodada)                          │
│   • 🎉 Parabéns. Ciclo encerrado. Próxima feature começa na Etapa 0 de novo.         │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 1.2 Exemplo Prático Real: "Cadastrar Cliente Completo (CU-V05)"

Para ficar 100% claro, aqui está o ciclo aplicado à Prioridade #1 do Backlog atual (2026-07-25):

| Etapa | O que foi feito? | Status em 2026-07-25 |
|---|---|---|
| 0 Ideia | "Luiza não consegue cadastrar cliente hoje. UI tem placeholder." | ✅ |
| 1 Discussão | PO + Arquiteto: "Persona P4. CU-V05 do PRD-125. Prioridade 1." | ✅ |
| 2 PRD CU | PRD-125 tem CU-V05: Cadastrar Cliente Completo | ✅ |
| 3 Árvore Decisão | "Altera arquitetura?" NÃO. Usa Master Data existente Cliente. | ✅ Pula ADR |
| 5 Backlog Item | Item [CU-V05-JORNADA-A] Cadastrar Cliente Completo / Prioridade 1 | ✅ |
| 6 Domínio | Cliente entity + EnderecoValue + CPFValidator + testes > 90% | ⏳ Fazendo agora |
| 7 Repositórios | ClientesDriftRepository + BaseRepository<Cliente> + índices | ⏳ |
| 8 Use Case | CadastrarClienteUseCase / EditarClienteUseCase / ExcluirClienteLogicoUseCase | ⏳ |
| 10 Controller | ClientesPageController com load/add/edit/delete states | ⏳ |
| 11 UI | ClientesPage com ListView + Modal Novo/Editar + Busca | ⏳ |
| 12 Testes | 3 testes widgets + E2E cadastra 10 clientes + reinicia app 3x | ⏳ |
| 13 Atualiza Docs | Atualiza Glossário "Cliente como Aggregate Master" | ⏳ |
| 14 Code Review | 2 aprovações + CI verde | ⏳ |
| 15 Merge | Merge main + release 0.4.0 | ⏳ |
| 16 Homologação | Luiza cadastra 10 clientes QA + valida | ⏳ |
| 17 Produção | Deploy piloto | ⏳ |
| 18 Fecha Ciclo | Marca prioridade 1 como concluída. Vai pra 2. | ⏳ |

---

# CAPÍTULO 2: QUANDO NÃO ESCREVER CÓDIGO (Anti-Padrões Comuns)

| Situação | Ação Correta | Erro Comum |
|---|---|---|
| "Tenho ideia legal, mas não existe nenhum CU no PRD-125" | Voltar Etapa 2 do ciclo. Criar CU + persona + aprovar PO. **Só depois tocar código.** | Implementar UI "para depois a gente ver". Isto vira dívida. |
| "UI já existe de outras versões. Só quero conectar no repositório." | Verificar se fluxo da UI corresponde à ordem ETAPA 1 do Wizard (Cliente OBRIG). Se NÃO → refatorar UI ANTES. | Conectar UI errada = propagar erro de modelagem. |
| "Quero criar Financeiro primeiro porque é 'mais fácil'" | **PROIBIDO.** Financeiro depende de Evento PedidoConfirmado (Jornada-B). Sem Pedido não há movimento. Volta para jornada anterior. | Criar modulo solto = trabalho perdido 100% |
| "Pular testes unitários domínio pq é 'simples'" | **PROIBIDO pelo Art 3, Princípio 7 da Constituição.** Se é simples, teste é mais rápido ainda. | Pular teste domínio = 90% chance de regressão. |

---

## CHECKLIST RÁPIDO DE PRONTO (Colar no PR Description)

```markdown
## Checklist Playbook 005 Obrigatório
- [ ] **Ordem correta**: Domínio (6) → Repo (7) → UC (8) → Controller (10) → UI (11). Não inverti.
- [ ] **CU Oficial**: Esta PR implementa o Caso de Uso [CU-___] do PRD-125.
- [ ] **Persona**: Implementa para [P__ Nome Persona].
- [ ] **Domínio 90%+**: Cobertura de testes na camada domain > 90%.
- [ ] **Teste E2E**: 1 teste ponta a ponta do fluxo existe.
- [ ] **Teste Reinício**: Validei que após reiniciar o app 3x, dados de [CU] continuam gravados.
- [ ] **Docs atualizados**: Se mudei fluxo → atualizei PRD-125 / Glossário / FAQ.
- [ ] **Undo Pattern**: Operações destrutivas tem Undo 4s toast.
- [ ] **Cliente FK**: Se toquei Pedido ou agregado transacional → clienteId NOT NULL sim.
```

---

**Owner Atualização**: Engineering Manager + Tech Lead
**Próxima Revisão**: 2026-10-25
**Documento ID**: `FPOS-PLAYBOOK-005-v1.0-FROZEN`
