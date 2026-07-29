---
Title: 015 Project Glossary
Status: Archived
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# FINCORE PROJECT GLOSSARY v1.0
## Glossário Oficial de Termos — Single Source of Truth

> **Document ID**: 015_Project_Glossary (FPOS Layer Referência Rápida)
> **Version**: 1.0.0
> **Status**: ✍️ Ativo — atualizado em TODO PR que adiciona termo novo
> **Owner**: QA + Tech Lead (curadoria)
> **Depende de**: Todos os outros documentos (este arquivo é uma compilação)
> **Obrigatoriedade**: 🟡 CONTEXTUAL — todo membro consulta ao não entender uma palavra. **Regra: Se uma palavra não está aqui e é usada no código ou docs, adicione-a imediatamente no mesmo PR.**

---

## Como usar este glossário

> **Encontrou um termo técnico, de negócio, de processo e não sabe o que é?**
> 1. Busque neste arquivo primeiro (Ctrl+F).
> 2. Se não encontrar aqui, busca no 016_Project_FAQ.md.
> 3. Se não encontrar lá, abre um PR ADICIONANDO o termo (não é preciso esperar review para adicionar glossário, só precisa de 1 aprovação rápida).

---

# 📚 A - Z (Ordem Alfabética)

## Aggregate Root
**Categoria**: DDD / Arquitetura
**Definição Oficial**: Entidade de mais alto nível em um domínio. É a **única porta de entrada** para qualquer alteração em objetos relacionados a ela. Uma transação em banco de dados NUNCA persiste múltiplos Aggregate Roots ao mesmo tempo — isto é feito por eventos + Outbox Pattern.
**Exemplos no FINCORE**: Pedido (Aggregate Root transacional mais importante), SessãoCaixa, LoteProdução.
**Por que importa**: Cliente é Master Data, não Aggregate transacional. Pedido é Aggregate.
**Documento Relacionado**: 100_platform_core_architecture, 125_operational_flows, 006 Decision Tree Regra A-03.

---

## ADR (Architecture Decision Record)
**Categoria**: Governança
**Definição Oficial**: Documento oficial de decisão arquitetural, seguindo template em `docs/templates/adr_template.md`, salvo em `docs/300_decisions/`. Contém contexto, decisão, 3 alternativas consideradas e consequências. APENAS ADRs são consideradas decisões oficiais. "Decisão de reunião sem ADR = não existe oficialmente".
**Número atual (2026-07-25)**: 1 ADR (301_adr_001_official_technology_stack).
**Documento Relacionado**: 006 Decision Tree Nó 1, 001 FPOS Parte 11.

---

## Bus Factor
**Categoria**: Governança / Risco
**Definição Oficial**: Número mínimo de pessoas que teriam que sair do projeto de uma vez para que o projeto pare. **No FINCORE o Bus Factor NUNCA pode ser menor que 2 para TODO cargo.** Se só 1 pessoa sabe assinar Release, treinar 2ª pessoa é prioridade #1 imediata.
**Documento Relacionado**: 001 FPOS Parte 12.3, 006 Decision Tree Regra E-01.

---

## Caso de Uso (Use Case / CU-XXX)
**Categoria**: Produto / Negócio
**Definição Oficial**: Uma AÇÃO (sempre começa com verbo) que UMA pessoa executa no sistema para resolver um problema real. Sempre associado a UMA persona P-X e UMA jornada. Padrão de ID: `CU-Vxx` (Venda), `CU-Kxx` (KDS/Produção), `CU-Fxx` (Financeiro).
**Exemplos Corretos**: CU-V05 Cadastrar Cliente Completo, CU-K02 Iniciar Preparo, CU-F07 Fechar Caixa Diário.
**Exemplos Incorretos (não são Casos de Uso, são MÓDULOS)**: ❌ "Estoque", ❌ "Financeiro", ❌ "Sistema de Preço".
**Documento Relacionado**: PRD-125 Fluxos Operacionais (Fonte oficial de todos os CUs).

---

## Clean Architecture + Ports & Adapters
**Categoria**: Arquitetura
**Definição Oficial**: Padrão de camadas do FINCORE. Domínio no centro (não conhece Flutter/Drift/Serverpod). Use Cases ao redor (orquestra domínio). Ports = interfaces abstratas. Adapters = implementações concretas (DriftRepository, ServerpodAdapter). UI na camada mais externa.
**Regra**: Dependências SEMPRE apontam para dentro (UI → Controller → UseCase → Domínio), nunca ao contrário. Domínio NÃO importa package:drift.
**Documento Relacionado**: 003_engineering_guide, 100_platform_core_architecture.

---

## DDD — Domain-Driven Design
**Categoria**: Arquitetura
**Definição Oficial**: Abordagem de modelagem de software onde o código é modelado IGUAL ao negócio real. Palavras do código são as mesmas palavras que o cliente piloto usa (Coxinha, Salgado, Cupom, Cozinheiro, Caixa). Não usamos "Order" se o usuário diz "Pedido". Não usamos "User" se o usuário diz "Cliente".
**Documento Relacionado**: 000 Constitution Art 3 Princípios, 120-123 Domínios.

---

## Drift
**Categoria**: Tecnologia / Local
**Definição Oficial**: ORM para SQLite em Dart/Flutter, usado no FINCORE como **banco de dados local OFFLINE-FIRST de primeira classe**. Toda leitura/gravação do app passa por tabelas Drift ANTES de ir para nuvem (Outbox + Sync).
**Documento Relacionado**: 100 Core Architecture.

---

## ESC/POS
**Categoria**: Hardware / Operação
**Definição Oficial**: Protocolo padrão de impressoras térmicas de cupom (impressoras de caixa usadas em todo food service). No FINCORE, a impressão é feita por UNC share do Windows com fallback para arquivo `.bin` em `%TEMP%`. É obrigatório que a impressão funcione sem internet.
**Documento Relacionado**: PRD-125 Fluxo 1 Impressão, 005 Playbook Etapa 11 UI.

---

## FPOS — FINCORE Project Operating System
**Categoria**: Governança
**Definição Oficial**: Este sistema de governança completa. Documento 001_Project_Operating_System. Funciona para o projeto como o Windows funciona para um PC: define ordem de leitura, ciclo vida feature, árvore decisão, padrões de documentação, anti-perda conhecimento. É a constituição + operação oficial do ecossistema.
**Documento Relacionado**: 000 Constitution (lei acima do FPOS), 001 FPOS (este).

---

## Frozen / Congelado
**Categoria**: Documentação / Status
**Definição Oficial**: Estado de um documento que NÃO pode ser alterado casualmente. Para alterar um documento FROZEN, é OBRIGATÓRIO criar um ADR e ter voto unânime do Comitê Executivo. Apenas documentos fundacionais são Frozen.
**Documentos Frozen hoje (2026-07-25)**: 000 Constitution, 001 FPOS, 091 Definition of Done.
**Documento Relacionado**: 000 Constitution Art 6 Penalidades.

---

## Jornada de Persona (JORNADA-A/B/C/D)
**Categoria**: Produto / Roadmap
**Definição Oficial**: Unidade de entrega do Roadmap FINCORE. Não entregamos "módulos". Entregamos **jornadas completas de uma pessoa real do começo ao fim**.
- **JORNADA-A** = Luiza Gestora (P4) → Cadastra Dados Reais → dura 7 dias.
- **JORNADA-B** = Maria Atendente (P1) → Vende de Verdade → dura 10 dias.
- **JORNADA-C** = João Cozinheiro (P2) → Produz Automaticamente → dura 5 dias.
- **JORNADA-D** = Luiza Gestora (P4) → Fechamento Diário Financeiro → pausado até C fechar.
**Documento Relacionado**: 001 FPOS, 012 Roadmap, Auditoria 2026_07_25 Seção 14 Roadmap v2.

---

## KDS — Kitchen Display System
**Categoria**: Produto / Operação
**Definição Oficial**: Sistema de visualização de pedidos na cozinha. 3 colunas: Pendente → Em Preparo → Pronto. Toda ordem recebe timer 1s periódico, atraso ativa Glow vermelho perigo. João o Cozinheiro não usa PDV, não cadastra cliente. Ele só reage a eventos de PedidoConfirmado que chegam automaticamente (<1s, sem F5).
**Documento Relacionado**: PRD-125 Fluxo 2 Produção, Auditoria 2026_07_25.

---

## Master Data
**Categoria**: Negócio / Domínio
**Definição Oficial**: Dados relativamente estáveis que servem de base para todos os processos transacionais. São "os cadastros do começo do dia". No FINCORE, 6 entidades são Master Data oficiais: Cliente, Produto, Categoria, FormaPagamento, LocalEntrega, TaxaEntrega. Luiza cadastra Master Data antes de Maria abrir caixa.
**Por que separar**: Master Data NÃO é Aggregate Root transacional. Alterações são poucas por dia. Transacionais (Pedido, Caixa) são muitas por dia.
**Documento Relacionado**: PRD-120 Configuration Domain, Auditoria 2026_07_25.

---

## Multi-Tenant Nativo
**Categoria**: Arquitetura
**Definição Oficial**: O FINCORE foi construído do zero para várias empresas (tenants) compartilharem a mesma infraestrutura SEM misturar dados. `tenantId` é a PRIMEIRA COLUNA de TODAS as tabelas. RLS (Row Level Security) no Postgres impede que tenant A veja dados tenant B mesmo que alguém erre endpoint.
**Documento Relacionado**: 000 Constitution Regra A-02, 100 Core Architecture.

---

## Offline-First Soberano
**Categoria**: Arquitetura / Princípio #1
**Definição Oficial**: Princípio mais alto do FINCORE (nº 1 dos 14 da Constituição). A operação LOCAL física do usuário é soberana e **NUNCA PARA por queda de internet**. Faturamento, impressão, preparo, baixa de estoque TUDO continua normalmente sincronizando depois em background. Se o app parou porque caiu net → existe BUG crítico.
**Como acontece**: Drift local escreve primeiro. Outbox Pattern grava operação. SyncEngine lineariza para Serverpod depois.
**Documento Relacionado**: 000 Constitution Art 3 Princípio 1, 004 Monorepo.

---

## Outbox Pattern
**Categoria**: Arquitetura / Distribuído
**Definição Oficial**: Padrão de confiabilidade transacional. Antes de retornar sucesso ao usuário, a transação do banco de dados salva DUAS coisas na mesma transação atômica: (1) O dado de negócio (Pedido novo). (2) Um registro de "mensagem para enviar" na tabela OutboxSync. Depois SyncEngine lê Outbox e publica eventos em background. Garante "nunca perde evento mesmo se cair rede".
**Documento Relacionado**: 100 Core Architecture.

---

## Persona (P1/P2/P3/P4)
**Categoria**: Produto
**Definição Oficial**: Representação de uma pessoa REAL que vai usar o FINCORE todos os dias. Todo caso de uso, todo ticket backlog, todo milestone tem UMA persona associada. Não existe funcionalidade "para o sistema" — existe funcionalidade "Para a Maria, Para o João, Para a Luiza".
| ID | Nome | Papel | Workstation |
|---|---|---|---|
| P1 | Maria Atendente/Caixa | Abrir Caixa, atender clientes, fechar venda | Windows 10" + impressora ESC/POS |
| P2 | João Cozinheiro | Produzir pedidos na cozinha | Tablet parede 10" zoom 150% |
| P3 | Carlos Entregador | Entregar pedidos delivery | Mobile |
| P4 | Luiza Gestora/Dona | Cadastro, Fechamento, Relatórios | Desktop 15" normal |
**Documento Relacionado**: PRD-125 Capítulo Personas.

---

## Pedido como Aggregate Root (Decisão Crítica #1)
**Categoria**: Domínio / Modelagem
**Definição Oficial**: Modelagem correta definida na Auditoria 2026_07_25 Pergunta 7 Decisão 1. Pedido NÃO começa com "Criar Pedido". Pedido é a **CONSEQUÊNCIA FINAL** de um fluxo de 8 passos: Abrir Caixa → Selecionar Cliente OBRIG → Selecionar Local → Montar → Resolver Preço → Pagamento → Confirmar Transação 7 passos → Impressão → Undo 4s.
**FK Obrigatórias**: Pedido SEMPRE tem `clienteId NOT NULL` e `localEntregaId NOT NULL`. Pedido sem cliente é órfão e NÃO EXISTE no FINCORE.
**Documento Relacionado**: 006 Decision Tree A-01, PRD-125 Fluxo 1, Auditoria 2026_07_25 Pergunta 7.

---

## Pricing Engine (7 Políticas)
**Categoria**: Domínio
**Definição Oficial**: Motor de precificação desacoplado do domínio transacional. Suporta 7 políticas oficiais: (1) Unitário, (2) Faixa, (3) Fracionado, (4) Peso, (5) Cento, (6) Combo, (7) Promocional com vigência temporal. Cobertura de testes atual: **95.65% (FROZEN)**. Nenhuma nova política entra sem 95%+ testes.
**Documento Relacionado**: PRD-121, 122, 123 Pricing Domain.

---

## PRD — Product Requirements Document
**Categoria**: Produto / Documento Oficial
**Definição Oficial**: Documento FROZEN ou Ativo que define O QUE o produto faz (não COMO). Faixa numérica 100-199. Exemplos: PRD-125 Fluxos Operacionais (documento de produto MAIS IMPORTANTE), PRD-120 Domain Config, PRD-121 Pricing. PRD nunca detalha tecnologia. Só detalha comportamento, personas, fluxos, casos de uso.
**Documento Relacionado**: templates/prd_template.md.

---

## RLS — Row Level Security (Postgres)
**Categoria**: Segurança / Multi-Tenant
**Definição Oficial**: Políticas de segurança nativas do Postgres. Mesmo que um desenvolvedor erre e esqueça `where tenantId = X` no endpoint, o RLS do banco bloqueia automaticamente qualquer linha que não pertence ao tenant do usuário logado. É a ÚLTIMA LINHA de defesa contra vazamento de dados entre clientes.
**Documento Relacionado**: 000 Constitution A-02, 100 Core Architecture.

---

## Serverpod
**Categoria**: Tecnologia / Nuvem
**Definição Oficial**: Backend framework Dart/Flutter do FINCORE. Responsável por APIs, autenticação, sincronização nuvem. Complementar ao Drift local: Serverpod NÃO é a primeira fonte de verdade. A primeira fonte de verdade é o Drift local. Serverpod recebe via SyncEngine.
**Regra Dupla Porta**: Serverpod é ÚNICA porta de escrita/leitura transacional. Supabase é APENAS gerenciador Postgres + Storage. Acesso REST direto Supabase DESATIVADO por RLS.
**Documento Relacionado**: 006 Decision Tree Pergunta 7 Decisão 3.

---

## SyncEngine Linear
**Categoria**: Arquitetura / Offline
**Definição Oficial**: Componente que lê tabela OutboxSync em background e sincroniza para Serverpod. Características: (1) Linear — ordem estrita de gravação, (2) Retry exponencial (5s → 30s → 2min), (3) Idempotente (chave UUID evita duplicatas), (4) Funciona sem UI fechada.
**Documento Relacionado**: 100 Core Architecture.

---

## Ticket Obrigatório [CU-XXX-JORNADA-X]
**Categoria**: Processo / Backlog
**Definição Oficial**: Formato de nome que TODO ticket no backlog do FINCORE tem que ter. Sem isto, ticket é automaticamente rejeitado e fechado.
Formato: `[CU-V05-JORNADA-A] Cadastrar Cliente Completo`
Por que existe? Força o time a pensar em CASO DE USO + PESSOA primeiro, não em "módulo".
**Documento Relacionado**: 006 Decision Tree C-02, 001 FPOS Entrega 4/4.

---

## Undo Pattern 4s
**Categoria**: UX / Qualidade Operacional
**Definição Oficial**: Padrão UI em toda operação destrutiva (confirmar venda, cancelar ordem, excluir cliente). Após o clique, aparece um TOAST verde (sucesso) por 4 segundos com botão **DESFAZER**. Se o usuário clica Desfazer em até 4s, TODO o estado da transação volta (estorno atômico). É a proteção número 1 contra erro humano de Maria no caixa.
**Documento Relacionado**: PRD-125 Fluxo 1 Passo 13, 005 Playbook UI.

---

## Wizard PDV 5 Passos
**Categoria**: UX / Fluxo
**Definição Oficial**: Ordem CORRETA e NÃO NEGOCIÁVEL dos passos do PDV. A ordem NÃO PODE SER INVERTIDA (regra B-03 da Decision Tree):
1. **STEP 0 OBRIGATÓRIO**: Selecionar Cliente (buscar OU criar rápido modal). Não pode pular.
2. **STEP 0.5**: Selecionar Local: Balcão / Retirada / Delivery + TaxaEntrega.
3. **STEP 1 Catálogo**: Montar pedido, produtos, quantidades, observações.
4. **STEP 2 Pagamento**: Dinheiro com troco automático / PIX / Cartão.
5. **STEP 3 Confirmação**: Transação atômica 7 passos + Toast Verde + Undo 4s.
Hoje o PDV tem só 3 passos. Será refatorado para esta ordem na JORNADA-B.
**Documento Relacionado**: PRD-125, Auditoria Perg 7 Dec 1.

---

# Índice Rápido por Categoria

| Categoria | Termos |
|---|---|
| 🏛️ Arquitetura | Aggregate Root, Clean Architecture, DDD, Drift, Serverpod, Multi-Tenant, Offline-First, Outbox, RLS, SyncEngine Linear, Pricing Engine |
| 📜 Governança | ADR, Frozen, Bus Factor, FPOS, Ticket Obrigatório [CU...] |
| 🛒 Produto/Negócio | Caso de Uso CU-XXX, Jornada Persona, Master Data, Pedido Aggregate Root, Persona P1-P4, KDS, Wizard PDV 5 Passos, ESC/POS, Undo Pattern 4s |
| 📄 Documentos | PRD, Constitution (000), FPOS (001), Development Playbook (005), Decision Tree (006) |

---

> **Lembrete**: Termo novo no código ou docs → **Abra o PR e adicione aqui neste arquivo.** Não precisa de review complexo. Basta 1 aprovação. Manter Glossário atualizado é responsabilidade de TODO mundo, não só QA.

**Owner**: QA Lead + Tech Lead (curadoria)
**Última Atualização**: 2026-07-25 — Governança Framework FPOS v1.0
