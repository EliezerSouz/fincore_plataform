---
Title: Next Steps
Status: Archived
Version: 1.0
Owner: Architecture
Approved By: Architecture Board
Last Updated: 2026-07-26
---
# FINCORE — PRÓXIMOS PASSOS OFICIAIS
## Plano de Execução Derivado da Documentação Consolidada

> **Document ID**: NEXT_STEPS_2026-07-25
> **Gerado em**: 2026-07-25 23:42 BRT
> **Baseado em**: 013_Project_State + 108_product_reset_fase4 + 125_operational_flows + AUDITORIA_COMITE_EXECUTIVO_2026_07_25 + Decision Tree (006)
> **Regra**: Este documento NÃO substitui o 013_Project_State. Ele DERIVA do 013_Project_State e o complementa com profundidade de execução.
> **Próxima revisão**: Quando CICLO-01 fechar.

---

## 🧭 PONTO DE PARTIDA — ONDE ESTAMOS HOJE

```
Versão atual:       0.3.0 (M4 concluída 2026-07-25)
Arquitetura:        82/100 — Fundação sólida. Sem módulos transacionais.
Maior lacuna:       Não existe entidade Pedido. PDV Express é simulação em memória.
Maior ativo:        Pricing Engine 99% + Design System + Clean Arch + Multi-Tenant.
Bloqueadores:       ZERO bloqueadores hoje.
Próxima milestone:  M5 (PDV Express com persistência real) — começa agora.
```

```
HIERARQUIA DE DEPENDÊNCIA TÉCNICA (não pule etapas):

  CICLO-01: Master Data Conectado (JORNADA-A Luiza)
       ↓
  CICLO-02: Pedido Real + PDV Express (JORNADA-B Maria)
       ↓
  CICLO-03: KDS Real + Produção (JORNADA-C João)
       ↓
  CICLO-04: Financeiro + Fechamento (JORNADA-D Luiza)
       ↓
  CICLO-05: Backend Serverpod Real (Sync completo)
       ↓
  CICLO-06: Dashboard + Analytics (M8)
```

> **Regra de ouro**: Nenhum ciclo começa antes do anterior ser homologado 100% pela persona correspondente.
> Não há atalho. Não há paralelismo não supervisionado.

---

## 📅 CICLO-01 — JORNADA-A: DADOS REAIS PRONTOS
### "Luiza consegue cadastrar clientes, produtos e preços reais — e eles persistem."

**Duração**: 7 dias úteis (2026-07-26 → 2026-08-03)
**Persona de homologação**: P4 Luiza (Gestora/Dona)
**Critério de encerramento**: Luiza usa o sistema sozinha por 30 minutos sem ajuda de desenvolvedor, cadastra 10 clientes reais e 20 produtos reais, fecha o app, reabre, os dados continuam lá.

---

### DIA 1 — Clientes CRUD Real

#### TAREFA 1.1 — `[CU-V05]` Cadastrar Cliente Completo
**Prioridade**: 🔴 MAX (Item #1 do backlog)

**O que fazer**:
```
1. Criar ClienteRepository.dart em fincore_data/repositories/
   → Herda BaseRepository<Cliente, ClienteId>
   → Injeta tenantId automaticamente (via BaseRepository)

2. Criar CriarClienteUseCase.dart em fincore_core/usecases/masterdata/
   → Input: ClienteInput (nome, cpf, telefone, email)
   → Output: Either<DomainFailure, Cliente>
   → Valida CPF único por tenant
   → Grava no Drift → enfileira no Outbox

3. Conectar ClientesPage.dart ao repositório real
   → Remover lista mock hardcoded
   → Usar StreamBuilder ou AsyncSnapshot do repositório
   → Botão "+" abre modal de cadastro real

4. Criar ClienteFormModal.dart
   → 6 campos: Nome*, CPF, Telefone*, Email, Observação
   → Validação em tempo real (CPF formato, telefone format)
   → Botão Salvar → chama CriarClienteUseCase
```

**Arquivos afetados**:
- `packages/fincore_core/lib/domain/masterdata/entities/cliente.dart` — verificar se ClienteId existe
- `packages/fincore_core/lib/usecases/masterdata/criar_cliente_usecase.dart` — CRIAR
- `packages/fincore_data/lib/repositories/cliente_repository.dart` — CRIAR
- `products/fincore-food/fincore_food_flutter/lib/features/clients/clientes_page.dart` — CONECTAR
- `products/fincore-food/fincore_food_flutter/lib/features/clients/cliente_form_modal.dart` — CRIAR

**Testes obrigatórios**:
- `test/usecases/criar_cliente_usecase_test.dart` — 3 casos: sucesso, CPF duplicado, campo obrigatório vazio
- `test/repositories/cliente_repository_test.dart` — 2 casos: save + findAll com tenantId

**Critério de aceite**:
```
□ Luiza abre ClientesPage → vê "Nenhum cliente cadastrado"
□ Clica "+" → modal abre
□ Preenche nome + telefone → Salvar
□ Cliente aparece na lista
□ Fecha app completamente
□ Reabre → cliente ainda está lá
□ Testes passando: 0 falhas
```

---

#### TAREFA 1.2 — `[CU-V06]` Editar Cliente + Excluir Lógico
**Prioridade**: 🔴 MAX (Item #2 do backlog)

**O que fazer**:
```
1. Criar EditarClienteUseCase.dart
   → Recebe ClienteId + ClienteInput atualizado
   → Atualiza Drift → enfileira Outbox com operação UPDATE

2. Criar ExcluirClienteUseCase.dart (exclusão LÓGICA)
   → Seta deletedAt = now() + deletedBy = userId
   → NÃO remove do banco. Apenas esconde na query (WHERE deletedAt IS NULL)
   → Enfileira Outbox com operação SOFT_DELETE

3. Atualizar ClientesPage
   → Cada card de cliente: swipe ou botão ⋮ (menu contextual)
   → Opções: Editar | Excluir
   → Confirmar exclusão: dialog "Tem certeza? Cliente será arquivado."
```

**Critério de aceite**:
```
□ Luiza clica em cliente → menu abre
□ Seleciona Editar → modal com dados preenchidos
□ Altera nome → Salvar → lista atualiza imediatamente
□ Seleciona Excluir → dialog confirma → some da lista
□ No banco Drift: registro tem deletedAt preenchido (não foi apagado)
```

---

### DIA 2 — Busca de Clientes + Produtos CRUD Real

#### TAREFA 2.1 — `[CU-V07]` Localizar Cliente (Busca Rápida)
**Prioridade**: 🔴 HIGH (Item #3)

**O que fazer**:
```
1. Adicionar SearchBar na ClientesPage
   → Campo de busca com debounce de 300ms
   → Busca por: Nome (LIKE '%query%') | Telefone | CPF

2. Criar BuscarClienteUseCase.dart
   → Recebe query: String
   → Retorna List<Cliente> filtrados por tenantId + deletedAt IS NULL

3. Em PDV Express → Step "Selecionar Cliente"
   → Reutilizar BuscarClienteUseCase
   → Substituir lista mock por busca real
```

**ATENÇÃO CRÍTICA**: Esta tarefa é o pré-requisito para o CICLO-02 (PDV). Sem busca real de cliente, o PDV não funciona. Prioridade alta.

---

#### TAREFA 2.2 — `[CU-P01]` Produtos + Categorias CRUD Real
**Prioridade**: 🔴 HIGH (Item #4)

**O que fazer**:
```
1. Criar ProdutoRepository + CriarProdutoUseCase + EditarProdutoUseCase + ExcluirProdutoUseCase
   → Mesmo padrão do Cliente (copiar estrutura, não o conteúdo)

2. Criar CategoriaRepository + CRUDs básicos

3. Conectar ProdutosPage ao repositório real
   → Lista filtrada por categoria
   → Produto tem: Nome, Categoria, Descrição, Código, Unidade, Foto (opcional)

4. Conectar CategoriasPage ao repositório real
```

**Arquivos afetados** (padrão a seguir):
```
fincore_core/usecases/masterdata/
  criar_produto_usecase.dart
  editar_produto_usecase.dart
  excluir_produto_usecase.dart

fincore_data/repositories/
  produto_repository.dart
  categoria_repository.dart
```

---

### DIA 3 — Preços Conectados ao Motor Real

#### TAREFA 3.1 — `[CU-P02]` PrecosPage + Associação N:N Produto↔Tabela
**Prioridade**: 🔴 HIGH (Item #5)

**O que fazer**:
```
1. O PricingEngine já existe e está 99% funcional.
   O problema: as telas de gestão de preços são mockadas.

2. Conectar PrecosPage ao PrecificacaoRepository real (já existe em fincore_pricing)
   → Listar tabelas de precificação ativas
   → Listar itens de precificação por tabela
   → Listar associações N:N (Produto ↔ Tabela)

3. Criar CriarTabelaPrecificacaoUseCase + AdicionarItemUseCase
   → Interface para Luiza criar uma nova tabela de preços
   → Associar produtos a tabelas com preço específico

4. Validar que ao criar pedido no PDV, o PricingEngine recebe
   dados reais do banco (não hardcoded)
```

**Regra crítica**: O Pricing Engine NÃO muda. Só conecta dados reais na entrada.

---

### DIA 4 — Seed Data Real + Homologação Parcial Luiza

#### TAREFA 4.1 — Seed Data Real do Estabelecimento Piloto

**O que fazer**:
```
1. Substituir dados de seed demo por dados reais do cliente piloto
   (ou dados de exemplo representativos)

2. Criar script de seed com:
   → 1 empresa real configurada
   → 5 categorias reais (Ex: Salgados, Bebidas, Sobremesas, Combos, Adicionais)
   → 20 produtos reais com preços
   → 1 tabela de precificação padrão "Balcão"
   → 1 tabela "Delivery" com taxa diferente
   → 5 formas de pagamento (Dinheiro, PIX, Débito, Crédito, VR)
   → 3 locais de entrega (Balcão, Retirada, Delivery)
```

#### TAREFA 4.2 — Homologação Parcial JORNADA-A (Dia 4)

**O que fazer**:
```
Luiza senta na frente do sistema com desenvolvedor ao lado (mas sem intervir):

1. Luiza faz login com PIN
2. Luiza abre Clientes → cadastra 5 clientes reais
3. Luiza abre Produtos → cadastra 3 produtos com categoria
4. Luiza configura 1 tabela de preço
5. Luiza fecha o app completamente, reabre
6. Todos os dados ainda estão lá

CRITÉRIO: Luiza não deve precisar fazer NENHUMA pergunta ao dev.
          Se precisar → bug/UX issue → registrar → voltar ao código.
```

---

### DIA 5-6 — Conectar Endereços + Formas de Pagamento + Locais

#### TAREFA 5.1 — Endereços de Cliente CRUD

**O que fazer**:
```
1. Um cliente pode ter N endereços (já modelado em ClienteEndereco)
2. Na tela de detalhe do cliente: seção "Endereços"
3. Adicionar/Editar/Remover endereço (com tipo: Residencial/Comercial/Delivery)
4. Endereço tem: Rua, Número, Complemento, Bairro, CEP, Cidade, UF
5. BuscarEnderecoViaCEPUseCase: consulta ViaCEP API se tiver internet,
   preenche campos automaticamente. Se offline → preenche manualmente.
```

#### TAREFA 5.2 — Formas de Pagamento + Locais (Validação)

**O que fazer**:
```
As entidades já existem (M4). Tarefa: verificar se as telas de configuração estão
conectadas ao repositório real ou ainda usam mock.

FormaPagamentoRepository → FormaPagamentoPage → Conectar
LocalEntregaRepository → LocalEntregaPage → Conectar
TaxaEntregaRepository → TaxaEntregaPage → Conectar
```

---

### DIA 7 — Homologação Final CICLO-01

**O que fazer**:
```
Teste completo JORNADA-A Luiza (sem desenvolvedor na sala):

□ Luiza faz login
□ Cadastra 10 clientes reais com endereço
□ Cadastra 20 produtos em 5 categorias
□ Configura 2 tabelas de preço (Balcão + Delivery)
□ Edita 3 clientes
□ Exclui logicamente 1 produto
□ Fecha app
□ Reabre 3 vezes em sequência
□ Todos os dados persistiram
□ Luiza confirma: "O sistema está pronto para eu usar no dia a dia de cadastro"

SE APROVADO → CICLO-01 FECHADO → CICLO-02 COMEÇA
SE REJEITADO → Corrigir issues → Nova homologação (max 2 dias extras)
```

**Versão gerada ao fechar CICLO-01**: `0.4.0-master-data-real`

---

## 📅 CICLO-02 — JORNADA-B: VENDE DE VERDADE
### "Maria cria um pedido real, o sistema persiste, o KDS recebe."

**Duração**: 10 dias úteis (2026-08-04 → 2026-08-15)
**Persona de homologação**: P1 Maria (Atendente/Caixa)
**Critério de encerramento**: Maria faz 5 vendas reais consecutivas sem intervenção de dev. O KDS de João mostra os pedidos. O caixa fecha com total correto.

---

### BLOCO B-1: Entidade Pedido (A Mais Crítica do Projeto)

#### TAREFA B-1.1 — Criar Aggregate Root Pedido no Domínio

**Esta é a tarefa mais crítica de todo o CICLO-02.**

```
DOMÍNIO (fincore_core):

1. Criar pedido.dart → Aggregate Root
   Campos obrigatórios:
   → pedidoId: PedidoId (UUID)
   → tenantId: TenantId (NOT NULL — vem de TenantContext)
   → clienteId: ClienteId (NOT NULL — FK obrigatória, sem exceção)
   → localEntregaId: LocalEntregaId (NOT NULL — FK obrigatória)
   → status: StatusPedido enum (7 estados)
   → itens: List<ItemPedido> (mínimo 1)
   → valorTotal: MoneyAmount
   → formaPagamento: FormaPagamento
   → createdAt / updatedAt / createdBy

2. Criar item_pedido.dart → Entity filho do Aggregate
   → itemId, pedidoId, produtoId, quantidade, precoUnitario, observacao

3. Criar status_pedido.dart → Enum com máquina de estados
   → RASCUNHO → CONFIRMADO → EM_PREPARO → PRONTO → ENTREGUE → CANCELADO → ESTORNADO
   → Transições válidas declaradas explicitamente
   → Transição inválida lança DomainException

4. Criar evento_pedido.dart → Domain Event
   → PedidoCriado, PedidoConfirmado, PedidoCancelado
```

**Regra INVIOLÁVEL** (Decision Tree A-01):
```
clienteId: NÃO NULO. NUNCA.
Pedido SEM cliente associado = VIOLAÇÃO CRÍTICA.
PR com migration que permite clienteId NULL = REJEITADO AUTOMATICAMENTE.
```

---

#### TAREFA B-1.2 — Criar Tabelas Drift para Pedido

```
INFRASTRUCTURE (fincore_data):

1. Criar pedidos_table.dart no Drift
   → Todas colunas espelham o Aggregate Root
   → clienteId NOT NULL (enforçado no schema Drift)
   → localEntregaId NOT NULL
   → tenantId NOT NULL

2. Criar itens_pedido_table.dart
   → FK pedidoId NOT NULL
   → FK produtoId NOT NULL

3. Criar eventos_pedido_table.dart (append-only, imutável)
   → eventId, pedidoId, tipo, payload JSON, createdAt

4. Migration: SchemaVersion 3 (adicionar as 3 tabelas acima)
   → Testar migration em banco existente (não perder dados de M4)
```

---

#### TAREFA B-1.3 — CriarPedidoUseCase (Transação Atômica)

```
DOMAIN (fincore_core):

CriarPedidoUseCase.execute(CriarPedidoInput input):
  Dentro de UMA transação Drift:
    1. Validar clienteId existe e não está deletado
    2. Validar localEntregaId existe
    3. Validar List<ItemPedido> não está vazia
    4. Chamar PricingEngine.resolvePrice() para cada item
    5. Calcular valorTotal
    6. Salvar Pedido na tabela pedidos (status: CONFIRMADO)
    7. Salvar todos ItemPedido
    8. Salvar EventoPedido tipo PedidoCriado
    9. Enfileirar OutboxSync entry (operação: CREATE_PEDIDO)
    10. Publicar OrdemPreparo no KDS (converter Pedido → OrdemPreparo)
  FIM TRANSAÇÃO
  Retornar: Either<DomainFailure, Pedido>

QUALQUER PASSO QUE FALHAR → ROLLBACK COMPLETO. Nada persiste.
```

---

### BLOCO B-2: PDV Express — Integração Real (5 Steps)

**Refatorar o PdvExpressController para 5 steps** (hoje tem 3):

```
Step 0:   ABRIR CAIXA (novo — obrigatório no início do dia)
Step 1:   SELECIONAR CLIENTE (obrigatório — busca real no banco)
Step 1.5: SELECIONAR LOCAL/ENDEREÇO (Balcão | Retirada | Delivery)
Step 2:   MONTAR PEDIDO (catálogo real — produtos do banco)
Step 3:   CONFIRMAR PAGAMENTO (dinheiro/PIX/cartão + troco)
→ EXECUTAR CriarPedidoUseCase (transação atômica)
→ EXIBIR confirmação + opção imprimir
```

**Step 0 — Abrir Caixa**:
```
1. Criar AbrirCaixaUseCase → registra FundoDeTroco + timestamp + usuário
2. Criar caixa_diario_table.dart no Drift
3. Sistema verifica se caixa está aberto ao login
4. Se não está → força Step 0 antes de qualquer venda
```

**Step 1 — Selecionar Cliente (real)**:
```
1. Remover mock. Conectar BuscarClienteUseCase (do CICLO-01)
2. Campo de busca com debounce 300ms
3. Resultado: lista de clientes reais
4. Opção "Cadastro Rápido": modal com Nome + Telefone apenas (6 campos max)
   → Sem sair do fluxo de venda
5. Cliente selecionado → armazenado no state do controller
```

**Step 2 — Montar Pedido (catálogo real)**:
```
1. Carregar produtos do ProdutoRepository (real, não mock)
2. Filtrar por categoria
3. Cada produto mostra preço resolvido pelo PricingEngine
   (baseado no cliente selecionado + local selecionado)
4. Undo de 4s já existe → manter
5. Observação por item → manter
```

**Step 3 — Pagamento + Confirmação**:
```
1. Dinheiro: campo valor recebido + cálculo de troco automático
2. PIX: exibir QR Code estático por enquanto (dinâmico = backlog futuro)
3. Cartão: apenas registrar "cartão débito/crédito" sem TEF (MVP)
4. Botão CONFIRMAR → chama CriarPedidoUseCase
5. Tela de confirmação: "Pedido #X criado. Cozinha notificada."
6. Opção: Imprimir Cupom (se impressora configurada)
```

---

### BLOCO B-3: Impressão ESC/POS

```
TAREFA B-3.1 — Impressão de Cupom Térmico 80mm

1. Adicionar pacote escpos_printer (ou equivalente Dart) ao pubspec.yaml
   → Confirmar com humano antes de adicionar dependência
2. Criar PrinterService.dart em fincore_core/services/
   → Interface (Port): abstract class PrinterPort
   → Implementação: EscPosPrinterAdapter em fincore_data/adapters/
3. Criar CupomFiscal template:
   → Cabeçalho: Nome empresa + CNPJ + Data/Hora
   → Itens: Quantidade × Produto = Valor
   → Totais: Subtotal + Taxa Entrega + Total
   → Pagamento: Forma + Valor Recebido + Troco
   → Rodapé: "Volte sempre!"
4. Fallback: Se impressora offline → salvar .txt em temp/ + log
5. Testar com impressora física do cliente piloto
```

---

### BLOCO B-4: Homologação CICLO-02

```
DIA 10 — Teste completo JORNADA-B Maria:

□ Maria faz login com PIN
□ Sistema pede para Abrir Caixa → ela informa fundo R$ 200,00
□ Caixa aberto → PDV Express disponível

VENDA 1 (balcão):
□ Maria busca cliente "José" → aparece na lista → seleciona
□ Seleciona Local "Balcão"
□ Adiciona 2 salgados + 1 refrigerante
□ PricingEngine calculou preço correto automaticamente
□ Maria recebe R$20,00 em dinheiro para pedido de R$17,50
□ Sistema calcula troco R$2,50
□ Maria clica CONFIRMAR
□ Impressora imprime cupom
□ Tela KDS de João mostra o pedido na coluna "Pendente"
□ Nenhuma exceção na tela. Nenhum spinner infinito.

REPETE 4 vezes com variações (PIX, delivery, novo cliente rápido).

SE APROVADO POR MARIA → CICLO-02 FECHADO → CICLO-03 COMEÇA
```

**Versão gerada ao fechar CICLO-02**: `0.5.0-pdv-real`

---

## 📅 CICLO-03 — JORNADA-C: PRODUÇÃO AUTOMATICAMENTE
### "João vê pedidos reais no KDS, marca como pronto, o fluxo fecha."

**Duração**: 5 dias úteis (2026-08-16 → 2026-08-20)
**Persona de homologação**: P2 João (Cozinheiro)

---

### BLOCO C-1: KDS Conectado ao Repositório Real

```
TAREFA C-1.1 — Substituir mock do KdsController por OrdensPreparoRepository real

1. CriarPedidoUseCase (CICLO-02) já persiste OrdemPreparo no Drift
2. KdsController.loadOrdens() → busca OrdensPreparoRepository.findAll(status: PENDENTE)
3. StreamBuilder ou polling 1s → atualiza colunas automaticamente
4. Remover hardcoded mock list do KdsController

TAREFA C-1.2 — Marcar OrdemPreparo como Em Preparo / Pronto

1. Criar IniciarPreparoUseCase.dart
   → Muda status: PENDENTE → EM_PREPARO
   → Registra startedAt = now()
   → Enfileira Outbox

2. Criar MarcarProntoUseCase.dart
   → Muda status: EM_PREPARO → PRONTO
   → Registra finishedAt = now()
   → Enfileira Outbox

3. Botão no card da ordem no KDS → executa os use cases acima

TAREFA C-1.3 — Atraso Glow (Indicador Visual de Tempo)

1. Timer 1s já existe (correto)
2. Conectar ao tempo real (startedAt do banco, não hardcoded)
3. Calcular elapsedTime = now() - startedAt
4. Se elapsedTime > 10min → borda vermelha glow 3px pulsante
5. Se elapsedTime > 20min → borda vermelha + vibração + badge "ATRASADO"
```

---

### BLOCO C-2: Estorno (LIFO)

```
EstornarLoteEstoqueUseCase já existe (M6).
Problema: usa dados mock de LoteInsumo.

TAREFA C-2.1 — Conectar EstornarLoteEstoqueUseCase ao banco real
1. LoteInsumo existe no Drift (M6)
2. Criar movimentacao_estoque_table.dart → registra cada movimento
3. Tipo de movimentos: ENTRADA | RESERVA | BAIXA | ESTORNO | PERDA | AJUSTE
4. EstornoUseCase → busca lotes reais do banco → aplica LIFO → registra movimento
```

---

### BLOCO C-3: Homologação CICLO-03

```
DIA 5 — Teste completo JORNADA-C João:

□ João abre tablet (KDS Screen)
□ Maria (PDV) cria 3 pedidos reais em sequência
□ Os 3 pedidos aparecem no KDS de João em "Pendente"
□ João clica no pedido 1 → "Iniciar Preparo" → vai para "Em Preparo"
□ Timer mostra tempo decorrido em tempo real
□ João marca pedido 1 → "Pronto" → vai para "Pronto"
□ Após 15 minutos sem mover pedido 2 → borda vermelha aparece
□ João tenta cancelar pedido 3 → estorno executa → insumos voltam ao estoque

SE APROVADO POR JOÃO → CICLO-03 FECHADO → CICLO-04 COMEÇA
```

**Versão gerada ao fechar CICLO-03**: `0.6.0-kds-real`

---

## 📅 CICLO-04 — JORNADA-D: FINANCEIRO
### "Luiza fecha o caixa, vê as vendas do dia, sabe quanto entrou."

**Duração**: 7 dias úteis (2026-08-21 → 2026-08-29)
**Dependência DURA**: CICLO-03 100% fechado. Sem Pedido real → sem dado financeiro.

```
BLOCOS PRINCIPAIS:

D-1. Criar LancamentoFinanceiro entity + tabela Drift
     → Todo pedido confirmado gera LancamentoFinanceiro automaticamente

D-2. Criar FechamentoCaixa use case
     → Consolida total de vendas por forma de pagamento
     → Registra FundoInicial + TotalRecebido + TotalTroco + Diferença

D-3. Criar RelatorioVendasDiario
     → Tela Financeiro: Total do dia, Por forma de pagamento, Top 5 produtos

D-4. Criar HistoricoPedidos
     → Lista de todos os pedidos do dia com status + valor + cliente
     → Filtros: por status, por forma de pagamento, por período

D-5. Homologação com Luiza: ela fecha o caixa, imprime relatório do dia
```

---

## 📅 CICLO-05 — BACKEND SERVERPOD REAL
### "O sistema sincroniza dados com a nuvem. Luiza vê no celular o que Maria vendeu."

**Duração**: 10 dias úteis (estimativa)
**Dependência DURA**: CICLO-04 100% fechado. Dados precisam existir para sincronizar.

```
BLOCOS PRINCIPAIS:

E-1. Criar Endpoints reais no Serverpod:
     → ClienteEndpoint (CRUD + busca)
     → ProdutoEndpoint (CRUD)
     → PedidoEndpoint (criar + atualizar status)
     → OrdemPreparoEndpoint (KDS status updates)
     → FinanceiroEndpoint (lançamentos + fechamento)

E-2. Conectar SyncEngine real ao Serverpod (substituir SupabaseConnector direto)
     → OutboxSync → SyncEngine → Serverpod API → PostgreSQL
     → Backoff exponencial (5s, 30s, 2m, 10m)
     → Idempotência via commandId

E-3. Aplicar RLS (Row Level Security) no PostgreSQL
     → Policy: usuário só vê dados do seu tenantId
     → Teste: tentar acessar dados de outro tenant → deve retornar vazio

E-4. Login real (AuthEndpoint)
     → Substituir PIN local por autenticação com token JWT
     → Refresh token automático
```

---

## 📅 CICLO-06 — DASHBOARD + ANALYTICS
### "Luiza abre o Dashboard e vê a saúde do negócio em 10 segundos."

**Duração**: 5 dias úteis (estimativa)
**Dependência DURA**: CICLO-05 com dados reais rodando.

```
BLOCOS PRINCIPAIS:

F-1. Dashboard Principal (4 cards):
     → Vendas Hoje (R$ + Quantidade)
     → Ticket Médio
     → Produto Mais Vendido
     → Tempo Médio de Preparo

F-2. Gráficos (simples, sem library pesada):
     → Vendas por hora (linha)
     → Vendas por categoria (pizza)
     → Evolução semanal (barras)

F-3. Alertas automáticos:
     → "Estoque de [produto] abaixo de 10 unidades"
     → "3 pedidos com atraso acima de 20 min"
```

---

## ⚠️ REGRAS INVIOLÁVEIS PARA TODOS OS CICLOS

```
REGRA 1 — ORDEM É ORDEM
Nunca pular item de backlog.
Nunca começar CICLO-N sem CICLO-(N-1) homologado.
Se aparecer "ideia urgente" → registra no backlog → volta ao item atual.

REGRA 2 — CLIENTE VEM PRIMEIRO
Pedido NUNCA é criado sem clienteId NOT NULL.
PR com nullable clienteId = rejeitado automaticamente.
Sem exceção. Sem "apenas para testar".

REGRA 3 — TUDO REAL, NADA MOCK
Ao final de cada ciclo, ZERO dados mock nas telas homologadas.
Mock é scaffold temporário, não produto.

REGRA 4 — ENTREGA COMPLETA
Módulo só fecha quando todas as camadas funcionam:
Flutter UI → Controller → UseCase → Repository → Drift → Outbox
Tela bonita sem persistência = não entregue.

REGRA 5 — HOMOLOGAÇÃO PELA PERSONA REAL
Nenhum ciclo fecha por decisão do desenvolvedor.
Quem aprova é a persona correspondente (Luiza / Maria / João).
Dev não pode dizer "está pronto" sozinho.

REGRA 6 — PADRÃO ANTES DE VELOCIDADE
Antes de criar qualquer arquivo, verificar:
→ Existe padrão para isso no Playbook (005)?
→ Existe Use Case similar para copiar estrutura?
→ Onde este arquivo vai (qual package)?
Velocidade sem padrão gera retrabalho. Padrão é velocidade sustentável.
```

---

## 📊 SCORECARD DE PROGRESSO

| Ciclo | Jornada | Persona | Status | % |
|---|---|---|---|---|
| CICLO-01 | JORNADA-A: Dados Reais | P4 Luiza | 🔴 NÃO INICIADO | 0% |
| CICLO-02 | JORNADA-B: PDV Real | P1 Maria | ⏳ BLOQUEADO por C-01 | 0% |
| CICLO-03 | JORNADA-C: KDS Real | P2 João | ⏳ BLOQUEADO por C-02 | 0% |
| CICLO-04 | JORNADA-D: Financeiro | P4 Luiza | ⏳ BLOQUEADO por C-03 | 0% |
| CICLO-05 | Backend Serverpod Real | Todos | ⏳ BLOQUEADO por C-04 | 0% |
| CICLO-06 | Dashboard Analytics | P4 Luiza | ⏳ BLOQUEADO por C-05 | 0% |

**Atualizar este scorecard toda sexta-feira junto com o 013_Project_State.md.**

---

> **Este documento é derivado, não é a fonte de verdade.**
> A fonte de verdade do estado do projeto é sempre o **013_Project_State.md**.
> As especificações técnicas de cada domínio estão nos **PRDs 120-125**.
> As regras de decisão estão no **006_Decision_Tree.md**.
> O processo de desenvolvimento está no **005_Development_Playbook.md**.
