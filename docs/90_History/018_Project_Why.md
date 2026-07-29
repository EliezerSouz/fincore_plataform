---
Title: 018 Project Why
Status: Archived
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# FINCORE PROJECT WHY — POR QUE NÓS TOMAMOS ESTAS DECISÕES?
## Resposta Oficial para as Perguntas que Todo Mundo Faz Daqui a 5 Anos

> **Document ID**: 018_Project_Why
> **Version**: 1.0.0
> **Status**: ✍️ Ativo — atualizado SEMPRE que uma decisão estratégica for tomada.
> **Owner**: Chief Technology Officer (CTO) + Chief Architect Oficial
> **Depende de**: ADRs 300_decisions/ (fonte primária), 019 Project Memory.
> **Relacionados**: 006 Decision Tree, 000 Constitution, 001 FPOS
> **Obrigatoriedade**: 🟡 CONTEXTUAL — Este documento existe para **economizar centenas de horas de discussão repetida**. Cada vez que alguém perguntar "por que a gente usou Serverpod em vez de Firebase?", a resposta está AQUI. Não precisa chamar reunião.

---

## 🎯 POR QUE ESTE DOCUMENTO EXISTE?

> **Há uma regra universal em projetos de software de vida longa:**
>
> ```
> 1 ANO depois → ninguém lembra mais por que a decisão foi tomada.
> 3 ANOS depois → alguém vem e diz: "isso é idiota, a gente devia usar X em vez de Y".
> 3 MESES depois → redesenham tudo para X.
> 1 MÊS depois → descobrem os MOTIVOS EXATOS do porque não usaram X há 3 anos.
> 2 MESES depois → voltam para Y exatamente como estava.
> RESULTADO: 6 meses de retrabalho. Nada mudou. Todos frustrados.
> ```
>
> **Este documento existe para QUEBRAR este ciclo.**
>
> Toda decisão estratégica importante registrada AQUI com o PORQUÊ completo, com as alternativas que consideramos, com os motivos porque REJEITAMOS cada alternativa.
>
> **Nenhuma discussão de re-decisão pode ser iniciada SEM antes ler a entrada correspondente neste documento.** Se você quer mudar Drift para outro ORM, primeiro você TEM que explicar POR QUE os motivos abaixo (que valiam em 2026) não valem mais HOJE. Não é suficiente dizer "porque é melhor". Tem que justificar contra os mesmos critérios.

---

# 🗂️ REGISTRO OFICIAL: POR QUE NÓS USAMOS ____?

---

## ❓ WHY-001: Por que usamos Flutter Desktop em vez de React (Electron/Tauri), WPF, Qt?

**Decisão**: Flutter 3.x + Dart como stack de UI ÚNICA para Desktop, Tablet Kiosk e (futuro) Mobile.
**Data da decisão**: 2026 janeiro.
**ADR correspondente**: 301_adr_001_official_technology_stack.

### Por que SIM Flutter?
1. **Código ÚNICO para 3 workstations:** Desktop PDV Windows (Maria) + Tablet Parede KDS (João) + Mobile Entregador (Carlos). Mesmo design system, mesma codebase, mesmo Pricing Engine. Com React precisaríamos de 2 codebases diferentes (Electron desktop + React Native mobile).
2. **Performance nativa em Windows sem dependências pesadas:** Flutter compila nativo x64. Tauri/Electron requerem Runtime de ~200MB na máquina do cliente (loja food service tem PCs de 8GB velhos).
3. **Isolamento de UI sem regressão visual:** Widget tree é determinística. "Na minha máquina funciona" é MUITO menos frequente. Ideal para impressão ESC/POS onde precisamos pixel-perfect.
4. **Dart é uma linguagem única (Frontend + Backend com Serverpod):** Mesmo desenvolvedor escreve UI Flutter e Endpoint Serverpod em Dart. Não troca contexto de TypeScript → Go. Menos erros. Menos bus factor.

### 3 Alternativas que CONSIDERAMOS e REJEITAMOS + MOTIVO:
| Alternativa | Pontos bons | Por que REJEITAMOS? |
|---|---|---|
| React + Electron + React Native | Maior ecossistema de devs | 2 codebases diferentes. Electron consome 1GB de RAM. Loja de salgado não tem PC para isto. |
| C# / WPF (Windows nativo) | Perf excelente | Mobile e Tablet Android não tem WPF. Dupla codebase. Aprendizado WPF é lento. |
| Qt Framework / C++ | Cross plataforma verdadeiro | Curva aprendizado absurda (STL, templates, memory management). Preço licença para uso comercial. Devs raros = Bus Factor = 1. |

---

## ❓ WHY-002: Por que usamos Serverpod em vez de Nest.js, Go, Supabase functions?

**Decisão**: Serverpod framework (Dart) como backend único de API.
**Data da decisão**: Janeiro 2026.

### Por que SIM Serverpod?
1. **Dart full stack (Frontend ↔ Backend):** O model `Cliente` (Dart) do Drift local é o MESMO modelo compilado do Serverpod YAML. Nenhuma duplicação. Nenhuma deserialização manual de JSON entre Flutter e endpoint. Economiza 30% de código em transações.
2. **Integração nativa com Postgres migrations:** Serverpod gera .sql automaticamente do YAML. Nenhuma migração escrita à mão = menos erro de typo.
3. **Authentication built-in:** RLS policies podem ser aplicadas já no framework, não tem que construir do zero.
4. **Cache distribuído + Serialização built-in:** Reduz boilerplate.

### Alternativas Consideradas:
| Alternativa | Por que REJEITAMOS? |
|---|---|
| Nest.js (Node) | Contexto TypeScript/Dart múltiplo. Models duplicados entre TypeORM e Drift. Mais chance de inconsistência. |
| Go / Gin | Muito rápido, mas modelo Dart → Go = serialização manual. Todo novo campo = 3 arquivos para tocar. Mais bus factor. |
| Supabase Edge Functions (Deno) | Lock-in de fornecedor. Impossível mover para outro provedor depois sem reescrever tudo. |

---

## ❓ WHY-003: Por que usamos Drift ORM (SQLite local) em vez de sqflite puro, Hive, Isar?

**Decisão**: Drift = banco local OFFLINE-FIRST oficial.
**Data**: Fevereiro 2026.

### Por que SIM Drift?
1. **SQLite nativo com tipagem forte DART:** Consultas SQL em string são verificadas em COMPILE TIME (erro de typo não passa o analyzer). `select * from cliente where name = ?` → erro no LINT se a coluna não existir. Com sqflite puro você descobre no RUNTIME (produção).
2. **Streams reativos nativos:** KDS 3 colunas atualiza automaticamente quando o Pedido é gravado no Drift, sem setState, sem StreamController manual.
3. **Migrations automáticas versionadas:** Nova coluna? Basta .drift file + Drift gera migration. Em Hive/Isar migrations são manuais (alto risco perda de dados se errar).
4. **BaseRepository genérico T funciona com Drift:** Mesma interface para Cliente, Produto, Pedido.

### Alternativas Rejeitadas:
| Alternativa | Por que REJEITAMOS? |
|---|---|
| sqflite (SQL puro Dart) | Nenhuma tipagem compile time. Erro de coluna errada = descobre em produção. |
| Isar Database | Performance excelente, mas NÃO tem SQL. Queries complexas (preço fracionado N:N produto↔tabela) → muito difícil escrever. Não tem suporte a triggers SQL nativos que usamos para Outbox. |
| Hive (NoSQL) | Chave-valor. Agregações transacionais (totais do pedido, relatórios de fechamento diário) = 10x mais lento e 10x mais código. Não serve para ERP. |

---

## ❓ WHY-004: Por que MULTI-TENANT NATIVO (tenantId primeira coluna), em vez de 1 banco por cliente?

**Decisão**: Multi-Tenant nativo, uma instância Postgres serve 500+ empresas. `tenantId` obrigatório em TODAS tabelas. RLS Postgres.
**Data**: Fevereiro 2026.

### Por que SIM Multi-Tenant único banco?
1. **Custo 20x menor para cliente pequeno:** Cliente piloto (salgaderia 1 funcionário) paga R$ 49/mês. Se 1 banco por cliente, cada banco custa ~R$ 20/mês em Supabase = margem negativa. Multi-tenant = R$ 0,20/mês por cliente.
2. **Deploy 1 alteração serve todos:** Nova versão do Pricing Engine? Deploy 1x serve 500 clientes. Com banco separado = 500 deploys.
3. **Backup 1 arquivo:** Backup diário = 1 Postgres dump. 500 clientes = 500 arquivos backup.
4. **RLS Postgres garante isolamento mesmo que endpoint tenha bug:** (Ver WHY-005 abaixo porque não usamos 1 schema por tenant).

### Por que NÃO 1 banco por cliente?
- Despesa infra impagável. Cliente food service brasileiro não paga R$ 300/mês de sistema.
- Deploy multiplica.
- Migrações multiplica por 500 a chance de erro.

### Por que NÃO "1 schema por tenant"?
- Índices são compartilhados? Não. Cada schema tem seus próprios índices.
- 500 schemas = 500 versões tabelas. Migração quebrada em 1 schema = cliente 123 fica sem sistema enquanto resto funciona? → pior do que RLS.

---

## ❓ WHY-005: Por que NÃO usamos Firebase / Firestore?

**Decisão**: Firebase NUNCA foi cogitado para dados transacionais do sistema. Apenas Supabase como Postgres gerenciado.
**Data**: Janeiro 2026.

### Por que NÃO Firebase/Firestore?
1. **Modelo documento (não relacional) = PÉSSIMO para ERP transacional.** Pedido tem FK Cliente, FK LocalEntrega, ItensPedido N:1, EventosPedido N:1, Pagamentos N:1. Para buscar pedido completo no Firestore = 6 requisições separadas. Muito lento + inconsistência transacional impossível sem transação 2PC.
2. **Offline-First do Flutter + Firebase é uma mentira.** Firebase persiste cache local SOMENTE para app Android/iOS. Para WINDOWS DESKTOP (nosso caso principal PDV), o cache Firestore não é ativo para transações pesadas. Perdemos a característica mais importante.
3. **Vendor Lock-In GRAVE.** Exportar 500 clientes de Firestore para Postgres depois é quase impossível (relações em documento). Com Supabase Postgres, podemos mover para AWS RDS amanhã sem mudar 1 linha de código Serverpod.
4. **Preço imprevisível.** "Pague por operação = R$ 0,06 por mil escritas". Um dia movimentado de 1000 pedidos / cliente × 500 clientes = 500 mil escritas = R$ 30/dia = R$ 900/mês. Preço explode sem controle.

### Quando FIREBASE É SUPORTADO (caso especial)?
- **Cloud Storage para imagens de produtos?** Supabase Storage é preferencial. Firebase Storage opcional se já tiver conta.
- **Push Notifications FCM?** Sim, FCM é permitido APENAS para mobile entregador. APENAS isto. Nada de dados transacionais no Firebase.

---

## ❓ WHY-006: Por que Offline-First é SOBERANO (Princípio #1 da Constituição)?

**Decisão**: Operação local não pode PARAR NUNCA por queda de internet. Nem impressão, nem caixa, nem cozinha.
**Data**: Fevereiro 2026.

### Por quê? (Motivo de vida ou morte para o cliente):
```
Cenário REAL: 19:30, pico do jantar. Maria atendendo 30 clientes/minuto.
Operadora Vivo cai (queda de internet regional na cidade).

Se NÃO temos Offline-First:
  → Sistema para de responder.
  → Maria não consegue imprimir cupom.
  → João cozinheiro não vê pedidos novos.
  → Fila começa a formar na porta.
  → 30 clientes saem sem comprar.
  → Dono Luiza perde R$ 800 em 1 hora.
  → Cancela contrato com a gente no dia seguinte.

Se TEMOS Offline-First correto:
  → Drift local grava tudo normalmente.
  → Impressão ESC/POS acontece LOCALMENTE, não precisa de net.
  → KDS atualiza local, João continua trabalhando.
  → Ninguém percebeu que a internet caiu.
  → Internet volta 20 minutos depois. SyncEngine lineariza tudo em background.
  → Nenhum pedido perdido. Nenhum cliente saiu. Nenhuma dor de cabeça.
```

Offline-First não é "feature nice to have". É a **garantia de emprego do nosso cliente**. E, portanto, garantia do nosso.

---

## ❓ WHY-007: Por que Pedido é Aggregate Root? E por que Cliente vem PRIMEIRO?

**Decisão** (Auditoria 2026-07-25, Pergunta 7 Decisão 1):
- Pedido é Aggregate Root transacional.
- Ordem de operação: Abrir Caixa → Selecionar Cliente OBRIG → Selecionar Local → Montar → Preço → Pagar → Confirmar (aqui é criado o Pedido).

### Por que Pedido não é o começo? Por que Cliente vem primeiro?
1. **Operação real não começa com "Criar Pedido".** A Maria na vida real não grita "vou criar um pedido agora!". Ela recebe o cliente na frente. Se o cliente não existir, ela cadastra rápido. Depois monta o pedido. O Pedido é a **consequência**, não a origem.
2. **Pedido sem dono não existe no mundo físico.** Nenhuma padaria imprime cupom sem saber quem retirou. Se você não sabe quem é o cliente, não sabe onde entregar, não sabe o preço dele (grupo atacadista tem preço diferente), não sabe o telefone para avisar "seu pedido ficou pronto". Pedido órfão é um bug, não uma feature.
3. **FK NOT NULL clienteId é proteção contra dívida técnica irreversível.** Se lançarmos o sistema permitindo pedido sem cliente, em 1 mês teremos 20% dos pedidos órfãos, e quando precisarmos gerar CRM ou Relatório Histórico de Compra por Cliente → É IMPOSSÍVEL DE RECUPERAR depois. A informação do cliente se perdeu para sempre.

### Alternativa Rejeitada: "Pedido começa com Catálogo, seleciona cliente no final"
- **Rejeitado por:** Esta ordem causa erro operacional clássico em 20% das vendas de PDV mal desenhado: "Maria monta todo pedido de 10 itens, chega no final e esquece de selecionar cliente. Clica confirmar. Pedido gravado órfão. Agora tem que cancelar e refazer tudo → cliente na fila impaciente." Step 0 Cliente OBRIGATÓRIO protege Maria dela mesma.

---

## ❓ WHY-008: Por que Pricing Engine está desacoplado do Pedido (pacote separado fincore_pricing)?

**Decisão**: fincore_pricing package independente. 95.65% testes. Nenhuma dependência para fora.
**Data**: Março 2026.

### Por que não pode estar dentro de Pedido UseCase?
1. **Pricing é regra de negócio COMPLEXA e VARIADA:** 7 políticas (unitário, faixa, fracionado, peso, cento, combo, promocional) + vigência temporal + N:N Produto↔Tabela. Se misturar isto com Use Case Pedido → Usa Case fica 1500 linhas = impossível de testar isoladamente.
2. **Pricing não depende de Pedido:** A mesma tabela de preço serve para: (1) Pedido PDV, (2) Ordem Compra Futura, (3) Cotação de orçamento, (4) App Mobile do cliente. Se tivesse acoplado ao Pedido, teria que duplicar código para orçamentos.
3. **Testes 95% → 70%:** Se Pricing dependesse de Repository Pedido, 30% dos testes precisariam de mock de repositório. Hoje o teste de pricing é puro, sem side effect.

---

## ❓ WHY-009: Por que documentação FIRST e CODE LAST (Playbook regra)?

**Decisão**: Playbook estabelece que nenhuma linha de código é escrita ANTES do Caso de Uso CU-XXX existir oficial no PRD-125.
**Data**: Auditoria 2026-07-25.

### Por que isto economiza tempo (não perde como parece)?
```
MODALIDADE ERRADA (Code First):
  Dev implementa UI bonita em 3 dias.
  Ao testar com cliente → "Ah não, precisava perguntar endereço ANTES do catálogo, não depois."
  Dev refatora tudo. Perde mais 4 dias.
  TOTAL: 7 dias. Nada foi ganho. "Rápido" virou mais lento.

MODALIDADE CERTA (Document First):
  PO + Arquiteto passam 2 HORAS desenhando CU-XXX + fluxo no PRD-125.
  Valida com Maria a atendente de verdade.
  "Ah, sim, endereço antes!"
  Dev implementa TUDO CERTO em 4 dias.
  TOTAL: 4 dias + 2 horas = MENOS do que os 7 do code first.
```

Além disso, a documentação é permanente. O desenvolvedor pode sair, mas o PRD fica, e outro assume do ponto exato. Code First = conhecimento na cabeça da pessoa = volta para estaca zero quando ela sai.

---

# 📌 NOVA ENTRADA? FORMATO OBRIGATÓRIO

Quando adicionar uma nova decisão estratégica, use:

```markdown
## ❓ WHY-XXX (Próximo número sequencial): Por que [decisão] em vez de [alternativa]?

**Decisão oficial:** [1 frase].
**Data da decisão**: YYYY-MM.
**ADR correspondente**: Se houver → número.

### Por que SIM escolhemos isto?
1. Motivo 1
2. Motivo 2
3. Motivo 3

### 3 Alternativas que consideramos e REJEITAMOS + motivo:
| Alternativa | Pontos Bons | Por que REJEITAMOS? |
|---|---|---|
| X | ... | ... |
| Y | ... | ... |
```

---

## 🛑 REGRA PARA REABRIR DISCUSSÃO DE DECISÃO ANTIGA

NÃO É SUFICIENTE dizer:
> "Eu acho que devíamos usar [tecnologia da moda] em vez de Drift."

**Para reabrir discussão você TEM que apresentar:**
1. Ler o WHY correspondente completamente.
2. **Apresentar por escrito** quais dos MOTIVOS do WH0-XXX mudaram de verdade desde a data original.
   - Exemplo: "Por que Internet Offline não é mais soberano? Porque hoje cliente contratou fibra 5G redundância 99.99% SLA." Não vale dizer "não gosto mais".
3. **Calcular custo da mudança:** Linhas de código para reescrever? Pessoas envolvidas? Risco de migração de dados? Tempo total?
4. **Apresentar ADR rascunho com 3 alternativas.**

Só depois desses 4 passos o Comitê Executivo VOTA se vale a pena reabrir. **Sem estes 4 passos → discussão arquivada. Não perdemos tempo.**

---

**Owner Atualização**: CTO + Chief Architect
**Última revisão**: 2026-07-25 (versão baseline 1.0 com 9 decisões estratégicas).
Próxima atualização: Quando for tomada a 10ª decisão estratégica.
