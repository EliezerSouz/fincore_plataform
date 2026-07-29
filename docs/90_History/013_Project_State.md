---
Title: 013 Project State
Status: Archived
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# FINCORE PROJECT STATE — ESTADO ATUAL OFICIAL
## Source of Truth: Onde paramos, onde estamos hoje, o que vem PRÓXIMO

> **Document ID**: 013_Project_State
> **Version**: 1.1.0 (EXECUTION RESET — 2026-07-26)
> **Status**: ✍️ Ativo — **ATUALIZAÇÃO OBRIGATÓRIA SEMANAL toda sexta-feira 17:00 BRT**
> **Owner**: Engineering Manager + Product Owner (ambos assinam toda atualização)
> **Depende de**: 020_FINCORE_Evolution_Framework (FEF), EXECUTION_RESET_2026-07-26, auditorias/AUDITORIA_2026_07_25
> **Obrigatoriedade**: 🔴 MANDATÓRIO — PRIMEIRO documento que TODO mundo abre depois de 000/001/005/006. **Se você abrir o projeto e não ler este primeiro, está fazendo errado.**
> **Última atualização**: 2026-07-26 00:39 BRT
> **ATENÇÃO**: Estratégia de execução resetada em 2026-07-26. Ver MEM-008 em 019_Project_Memory.md.

---

## 🎯 OBJETIVO DESTE DOCUMENTO

> **Daqui a 2 anos, um novo desenvolvedor entra no projeto.** Ele abre o repositório. A primeira pergunta que ele tem não é "O que é Clean Architecture?". Não é "Como rodar o app?". A primeira pergunta dele é:
>
> **"Onde exatamente o pessoal parou? O que já está pronto hoje? O que está meio pronto? Qual é a PRÓXIMA tarefa que eu devo pegar? Existe algum bloqueador?"**
>
> Este documento existe para responder TUDO isso em 1 página, SEM precisar ler 30 documentos, SEM precisar verificar último commit, SEM precisar procurar alguém para perguntar.
>
> **A verdade sobre o estado do projeto mora aqui. Não mora no último commit. Não mora na cabeça de ninguém. Mora AQUI.**

---

# 🟢 1. RESUMO GERAL — EM 10 SEGUNDOS

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│  VERSAO ATUAL DO PRODUTO: 0.4.0 (LC-1: Jornada Zero / Onboarding SaaS)       │
│                                                                              │
│  PROXIMA VERSAO: 0.5.0 — LC-2: Cadastro de Clientes e Produtos (Dados Reais) │
│                                                                              │
│  ESTRATÉGIA: Customer Lifecycle + Capabilities (ver 020_FEF.md)             │
│                                                                              │
│  MAIOR PRIORIDADE HOJE (2026-07-26):                                         │
│     ★ LC-2 SETUP: Iniciar as tarefas do novo ciclo LC-2 (Clientes/Produtos)   │
│     ★ META: Mapear novas tabelas e UseCases no DatabaseInitializer           │
│                                                                              │
│  BLOQUEIOS: Nenhum bloqueador ativo                                          │
│  RISCOS CRÍTICOS: 2 (Pedido não existe · PDV sem persistência)               │
│  PROXIMA ATUALIZACAO: 2026-08-01 (sexta-feira 17:00 BRT)                    │
└──────────────────────────────────────────────────────────────────────────────┘
```

> 📌 **NOVO ROADMAP**: O projeto foi reorganizado por Customer Lifecycle.
> O ciclo LC-1 (Jornada Zero) está 100% concluído e homologado.
> Entramos no ciclo LC-2 (Capabilities: Clientes e Produtos com persistência Drift).
> Leia `020_FINCORE_Evolution_Framework.md` para entender o novo método.

---

# 🏛️ 2. ESTADO DA ARQUITETURA (Fundação)

| Fundação | Estado % | Status | Observação |
|---|---|---|---|
| Arquitetura Geral (Clean Arch + DDD + Ports) | **92%** | ✅ Concluída | fincore_core está robusto |
| Multi-Tenant Nativo + tenantId automático | **95%** | ✅ Concluído | BaseRepository implementado |
| Offline-First + Outbox + SyncEngine Linear | **80%** | 🟡 Parcial | Sync OK. Falta teste E2E longa duração |
| Drift SQLite Local (14 tabelas) | **70%** | 🟡 Parcial | Master Data OK. Falta tabelas transacionais |
| Serverpod Backend + models YAML | **25%** | 🟡 Iniciado | 1 endpoint (Greeting). Falta 3: Cliente/Produto/Pedido |
| Postgres + RLS Policies | **10%** | 🔴 Falta | Criado servidor. RLS não aplicado. Índices faltando. |
| Design System Foundation | **88%** | ✅ Concluído | Tokens, Buttons, Cards, Toast, Undo 4s. Falta Semantics. |
| Pricing Engine 7 Políticas | **99%** | ✅ FROZEN | 95.65% testes. Nenhuma alteração permitida sem ADR. |

**Arquitetura Score Geral**: **82 / 100** (FROZEN. Nenhuma alteração permitida sem ADR).

---

# 🧩 3. ESTADO DOS MÓDULOS FUNCIONAIS (Por Persona / Jornada)

| Módulo / Jornada | Estado | % Completo | Jornada Persona | Observação |
|---|---|---|---|---|
| **Master Data / Cadastros** | ✅ UI Placeholder + Domínio FROZEN | **60%** | JORNADA-A Luiza | Falta **conectar telas CRUD ao repositório real** (Prioridades 1-4 backlog) |
| ├─ Cliente + Endereço | 🟡 Entity + tabela OK. UI fake. | 50% | P4 Luiza | Item #1 backlog |
| ├─ Produto + Categoria | 🟡 Entity + tabela OK. UI fake. | 55% | P4 Luiza | Item #3 backlog |
| ├─ Preço + Tabelas N:N | 🟡 Engine 99% UI não conectada | 65% | P4 Luiza | Item #4 backlog |
| ├─ Forma Pagamento / LocalEntrega | ✅ Domínio congelado | 75% | P1 Maria | Serão usados em Jornada-B |
| **PDV / Venda (Fluxo 8 passos)** | 🟡 UI IMPELÁVEL. Sem persistência real. | **35%** | JORNADA-B Maria | Wizard 3 passos hoje → precisa refatorar p/ 5 passos: Step 0 CLIENTE OBRIG + 0.5 LOCAL |
| ├─ Abrir Caixa | 🔴 NÃO EXISTE | 0% | P1 Maria | Prioridade 14 backlog |
| ├─ Selecionar Cliente Wizard Step 0 | 🔴 NÃO EXISTE hoje no UI | 0% | P1 Maria | Prioridade 9 backlog. FK OBRIGATÓRIA NOT NULL. |
| ├─ Montar pedido Catálogo | ✅ UI impecável Undo 4s | 90% | P1 Maria | Só precisa integrar repositório real |
| ├─ Pagamento Dinheiro + troco | 🟡 Parcial UI | 60% | P1 Maria | Prioridade 13 backlog |
| ├─ Transação Atômica 7 passos + Confirmação | 🔴 NÃO EXISTE código | 0% | P1 Maria | Prioridade 12 backlog |
| ├─ Impressão ESC/POS USB | 🔴 NÃO EXISTE código | 0% | P1 Maria | Prioridade 15 backlog |
| **Produção / KDS 3 Colunas** | ✅ UI IMPELÁVEL. Controller com Mock List. | **50%** | JORNADA-C João | Falta conectar a Repository real (retira mock Orders). Timer periódico já existe. |
| ├─ Colunas Pendente/Preparo/Pronto | ✅ UI pronta | 95% | P2 João | Perfeito |
| ├─ Timer 1s periódico | ✅ Implementado | 100% | P2 João | |
| ├─ Atraso Glow perigo 3px vermelho | 🟡 Mock hardcoded | 40% | P2 João | Prioridade 19 backlog |
| ├─ KdsController ← OrdensPreparoRepository (real, não mock) | 🔴 NÃO EXISTE | 0% | P2 João | Prioridade 18 backlog |
| **Financeiro / Fluxo Caixa / Fechamento** | 🔴 NÃO EXISTE NADA | **0%** | JORNADA-D Luiza | **BLOQUEADO ATÉ JORNADA-C FECHAR 100%**. Não iniciar. |
| **Estoque Tripartite (Físico/Reservado/Disponível)** | 🔴 Domínio não iniciado | **0%** | N/D | Dependente de Evento PedidoConfirmado. Espera Jornada-B. |
| **Analytics / Dashboard M8** | 🔴 NÃO EXISTE NADA | **0%** | P4 Luiza | Sem dados rolando não faz sentido. Último módulo. |
| **Expedição / Entregador Carlos (P3)** | 🔴 NÃO EXISTE NADA | **0%** | P3 Carlos | Espera Jornadas A/B/C concluir. |

---

# 🗺️ 4. ROADMAP STATUS — CICLOS 1/2/3

| Ciclo | Nome Jornada | Persona | Dias totais | Início Previsto | Conclusão Prevista | % Concluído hoje |
|---|---|---|---|---|---|---|
| **EXECUTION RESET** (1 dia) | Governança Framework + colar backlog parede | Time todo | 1 | 2026-07-25 | 2026-07-25 | **100%** |
| **LC-1: JORNADA ZERO** | Onboarding SaaS (Visitor → Active) | Time todo | 1 | 2026-07-26 | 2026-07-26 | **100%** |
| **CICLO-01 (LC-2)** | JORNADA-A Dados Reais Prontos | P4 Luiza | 7 | 2026-07-27 | 2026-08-03 | **0%** |
| **CICLO-02** | JORNADA-B Vende de Verdade | P1 Maria | 10 | 2026-08-04 | 2026-08-15 | **0%** |
| **CICLO-03** | JORNADA-C Produz Automaticamente | P2 João | 5 | 2026-08-16 | 2026-08-20 | **0%** |

> **Regra de ouro**: Nenhum ciclo seguinte começa 1 dia antes do ciclo anterior não ter sido **100% HOMOLOGADO pela persona correspondente**. Se Jornada-A atrasar 2 dias, Jornada-B e Jornada-C simplesmente deslocam 2 dias pra frente. NÃO TEM atalho.

---

# ⚡ 5. PRÓXIMA TAREFA (AGORA MESMO — 2026-07-25)

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│  🏆 PRÓXIMA TAREFA: BACKLOG ITEM #1 (MAIOR PRIORIDADE, NÃO PULA)           │
│                                                                             │
│  Título: [CU-V05-JORNADA-A] Cadastrar Cliente Completo (CRUD real)         │
│  Caso Uso: PRD-125 → CU-V05                                                │
│  Persona: P4 Luiza Gestora / Dono                                          │
│  Estimativa: 1 dia útil                                                     │
│  Responsável: ____ (aguardando alocação)                                    │
│  Jornada: CICLO-01 DIA-1                                                    │
│                                                                             │
│  CRITÉRIO DE ACEITAÇÃO PARA FECHAR ESTA TAREFA:                             │
│   ✅ 1. Luiza abre o app e loga com PIN                                     │
│   ✅ 2. Clica em ClientesPage → Lista mostra "Nenhum cliente" + botão +     │
│   ✅ 3. Clica botão "+ Novo Cliente" → modal de cadastro abre               │
│   ✅ 4. Preenche 10 clientes reais + CPF + 2 endereços cada                 │
│   ✅ 5. Clica em Editar → altera nome de 1 cliente → atualiza na lista      │
│   ✅ 6. Clica em Excluir logicamente → some da lista mas continua no banco  │
│   ✅ 7. FECHA TODO APP, REINICIA 3 VEZES. Os 10 clientes CONTINUAM lá.      │
│   ✅ 8. Nenhum desenvolvedor interviu pra preencher manual.                 │
│                                                                             │
│  ARQUIVOS AFETADOS prováveis (não é regra, é referência):                   │
│   • packages/fincore_app/lib/features/clients/*.dart (ClientesPage+Ctrl)    │
│   • packages/fincore_core/lib/domain/masterdata/entities/cliente.dart       │
│   • packages/fincore_core/lib/infrastructure/repositories/                 │
│   • packages/fincore_core/lib/usecases/masterdata/crud_cliente_usecase.dart │
│   • Testes: test/domain + test/integration (3 testes widgets + 1 e2e)      │
│   • Atualizar docs/016_FAQ.md se perguntas novas apareceram                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Depois que a tarefa #1 fechar 100%, a próxima é o item #2.** Não escolhemos. Não decidimos. Ordem é ordem.

---

# 🔜 6. PRÓXIMAS 5 TAREFAS NA ORDEM EXATA

| # | Prioridade | Título | Persona | Ciclo |
|---|---|---|---|---|
| 1 | 🔴 MAX | [CU-V05-JORNADA-A] Cadastrar Cliente Completo (CRUD real) | P4 Luiza | CICLO-01 Dia 1 |
| 2 | 🔴 MAX | [CU-V06-JORNADA-A] Editar Cliente + Excluir Lógico | P4 Luiza | CICLO-01 Dia 1 |
| 3 | 🔴 HIGH | [CU-V07-JORNADA-A] Localizar Cliente (Busca Nome/Telefone/CPF) | P4 Luiza + P1 Maria | CICLO-01 Dia 2 |
| 4 | 🔴 HIGH | [CU-P01-JORNADA-A] ProdutosPage + CategoriasPage CRUD real | P4 Luiza | CICLO-01 Dia 2 |
| 5 | 🔴 HIGH | [CU-P02-JORNADA-A] PrecosPage + Associação N:N Produto↔Tabela | P4 Luiza | CICLO-01 Dia 3 |

---

# 🚫 7. BLOQUEADORES ATIVOS (Impeidem o progresso hoje?)

| ID | Descrição do Bloqueador | Severidade | Data desde | Prazo desbloqueio | Responsável |
|---|---|---|---|---|---|
| B-01 | ❌ NENHUM BLOQUEADOR DE IMPEDIMENTO HOJE | — | — | — | — |

> **Observação**: Não confundir "bloqueador" com "tem coisa para fazer". O backlog de 21 itens existe. É prioridade e trabalho. Não é bloqueio. Bloqueio = "não consigo avançar porque dependo de algo/alguém externo".

---

# ⚠️ 8. RISCOS CRÍTICOS ATIVOS (Podem atrasar mais de 5 dias?)

| ID | Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|---|
| R-01 | **Pedido criado SEM FK Cliente NOT NULL** (violação A-01 Decision Tree) | 60% | CATASTRÓFICO (dívida impagável) | Revisores de PR devem **PRIMEIRO checar a migration YAML/Drift clienteId NOT NULL antes de qualquer outra coisa**. |
| R-02 | **Time voltar a organizar backlog por módulos ("vamos fazer Estoque primeiro")** | 40% | ALTO (Retrabalho 2+ semanas) | Todo PR de backlog novo é **automaticamente rejeitado** se não começar com `[CU-XXX-JORNADA-X]`. Ver Decision Tree C-02. |
| R-03 | Impressora ESC/POS de cliente piloto não for compatível com modelo do código | 15% | MÉDIO (2-3 dias atraso) | No item 15 backlog, testar em cliente piloto logo no Dia 7. Criar fallback %TEMP% .bin (já previsto no PRD). |

---

# 🧪 9. ÚLTIMOS 3 RESULTADOS DE TESTES / HOMOLOGAÇÃO

| Data | Teste executado por | Resultado | Nº bugs encontrados |
|---|---|---|---|
| 2026-07-25 | Comitê Executivo → Auditoria completa | Aprovado com ressalvas (6.5 maturidade geral) | 7 blocos de problemas, já convertidos em backlog de 21 itens |
| 2026-07-20 | Tech Lead → Teste UI PDV com dados mock | Aprovado UI/UX | 0 bugs visuais, 0 bugs fluxo. Sem persistência = MVP não operacional. |
| 2026-07-15 | Teste Pricing Engine 47 testes unitários | Aprovado FROZEN | 0 regressões, 95.65% cobertura |

---

# 📋 10. CHECKLIST DE ATUALIZAÇÃO DESTE ARQUIVO (Sexta-feira 17:00)

Todo sexta-feira, **antes de sair do trabalho**, o Engineering Manager + Product Owner:

- [ ] **1. Atualiza a Seção 1 Resumo Geral com novos números de versão**
- [ ] **2. Atualiza a % completa de cada módulo na Seção 3**
- [ ] **3. Atualiza o status do Ciclo atual na Seção 4 (% concluído)**
- [ ] **4. Se a TAREFA #1 fechou → apaga a descrição antiga e coloca a tarefa NOVA #1 (ex item #2)**
- [ ] **5. Atualiza a lista "Próximas 5 tarefas" Seção 6**
- [ ] **6. Verifica bloqueadores novos (se houver) → adiciona na Seção 7**
- [ ] **7. Fecha/Atualiza riscos na Seção 8 se algo mudou**
- [ ] **8. Adiciona linha na Seção 9 com última homologação**
- [ ] **9. Atualiza o campo "Última atualização" no cabeçalho**
- [ ] **10. Ambos (EM + PO) assinam com data e nome no rodapé**

---

## ASSINATURA DA VERSÃO ATUAL 1.0.0

| Cargo | Nome | Data | Assinou? |
|---|---|---|---|
| Engineering Manager | ___________ | 2026-07-25 | ☐ Sim |
| Product Owner | ___________ | 2026-07-25 | ☐ Sim |

---

**⚠️ AVISO**: Se você abrir este arquivo e ver que a **"Última atualização"** tem mais de **14 dias** de atraso → **O backlog e o roadmap estão, por definição, DESATUALIZADOS.** Antes de escrever QUALQUER linha de código, a primeira tarefa do dia é atualizar este arquivo. Não codifique com documento de estado desatualizado = dirigir de olhos fechados.

---

Documento ID: FPOS-STATE-013-v1.0
Próxima atualização obrigatória: 2026-08-01 17:00 BRT
