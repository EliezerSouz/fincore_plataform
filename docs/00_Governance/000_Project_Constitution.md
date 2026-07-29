---
Title: Project Constitution
Status: Active
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# CONSTITUIÇÃO DO PROJETO FINCORE
## Project Constitution — Lei Suprema do Ecossistema

> **Document ID**: 000_Project_Constitution (FPOS-LEVEL 0)
> **Version**: 1.0.0
> **Status**: ❄️ FROZEN (Congelado — alteração permitida APENAS por ADR-000 com voto unânime do Comitê Executivo)
> **Owner**: Comitê Executivo Permanente FINCORE
> **Effective Date**: 2026-07-25
> **Supersedes**: Nenhum. Este é o documento mais alto nível de TODO o ecossistema. Nenhum outro documento, PRD, ADR, decisão ou código pode contradizer esta Constituição.

---

## 0. Por que esta Constituição Existe?

> **Todo projeto de software que dura mais de 2 anos começa a morrer de perda de conhecimento tácito.** Pessoas saem. Memória falha. Novos desenvolvedores reinventam roda. IAs inferem intenções erradas a partir de código antigo. O resultado final é dívida técnica impagável, retrabalho infinito e morte lenta do produto.

Esta Constituição existe para **tornar o FINCORE à prova de saída de pessoas**. Daqui a 5, 10 ou 20 anos:

```text
O criador original pode sair.
O primeiro time pode sair.
A consultoria pode ser trocada.
A modelagem de IA pode mudar 10 vezes.

MAS A FORMA COMO O PROJETO EVOLUI CONTINUA A MESMA.
PORQUE ELA NÃO DEPENDE DE NENHUMA PESSOA.
DEPENDE DESTA CONSTITUIÇÃO.
```

---

## 1. ARTIGO 1° — NATUREZA JURÍDICA DO PROJETO

### § 1.1 O que é o FINCORE oficialmente
O **FINCORE** é uma **Plataforma Operacional Multi-Tenant Offline-First** construída exclusivamente com os princípios desta Constituição. Ele não é "um app Flutter". Não é "um backend Serverpod". Não é "um banco Postgres".

O FINCORE é definido como a **SOMA TRÊS PILARES INDIVISÍVEIS**:

```text
                ┌──────────────────────────────────────┐
                │         FINCORE =                    │
                │  ┌───────────┐  ┌─────────────┐      │
                │  │ GOVERNANÇA│  │  PRODUTO    │      │
                │  │  (FPOS)   │  │  (PRDs)     │      │
                │  └─────┬─────┘  └──────┬──────┘      │
                │        └───────┬───────┘              │
                │         ┌──────▼───────┐              │
                │         │  CÓDIGO      │              │
                │         │ Fonte + Dados│              │
                │         └──────────────┘              │
                └──────────────────────────────────────┘
```

> **REGRA DE EMERGÊNCIA**: Se um dia você tiver que escolher entre "(1) manter o código bonito mas quebrar a governança" ou "(2) manter a governança perfeita mas código feio", a resposta é **(2) SEM DÚVIDA**. Código feio conserta-se em 1 semana. Governança perdida nunca mais se recupera.

---

## 2. ARTIGO 2° — FONTES OFICIAIS DA VERDADE (Single Source of Truth)

A partir de hoje, o projeto FINCORE **NÃO POSSUI CONHECIMENTO NÃO DOCUMENTADO OFICIALMENTE**.

### § 2.1 A Pirâmide da Verdade Oficial

| Nível | Onde mora a verdade | Pessoas / sistemas consultam isto para responder perguntas |
|---|---|---|
| NÍVEL 0 | **Esta Constituição (000)** | Nenhuma decisão de qualquer natureza contradiz isto. |
| NÍVEL 1 | **FPOS — Project Operating System (001)** | Como operar o projeto? Ordem de leitura? Ciclo de vida? |
| NÍVEL 2 | **ADR (300_decisions/*.md)** | Decisões de arquitetura tomadas com justificativa. |
| NÍVEL 3 | **PRD (100-199_*.md, 125_operational_flows.md)** | O que o produto faz? Quais fluxos operacionais? Quais personas? |
| NÍVEL 4 | **Engineering Guides (003, 004, 008-014, 09x)** | Como escrever código? Como testar? Qual estrutura de pasta? |
| NÍVEL 5 | **CODE (lib/** packages/) | Detalhe da implementação. Último lugar onde procurar verdade. |

> **REGRA ABSOLUTA § 2.2**: Nenhuma pergunta de qualquer natureza (negócio, arquitetura, tecnologia, processo, padrão) pode ser respondida apenas por "conversa anterior", "o time decidiu na reunião", "o dono falou no WhatsApp", "eu lembro que era assim". Toda resposta tem que ter um link para o documento oficial correspondente na pirâmide acima. **Se não tem link oficial, a resposta não existe oficialmente — e a decisão tem que ser formalizada primeiro.**

> **REGRA § 2.3**: O Código-fonte é **evidência de implementação**, não é fonte da verdade de negócio. Exemplo: "Cliente não tem CPF no modelo de dados" não significa que "CPF não é necessário". Para saber se CPF é necessário, consultar PRD 120 / CU-V05 do PRD-125. Depois, se o código não estiver de acordo com o PRD, **o código está errado — não o PRD**.

---

## 3. ARTIGO 3° — OS 14 PRINCÍPIOS FUNDAMENTAIS INALTERÁVEIS

Estes princípios não são sugestões. Não são "boas práticas recomendadas". São **leis fundamentais que não podem ser quebradas por nenhum documento abaixo do Nível 0**.

### Princípios de Arquitetura (1-5)
1. **Offline-First é soberano.** A operação local do usuário nunca para por queda de internet. Sincronização é assíncrona em background.
2. **Multi-Tenant nativo é obrigatório.** `tenantId` é a primeira coluna de TODAS as tabelas. Nenhuma exceção.
3. **Clean Architecture + DDD + Ports & Adapters.** Camadas não podem se misturar. Domínio não conhece Flutter/Serverpod/Drift.
4. **Aggregate Root define transação.** Nenhum repositório persiste múltiplas agregações em uma transação exceto o Use Case.
5. **Event-Driven CQRS.** Toda mudança de estado relevante publica Evento imutável. Leitor separado de escritor.

### Princípios de Negócio (6-9)
6. **Pessoa primeiro, entidade depois.** O desenvolvimento é guiado por **jornada de persona + caso de uso**, não por nome de módulo. Cliente sempre vem antes de Pedido.
7. **Document First, Code Last.** Nenhum código é escrito antes do PRD/Caso de Uso correspondente existir formalmente.
8. **Persistência Real > UI Bonita.** Melhor uma tela feia que grava e sobrevive ao reinício do app do que uma tela perfeita que perde os dados.
9. **Todo ticket SEMPRE começa com `[CU-XX-JORNADA-X]`** referenciando caso de uso + persona do PRD-125. Se não tem, ticket é automaticamente rejeitado.

### Princípios de Governança (10-14)
10. **Conhecimento sem documento oficial = Conhecimento que não existe.** Nenhuma pessoa é insubstituível por definição.
11. **Qualquer decisão que altere arquitetura = ADR obrigatório.** Se não tem ADR, não foi decidido.
12. **Backlog é prioridade linear 1→2→3… Nunca paraleliza jornada incompleta.** Próxima atividade sempre é o item 1 do backlog que não está fechado.
13. **Auditorias periódicas trimestrais.** A cada 3 meses, um relatório como o de 2026_07_25 é gerado obrigatoriamente comparando PRD vs realidade.
14. **Nunca refatore governança sem ADR + Voto Unânime.** Esta Constituição só altera por ADR-000.

---

## 4. ARTIGO 4° — ÓRGÃOS DE GOVERNANÇA PERMANENTES

O projeto é gerido por **3 comitês permanentes**. Eles não são pessoas. São **cargos com responsabilidades definidas** que podem ser ocupados por qualquer indivíduo ou IA que cumpra os requisitos.

| Comitê | Responsabilidade | Como decide |
|---|---|---|
| **🏛️ Comitê Executivo** (Proprietário Produto + Arquitetura Chefe) | Altera Constituição (Nível 0), Aprova ADRs críticos, Assina Release, Homologa Cliente Piloto | **Voto Unânime** (2 membros concordando) |
| **👷‍♂️ Comitê de Engenharia** (Tech Lead + QA + DevOps) | Padrões código, testes, CI/CD, versionamento, releases menores | **Maioria Simples** |
| **💼 Comitê de Produto** (Product Owner + Product Manager + Persona cliente piloto) | Prioriza backlog, valida PRDs, aprova caso de uso novo | **PO tem voto de minerva** após ouvir os outros |

> **§ 4.1 Anti-Bus Factor**: Qualquer comitê precisa ter pelo menos 2 membros treinados para cada cargo. Se hoje só 1 pessoa sabe assinar Release, a prioridade #1 do backlog imediato é "treinar segunda pessoa até ela assinar uma Release sozinha".

---

## 5. ARTIGO 5° — CICLO DE VIDA DO CONHECIMENTO

**Todo conhecimento relevante tem que:**
1. **Nascer documentado**: Nunca existe primeiro na cabeça de alguém.
2. **Ter dono oficial**: Campo `Owner:` em todos os documentos.
3. **Ter data de revisão**: Todo documento é revisado no mínimo a cada 90 dias.
4. **Ter dependências explícitas**: Campo `Depende de:` linkando documentos que precisam existir primeiro.
5. **Ser arquivado corretamente quando obsoleto**: Mover para `docs/Archive/` com data + justificativa. NUNCA apaga.

---

## 6. ARTIGO 6° — PENALIDADES (Violadores desta Constituição)

| Violação | Consequência Imediata |
|---|---|
| Código sem PRD/ADR correspondente | **Revert imediato.** PR não pode ser mergeado. |
| Ticket sem `[CU-XX-JORNADA-X]` + persona | **Ticket fechado automaticamente.** Reaberto só quando corrigido. |
| Decisão arquitetura sem ADR | **Decisão é inválida oficialmente.** Se já implementada, próxima prioridade #1 é documentar com ADR ou desfazer. |
| Módulo todo construído antes de jornada anterior fechar | **Todo trabalho em módulo acima é pausado.** Volta para a jornada pendente. |
| Altera documento Frozen sem ADR | **Revert do commit.** ADR-000 tem que ser criado primeiro. |

> **Observação Importante**: Penalidades aqui não são punições pessoais. São **mecanismos de proteção do projeto contra a própria natureza humana de querer "ir rápido agora para depois pagar o preço"**. Protege o presente do futuro. Protege o novo desenvolvedor do antigo. Protege o projeto da memória das pessoas.

---

## 7. DECLARAÇÃO FINAL DE VINCULAÇÃO

> **A partir desta data (2026-07-25), TODO indivíduo, consultoria, inteligência artificial ou qualquer entidade que interaja com o código-fonte, documentação, dados, infraestrutura, clientes ou produto FINCORE, reconhece e ACEITA automaticamente esta Constituição como a lei suprema do ecossistema.**
>
> **O desconhecimento desta Constituição não justifica o seu não cumprimento.** É obrigação de TODO novo membro (humano ou IA) ler e compreender o FPOS-001 e esta Constituição antes de realizar a primeira ação no projeto.

---

**Assinado digitalmente:**
* Comitê Executivo Permanente FINCORE
* Documento ID: `FPOS-CONST-000-v1.0.0-FROZEN-20260725`
* Hash SHA-256 de integridade (apenas registro formal): `13b7e3024d5a1ef...`
