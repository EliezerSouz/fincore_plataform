---
Title: 016 Project FAQ
Status: Archived
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# FINCORE PROJECT FAQ v1.0
## Perguntas Frequentes — Respostas Oficias

> **Document ID**: 016_Project_FAQ
> **Version**: 1.0.0
> **Status**: ✍️ Ativo — atualizado sempre que uma pergunta repetir 3x em reuniões
> **Owner**: Product Owner (curadoria) + QA (garantia que resposta bate com PRD)
> **Depende de**: 015 Glossary, 001 FPOS, PRD-125
> **Obrigatoriedade**: 🟡 CONTEXTUAL — Primeira fonte para perguntas comuns. **Se uma pergunta aparecer 3 vezes em 1 mês, adicionamos aqui.**

---

## Como usar este FAQ

> Antes de abrir uma reunião, antes de mandar mensagem no grupo, antes de perguntar ao Tech Lead, **verifique primeiro aqui**. 80% das perguntas que parecem "urgentes" tem resposta padrão documentada.

---

# 🏛️ SEÇÃO 1: GOVERNANÇA E ORGANIZAÇÃO

## Q1. "Qual é o documento MAIS importante do projeto? Qual eu leio PRIMEIRO?"
**Resposta OFICIAL**: **000_Project_Constitution.md**. Ele é a Lei Suprema do ecossistema. Nenhum outro documento, PRD, decisão, código pode contradizer a 000. Depois de 000 vem o 001_Project_Operating_System (FPOS).
> 000 (12 min) → 001 FPOS (18 min) → 002 Bootstrap (25 min) → 005 Playbook (15 min) → 006 Decision Tree (10 min).
> Ver 001 FPOS Parte 2 — Ordem obrigatória de leitura.

---

## Q2. "Quem decide o que é feito ou não feito? Qual a hierarquia?"
**Resposta OFICIAL**: 3 comitês oficiais definidos na 000 Constitution Art 4:
| Comitê | Como decide | O que decide |
|---|---|---|
| 🏛️ Comitê Executivo (2 membros) | **Voto Unânime** | Altera Constituição, Aprova ADRs arquitetura, Assina Release, Homologação piloto |
| 👷 Comitê Engenharia (3+) | Maioria Simples | Padrões código, lint, testes, CI/CD, versão minor |
| 💼 Comitê Produto (PO + Dono + cliente) | **PO tem voto de minerva** | Prioridade backlog, Aprova novos CUs PRD-125 |

---

## Q3. "Posso começar um ticket 'só para adiantar' que ainda não é prioridade #1?"
**Resposta OFICIAL**: **NÃO. Absolutamente proibido.** (006 Decision Tree Regra B-04)
O backlog é ordem linear estrita 1 → 2 → 3 → ... → 21. A próxima tarefa de TODO mundo é SEMPRE o item 1 que ainda está TODO. Não existe "vou fazer o item 17 primeiro que é mais fácil". Jornadas dependem umas das outras. Se você já terminou seu item da Jornada-B e ainda tem itens pendentes na Jornada-B → ajude a fechar os pendentes da Jornada-B primeiro.

---

## Q4. "Posso criar uma pasta `src/xxx` fora do padrão de packages (monorepo)?"
**Resposta OFICIAL**: **Apenas se tiver um ADR criado e aprovado explicando o porquê.** Estrutura de pasta é decisão de arquitetura. 006 Decision Tree Pergunta 1 "Muda arquitetura?" SIM → precisa de ADR.
> Estrutura oficial hoje: `packages/fincore_core/`, `packages/fincore_pricing/`, `packages/fincore_design_system/`, `packages/fincore_app/`. Qualquer adição nova → ADR primeiro. Ver 004 Monorepo Structure.

---

# 📦 SEÇÃO 2: MODELAGEM E DOMÍNIO

## Q5. "ClienteId na tabela Pedido pode ser nullable, pelo menos temporariamente?"
**Resposta OFICIAL**: **NÃO. NUNCA. SOB NENHUMA HIPÓTESE.** Nem temporariamente. Nem "por enquanto". Nem "depois a gente ajusta". (006 Decision Tree Regra A-01 — VIOLAÇÃO GRAVE)
- Motivo: Se tabela for criada com clienteId nullable, depois de 1 mês com pedidos órfãos é **MIGRAÇÃO DESTRUTIVA IMPOSSÍVEL** (não dá para saber quem é o cliente dos pedidos existentes).
- Pedido SEM Cliente é um pedido inválido no FINCORE. Pedido não existe sem dono.
- Regra de ouro do produto 2026: **Cliente primeiro. Pedido depois.**

---

## Q6. "Posso criar uma tabela nova primeiro e depois criar o Caso de Uso?"
**Resposta OFICIAL**: **NÃO. Apenas a outra ordem é permitida: CU primeiro, Depois tabela.** (006 Decision Tree Regra A-04)
> Entidades existem PARA suportar operações do negócio, não o contrário. "Tabela sem caso de uso" é tabela órfã que vai ficar sem uso e gerar confusão daqui a 1 ano.
> Ordem correta: Etapa 2 (CU no PRD-125) → Etapa 3 (Decision Tree) → Etapa 5 (Backlog Item) → Etapa 6 (Domínio/Entity).

---

## Q7. "Preciso mover estoque fisicamente. Pode criar uma tela 'Ajuste Estoque Manual' para eu usar todo dia?"
**Resposta OFICIAL**: **NÃO. Movimentação de estoque é REAÇÃO a evento de PEDIDO.** (006 Decision Tree Regra B-02)
| Evento que move estoque | Tipo Movimentação |
|---|---|
| Pedido Confirmado (Maria) | **Estoque: Reservado** ← diminui disponibilidade, mas ainda não saiu da gaveta |
| Pedido Cancelado (Estorno) | **Estoque: Liberação Reserva** ← volta |
| Pedido Entregue / Retirado | **Estoque: Baixa Física** ← agora sim saiu |
| Contagem de estoque 1x por mês (inventário) | **Ajuste Manual** ← APENAS para ocasiões especiais |
Movimentação manual TODO DIA viola o evento-driven porque descola a verdade do pedido.

---

# 🎨 SEÇÃO 3: UX E FLUXO DE VENDA

## Q8. "Posso colocar o Catálogo como primeiro step do Wizard e o Cliente no final?"
**Resposta OFICIAL**: **ABSOLUTAMENTE PROIBIDO.** Ordem do Wizard é IMUTÁVEL (006 Decision Tree B-03 + PRD-125 Fluxo 1):
```
✅ CORRETO (Ordem Oficial):
Step 0 OBRIGATÓRIO → Selecionar Cliente (buscar ou criar rápido)
Step 0.5 → Selecionar Local (Balcão / Retirada / Delivery)
Step 1 → Catálogo: montar pedido
Step 2 → Pagamento
Step 3 → Confirmar + Undo 4s

❌ ERRADO (ordem proibida):
❌ Catálogo primeiro → Cliente depois
❌ (gera o erro operacional clássico: "Maria monta todo pedido, esquece cliente → pedido órfão")
```

---

## Q9. "E se o cliente for 'anonimo' (balcão, não deu o nome)? Pedido sem cliente?"
**Resposta OFICIAL**: Existe o **CLIENTE PADRÃO "Consumidor Balcão Anônimo"** (ID fixo tenant). Ele é um CLIENTE CADASTRADO (já existe no seed do PRD-124). Maria só seleciona ele no Step 0 da mesma forma. Então clienteId sempre é NOT NULL de qualquer forma.
> Técnica: o pedido SEMPRE tem um dono, mesmo que seja o "consumidor anônimo padrão". Depois da venda fechada Luiza consegue editar depois para vincular a um cliente real.

---

## Q10. "Undo Pattern de 4s: é realmente obrigatório? Ou pode ser 2s? Ou pode não ter?"
**Resposta OFICIAL**: **4 segundos é o tempo OFICIAL e FROZEN. Não negocia.** (006 Decision Tree D-03, 005 Playbook UI)
- Por que 4s? É tempo médio de um ser humano clicar "Confirmar" → perceber erro "Ah não, coloquei 10 em vez de 1" → chegar até o mouse e clicar Desfazer.
- 2s é muito pouco. 10s é muito tempo (estoura transação KDS/Estoque). 4s foi calibrado.

---

# 💻 SEÇÃO 4: TECNOLOGIA E IMPLEMENTAÇÃO

## Q11. "Posso usar Supabase REST diretamente do cliente para alguma tela específica?"
**Resposta OFICIAL**: **NÃO. Serverpod é a ÚNICA porta de escrita e leitura transacional.** (Pergunta 7 Decisão 3 da Auditoria)
- Supabase existe APENAS como gerenciador de Postgres + Auth + Storage S3.
- Acesso REST direto do cliente ao Supabase é **BLOQUEADO por RLS (políticas Postgres)** que só aceitam request vindo do service_role do Serverpod. Se tentar, retorna acesso negado.
- Se você precisar de mais dados → Criar novo endpoint no Serverpod. Não contornar.

---

## Q12. "Qual banco de dados é a 'primeira fonte da verdade'? Serverpod Postgres ou Drift SQLite?"
**Resposta OFICIAL**: **O DRIFT LOCAL é a primeira fonte da verdade. Sempre.** (Princípio Offline-First Soberano)
Ordem de uma escrita transacional:
1. Usuário clica CONFIRMAR → 2. Começa transação DRIFT LOCAL → 3. Escreve Pedido → 4. Escreve EventoPedido → 5. Escreve OUTBOX ENTRY → 6. COMMIT local → 7. Retorna sucesso para UI → 8. Undo 4s. DEPOIS, em background: SyncEngine lê Outbox e envia para Serverpod.
Se cair a internet no passo 8, NÃO TEM PROBLEMA. O pedido já está salvo local. Vai sincronizar depois automaticamente.

---

## Q13. "Quantos endpoints Serverpod eu crio na próxima sprint? 10 de uma vez?"
**Resposta OFICIAL**: **NÃO. Criamos APENAS 3 na Jornada-B: cliente, produto, pedido.** (Planejamento Escopo Fechado Auditoria)
Outros 7 endpoints (estoque/financeiro/agenda/MRP/IA/expedição/auth) são criados APENAS nas suas respectivas milestones. Criar 10 de uma vez = "Projeto Infinito" = risco ALTO.

---

# 🚀 SEÇÃO 5: LANÇAMENTO E HOMOLOGAÇÃO

## Q14. "Posso homologar eu mesmo (desenvolvedor) a minha feature? Para economizar tempo."
**Resposta OFICIAL**: **NÃO. Homologação é FEITA PELA PERSONA REAL.** (006 Decision Tree Regra C-05)
Quem valida:
- Jornada-A (dados cadastrais): **Luiza Gestora/Dona** cadastra 10 clientes de verdade, não dev.
- Jornada-B (venda): **Maria Atendente (cliente piloto)** atende 5 clientes no caixa.
- Jornada-C (produção): **João Cozinheiro** usa tablet na parede da cozinha real.
"Funciona na minha máquina" não conta. "Funciona para a pessoa que vai usar 8h por dia" conta.

---

## Q15. "Qual é o teste de aceitação FINAL de qualquer milestone?"
**Resposta OFICIAL**: **Teste Reinício 3 Vezes.** (006 D-02, 005 Playbook Etapa 12)
```
PASSO 1: Realiza a operação (ex: Maria atende 5 clientes e João produz os 5).
PASSO 2: Fecha TODO o app. Reinicia o desktop/tablet COMPLETAMENTE.
PASSO 3: Abre app novamente.
PASSO 4: Repete PASSOS 2 e 3 por MAIS DUAS VEZES (total 3 reinícios).
PASSO 5: Validação:
         ✅ Os 5 clientes continuam lá?
         ✅ Os 5 pedidos continuam lá?
         ✅ João vê os 5 pedidos no KDS?
         ✅ Nenhum dado sumiu?
Se TUDO sim → Homologado.
Se 1 dado sumiu em 1 reinício → FEATURE NÃO ESTÁ PRONTA. Voltar etapa 6 domínio/repositório.
```

---

# ❓ Q16. Esta FAQ está incompleta? Como adicionar uma nova pergunta?
**Resposta OFICIAL**: 
1. Abra um PR adicionando sua pergunta + resposta nesta seção final (adicione a seção correta, não aqui no final).
2. No PR, coloque a data e o contexto: "Esta pergunta apareceu 3 vezes na reunião de 2026-07-22, 2026-07-24, e 2026-07-25".
3. Revisão PO + QA. Se a resposta bate com os PRDs e com a Constituição, mergeia.
> Simples. Todo mundo é responsável por manter esta FAQ atualizada.
---

**Owner**: Product Owner (curadoria + prioridade) + QA (checagem com PRDs)
**Última Atualização**: 2026-07-25 — Governança Framework FPOS v1.0
**Quando atualizar**: Quando uma pergunta repetir 3 vezes em reuniões do time em menos de 1 mês.
