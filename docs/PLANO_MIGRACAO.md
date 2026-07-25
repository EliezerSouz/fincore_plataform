# PLANO DE MIGRAÇÃO INCREMENTAL — SISTEMA SALGADERIA

> **Objetivo:** Transformar o sistema atual em uma base sólida para ERP futuro, sem quebrar funcionalidades a cada passo.  
> **Princípio:** Cada sprint deixa o sistema **mais estável e mais modular** que o anterior.

---

## VISÃO GERAL DOS SPRINTS

| Sprint | Foco | Altera código funcional? | Risco |
|--------|------|--------------------------|-------|
| Sprint 0 | Documentação e contratos | ❌ Não | Zero |
| Sprint 1 | Estabilização crítica | ✅ Sim (correções cirúrgicas) | Baixo |
| Sprint 2 | Desacoplamento e interfaces | ✅ Sim (extração de lógica) | Médio |
| Sprint 3 | UX e layout profissional | ✅ Sim (visual incremental) | Baixo |
| Sprint 4 | Funcionalidades ausentes | ✅ Sim (adição de features) | Médio |
| Sprint 5 | Qualidade e preparação ERP | ✅ Sim (refatoração estrutural) | Médio |
| Sprint 6 | Estoque de produtos prontos | ✅ Sim (novo módulo) | Médio |

---

## SPRINT 0 — DOCUMENTAÇÃO E CONTRATOS ✅

**Status:** Em execução  
**Duração estimada:** 1 sessão  
**Entregáveis:**

- [x] `AUDITORIA.md` — diagnóstico completo
- [x] `docs/ARQUITETURA_ATUAL.md` — estado real documentado
- [x] `docs/ARQUITETURA_ALVO.md` — visão ERP-ready
- [x] `docs/CONTRATOS.md` — interfaces e contratos
- [x] `docs/GUIA_DESENVOLVIMENTO.md` — convenções
- [x] `docs/PLANO_MIGRACAO.md` — este arquivo
- [x] `implementation_plan.md` — plano revisado aprovado

**Nenhum arquivo funcional foi alterado neste sprint.**

---

## SPRINT 1 — ESTABILIZAÇÃO CRÍTICA

**Meta:** Zero crashes. Zero erros de compilação. Funcionalidade atual preservada integralmente.  
**Estratégia:** Correções cirúrgicas, menores possíveis.

### Tarefas

| # | Tarefa | Arquivo(s) | Risco |
|---|--------|-----------|-------|
| 1.1 | Adicionar `*.bak` e outputs ao `.gitignore` | `.gitignore` | Zero |
| 1.2 | Corrigir `widget_test.dart` | `test/widget_test.dart` | Zero |
| 1.3 | Corrigir crash `_faixaDialog` (null assertion) | `pages/produtos/produtos_page.dart` | Baixo |
| 1.4 | Corrigir `ConfiguracoesPage.init` — mover para `initState()` | `pages/configuracoes/configuracoes_page.dart` | Baixo |
| 1.5 | Tornar `proximoNumero()` atômico na transação | `database/app_database.dart` | Baixo |
| 1.6 | Adicionar índices ao schema (v3) | `database/app_database.dart` | Baixo |
| 1.7 | Criar `core/utils/formatters.dart` — mover `dinheiro()` e `pedidoNumero()` | Novo + atualizar imports | Baixo |
| 1.8 | Corrigir `taxa.text` inicializado dentro de `build()` | `pages/pedidos/novo_pedido_page.dart` | Baixo |
| 1.9 | Corrigir warnings de `mounted` após await | Múltiplos | Baixo |

**Critério de conclusão:** `flutter analyze` com zero erros. Aplicação abre, navega e salva pedido sem crash.

---

## SPRINT 2 — DESACOPLAMENTO E INTERFACES

**Meta:** Regras de negócio fora das telas. Impressão via interface. Repositórios separados.  
**Estratégia:** Extração sem alterar comportamento — mover código existente, não reescrever.

### Tarefas

| # | Tarefa | Arquivo(s) | Risco |
|---|--------|-----------|-------|
| 2.1 | Criar `core/errors/app_exceptions.dart` | Novo | Zero |
| 2.2 | Criar `domain/ports/impressora_port.dart` | Novo | Zero |
| 2.3 | Criar `domain/ports/*_repository_port.dart` (4 ports) | Novos | Zero |
| 2.4 | Extrair `ValidarFaixasPrecoUseCase` de `GrupoPrecoRepository` | Novo + modif. | Baixo |
| 2.5 | Extrair `RecalcularPrecoUseCase` de `CalculadoraPrecoGrupo` | Novo + modif. | Baixo |
| 2.6 | Criar `BuscarClientePorTelefoneUseCase` | Novo | Zero |
| 2.7 | Criar `data/services/impressora_escpos.dart` implementando `IImpressoraPort` | Novo | Médio |
| 2.8 | Fazer `AppViewModel` injetar `IImpressoraPort` em vez de `ImpressoraService` | `providers/app_view_model.dart` | Médio |
| 2.9 | Separar `repositories.dart` em 4 arquivos individuais | Novos + barrel | Baixo |
| 2.10 | Criar `PedidoProvider` — mover estado do carrinho de `NovoPedidoPage` | Novo + modif. | Médio |
| 2.11 | Criar `core/utils/validators.dart` | Novo | Zero |

**Critério de conclusão:** Nenhuma tela acessa repositório ou banco diretamente. Impressão testável via mock.

---

## SPRINT 3 — UX E LAYOUT PROFISSIONAL

**Meta:** Interface de software comercial. Mínimo de cliques por operação.  
**Estratégia:** Melhorar tela por tela de forma incremental. Nunca apagar e recriar.

### Tarefas

| # | Tarefa | Arquivo(s) | Risco |
|---|--------|-----------|-------|
| 3.1 | Adicionar `google_fonts` ao `pubspec.yaml` | `pubspec.yaml` | Baixo |
| 3.2 | Reescrever `app_theme.dart` — tokens, Inter, cards, inputs | `core/theme/app_theme.dart` | Baixo |
| 3.3 | Criar widgets base: `AppSnackbar`, `ConfirmDialog`, `EmptyState`, `StatusBadge` | `core/widgets/` | Baixo |
| 3.4 | Melhorar `Shell` — logo empresa, animação, divisor visual | `main.dart` | Baixo |
| 3.5 | Melhorar `DashboardPage` — cards com hierarquia, 5 últimos pedidos | `dashboard_page.dart` | Baixo |
| 3.6 | Melhorar `NovoPedidoPage` — autocomplete cliente por telefone, quantidade inline | `novo_pedido_page.dart` | Médio |
| 3.7 | Melhorar `ClientesPage` — busca na lista, formulário com campos nomeados, validação | `clientes_page.dart` | Baixo |
| 3.8 | Melhorar `ProdutosPage` — eliminar N+1 queries, busca, autocomplete categoria | `produtos_page.dart` | Médio |
| 3.9 | Melhorar `HistoricoPage` — chips de filtro, badge de status, detalhes ao clicar | `historico_page.dart` | Médio |
| 3.10 | Melhorar `ConfiguracoesPage` — seções agrupadas, preview cupom | `configuracoes_page.dart` | Baixo |

**Critério de conclusão:** Visual aprovado pelo usuário. Pedido cadastrado em menos de 60 segundos.

---

## SPRINT 4 — FUNCIONALIDADES AUSENTES E IMPRESSÃO

**Meta:** CRUD completo. Impressão funcionando em produção.

### Tarefas

| # | Tarefa | Arquivo(s) | Risco |
|---|--------|-----------|-------|
| 4.1 | `PedidoRepository.alterarStatus()` | `data/repositories/pedido_repository.dart` | Baixo |
| 4.2 | `PedidoRepository.duplicar()` | idem | Baixo |
| 4.3 | `PedidoRepository.cancelar()` | idem | Baixo |
| 4.4 | UI de alterar status no histórico | `historico_page.dart` | Baixo |
| 4.5 | UI de duplicar e cancelar no histórico | `historico_page.dart` | Baixo |
| 4.6 | Reimplementar `ImpressoraEscPos` — USB + TCP/IP + UNC | `impressora_escpos.dart` | Alto |
| 4.7 | Criar `ImpressoraPdf` | `impressora_pdf.dart` | Médio |
| 4.8 | Adicionar `pdf` e `printing` ao `pubspec.yaml` | `pubspec.yaml` | Baixo |
| 4.9 | Criar `PreviewCupomWidget` — texto monospace + botões | `modules/pedidos/widgets/` | Baixo |
| 4.10 | Criar `PedidoDetalheWidget` | `modules/pedidos/widgets/` | Baixo |

**Critério de conclusão:** Pedido pode ser criado, visualizado, ter status alterado, ser duplicado e cancelado. Impressão gera cupom corretamente alinhado.

---

## SPRINT 5 — QUALIDADE E PREPARAÇÃO ERP

**Meta:** Zero warnings. Testes básicos. Estrutura modular pronta para crescer.

### Tarefas

| # | Tarefa | Arquivo(s) | Risco |
|---|--------|-----------|-------|
| 5.1 | Corrigir todos os lint warnings remanescentes | Múltiplos | Baixo |
| 5.2 | Paginação no histórico (`limit/offset`) | `pedido_repository.dart` | Baixo |
| 5.3 | Testes: `ValidarFaixasPrecoUseCase` | `test/` | Zero |
| 5.4 | Testes: `RecalcularPrecoUseCase` | `test/` | Zero |
| 5.5 | Testes: `widget_test.dart` (smoke test) | `test/` | Baixo |
| 5.6 | Criar `modules/estoque/README.md` | Novo | Zero |
| 5.7 | Criar `modules/financeiro/README.md` | Novo | Zero |
| 5.8 | Remover arquivos `.bak` do filesystem (após aprovação do usuário) | Limpeza | Zero |
| 5.9 | Gerar `RELATORIO_FINAL.md` | Novo | Zero |

**Critério de conclusão:** `flutter analyze` limpo. `flutter test` passando. Build de produção limpo.

---

## ESTRATÉGIA DE ROLLBACK

Em cada sprint, antes de alterar qualquer arquivo funcional:

1. O Git serve como backup principal
2. Arquivos `.bak` existentes são mantidos até Sprint 5
3. Toda alteração segue o ciclo: **ler → entender → modificar → verificar**
4. Se uma correção causar regressão, reverter imediatamente e documentar

---

## DEPENDÊNCIAS E PRÉ-REQUISITOS

```
Sprint 0 → nenhum pré-requisito
Sprint 1 → Sprint 0 concluído
Sprint 2 → Sprint 1 concluído (zero erros de compilação)
Sprint 3 → Sprint 2 concluído (interfaces definidas)
Sprint 4 → Sprint 2 concluído (PedidoProvider criado)
Sprint 5 → Sprint 4 concluído
```

---

## MAPA DE EVOLUÇÃO PARA ERP

```
v1.0 (estado atual)
  │
  ├── Sprint 0: documentado
  ├── Sprint 1: estável
  ├── Sprint 2: desacoplado
  ├── Sprint 3: profissional
  ├── Sprint 4: completo
  └── Sprint 5: preparado
              │
              ▼
v2.0 (ERP Fase 1)
  ├── Módulo Estoque
  │     Novas tabelas + repository + use cases + telas
  │     Sem alterar código existente
  └── Módulo Financeiro
        Novas tabelas + repository + use cases + telas
        Sem alterar código existente
```

---

## MAPA DE EVOLUÇÃO — ECOSSISTEMA MULTICANAL

### Fase 1 — ERP Windows (agora)

```
Flutter Desktop → SQLite (Drift)

Objetivo: validar todo o fluxo operacional.
domain/usecases/ já isolados — prontos para migrar sem reescrita.
```

**Entregáveis desta fase (Sprints 1–5):**
- ERP Windows estável e completo
- Cadastros, pedidos, faixas de preço, impressão, histórico
- Módulos de estoque e financeiro (Sprint 5+)
- Código desacoplado via interfaces — migrável sem reescrita

---

### Fase 2 — Backend Go + PostgreSQL (próxima)

```
Flutter Desktop → API REST (Go) → PostgreSQL
                      ▲
              (substitui SQLite)
```

**O que muda no ERP:**
- `data/repositories/` passa a chamar HTTP em vez de Drift
- `domain/`, `modules/`, `providers/`, `core/` → **não mudam nada**
- Autenticação JWT adicionada

**O que o backend Go provê:**
- Todas as regras de negócio (cálculo de preços, validações, status)
- Autenticação e controle de permissões
- WebSocket para notificações em tempo real no ERP
- Endpoints REST documentados (OpenAPI)

**Critério de conclusão:** ERP Desktop funciona idêntico, agora conectado ao backend.

---

### Fase 3 — Portal Web do Cliente

```
Flutter Web → mesma API (Go) → mesmo PostgreSQL
```

**Funcionalidades:**
- Login por telefone/email
- Catálogo de produtos com faixas de preço automáticas
- Composição do pedido com cálculo em tempo real
- Seleção de data, hora e tipo de entrega
- Pagamento: PIX, cartão (via gateway)
- Confirmação → ERP recebe notificação instantânea

**Reutilização de código:**
- `domain/entities/` — mesmos modelos
- Lógica de preços — calculada no backend (não duplicada)
- Componentes Flutter adaptados para Web

---

### Fase 4 — App do Entregador

```
Flutter Android → mesma API (Go) → mesmo PostgreSQL
```

**Funcionalidades:**
- Lista de pedidos do dia por entregador
- Atualização de status: Saiu → Entregue
- Coleta de assinatura digital
- Foto de confirmação de entrega
- GPS tracking (opcional)

---

### Linha do Tempo Ilustrada

```
2026 ──── Fase 1: ERP Windows ──────────────────────────────────────────┐
                   (você está aqui)                                       │
                   Sprints 1→5                                            │
                                                                          │
         ──── Fase 2: Backend Go + migração ERP ─────────────────────────┤
                   Quando o fluxo operacional estiver validado            │
                                                                          │
         ──── Fase 3: Portal Web do Cliente ─────────────────────────────┤
                   Quando o backend estiver estável                       │
                                                                          │
         ──── Fase 4: App Entregador ───────────────────────────────────►┘
                   Quando o portal estiver operacional
```

---

### Integrações que entram pela API (sem impacto nos clientes Flutter)

| Integração | Fase |
|-----------|------|
| PIX via Pagar.me / Asaas | Fase 3 |
| Mercado Pago | Fase 3 |
| WhatsApp — confirmação de pedido | Fase 2 |
| WhatsApp — status de entrega | Fase 4 |
| Nota fiscal eletrônica | Fase 2+ |
| Área do cliente — histórico e favoritos | Fase 3 |
| Repetir último pedido | Fase 3 |
| Pagamento no cartão | Fase 3 |

---

## ESTRATÉGIA DE ROLLBACK

Em cada sprint, antes de alterar qualquer arquivo funcional:

1. O Git serve como backup principal
2. Arquivos `.bak` existentes são mantidos até Sprint 5
3. Toda alteração segue o ciclo: **ler → entender → modificar → verificar**
4. Se uma correção causar regressão, reverter imediatamente e documentar

---

## DEPENDÊNCIAS E PRÉ-REQUISITOS

```
Sprint 0 → nenhum pré-requisito
Sprint 1 → Sprint 0 concluído
Sprint 2 → Sprint 1 concluído (zero erros de compilação)
Sprint 3 → Sprint 2 concluído (interfaces definidas)
Sprint 4 → Sprint 2 concluído (PedidoProvider criado)
Sprint 5 → Sprint 4 concluído
Sprint 6 → Sprint 5 concluído (arquitetura modular estável)
Fase 2   → Sprint 6 concluído (fluxo operacional + estoque validados)
Fase 3   → Fase 2 estável (backend em produção)
Fase 4   → Fase 3 operacional
```

---

*Gerado em Sprint 0. Visão multicanal incorporada em 2026-07-21.*  
*Atualizar status ao final de cada sprint.*

---

# SPRINT 6 — CONTROLE DE PRODUÇÃO E ESTOQUE DE PRODUTOS PRONTOS

**Meta:** Controlar apenas o estoque de produtos prontos, mantendo o sistema simples, rápido e aderente à operação da salgaderia.

> **Importante:** Este sistema **NÃO controlará matéria-prima, ingredientes ou fichas técnicas**. O objetivo é controlar exclusivamente o saldo de produtos acabados disponíveis para venda.

---

## Princípios do módulo

O estoque será baseado em movimentações.

**Nunca alterar diretamente o saldo de um produto.**

Toda alteração deverá gerar uma movimentação de estoque.

Tipos de movimentação:

| Tipo | Quando ocorre |
|------|--------------|
| `PRODUCAO` | Registro de lote produzido |
| `VENDA` | Pedido confirmado (automático) |
| `CANCELAMENTO` | Pedido cancelado após baixa (automático) |
| `AJUSTE` | Ajuste manual com motivo |
| `PERDA` | Quebra, vencimento |
| `DOACAO` | Doação |
| `CORRECAO_INVENTARIO` | Inventário físico |

Todo histórico deverá permanecer armazenado. **Nunca apagar movimentações.**

---

## Estrutura do banco de dados

### Tabela: `EstoqueAtual`

```
produto_id            FK → Produtos (único por produto)
saldo_atual           INTEGER  (em unidades)
ultima_movimentacao   DATETIME
```

> Tabela de leitura rápida — sempre derivada das movimentações. Nunca editar diretamente.

### Tabela: `MovimentacoesEstoque`

```
id                    PK AUTOINCREMENT
produto_id            FK → Produtos
tipo                  TEXT  (PRODUCAO | VENDA | CANCELAMENTO | AJUSTE | PERDA | DOACAO | CORRECAO_INVENTARIO)
quantidade            INTEGER  (sempre positivo; o sinal é dado pelo tipo)
pedido_id             FK → Pedidos (nullable — preenchido em VENDA e CANCELAMENTO)
observacao            TEXT  DEFAULT ''
usuario               TEXT  DEFAULT ''
data_movimentacao     DATETIME  DEFAULT NOW()
```

---

## Alterações em tabelas existentes

### Tabela `Produtos` — novos campos

```
controla_estoque      BOOLEAN  DEFAULT false
estoque_minimo        INTEGER  DEFAULT 0
```

**Nem todos os produtos precisam controlar estoque:**
- Coxinha → `controla_estoque = true`, `estoque_minimo = 20`
- Kibe → `controla_estoque = true`, `estoque_minimo = 10`
- Kit Festa → `controla_estoque = false`
- Produto Sob Encomenda → `controla_estoque = false`

---

## Configuração do modo de operação

Adicionar em `AppSettings` (e na tela de Configurações):

```
modoEstoque: 'INFORMATIVO' | 'RESTRITIVO'
```

| Modo | Comportamento ao vender com saldo insuficiente |
|------|-----------------------------------------------|
| **INFORMATIVO** | Exibe aviso, pergunta se deseja continuar. Permite prosseguir. Ideal para encomendas. |
| **RESTRITIVO** | Bloqueia o pedido quando quantidade solicitada > saldo disponível. Ideal para pronta entrega. |

> **Esta regra viverá no backend Go na Fase 2** — o ERP e o portal web compartilharão o mesmo comportamento mudando apenas uma configuração administrativa.

---

## Telas e módulos

### Estrutura de arquivos

```
lib/
└── modules/
    └── estoque/
        ├── pages/
        │   ├── estoque_page.dart          # Consulta de saldo em tempo real
        │   ├── producao_page.dart         # Registro de produção
        │   ├── ajuste_page.dart           # Ajuste manual
        │   └── historico_movimentacoes_page.dart
        ├── providers/
        │   └── estoque_provider.dart
        └── widgets/
            ├── saldo_badge.dart           # Badge de disponibilidade inline
            └── alerta_estoque_card.dart   # Card para o Dashboard
```

### Use cases (em `domain/usecases/`)

```dart
RegistrarProducaoUseCase      // PRODUCAO — atualiza EstoqueAtual
RegistrarVendaUseCase         // VENDA — chamado ao confirmar pedido
RegistrarCancelamentoUseCase  // CANCELAMENTO — chamado ao cancelar pedido
AjustarEstoqueUseCase         // AJUSTE/PERDA/DOACAO/CORRECAO
BuscarSaldoProdutoUseCase     // leitura rápida de saldo
VerificarDisponibilidadeUseCase // retorna: disponível, atenção ou insuficiente
```

### Repository (em `data/repositories/`)

```dart
// data/repositories/estoque_repository.dart
class EstoqueRepository implements IEstoqueRepository {
  // Drift queries em EstoqueAtual e MovimentacoesEstoque
}
```

---

## Tela: Estoque (consulta)

```
┌────────────────────────────────────────────────────────────────┐
│  ESTOQUE                                       [+ Registrar]   │
│                                                                 │
│  🔍 Pesquisar produto...  [Categoria ▾] [Sem estoque] [Baixo]  │
│                                                                 │
│  Produto          Disponível   Status                           │
│  ─────────────────────────────────────────────────────────     │
│  Coxinha              180      🟢 Normal                        │
│  Kibe                  45      🟡 Atenção (mín. 50)            │
│  Bolinha de Queijo      0      🔴 Sem estoque                   │
│  Kit Festa              —      ⚪ Não controla                  │
└────────────────────────────────────────────────────────────────┘
```

---

## Tela: Produção

Campos:
- Produto (autocomplete — apenas produtos com `controla_estoque = true`)
- Quantidade produzida
- Data
- Observação

Ao salvar → `RegistrarProducaoUseCase` → movimentação `PRODUCAO` + atualiza `EstoqueAtual`.

---

## Tela: Ajuste Manual

Campos:
- Produto
- Tipo: `Entrada` | `Saída`
- Quantidade
- Motivo: Quebra / Perda / Doação / Correção / Outro
- Observação

Sempre gera movimentação. Nunca edita `EstoqueAtual` diretamente.

---

## Integração com pedidos (automática)

### Ao confirmar pedido

Para cada item do pedido:
```
produto.controla_estoque == true?
  └── Sim → RegistrarVendaUseCase(produtoId, quantidade, pedidoId)
             → MovimentacoesEstoque: tipo=VENDA
             → EstoqueAtual: saldo -= quantidade
```

### Ao cancelar pedido

```
Pedido gerou movimentação VENDA?
  └── Sim → RegistrarCancelamentoUseCase(pedidoId)
             → MovimentacoesEstoque: tipo=CANCELAMENTO
             → EstoqueAtual: saldo += quantidade (estorno)
```

---

## Integração com tela de pedidos (NovoPedidoPage)

Ao adicionar produto com `controla_estoque = true`, exibir inline:

```
Coxinha
Disponível: 180 unidades        ← badge verde se OK, laranja se baixo, vermelho se zero
```

Se quantidade solicitada > saldo (modo INFORMATIVO):
```
⚠️ Estoque insuficiente
   Disponível: 180 | Solicitado: 220
   Deseja continuar mesmo assim? [Sim] [Não]
```

Se modo RESTRITIVO:
```
🚫 Estoque insuficiente. Não é possível adicionar este item.
   Disponível: 180 | Solicitado: 220
```

---

## Dashboard — novos cards

```
┌──────────────────────┐  ┌──────────────────────┐
│  Sem estoque         │  │  Estoque baixo        │
│  🔴 3 produtos       │  │  🟡 5 produtos        │
└──────────────────────┘  └──────────────────────┘
```

Abaixo dos cards: lista das **últimas 5 movimentações** com produto, tipo e quantidade.

---

## Histórico de movimentações

Filtros disponíveis:
- Produto
- Tipo de movimentação
- Período (data início / fim)
- Número do pedido (para rastrear VENDA/CANCELAMENTO)
- Usuário

**Nunca apagar movimentações** — apenas auditoria, nunca deleção.

---

## Objetivos ao final da Sprint 6

Ao término, o sistema deverá ser capaz de:

- [x] Controlar saldo de produtos prontos (não matéria-prima)
- [x] Registrar toda movimentação com histórico permanente
- [x] Baixar automaticamente ao confirmar pedido
- [x] Estornar automaticamente ao cancelar pedido
- [x] Registrar produções com data e observação
- [x] Realizar ajustes manuais com motivo e rastreabilidade
- [x] Operar em modo Informativo ou Restritivo (configurável)
- [x] Alertar sobre estoque baixo no Dashboard
- [x] Exibir disponibilidade em tempo real na tela de pedidos
- [x] Manter histórico completo para auditoria
- [x] Respeitar a mesma regra de negócio que o futuro portal web usará

---

> **Nota de escalabilidade:** O campo `modoEstoque` em `AppSettings` e o `VerificarDisponibilidadeUseCase` já estão projetados para ser consumidos pelo backend Go na Fase 2. O portal web do cliente não precisará reimplementar nenhuma regra — apenas chamará o endpoint `/api/estoque/verificar` antes de confirmar um pedido.
