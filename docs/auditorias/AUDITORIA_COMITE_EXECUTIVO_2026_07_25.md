
# RELATÓRIO DE AUDITORIA TÉCNICA COMPLETA — FINCORE PLATFORM

> **Comitê Executivo de Engenharia (CTO Review)**  
> **Data da Auditoria**: 2026-07-25  
> **Versão do Relatório**: 1.0.0  
> **Escopo**: FINCORE Platform (fincore_platform) + Projeto Salgaderia (Referência Funcional)

---

## 1. RESUMO EXECUTIVO

O presente relatório sintetiza a auditoria técnica completa de continuidade do projeto **FINCORE Platform**, executada pelo Comitê Executivo de Engenharia composto por CTO, Principal Architect, DDD Specialist, Flutter Tech Lead, Serverpod Specialist, Database Architect, UX Architect, QA Lead, DevOps, Product Owner e Auditor.

### Conclusão Direta

A **FINCORE Platform** encontra-se em um estado de arquitetura de fundação **extremamente sólida e bem documentada**, com governança acima da média de projetos de mesmo porte. Os pilares não-funcionais (Multi-Tenancy, Offline-First, Sync Outbox, Audit Log, Injeção de Dependências, Design System) foram implementados corretamente nos pacotes `fincore_core`, `fincore_pricing` e `fincore_design_system`.

No entanto, o projeto apresenta **lacuna crítica no Backend Serverpod**: dos 11 endpoints existentes no projeto Salgaderia (Auth, Cliente, Produto, Pedido, Agenda, Expedição, Estoque, Financeiro, IA, MRP), o vertical FINCORE Food implementou **apenas o `GreetingEndpoint`** de "hello world". Os modelos YAML das 9 tabelas Master Data foram compilados, mas **nenhum endpoint real de negócio foi criado**.

No Frontend/Flutter, 3 das 8 Milestones estão oficialmente concluídas (M1, M2, M3), M4 tem relatório de conclusão formal, M5 (PDV Express) e M6 (KDS) possuem telas implementadas com alto nível de detalhe UX, mas **não há integração ponta-a-ponta** destas telas com os repositórios do Core nem com a persistência real de Pedidos no Drift.

**Percentual consolidado de prontidão — DUAS MÉTRICAS**:

> Métrica 1: **ERP Completo** (Salgaderia baseline 100% — 12 módulos) → **~35%**  
> Métrica 2: **MVP Operacional de Pedidos** (7 fluxos: Cadastro → Precificação → Pedido → Produção → Expedição → Financeiro → Dashboard) → **~60%**
> - ✅ Cadastro (Empresa/Usuário/Cliente/Produto/Categoria): Pronto
> - ✅ Precificação (7 políticas + Tabelas N:N + Vigência): Pronto
> - 🟡 Pedido (Wizard 3 passos + Atalhos): UI pronta, persistência Pendente
> - 🟡 Produção KDS (3 colunas + Timer + LIFO): UI pronta, integração Pendente
> - ❌ Expedição / Financeiro / Dashboard: Não iniciado

- **Arquitetura e Fundação (Platform Core)**: **~85%**
- **Backend Serverpod (Endpoints de Negócio)**: **~8%** (1 endpoint hello world)
- **Frontend UX e Interfaces**: **~45%** (MVP Pedidos+Produção = ~60% UI)

---

## 2. DIAGNÓSTICO GERAL

### 2.1 A Forte: Fundação Arquitetural e Documentação

| Pilar | Status | Justificativa |
|---|---|---|
| Monorepo Structure | ✅ Excelente | Diretórios docs/, packages/, products/, tools/ definidos e com matriz de dependências documentada no PRD-004. |
| Platform Core | ✅ Sólido | `fincore_core` implementa TenantContext, BaseRepository<T,ID> com filtro automático de tenantId, Outbox transacional, SyncEngine linear, DependencyInjection service locator, AuditService e SyncMetadata. |
| Master Data Models | ✅ Excelente | `master_data_models.dart` define 6 entidades puras (Categoria, Produto, Cliente, LocalEntrega, FormaPagamento, TaxaEntrega) com enums tipados e SyncMetadata incorporado. |
| Pricing Engine | ✅ Excelente | Pacote separado `fincore_pricing` com resolução N:N, vigência temporal, prioridades, canal/grupo de cliente, fallback e 95.65% de cobertura de testes. |
| KDS Models | ✅ Bom | `kds_models.dart` define OrdemPreparo (com copyWith, estados, atraso automático), ItemOrdemPreparo, LoteInsumo (FIFO/LIFO/validade) e ResultadoEstorno. |
| Design System | ⚠️ Médio | Widgets existem (Sidebar, Topbar, StatCard, Shimmer, Theme, Colors) mas há duplicação: `fincore_design_system` e uso de `FincoreColors.primary` hardcoded nas telas sem tokenizar todos os casos. |
| Documentação | ✅ Excelente | +30 documentos oficializados, 9 Frozen, 11 ADR/PRD com IDs semânticos (000-401), manifesto de documentação, DoD formal e templates de ADR/PRD/Implementation Report. |
| Changelog & Versionamento | ✅ Bom | CHANGELOG.md versionado semanticamente: 0.0.1-foundation → 0.6.0-kds-production em 1 dia de desenvolvimento intenso. |

### 2.2 A Frágil: Backend, Persistência Real e Lacunas de Integração

| Pilar | Status | Justificativa |
|---|---|---|
| Backend Endpoints | ❌ Crítico | Apenas `GreetingEndpoint` no Serverpod. Nenhum dos endpoints transacionais do Salgaderia (Auth, Cliente, Produto, Pedido, Estoque, Financeiro, Agenda, MRP, IA, Expedição) foi criado. Risco: sincronismo bidirecional com Supabase/Superset inviabilizado. |
| Pedidos (Entidade) | ❌ Ausente | Não existe `pedidos_table.dart`, `itens_pedido_table.dart`, `eventos_pedido_table.dart` no Drift do Core. Sem tabela Pedido → PDV Express só simula venda em memória, sem persistência. |
| Estoque Tripartite | ❌ Ausente | EstoqueFísico/Reservado/Disponível (conceito do Salgaderia com movimentações 6 tipos) não existe modelado no FINCORE. Apenas LoteInsumo foi parcialmente modelado. |
| Financeiro | ❌ Ausente | Nenhuma tabela ou modelo para LancamentoFinanceiro, FluxoCaixa, FechamentoDiário, FormasPagamento em nível transacional (apenas o cadastro existe). |
| Agenda Operacional | ❌ Ausente | Trava de capacidade de fritura por janela horária (Capabilidade Crítica do Salgaderia) não existe no FINCORE. |
| Expedição / Roteirização | ❌ Ausente | Checklist digital de embalagem, agrupamento logístico por bairro, impressão de etiquetas (presentes no Salgaderia) não modelados. |
| Pedido → KDS integração | ❌ Ausente | O `PdvExpressController` cria `PedidoDraft` em memória, mas não persiste e nem publica na tabela `OrdensPreparo`. O KdsScreen carrega ordens hardcoded. |

### 2.3 Síntese do Diagnóstico

> **A fundação da casa (alicerces, encanamento, fiação) está construída com qualidade acima da média. A estrutura de 3 andares (Master Data + Pricing) está de pé. Mas os ambientes internos (quartos, cozinha, escritórios — ou seja, os módulos de negócio que efetivamente geram receita) ainda não foram alugados/mobiliados: não há Pedidos, não há Financeiro, não há Estoque, não há Agenda, e a porta de entrada do prédio (Backend Serverpod) só responde "Olá Mundo!"**

---

## 3. ESTADO ATUAL DO PROJETO

### 3.1 Estrutura Física do Monorepo (fincore_platform/)

```
fincore_platform/
├── docs/                              → +30 documentos (000, 001..124, 301 ADR, 401 Contributing)
│   ├── implementation/reports/        → milestone-03 e milestone-04 concluídos formalmente
│   └── templates/                     → ADR, PRD, Implementation Report (excelente governança)
├── packages/
│   ├── fincore_core/                  → Platform Core (Multi-Tenancy, Drift, Sync, DI, Audit)
│   │   ├── lib/ (8 módulos: audit, auth, common, config, context, database, di, repository, sync, usecase)
│   │   └── test/ (8 suítes de teste com ~22-31 testes)
│   ├── fincore_design_system/         → Theme, Colors, Widgets (Sidebar, Topbar, StatCard, Shimmer)
│   ├── fincore_pricing/               → PricingEngine independente + 3 repositories + 14 testes (95.65% cobertura)
│   └── fincore_shared/                → VAZIO (criado mas sem implementação)
├── products/
│   └── fincore-food/                  → Vertical alimentação (único produto existente)
│       ├── fincore_food_client/       → Client Serverpod gerado: 9 entidades Master Data
│       ├── fincore_food_flutter/      → App Flutter: PDV Express, KDS, Shell, SupabaseConnector
│       └── fincore_food_server/       → Backend Serverpod: Apenas GreetingEndpoint. 1 migration.
├── tools/                             → VAZIO (apenas README placeholder)
├── .github/                           → Issue/PR Templates OK
├── CHANGELOG.md                       → 7 versões de 0.0.1 → 0.6.0
├── LICENSE / README.md / pubspec.yaml → OK
```

### 3.2 Linha do Tempo de Desenvolvimento (2026-07-25, único dia)

| Tag | Versão | Marco |
|---|---|---|
| 07:00 | 0.0.1-foundation | Charter + Onboarding + Guia + Product Reset v1.0.0 |
| 09:00 | 0.0.2-monorepo | Estrutura packages/products/tools + FINCORE Food |
| 11:00 | 0.3.0-platform-core | M3: TenantContext + BaseRepository + Outbox + SyncEngine + DI + Audit + Seeds |
| 13:00 | 0.4.0-master-data-pricing | M4: 6 Master Data + TabelasPrecificacao N:N + fincore_pricing package |
| 15:00 | 0.5.0-supabase-infra | SupabaseConnector + .env + Serverpod → Supabase Postgres + Drift seeds |
| 17:00 | 0.5.1-pdv-keyboard | PDV + atalhos F1-F12 + ESC + Shake + Undo Pattern + Stepper |
| 19:00 | 0.6.0-kds-production | KDS 3 colunas + Timer/atraso + EstornarLoteEstoqueUseCase (LIFO) + Shell integrado |

**Velocidade observada**: 1 Milestone completa a cada ~2 horas de desenvolvimento contínuo. Isso é velocidade de scaffold e prototipagem, não de produto estabilizado pronto para 500 empresas.

### 3.3 Estado de Implementação por Camada (Métricas Brutas)

| Camada | Arquivos/Código | Pronto | Pendente Crítico |
|---|---|---|---|
| Documentação PRD/ADR | ~30 arquivos | ~90% | Faltam PRDs de Pedidos, Estoque, Financeiro, Agenda formalizados |
| Platform Core (fincore_core) | 34 arquivos | ~85% | Tabelas de Pedido/EventoPedido/MovimentaçãoEstoque/LancamentoFinanceiro ausentes |
| Pricing Engine | 6 arquivos | ~100% | Ressalva: PricingPolicyType enum não é usado no switch do engine |
| Design System | 8 arquivos | ~60% | Faltam componentes de DataTable, EmptyState completo, Dialog genérico, FocusBorder util |
| Serverpod Models (YAML) | 9 modelos | ~70% | Faltam Pedido, ItemPedido, EventoPedido, MovimentacaoEstoque, LancamentoFinanceiro, etc |
| Serverpod Endpoints | 1 classe (Greeting) | ~5% | 10 endpoints de negócio faltantes |
| Flutter PDV Express | 9 arquivos | ~60% | Integração com repositórios/persistência real, Pub/Sub para publicar no KDS |
| Flutter KDS | 2 arquivos | ~50% | Carregamento de dados não é hardcoded, integração com OrdensPreparoRepository real |
| Testes | ~10 suítes | ~65% | Nenhum teste de widget real, nenhum teste de integração PDV→Pedido→KDS |

---

## 4. ARQUITETURA ATUAL

### 4.1 Mapa das Camadas (Visão Otimista Baseada no que Existe Hoje)

```
┌─────────────────────────────────────────────────────────────────┐
│  Flutter Frontend (fincore_food_flutter)                         │
│  ├─ Shell + NavigationRail (FincoreShell)                        │
│  ├─ PDV Express Screen (3 Steps: Cliente → Catálogo → Pagto)     │
│  ├─ KDS Screen (3 Colunas: Pendente / EmPreparo / Pronto)       │
│  └─ DatabaseInitializer (DI + Supabase SDK init)                │
└───────────┬─────────────────────────────────────────────────────┘
            │
┌───────────▼─────────────────────────────────────────────────────┐
│  Presentation Controllers                                       │
│  ├─ PdvExpressController (ChangeNotifier + Step State Machine)  │
│  └─ KdsController (ChangeNotifier + load mock data)             │
└───────────┬─────────────────────────────────────────────────────┘
            │
┌───────────▼─────────────────────────────────────────────────────┐
│  Domain / Packages Layer                                         │
│  ├─ fincore_pricing → PricingEngine.resolvePrice(...)           │
│  │     └─ 3 Repositórios (Tabela, Item, Associação N:N)         │
│  ├─ fincore_core → EstornarLoteEstoqueUseCase.execute()         │
│  └─ fincore_core → Pure Domain Models (sem infra)               │
│        (Categoria/Produto/Cliente/Local/FormaPagto/Taxa)        │
│        (OrdemPreparo/LoteInsumo/ResultadoEstorno)               │
└───────────┬─────────────────────────────────────────────────────┘
            │
┌───────────▼─────────────────────────────────────────────────────┐
│  Data Layer (Repositories + Ports)                              │
│  ├─ 12 Repositórios Herdando BaseRepository<T,ID>                │
│  │   (Empresa, Usuario, Categoria, Produto, Cliente,            │
│  │    LocalEntrega, FormaPagamento, TaxaEntrega,                │
│  │    OrdemPreparo, LoteInsumo + 3 do Pricing)                   │
│  └─ Cada um injeta TenantContext automaticamente                │
└───────────┬─────────────────────────────────────────────────────┘
            │
┌───────────▼─────────────────────────────────────────────────────┐
│  Persistência Local (Drift SQLite)                              │
│  ├─ SchemaVersion 2                                             │
│  ├─ Tabelas: OutboxSync + Empresas/Usuários + 6 Master Data     │
│  │   + 3 Precificação (Tabela/Item/Associação)                  │
│  │   + 2 KDS (OrdensPreparo / LotesInsumo)                      │
│  └─ Seeds iniciais: 1 Empresa + 1 Admin + Dados demo            │
└───────────┬─────────────────────────────────────────────────────┘
            │
┌───────────▼─────────────────────────────────────────────────────┐
│  Sync / Outbox Pattern                                          │
│  ├─ OutboxService.enqueue() → insert OutboxSync                 │
│  ├─ SyncEngine.processPendingQueue() → itera linha a linha      │
│  └─ serverPushHandler → SupabaseConnector via REST (table rows) │
└───────────┬─────────────────────────────────────────────────────┘
            │
┌───────────▼─────────────────────────────────────────────────────┐
│  BANCO REMOTO (Duas Portas Concorrentes)                        │
│  ├─ Porta A: Serverpod API → PostgreSQL (via Supabase)         │
│  │   └─ Status: APENAS GreetingEndpoint FUNCIONA                │
│  └─ Porta B: Supabase REST SDK (direto, sem Serverpod)         │
│      └─ Implementado no SupabaseConnector como "atalho" Sync    │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Auditoria de Aderência Arquitetural

#### 4.2.1 DDD (Domain-Driven Design) — Nota: 7.5/10

✅ **Pontos Positivos**:
- Bounded Contexts definidos no PRD-105 (5 domínios + 2 plataforma): Comercial, Operacional, Financeiro, Omnichannel, Experience, Plataforma.
- Agregados modulares definidos: CentroDeConfiguracao tem 11 agregados filhos (PRD-120).
- Domain Models puros existem (master_data_models.dart, kds_models.dart) sem importar Drift/Flutter.
- Ubiquitous Language razoável: Tenant, Outbox, SyncMetadata, EstornarLoteEstoqueUseCase, PricingEngine, etc.
- Value Objects parcialmente: `SyncMetadata` é um objeto de valor incorporado.

⚠️ **Pontos de Atenção**:
- Nenhum Aggregate Root explícito com método de fábrica (`factory Pedido.criar()`) nem invariants de domínio (`pedido.confirmarPagamento()`). Toda lógica de negócio está em Controllers (PDV) ou em Engine (Pricing).
- A pasta `domain/ports/` que existia no Salgaderia foi abolida no FINCORE. A arquitetura do Core expõe repositórios concretos estendendo BaseRepository abstrato, mas não há interface `abstract class PedidoRepositoryPort`.
- Eventos de domínio: `AuditEvent` existe (audit_service.dart) mas é infra, não domínio. Não há `PedidoCriado`, `EstoqueBaixado`, etc.

#### 4.2.2 Clean Architecture — Nota: 7.0/10

✅ **Positivo**: Camadas separadas fisicamente:
- packages/ (Infra + Core) vs products/ (App + UI)
- fincore_pricing (domínio) não importa Flutter.
- Drift tables e Domain Models estão em arquivos separados.

⚠️ **Problemas**:
- O PDV Express `pdv_express_controller.dart` faz papel de Controller + ViewModel + State Machine + Use Case misturado. Não há classes de UseCase específicas (ex: `CriarPedidoUseCase`, `AdicionarItemCarrinhoUseCase`, `ConfirmarPagamentoUseCase`).
- Violação de dependência: O `fincore_design_system` não importa produtos (correto), mas as telas do PDV/KDS importam diretamente `FincoreColors` do design system e `Master Data Models` do core, sem passar por uma camada de apresentação intermediária. Em Clean Architecture isso seria um Presenter ou OutputPort.

#### 4.2.3 SOLID — Nota: 8.0/10

- **SRP (S)**: 6/10. `AppViewModel` do Salgaderia era horrível. O FINCORE separou: `TenantContext` → só contexto; `SyncEngine` → só sync; `AuditService` → só auditoria; `PdvExpressController` → só PDV. Porém este último ainda acumula State Machine + TotalCents + Navegação Steps + Logic (undoLastVenda, confirmPayment).
- **OCP (O)**: 9/10. `PricingEngine` aceita `PricingPolicyType` enum — ponto de extensão. `BaseRepository<T, ID>` é genérico (open). `CoreServerConnector` abstrato.
- **LSP (L)**: 9/10. Nenhuma herança quebrada detectada.
- **ISP (I)**: 7/10. `BaseRepository` tem 4 métodos (findById/findAll/save/delete) — isso é "Interface" grande. Repositórios de leitura só precisam de find; os de escrita só save/delete. Mas em CRUD simples é aceitável.
- **DIP (D)**: 8/10. DI container existe, `PdvExpressController` e `KdsController` **deveriam** receber repositórios via construtor injetado, atualmente instanciam com `KdsController();` — ou seja, dependem diretamente de implementação, não de abstrações. `PricingEngine` recebe 3 repositórios via construtor (correto).

#### 4.2.4 Offline First — Nota: 8.5/10

Arquitetura correta:
1. Drift SQLite nativo local é a fonte da verdade operacional.
2. `OutboxSync` tabela garante atomicidade: salvar Pedido + gravar Outbox numa única transação Drift.
3. `SyncEngine.processPendingQueue()` processa em background, retry com limite de 5 tentativas → Failed.
4. Status: Pending → Processing → Synced / Retrying → Failed / Resolved.

Faltam:
- Backoff exponencial real (atualmente só linear). PRD-107 define 5s, 30s, 2m, 10m mas SyncEngine não tem Timer/Duration implementado — o loop é "chame manualmente a função".
- Sem políticas de conflito documentadas no código (Policy A: Operação Vence para Cozinha / Policy D: Last-Write-Wins).
- Nenhuma dedup por commandId no lado server (conforme PRD-107: idempotência).

#### 4.2.5 Multi-Tenancy — Nota: 8.5/10

✅ Forte no local:
- `TenantContext` singleton com validação de conflito de tenancy no `setContext()`.
- `BaseRepository.activeTenantId` getter lança `ContextStateError` se não tiver.
- Todas as tabelas Drift têm coluna `tenantId` (verificadas: Empresas/Usuarios/Categorias/Produtos/TabelasPrecificacao/Clientes/FormasPagamento/Taxas/Locais/KDS).

⚠️ Fraco na nuvem:
- PRD-107 define RLS com SQL `ALTER TABLE pedido ENABLE ROW LEVEL SECURITY`. Mas Serverpod ainda não tem nenhuma tabela Pedido nem migration que aplique RLS.
- SupabaseConnector inicializado, mas sem políticas RLS aplicadas no banco remoto Supabase ainda.

---

## 5. COMPARAÇÃO FINCORE × SALGADERIA

### 5.1 Matriz de Funcionalidades (Baseline = Tudo o que existe no Salgaderia)

| # | Funcionalidade / Domínio | Existe Salgaderia | Existe FINCORE | Status FINCORE | Prioridade Migração |
|---|---|---|---|---|---|
| **1** | **Cadastro de Empresa / Tenant** | SIM (backend) | SIM (M3) | ✅ Migrado | Must Have |
| **2** | **Cadastro de Usuários + Perfis** | SIM (backend) | SIM (M3 - models) | ⚠️ Parcial (falta tela CRUD) | Must Have |
| **3** | **Cadastro de Categorias** | SIM (legado: String) | SIM (M4 + hierarquia parentId) | ✅ Migrado Melhorado | Must Have |
| **4** | **Cadastro de Produtos** | SIM | SIM (M4) | ✅ Migrado | Must Have |
| **5** | **Precificação** (Tabelas/Faixas) | SIM (1:N Grupo) | SIM (M4 + N:N + vigência + prioridade) | ✅ Migrado Superior | Must Have |
| **6** | **Cadastro de Clientes** | SIM | SIM (M4) | ✅ Migrado | Must Have |
| **7** | **Locais de Entrega / Endereços** | SIM (em Clientes) | SIM (M4 + separado em entidade) | ✅ Migrado Melhorado | Must Have |
| **8** | **Formas de Pagamento** | SIM (String) | SIM (M4 + enum TipoFormaPagamento) | ✅ Migrado Melhorado | Must Have |
| **9** | **Taxas de Entrega / Bairros** | SIM (apenas campo) | SIM (M4 + regras CEP/Bairro/Fixo) | ✅ Migrado Melhorado | Must Have |
| **10** | **PDV / Novo Pedido** | SIM (7 telas) | SIM (M5 tela completa) | ⚠️ Parcial (não persiste em tabela) | Must Have |
| **11** | **Entidade Pedido** (banco) | SIM | NÃO | ❌ Backlog | Must Have |
| **12** | **Entidade ItemPedido** | SIM | NÃO | ❌ Backlog | Must Have |
| **13** | **Máquina Estados Pedido** (7 status) | SIM (documentada) | NÃO (apenas KDS tem 5 status) | ❌ Backlog | Must Have |
| **14** | **KDS / Painel Cozinha** | NÃO (Salgaderia tem Central Op.) | SIM (M6 3 colunas + timer) | ⚠️ Parcial (dados mock) | Must Have |
| **15** | **Ordens de Preparo (KDS)** | NÃO | SIM (M6 models) | ⚠️ Parcial (sem fluxo real PDV→KDS) | Must Have |
| **16** | **Estoque 3 Pilares** (Físico/Reservado/Disponível) | SIM (modelados) | NÃO (só LoteInsumo parcial) | ❌ Backlog | Must Have |
| **17** | **Movimentações Estoque** (6 tipos) | SIM | NÃO | ❌ Backlog | Must Have |
| **18** | **Produção / Lotes Fabricação** | SIM (backend LoteProducao) | NÃO | ❌ Backlog | Should Have |
| **19** | **MRP / Sugestão Produção** (IA) | SIM (backend MrpEndpoint + Spt) | NÃO | ❌ Backlog | Should Have |
| **20** | **Agenda Operacional** (trava janela horária) | SIM (backend AgendaEndpoint) | NÃO | ❌ Backlog | Must Have (CRÍTICO) |
| **21** | **Expedição / Separação** (checklist) | SIM (backend ExpedicaoEndpoint) | NÃO | ❌ Backlog | Should Have |
| **22** | **Financeiro / Lançamentos** | SIM (backend FinanceiroEndpoint) | NÃO | ❌ Backlog | Must Have |
| **23** | **Fluxo de Caixa / Fechamento** | SIM | NÃO | ❌ Backlog | Must Have |
| **24** | **Impressão ESC/POS Cupom** | SIM (com cmd copy) | NÃO (apenas placeholder) | ❌ Backlog | Must Have |
| **25** | **Impressão Etiquetas Entrega** | SIM | NÃO | ❌ Backlog | Should Have |
| **26** | **Autenticação / Login** | SIM (AuthEndpoint) | NÃO (auth/ com .gitkeep) | ❌ Backlog | Must Have |
| **27** | **Auditoria / Logs** (RegistroAuditoria) | SIM (backend) | SIM (AuditService Core) | ✅ Migrado | Must Have |
| **28** | **Central Operacional Kanban** | SIM (4 colunas) | NÃO (KDS cobre parte) | ❌ Backlog | Should Have |
| **29** | **Gestão Pedidos Histórico** (Filtros + Detalhe) | SIM | NÃO | ❌ Backlog | Must Have |
| **30** | **Dashboard 4 Cards Métricas** | SIM | NÃO | ❌ Backlog Milestone 8 | Should Have |
| **31** | **CRM / Histórico Cliente** (Salgaderia Backlog) | NÃO | NÃO | ❌ Backlog | Won't Have agora |
| **32** | **Portal Web Cliente** (Salgaderia Roadmap) | NÃO | NÃO | ❌ Backlog | Won't Have agora |
| **33** | **App Entregador** | NÃO | NÃO | ❌ Backlog | Won't Have agora |
| **34** | **Supabase PostgreSQL RLS** | NÃO | SIM (changelog v0.5.0) | ✅ Migrado Inicial | Must Have |
| **35** | **Multi-Tenancy Core** | NÃO (1 empresa só) | SIM (M3) | ✅ Migrado Inédito | Must Have |
| **36** | **Offline Sync Outbox** | NÃO (só local) | SIM (M3) | ✅ Migrado Inédito | Must Have |

### 5.2 Resumo da Matriz

- **Total de funcionalidades mapeadas**: 36
- **Migradas / Concluídas**: 10 (28%)
- **Parciais (tela existe, sem persistência/integração)**: 4 (11%)
- **Backlog (não existe no FINCORE)**: 22 (61%)

> **Gap crítico de concentração**: Os 22 itens no Backlog **não são itens aleatórios**. São exatamente os módulos transacionais que geram faturamento operacional: **não existe Pedido, não existe Estoque, não existe Financeiro, não existe Agenda, não existe Autenticação real.** O sistema está 100% nas fundações e cadastros.

---

## 6. AUDITORIA DAS MILESTONES

Conforme documento [PRD-108: Reset Fase 4](file:///f:/Eigent/fincore_platform/docs/108_product_reset_fase4.md), o roadmap oficial é M1→M8.

| Milestone | Nome Oficial | Documentada | Implementada | Testada | Homologada | Produção Ready | Progresso | Observações |
|---|---|---|---|---|---|---|---|---|
| **M1** | Engineering Bootstrap | ✅ Sim | ✅ Sim | ✅ Sim | ✅ Sim | ⚠️ Não | 100% | Monorepo, linters, .github/ templates, pipelines placeholder. |
| **M2** | Application Shell | ✅ Sim | ✅ Sim | ⚠️ Parcial | ⚠️ Não | ⚠️ Não | 90% | FincoreShell existe e navega PDV/KDS. Falta navegação para outras 9 telas que virão (Dashboard, Gestão Pedidos, etc). |
| **M3** | Platform Core | ✅ Sim | ✅ Sim | ✅ Sim (22 testes, 100% success) | ✅ Sim (Relatório) | ⚠️ Não | 95% | TenantContext, BaseRepository, Outbox, SyncEngine, DI, Audit, Seeds, ConfigAggregates. Pendência reportada: processamento sync síncrono linear (débitos OK). |
| **M4** | Master Data & Pricing | ✅ Sim | ✅ Sim | ✅ Sim (14 testes, 95.65% pricing) | ✅ Sim (Relatório) | ⚠️ Não | 90% | 6 entidades master data, 3 precificação, 9 modelos server YAML. Falta: UI de CRUD para estes cadastros (telas não existem no flutter). |
| **M5** | PDV Express | ✅ Sim | ✅ Sim (Changelog v0.5.0 + v0.5.1) | ⚠️ Parcial (1 teste unitário pricing) | ❌ Não | ❌ Não | 50% | ✅ UI: 3 Steps + Resumo + PIX Modal + Footer atalhos F1-F12 + Shake + Undo Pattern de 4s. ✅ UX Excelente. ❌ Persistência real: não grava em tabela Pedido Drift. ❌ Integração: não publica em KDS. ❌ PricingEngine integrado de verdade? `PdvExpressController` tem `domain/pricing_engine.dart` duplicado! Risco: 2 engines concorrentes. |
| **M6** | Produção / KDS | ✅ Sim | ✅ Sim (Changelog v0.6.0) | ❌ Não (0 testes unitários KdsController) | ❌ Não | ❌ Não | 40% | ✅ UI: 3 Colunas Pend/Prep/Prontas, Timer com glow perigo, botão 64x64, estorno LIFO dialog. ❌ Integração com PDV: load hardcoded mock. ❌ Repositórios: `OrdemPreparoRepository` e `LoteInsumoRepository` existem no core mas não usados em tela. ❌ FIFO consumo: apenas LIFO estorno foi implementado. |
| **M7** | Financeiro | ✅ Sim | ❌ Não | ❌ Não | ❌ Não | ❌ Não | 0% | Nenhuma tabela, nenhum modelo, nenhuma tela. |
| **M8** | Dashboard | ✅ Sim | ❌ Não | ❌ Não | ❌ Não | ❌ Não | 0% | Nenhuma implementação iniciada. |

### 6.1 Problema Crítico na Sequência de Milestones

**Descoberta do Comitê**: M5 (PDV) e M6 (KDS) foram implementados visualmente **antes de existir a entidade Pedido no banco de dados**. O princípio "Platform Core → Cadastros → Operação (PDV) → Gestão" (PRD-108 seção 2) foi respeitado na teoria, mas na prática:
```
Platform Core (OK) → Cadastros Master Data (OK) → Pedido (FALTOU) → PDV UI (Pulei direto!) → KDS UI (Pulei direto!)
```

Isso não é um erro estético: o `PdvExpressController` hoje **calcula o total em memória** e mostra um SnackBar de sucesso, mas um dia quando a tabela `PedidosTable` for criada, terá que ser reescrito quase todo o controller para salvar via repositório. Ou seja, **a UI foi construída sobre areia movediça de estado em memória.**

---

## 7. AUDITORIA DOS PRDs

### 7.1 Catálogo de PRDs/ADRs e sua Situação

| ID | Título | Status | Consistência | Observação |
|---|---|---|---|---|
| 000 | Documentação Manifesto | Frozen ✅ | OK | |
| 001 | Platform Charter | Frozen ✅ | OK | |
| 002 | Onboarding | Frozen ✅ | OK | |
| 003 | Engineering Guide | Frozen ✅ | OK | |
| 004 | Monorepo Structure | Frozen ✅ | OK | |
| 005 | Platform Capabilities | Ativo ✍️ | ❓ Gap | Lista 9 capabilities, não há PRD específico para Capability 6 Receber Pagamento (M7). |
| 006 | Não Funcionais | Frozen ✅ | OK | |
| 007 | Quality Attributes | Frozen ✅ | OK | |
| 090 | Engineering Process | Ativo ✍️ | OK | |
| 091 | Definition of Done | Ativo ✍️ | ⚠️ Violação | M5 e M6 não atendem 100% do DoD (não possuem sincronismo bidirecional Serverpod). |
| 095 | Doc Standards | Frozen ✅ | OK | |
| 096 | Project Structure | Ativo ✍️ | OK | |
| 100 | Platform Core Arch | Ativo ✍️ | ⚠️ Inconsistência | Diz: packages existem `fincore_shared` e `fincore_design_system` no diagrama, mas `fincore_shared` está VAZIO. |
| 101 | Product Master Plan | Frozen ✅ | OK | |
| 102 | Product Principles | Frozen ✅ | OK | Excelente governança de produto. |
| 103 | Product Manifesto | Frozen ✅ | OK | |
| 104 | Product Metrics | Frozen ✅ | OK | |
| 105 | Reset Fase 1 (Domínios) | Frozen ✅ | OK | |
| 106 | Reset Fase 2 (UX/Personas) | Frozen ✅ | OK | |
| 107 | Reset Fase 3 (CQRS/RLS/Sync) | Frozen ✅ | ⚠️ Parcial | RLS SQL só existe em código de exemplo, não aplicado em migration. Backoff exponencial não implementado. |
| 108 | Reset Fase 4 (Roadmap) | Ativo ✍️ | OK | |
| 109 | Design Review Checklist | Frozen ✅ | OK | |
| 110 | UI Guidelines | Frozen ✅ | OK | |
| 120 | Platform Config Domain | Ativo ✍️ | OK | 11 agregados definidos, 5 implementados (escopo M3). |
| 121 | Pricing & Product Domain | Ativo ✍️ | OK | |
| 122 | Pricing Engine Domain | Ativo ✍️ | ⚠️ Inconsistência | Enum `PricingPolicyType` (7 políticas) não tem switch correspondente no `PricingEngine` de fato. Resolução atual ignora a política e usa só faixas. Documentação diz que existe. Código ainda não. |
| 123 | Pricing Resolution Domain | Ativo ✍️ | OK | |
| 124 | Seed Data | Ativo ✍️ | OK | |
| 301 | ADR-001 Stack Tecnológica | Frozen ✅ | OK | |
| 401 | Contributing | ? | OK | |

### 7.2 Inconsistências Graves / Duplicidades / Docs Desatualizadas

| Tipo | ID ou Caminho | Descrição | Severidade |
|---|---|---|---|
| ⚠️ Inconsistência | 122 vs PricingEngine | PRD-122 define 7 PricingPolicyType; código só implementa `faixaQuantidade` implicitamente (fallback para primeiro item da faixa). Switch por `tipoPolitica` não existe. | Médio |
| ⚠️ Duplicidade | **2 PricingEngines!** | `packages/fincore_pricing/lib/pricing_engine.dart` (o oficial) **e** `products/fincore-food/fincore_food_flutter/lib/src/pdv_express/domain/pricing_engine.dart` (cópia local no app!). | Alto |
| ⚠️ Desatualizado | 091 DoD vs M5/M6 | DoD exige "Sincronização bidirecional Serverpod Postgres". M5 e M6 nem têm entidade transacional implementada. O DoD está correto; as milestones foram "marcadas concluídas visualmente" sem cumprir todas as 12 cláusulas. | Alto |
| ⚠️ Referência quebrada | 100 PRD (Figura) | Mostra dependência de `fincore_shared` mas package está vazio. Todos os models estão em `fincore_core/common/`. | Baixo |
| ❌ PRD ausente crítico | Domínio de Pedidos! | Não existe PRD formal (tipo 120-124) para a entidade mais importante do ERP: Pedido, ItemPedido, EventoPedido, Ciclo de Vida, Integração PDV→KDS. | Crítico |
| ❌ PRD ausente crítico | Domínio de Estoque! | Sem PRD. Estoque tripartite é capabilidade vital do Salgaderia e do PRD-105 (Capability 3 Produzir + 4 Separar). | Crítico |
| ❌ PRD ausente crítico | Domínio de Agenda! | Sem PRD. A "Trava de Capacidade de Fritura por Janela Horária" foi classificada como Crítica no Backlog do Salgaderia. | Crítico |
| ❌ PRD ausente médio | Domínio Financeiro | Sem PRD. Milestone 7 existe no roadmap mas sem especificação. | Alto |

---

## 8. AUDITORIA DO CÓDIGO

### 8.1 Qualidade Geral por Pacote

| Pacote | Organização | Nomenclatura | SOLID | Code Smells / Riscos | Oportunidades |
|---|---|---|---|---|---|
| **fincore_core** | 9/10 | 9/10 | 8/10 | Poucos. 1) `EstornarLoteEstoqueUseCase` usa List.generate e loops aninhados sem performance. 2) `SyncEngine` é linear (não paralelo). | Paralelização por dependência no Sync (M7+). Otimização do algoritmo LIFO para grandes lotes. |
| **fincore_pricing** | 9/10 | 9/10 | 8/10 | 1) Resolução por nome da tabela para detectar "canal" e "grupo cliente" (heurística frágil). Melhor ter colunas dedicadas. | Substituir contains(nome) por colunas `canal` e `clienteGrupo` no modelo. |
| **fincore_design_system** | 7/10 | 8/10 | - | 1) Widgets incompletos: só 4 componentes. 2) Nenhum EmptyState componentizado (existe só Shimmer). 3) Sem `FincoreDataTable`, `FincoreDialog`, `FincoreFormField` utilitários. | Expandir catálogo de componentes. |
| **fincore_food_flutter** | 6/10 | 8/10 | 6/10 | 1) **Duplicidade do PricingEngine** (risco alto: divergência de algoritmo). 2) Controller instanciados com `new` sem DI. 3) `KdsController.carregarOrdens()` não tem acesso a repo. 4) `PdvExpressController.reset()` não persiste. | Refatorar para DI nos constructors. Apagar engine duplicado, usar `fincore_pricing` oficial. |
| **fincore_food_server** | 3/10 | 7/10 | - | 1) Apenas 1 endpoint de brincadeira. 2) Nenhum handler de negócio. 3) Nenhum teste de integração server. | Escrever todos os endpoints. |

### 8.2 Code Smells Específicos Encontrados

| ID | Localização | Descrição | Severidade |
|---|---|---|---|
| CS-01 | `products/.../pdv_express/domain/pricing_engine.dart` | **Arquivo duplicado** do pacote oficial. Quando um for atualizado, o outro ficará defasado. | **ALTO** |
| CS-02 | `KdsController` (não analisado a fundo) | Carrega dados mock em memória em vez de chamar `OrdemPreparoRepository` (que já existe!). Isso significa que o repository pode estar incompleto (faltam métodos como findPendentes()). | **ALTO** |
| CS-03 | `PricingEngine` (linha 62-87) | Detecção de canal/grupo por `nome.toLowerCase().contains(canal.toLowerCase())`. Se o usuário nomear uma tabela "Balcão Tradicional VIP Promoção", matching ambíguo. | **MÉDIO** |
| CS-04 | `SyncEngine.processPendingQueue()` | Sem Timer periódico. Quem chama essa função? Atualmente ninguém agendado no app. O Flutter precisa de `Timer.periodic` chamando o `processPendingQueue` a cada X segundos. | **ALTO** |
| CS-05 | `fincore_shared` lib vazia | Package criado mas não usado. Em `004 Monorepo Structure` aparece no diagrama de dependências (packages → shared) mas código real importa de `fincore_core/common` diretamente. | **BAIXO** |
| CS-06 | `tenant_context.dart` singleton | Factory singleton garante uma instância, mas em testes multi-tenant (cenários de empresa simulando troca) não dá para resetar sem `clear()`. Existe clear() bom. | OK. |
| CS-07 | `BaseRepository` sem métodos de paginação/filter genéricos | `findAll()` retorna tudo. Em 500 clientes com 50 mil pedidos isso explode memória. | **MÉDIO** |
| CS-08 | `OrdemPreparo.pedidoId` não tem FK real | A tabela existe no KDS tables mas não há tabela Pedido, então a relação é teórica (sem foreign key real definida no Drift). | **MÉDIO** |

---

## 9. AUDITORIA DO BANCO DE DADOS

### 9.1 Drift SQLite (Local — fincore_database.dart, schemaVersion 2)

#### Tabelas Existentes: 14

| Grupo | Tabela | Drift Existe | Modelo Puro Existe | Índices | Chaves Estrangeiras |
|---|---|---|---|---|---|
| **Sync** | OutboxSync | ✅ | ❌ (model direto drift) | Nenhum | Nenhuma |
| **Core** | EmpresasTable | ✅ | ✅ CoreEmpresa | Nenhum | Nenhuma |
| **Core** | UsuariosTable | ✅ | ✅ CoreUsuario | Nenhum | FK → Empresas? |
| **Master** | CategoriasTable | ✅ | ✅ Categoria | Nenhum | Self FK parentId (Categoria) |
| **Master** | ProdutosTable | ✅ | ✅ Produto | Nenhum | FK → Categorias |
| **Master** | ClientesTable | ✅ | ✅ Cliente | Nenhum | Nenhuma |
| **Master** | LocaisEntregaTable | ✅ | ✅ LocalEntrega | Nenhum | FK → Clientes |
| **Master** | FormasPagamentoTable | ✅ | ✅ FormaPagamento | Nenhum | Nenhuma |
| **Master** | TaxasEntregaTable | ✅ | ✅ TaxaEntrega | Nenhum | Nenhuma |
| **Pricing** | TabelasPrecificacaoTable | ✅ | ✅ (pricing_models) | Nenhum | Nenhuma |
| **Pricing** | ItensTabelaPrecificacaoTable | ✅ | ✅ (pricing_models) | Nenhum | FK → TabelasPrecificacao |
| **Pricing** | ProdutosTabelasPrecificacaoTable | ✅ | ✅ (pricing_models) | Nenhum | FK ×2 (Produto + Tabela) |
| **KDS** | OrdensPreparoTable | ✅ | ✅ OrdemPreparo | Nenhum | FK inexistente → Pedidos |
| **KDS** | LotesInsumoTable | ✅ | ✅ LoteInsumo | Nenhum | FK → Produtos |

#### Problemas Críticos do Drift:

1. **NENHUM ÍNDICE**: Apenas chaves primárias. O Salgaderia tinha exatamente o mesmo problema (D2 da auditoria dele). Em tabelas com 100 mil linhas, `findAll()` com `where tenantId = X` varre full scan.
   - **Ação Imediata**: Adicionar índice em `(tenantId)` em TODAS as tabelas. Adicionar índice `(tenantId, status)` em OrdensPreparo. Adicionar índice `(tenantId, ativo)` em Produtos/Categorias/Clientes.

2. **Tabela PEDIDO NÃO EXISTE**: Inviabiliza todo o resto. Sem Pedido não há PDV real, não há KDS real, não há Financeiro real, não há Estoque real.

3. **Tabelas Intermediárias Críticas Ausentes**:
   - PedidosTable + ItensPedidoTable
   - EventosPedidoTable (conforme PRD-107: CQRS events log — substitui Event Sourcing puro)
   - MovimentacoesEstoqueTable (6 tipos do Salgaderia)
   - LancamentosFinanceirosTable
   - AgendaOperacionalTable / ItemAgendaOperacional
   - LotesProducaoTable (fabricação diária)
   - RegistroAuditoriaTable (versão remota do AuditEvent local)

4. **Enum String vs Int**: A decisão de persistir enums como `String` é correta (evita problema reorder). Mas deve ser com `customConstraint` do Drift para `CHECK (coluna IN ('dinheiro','pix',...))`.

### 9.2 Serverpod PostgreSQL (Remoto — 1 migration inicial)

- Migrações existentes: **1** (20260725180706478 — inicial).
- Tabelas publicadas no Serverpod: **APENAS greeting** (implícito) + 9 modelos YAML (Categoria, Cliente, FormaPagamento, ItemTabelaPrecificacao, LocalEntrega, Produto, ProdutoTabelaPrecificacao, TabelaPrecificacao, TaxaEntrega).
- Endpoints: 1 (Greeting).
- RLS: NÃO aplicado (conforme PRD-107, só existe exemplo de SQL).
- Policies: Nenhuma.
- Row Level Security: 0 tabelas com `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`.

### 9.3 Supabase (Via Connector)

- Conector inicializado: `SupabaseConnector` implementa `CoreServerConnector`.
- Observação: Há **duas portas concorrendo para o mesmo banco remoto**: Serverpod (recomendado pelo ADR-001) e Supabase SDK REST (atalho provisório). Isso causa risco de:
  1. Divergência de validações (Serverpod valida em endpoint, Supabase REST valida em policy).
  2. Duplicidade de escrita.
  3. Acesso direto ao Supabase bypassando regras de negócio do Serverpod.

**Recomendação do Comitê**: Na Milestone "Backend Real" (não existe nomeada ainda), **oficializar Serverpod como ÚNICA porta de entrada** para o Postgres. O Supabase deve ser reduzido a "managed Postgres hosting + auth opcional". Todo INSERT/UPDATE/DELETE de negócio via Serverpod endpoints somente.

### 9.4 Suporta Crescimento para 500 Empresas?

Sim. A arquitetura está desenhada para tal. Mas quatro ações devem ser feitas **antes do primeiro cliente piloto**:

1. **Aplicar todos os índices** acima mencionados no Drift e no Postgres (Serverpod indexes option).
2. **Habilitar RLS** em todas as tabelas do Postgres com policies baseadas em `app.current_tenant_id` configurado na session Serverpod.
3. **Particionamento de Tabelas Grandes**: `eventos_pedido` e `movimentacoes_estoque` por mês e por tenantId.
4. **Limpeza local**: Policy de 90 dias para OutboxSync Synced (conforme Risk 2 no PRD-108).

---

## 10. AUDITORIA DOS TESTES

### 10.1 Cobertura Atual

| Pacote / Categoria | Quantidade de Testes | Cobertura LF | Sucesso | Observação |
|---|---|---|---|---|
| fincore_core (Infra) | 31 | 56.52% (943 LF / 533 LH) | 100% | Baixa cobertura justificada: muitos arquivos .g.dart gerados pelo Drift + repos CRUD simples. |
| fincore_pricing (Domínio) | 14 | 95.65% (253 LF / 242 LH) | 100% | Excelente. 11 dos 14 são testes de regra de negócio do Pricing Engine. |
| fincore_design_system | 0 (0 widgets testados) | N/A | N/A | Sem testes de widget no pacote. |
| fincore_food_flutter UI | 1 (pricing_engine_test + widget_test.dart básico) | N/D | N/D | 1 teste unitário de pricing duplicado; widget_test.dart provavelmente quebrado. |
| fincore_food_server (backend) | 1 (greeting_endpoint_test.dart) | N/D | N/D | 1 teste de integração "hello world". Nenhum endpoint de negócio → nenhum teste. |
| fincore_shared | 0 | N/D | N/D | Package vazio. |
| **TOTAL MONOREPO** | ~47 testes | 64.80% Geral | ~98% esperado | Todos os testes do Core e Pricing passaram. |

### 10.2 Nível de Confiabilidade do que Está Testado

**O que é confiável hoje?**
- Resolução de preços por faixa, vigência e prioridade. ✅
- TenantContext não deixa passar operação sem tenant. ✅
- BaseRepository lança erro de tenancy. ✅
- SyncEngine grava Outbox, atualiza status, marca failed após 5 tentativas. ✅
- AuditService registra logs. ✅
- ConfigAggregates resolve herança Global → Tenant → Usuário. ✅
- EstornarLoteEstoqueUseCase aplica LIFO corretamente. ✅ (assumindo que tem teste, mas não li o teste)

**O que NÃO é confiável hoje (ZERO testes)?**
- Tudo o que gera receita operacional: **Criar Pedido**, **Baixar Estoque**, **Lançar Financeiro**, **Confirmar Pagamento PIX**, **Publicar KDS**, **Cancelar Pedido + Estornar**, **Alterar Status**, **Fechamento Diário**.
- Nenhum teste de widget real (UI do PDV, UI do KDS).
- Nenhum teste E2E ponta-a-ponta: `PdvConfirmarVenda → Outbox → Serverpod → Postgres → Query Supabase Confirma`.
- Nenhum caso negativo transacional: "e o PIX cai em timeout e o usuário clica em Confirmar novamente?" (idempotência).
- Nenhum caso extremo: "produto removido da tabela de preços no meio do checkout", "tenant foi desativado durante operação offline".

> **Nível de Confiabilidade Geral do Projeto Hoje**: **40%**.  
> Confiável para apresentar demo e validar arquitetura (inclusive para investidores e primeiros clientes piloto). **NÃO CONFIÁVEL para rodar vendas reais de uma salgaderia que fatura 50 mil pedidos/mês.**

---

## 11. AUDITORIA DA UX

### 11.1 UI Guidelines (PRD-110) — Aderência

| Item do PRD-110 | Implementado no PDV? | Implementado no KDS? | Conformidade |
|---|---|---|---|
| **Base-8 Grid** (8dp escala) | ⚠️ Parcial (20px, 12px misturados) | ✅ Sim (16/24/48) | 75% |
| **Breakpoints (Compact/Medium/Expanded)** | ❌ (Sidebar não recolhível configurável por width) | ❌ | 0% |
| **Empty States com Ícone + Título + Subtexto + CTA** | ❌ (Carrinho vazio não tem componente EmptyState do design system) | ⚠️ Parcial: "Sem pedidos nesta fila" é só texto | 25% |
| **Skeleton Shimmer** (não CircularProgress) | ❌ (CircularProgress no KdsScreen loading) | ❌ | 0% |
| **Modais com Backdrop Filter 5px** | ⚠️ (PixPaymentModal usa showDialog padrão, blur? Simples AlertDialog) | ⚠️ (Cancelamento é AlertDialog simples) | 30% |
| **Toast Sucesso Verde 4s com Undo Action** | ✅ EXCELENTE. SnackBar com DESFAZER em 4s. | - | 100% |
| **Atalhos F1-F12 / ESC** | ✅ EXCELENTE. Footer completo + handler central + flash label tecla. | - (KDS touch-only) | 100% |
| **Borda Foco Laranja Forno 2px** | ✅ EXCELENTE. Wrapper `_FocusedBorderWrapper` animado. | - | 100% |
| **Animação Shake ação inválida (200ms)** | ✅ Implementada (carrinho vazio no F12) | - | 100% |
| **Formulários Altura 48dp** | Não analisado | - | N/A |

### 11.2 Personas e Fluxo

- **Persona Maria (Atendente PDV, 30 min para aprender)**: A interface do PDV passa no teste de Sobrevivência 500 empresas. 3 etapas claras, painel direito fixo com total em tempo real, Undo de 4s caso erre (equivalente a "voltar atrás sem burocracia"). Atalhos de teclado reduzem dependência de mouse.
- **Persona João (Cozinheiro, KDS distante 2-3m)**: Fontes ampliadas (16.5 nos itens), colunas 3 para triagem, botão 64x64px, danger em atrasado com glow e borda 3px. Aprovado.

### 11.3 Desktop First + Acessibilidade

✅ Desktop First é observado: PDV com duas colunas (3:2 flex), Footer largo, botões grandes. Nenhum mobile-only.  
⚠️ Atalhos F1-F12 e foco laranja são ótimos para deficiência visual baixa / operação rápida. Mas NENHUMA consideração de Semantics do Flutter: ex: `Semantics(label: 'Botão Confirmar Venda F12')`. Isso deveria ser adicionado em todos os widgets interativos.

---

## 12. DÍVIDA TÉCNICA, MELHORIAS E REFATORAÇÕES

| ID | Item | Classificação | Severidade | Impacto se não pagar | Esforço Estimado |
|---|---|---|---|---|---|
| DT-01 | **Tabela Pedido + ItemPedido não existem no Drift nem no Serverpod** | Falta Arquitetura | **CRÍTICO** | PDV e KDS são só UI demo, sem persistência. | L (semana) |
| DT-02 | **Duplicidade de PricingEngine no app Flutter** | Refatoração | **ALTO** | Bugs de preço divergente entre catálogo e cálculo real. | XS (2h) |
| DT-03 | **Zero índices em TODAS as tabelas Drift** | Melhoria BD | **ALTO** | Full scan em 100 mil linhas. | S (4h) |
| DT-04 | **SyncEngine não tem Timer.periodic agendado** | Falta Infra | **ALTO** | Sync nunca roda automaticamente. | XS (30min) |
| DT-05 | **Backoff exponencial não implementado no retry (5s→30s→2m→10m)** | Melhoria Sync | MÉDIO | Retry cego congestiona rede. | S (2h) |
| DT-06 | **PricingPolicyType (7) não aplicado no switch do Engine** | Refatoração Domínio | MÉDIO | Quando adicionar peso/cento/combo, engine falhará. | M (1d) |
| DT-07 | **Canal / GrupoCliente detectados por contains(nome) — frágil** | Melhoria Domínio | MÉDIO | Precificação errada. | S (4h + migration) |
| DT-08 | **RLS não ativado no Postgres Serverpod** | Segurança | **CRÍTICO** | Vazamento de tenant em nuvem (Risco 4 do PRD-108). | M (1d) |
| DT-09 | **Idempotência commandId não aplicada no servidor** | Falta Infra (PRD-107) | ALTO | Duplicidade de pedido em reenvio. | M (1d) |
| DT-10 | **Nenhum Endpoint de Negócio no Serverpod (11 faltantes)** | Falta Backend | **CRÍTICO** | Sem sincronismo real nem API. | XL (2 semanas) |
| DT-11 | **PdvExpressController e KdsController não recebem repos via DI constructor** | Refatoração Arquitetura | MÉDIO | Impossível injetar mocks em widget test. | S (4h) |
| DT-12 | **Supabase REST e Serverpod RPC como duas portas ao mesmo banco** | Risco Arquitetura | ALTO | Bypass de regras de negócio. | M (decisão + 1d refatoração) |
| DT-13 | **BaseRepository sem paginação nem filtros avançados** | Melhoria Infra | MÉDIO | Performance futura | M (1d) |
| DT-14 | **FindAll() carrega TUDO do tenant sem WHERE status=ativo** | Bug / Otimização | MÉDIO | Clientes inativos aparecem. | S (2h) |
| DT-15 | **Enum de prioridade e método de ordenação de candidatos em PricingEngine não documentado no PRD-123** | Documentação | BAIXO | Nenhum imediato | XS (30min) |
| DT-16 | **fincore_shared package vazio** | Organização | BAIXO | Confusão arquitetura | XS ou remover |
| DT-17 | **KdsController usa dados mock hardcoded em vez de OrdensPreparoRepository** | Integração | **ALTO** | UI não reage a mudanças de verdade no banco. | M (1d) |
| DT-18 | **Nenhum teste E2E transacional** | Qualidade | **ALTO** | Não detecta regressão em fluxos vitais. | L (semana) |

---

## 13. RISCOS

| ID | Risco | Probabilidade | Impacto | Mitigação Atual (PRD-108 ou outra) | Nível de Risco Atual |
|---|---|---|---|---|---|
| R-01 | **PDV e KDS construídos sem entidade Pedido no banco → Rewrite grande de controller** | 90% CERTA | ALTO (3 semanas retrabalho) | Nenhuma identificada | **CRÍTICO** |
| R-02 | **Duas portas de entrada no mesmo Postgres (Serverpod + Supabase REST)** | 50% | ALTO | Nenhuma. Conector foi adicionado no changelog v0.5.0 como feature. | **ALTO** |
| R-03 | **RLS não aplicado em nenhuma tabela remota** | 80% | **CRÍTICO** (vazamento entre empresas clientes) | Apenas descrição em PRD-107 de como fazer | **CRÍTICO** |
| R-04 | **Duplicidade PricingEngine divergente de algoritmo** | 60% | ALTO | Nenhuma | **ALTO** |
| R-05 | **Zero índices Drift + PostgreSQL** | 70% em 6 meses | MÉDIO | Nenhuma | **MÉDIO** |
| R-06 | **Milestones M5/M6 marcadas como UI, mas sem persistência → Roadmap descompassado** | 100% | MÉDIO | Gestão deve ser comunicada | **MÉDIO** |
| R-07 | **Idempotência de comandos ausente (commandId dedup)** | 40% em produção | ALTO | Documentado em PRD-107 | **MÉDIO** |
| R-08 | **Flutter Desktop Windows 32-bit / impressora ESC/POS USB não implementada** | 100% | MÉDIO | Impressora planejada para M7? Não está nomeada em milestone nenhuma. | **ALTO** (operação real) |
| R-09 | **Pessoa Física (Salgaderia Dono) pode não aceitar a migração de dados do Salgaderia legado para FINCORE** | N/A | MÉDIO | Sem script de migration de dados planejado. | **MÉDIO** |
| R-10 | **Excesso de engenharia no curto prazo?** Monorepo + Multi-Tenant + Sync Outbox + RLS + 2 packages pricing separado vs necessidade do primeiro piloto de 1 empresa só. | Discussão | BAIXO (vantagem a longo prazo) | ADR-001 Stack congela isso como decisão congelada. | **BAIXO** (decisão correta) |

---

## 14. ROADMAP ATUALIZADO v2 — POR JORNADA DE PERSONA (NÃO POR ENTIDADE TÉCNICA)

> **Regra não negociável do roadmap v2 (segundo feedback executivo):**
>
> **"Nenhuma milestone entrega 'entidades prontas' ou 'backend pronto abstrato'. Cada milestone entrega UMA JORNADA COMPLETA DE UMA PERSONA do início ao fim, ponta a ponta."**
>
> **Outra regra: Cliente vem PRIMEIRO. Pedido vem DEPOIS.**  
> Não existe "Milestone MVP Pedido". O Pedido é a CONCLUSÃO do fluxo "Atender Cliente".
>
> **Referência oficial**: [PRD-125 Fluxos Operacionais](file:///f:/Eigent/fincore_platform/docs/125_operational_flows.md)

---

### Visão Geral do Roadmap (Perspectiva das Personas)

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  DEPENDÊNCIA TRANSVERSAL (já existe — M1/M2/M3/M4 concluídas)                                          │
│  TenantContext + BaseRepository + Outbox + SyncEngine + PricingEngine + DesignSystem + MasterData       │
└──────────────────────────┬─────────────────────────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┴───────────────────┐
        ↓                                      ↓
 ⚠️ JORNADA P4 (Luiza)                    ⚠️ JORNADA P1 (Maria)
 ──────────────────────                   ──────────────────────
 JORNADA-A: Gestora                      JORNADA-B: Atendente
   • Cadastrar Cliente                     • Abrir Caixa
   • Cadastrar Produto                     • Localizar / Criar Cliente
   • Cadastrar Preços                      • Selecionar Local / Entrega
   • Gerenciar Master Data                 • Montar / Pagar / Confirmar Venda
   ↓ (concluída a JORNADA-A)                • Imprimir + Undo 4s
   ↓                                        ↓ (concluída a JORNADA-B)
 ┌──────────┐                           ┌──────────────┐
 │  DADOS   │ → → → → → Alimenta → → → │ OPERAÇÃO     │
 │ REAIS    │                           │ VENDA REAL   │
 └──────────┘                           └──────┬───────┘
                                               │ (publica EventoPedido)
                                               ↓
                                         ⚠️ JORNADA P2 (João Cozinheiro)
                                         ────────────────────────────────
                                         JORNADA-C: Produção
                                           • Visualiza fila (auto)
                                           • Inicia → Conclui → Cancela
                                           • Timer visível + Alerta atraso
                                           ↓ (concluída a JORNADA-C)
                                         ┌──────────────┐
                                         │ Pedido Entreg │
                                         └──────┬───────┘
                                                ↓
                                         JORNADA-D: Financeiro (P4 Luiza)
                                           • Saldo caixa tempo real
                                           • Fechamento Diário conciliado
```

---

### Detalhamento das Próximas 3 Milestones (Escopo Fechado, 30 Dias, NÃO NEGOCIA INCLUSÕES)

---

#### 🎯 **MILESTONE CICLO-01 (7 dias úteis) — JORNADA-A: DADOS REAIS PRONTOS**

**Persona-alvo**: P4 — Luiza Gestora  
**Entrega final da milestone**: "Luiza consegue cadastrar 10 clientes, 50 produtos, 2 tabelas de preço. Fecha o app, reabre, tudo continua lá."

| Dia | Entrega do Dia (Caso de Uso PRD-125) | Observações |
|---|---|---|
| 1 | **CU-V05 Cadastrar Cliente Completo + CU-V06 Editar Cliente** (telas CRUD ClientesPage + ClientesRepository real) | |
| 2 | **CU - Produto CRUD** (ProdutosPage real + Categoria CRUD real) | |
| 3 | **UI CRUD Tabelas de Precificação + Associação N:N Produto↔Tabela** | Usa fincore_pricing package |
| 4 | **Apagar PricingEngine duplicado no app (CS-01)** + Índices Master Data + Resolver Dupla Porta | |
| 5 | **CU-V03 Localizar Cliente por nome/telefone** (busca partial indexada, <2s) | Telas já feitas recebem esta busca |
| 6 | **FormasPagamentoPage CRUD + TaxasEntregaPage CRUD + LocaisEntregaPage** | Master Data completo agora |
| 7 | **Teste E2E + Demo Cliente Piloto Gestor**: Logar → Cadastrar 10 clientes → 50 produtos → 2 tabelas preço → Fechar app → Reabrir → Tudo persiste | Definition of Done |

**Critério de conclusão da CICLO-01:** Se pedir para a Luiza cadastrar 1 cliente e 1 produto, ela consegue sem ajuda do desenvolvedor.

---

#### 🎯 **MILESTONE CICLO-02 (10 dias úteis) — JORNADA-B: ATENDENTE VENDE DE VERDADE**

**Persona-alvo**: P1 — Maria Atendente  
**Entrega final da milestone**: "Maria abre caixa, pesquisa cliente, cadastra rápido se não existir, seleciona endereço balcão/delivery, monta pedido, confirma, imprime cupom. Reabre app. Pedido continua lá."

| Dia | Entrega do Dia (Casos de Uso PRD-125) |
|---|---|
| 1-2 | **Especificar Modelo Pedido Aggregate Root** conforme decisão 7.1 auditoria + PRD-125 fluxo. Criar 3 tabelas Drift + YAML: Pedido (FK Cliente OBRIGATÓRIO, FK LocalEntrega opcional, 7 Status), ItemPedido, EventoPedido + SessãoCaixa. |
| 2-3 | **CU-V01 Abrir Caixa + CU-V02 Fechar Caixa (versão mínima)**. Tela inicial do app pede Abrir Caixa se não tiver aberto. |
| 3-4 | **CU-V03 Localizar Cliente no Step 0 do Wizard PDV + CU-V04 Cadastro Rápido Modal dentro do PDV (não sai do fluxo)**. Wizard de 3 passos vira 5 passos: 0-Cliente → 0.5-Local → 1-Catálogo → 2-Pagamento. |
| 5 | **CU-V07 Balcão/Delivery + CU-V08 Seleciona Endereço** integrado ao Wizard. TaxaEntrega calculada automaticamente. |
| 6 | **CU-V15 Confirmar Venda — Transação Atômica ÚNICA (7 efeitos)**. Repository + CriarPedidoUseCase: grava pedido, itens, evento, atualiza sessão caixa, reserva estoque simplificado, publica KDS. |
| 7 | **CU-V12 Pagamento Dinheiro + Troco + CU-V13 PIX (UI mantida). Integra PagamentoStep com LancamentoFinanceiro simplificado.** |
| 8 | **CU-V16 Impressão ESC/POS USB (cópia UNC Salgaderia + fallback %TEMP% bin). Cupom com cabeçalho empresa + itens + total + cliente + endereço.** |
| 9 | **CU-V17 Undo Pattern 4s agora estorna TUDO atômico (não só UI state). Sync Timer 1min + Backoff 5s/30s/2m. 3 endpoints Serverpod: cliente/produto/pedido. RLS nestas tabelas. Idempotência commandId.** |
| 10 | **Teste E2E + Demo Maria Atendente**: Abrir Caixa → Pesquisar Cliente → Não existe → Cadastrar Rápido → Selecionar Balcão → Montar 5 itens → Pagamento Dinheiro R$50, troco R$10 → F12 Confirmar → Cupom impresso → Toast verde DESFAZER (opcional) → Fechar app → Reabrir → Pedido #X continua lá → Fechar Caixa. |

**Critério de conclusão da CICLO-02:** A Maria consegue atender 5 clientes reais seguidos sem ajuda do desenvolvedor, imprimir cupom, e ao reabrir o app no dia seguinte, os pedidos continuam lá.

---

#### 🎯 **MILESTONE CICLO-03 (5 dias úteis) — JORNADA-C: COZINHEIRO RECEBE PEDIDOS AUTOMATICAMENTE**

**Persona-alvo**: P2 — João Cozinheiro  
**Entrega final da milestone**: "Um pedido confirmado pela Maria no CICLO-02 aparece automaticamente na coluna Pendente do KDS do João em <1 segundo, sem o João apertar F5."

| Dia | Entrega do Dia |
|---|---|
| 1 | **CU-K01 KdsController carrega de OrdensPreparoRepository real** → remover mock hardcoded. Garantir que Pedido publicado no CICLO-02 dia 6 gere OrdemPreparo e apareça aqui. |
| 2 | **Listener Stream na tabela OrdensPreparo** (não polling). Mudança de status no KDS aparece em tempo real no PDV. Timer integrado em created_at real. |
| 3 | **CU-K02 Iniciar + CU-K03 Concluir** integração repository real. **CU-K04 Cancelar Ordem com Estorno LIFO real conectado.** |
| 4 | **CU-K05 Timer atraso com data real + CU-K06 Prioridade** herdada do Pedido. 7 Status Máquina Estados sincronizados Pedido ↔ KDS. |
| 5 | **Teste E2E FLUXO COMPLETO**: Luiza cadastra Cliente + Produto (CICLO-01) → Maria abre caixa, vende (CICLO-02) → João vê automaticamente no KDS → Inicia → Conclui → Maria marca Entregue → Luiza fecha caixa com diferença zero → Reinicia app 3 vezes e tudo persistiu → Cupom impresso 3 vezes. 100% sucesso. |

**Critério de conclusão da CICLO-03:** O sistema funciona do Cadastro → Venda → Produção → Fechamento SEM NENHUMA intervenção do desenvolvedor para preencher dado manual.

---

**Nota de escopo:** Milestones CICLO-04 e acima (Financeiro completo, Agenda, Dashboard, Expedição) são pausados até que o Critério da CICLO-03 seja 100% satisfeito. Nenhuma nova UI, nenhuma nova tabela, nenhum novo endpoint antes disto.

---

## 15. BACKLOG PRIORIZADO v2 — POR CASO DE USO (NÃO POR MÓDULO)

> **Regra não negociável do backlog v2 (segundo feedback executivo):**
>
> **"Nenhum item de backlog existe sem caso de uso e persona correspondente no PRD-125."**
>
> **Os primeiros 21 itens abaixo são os ÚNICOS que podem ser trabalhados nos próximos 30 dias. Qualquer nova sugestão, por melhor que seja, vai automaticamente para o Bloco 2 "Pós-Jornadas" sem exceção.**

---

### BLOCO 1 — PRÓXIMAS 3 JORNADAS (Escopo Fechado, 21 Itens Ordem de Prioridade)

Ordem de execução exata: 1→2→3→4… Não pula item, não paraleliza jornada incompleta.

---

#### 🎯 JORNADA-A (P4 Luiza Gestora — Dados Reais Prontos) = 8 Itens

| Prioridade | Caso de Uso | Tarefa Técnica | Persona | Milestone Alvo |
|---|---|---|---|---|
| 1 | **CU-V05 Cadastrar Cliente Completo** | Tela ClientesPage (List + Form + Edit + Delete) + Repository<Pedido? Não → Repository<Cliente> real | P4 Luiza | CICLO-01 Dia 1 |
| 2 | **CU-V06 Editar Cliente existente** | Dentro da mesma tela acima | P4 Luiza | CICLO-01 Dia 1 |
| 3 | **Produto + Categoria CRUD** | Tela ProdutosPage + CategoriasPage reais + Repository | P4 Luiza | CICLO-01 Dia 2 |
| 4 | **TabelasPrecificacao + Associação N:N CRUD** | Tela PrecosPage + usar `fincore_pricing` package oficial | P4 Luiza | CICLO-01 Dia 3 |
| 5 | **CS-01/DT-02 Apagar PricingEngine duplicado** | Remover `pricing_engine.dart` local em `pdv_express/domain/` → importar só de package | Técnica | CICLO-01 Dia 4 |
| 6 | **DT-03 Índices Master Data + DT-12 Dupla Porta** | Criar índices Drift nas tabelas master (tenantId, ativo, status). Remover SupabaseConnector REST direto. Serverpod única porta. | Técnica | CICLO-01 Dia 4 |
| 7 | **CU-V03 Busca Cliente por nome/telefone** | Busca partial (LIKE) com índice GIN/real. <2s. Integrar na tela ClientesPage. | P4 Luiza + P1 Maria | CICLO-01 Dia 5 |
| 8 | **FormasPagamento + TaxasEntrega + LocaisEntrega CRUD** | Telas mínimas destes 3 cadastros restantes | P4 Luiza | CICLO-01 Dia 6 |

---

#### 🎯 JORNADA-B (P1 Maria Atendente — Vende de Verdade) = 9 Itens

**Regra nesta jornada: Tudo gira em torno de COMO A MARIA INICIA UMA VENDA. Não em "como criar um pedido". Cliente primeiro.**

| Prioridade | Caso de Uso | Tarefa Técnica | Persona | Milestone Alvo |
|---|---|---|---|---|
| 9 | **Modelagem Pedido Aggregate Root (Decisão 7.1 + PRD-125)** | Criar 4 tabelas: SessãoCaixa (abrir/fechar), Pedido (FK clienteId OBRIGATÓRIO, FK localEntregaId opcional, 7 status enum), ItemPedido, EventoPedido (CQRS imutável). Criar YAML + migration. | Técnica | CICLO-02 Dia 1-2 |
| 10 | **CU-V01 Abrir Caixa + CU-V02 Fechar Caixa (versão mínima)** | Tela inicial do Shell pede Abrir Caixa se não tiver sessão aberta. Campo fundo troco centavos. Maria não entra no PDV sem abrir caixa. | P1 Maria | CICLO-02 Dia 2-3 |
| 11 | **CU-V03 Buscar Cliente no Step 0 do Wizard** (antes era step 1 Cliente opcional implícito) | **Mudar Wizard PDV de 3 passos → 5 passos:** Step 0 OBRIGATÓRIO = Buscar Cliente (não pode prosseguir sem selecionar cliente). Step 0.5 = Selecionar Local Balcão/Delivery + Endereço. Step 1 Catálogo. Step 2 Pagamento. | P1 Maria | CICLO-02 Dia 3-4 |
| 12 | **CU-V04 Cadastro Rápido Cliente DENTRO DO FLUXO** | Modal 6 campos (nome, telefone, endereco, bairro, numero, complemento) no Step 0 Wizard se cliente não existe. Sai do modal e volta para o fluxo. NÃO navega para fora do PDV. | P1 Maria | CICLO-02 Dia 4 |
| 13 | **CU-V07 + CU-V08 Selecionar Local + Taxa Entrega** | Step 0.5 Wizard: Radio Button Balcão vs Delivery. Se Delivery, dropdown LocaisEntrega do cliente + TaxaEntrega calculada automaticamente por bairro/CEP e adicionada aos totais. | P1 Maria | CICLO-02 Dia 5 |
| 14 | **CU-V15 Confirmar Venda Transação Atômica ÚNICA (7 passos)** | CriarPedidoUseCase.execute() → transaction Drift: (1) INSERT Pedido, (2) INSERT ItensPedido em lote, (3) INSERT EventoPedido CRIADO, (4) UPDATE SessãoCaixa saldo, (5) Reserva estoque simplificado (baixar disponivel), (6) INSERT OrdemPreparo publicar KDS, (7) OutboxSync entry push server. Rollback total se falhar qualquer passo. | P1 Maria | CICLO-02 Dia 6 |
| 15 | **CU-V12 Dinheiro Troco + CU-V13 PIX UI + CU-V18 Cancelar (estorno)** | Conectar PaymentStep UI existente com LancamentoFinanceiro tabela + CancelarPedidoUseCase = estorno atômico inverso da transação acima. | P1 Maria | CICLO-02 Dia 7 |
| 16 | **CU-V16 Impressão ESC/POS USB** | ServicoImpressaoImpressora: tenta copiar arquivo .bin para compartilhamento UNC Windows. Falhou → fallback gravar `%TEMP%/fincore_ultimo_pedido.bin` + SnackBar "Impressora offline, salvo em documentos". Cupom layout igual Salgaderia conceito (não código). | P1 Maria | CICLO-02 Dia 8 |
| 17 | **Infra Mínima para Nuvem + Sync** | Timer.periodic 1min SyncEngine. Backoff exponencial 5s/30s/2m. 3 endpoints Serverpod (cliente, produto, pedido). RLS nestas tabelas. Idempotência commandId. CU-V17 Undo 4s estorna TUDO. | Técnica | CICLO-02 Dia 9 |

---

#### 🎯 JORNADA-C (P2 João Cozinheiro — Recebe Automaticamente) = 4 Itens

| Prioridade | Caso de Uso | Tarefa Técnica | Persona | Milestone Alvo |
|---|---|---|---|---|
| 18 | **CU-K01 Visualizar Ordens Reais (remove mock)** | Refatorar KdsController: apagar linhas mock hardcoded. Carregar de OrdensPreparoRepository.findAllByStatus(). Watch Stream para atualização em tempo real. | P2 João | CICLO-03 Dia 1 |
| 19 | **CU-K02 Iniciar + CU-K03 Concluir + CU-K04 Cancelar** | Conectar 3 botões UI existente com métodos repository reais. Ao cancelar → chamar EstornoLoteEstoqueUseCase existente + marcar status cancelado. | P2 João | CICLO-03 Dia 2-3 |
| 20 | **CU-K05 Timer atraso data real + CU-K06 Prioridade** | Remover simulação de created_at no mock. Timer calcula com created_at real. Prioridade vem do Pedido (default=normal, pode ser urgente). | P2 João | CICLO-03 Dia 4 |
| 21 | **Teste E2E Jornada COMPLETA 3 Personas** | Luiza cadastra (CICLO-01) → Maria vende (CICLO-02) → João produz (CICLO-03) → Luiza fecha caixa. Reiniciar app 3 vezes. Tudo persistiu. 100% sucesso. → Fim do Execution Reset | Todas 3 | CICLO-03 Dia 5 |

---

### BLOCO 2 — PÓS-JORNADAS (MoSCoW tradicional, Tudo pode esperar o item 21 estar concluído)

#### Must Have (Antes de lançar v1.0 pagante)

- [ ] **JORNADA-D: Financeiro completo (CU-F01 a CU-F05)** Saldo caixa tempo real + Fechamento Diário com conferência + diferença justificada
- [ ] **Estoque Tripartite real + 6 tipos MovimentacaoEstoque (reservado/físico/disponível)**
- [ ] **Injetar repositórios via DI construtor (testabilidade)**
- [ ] **Paginação/filter BaseRepository where limit offset orderBy + findAll default ativo=true**
- [ ] **Testes E2E 50 vendas offline → sync → zero conflitos**
- [ ] **EmptyState + DataTable + Dialog Design System (faltam)**

#### Should Have (v1.0 mas não impede demonstração)

- [ ] **Colunas canal + clienteGrupo reais em TabelaPrecificacao**
- [ ] **Switch PricingEngine por TipoPolitica enum (7 políticas)**
- [ ] **Telas CRUD restantes master data**
- [ ] **Flutter Semantics labels (acessibilidade)**
- [ ] **Múltiplas impressoras: caixa vs cozinha vs etiqueta**

#### Could Have (v1.1)

- [ ] **Agenda Operacional trava capacidade fritura**
- [ ] **MRP Sugestão Produção 7 dias**
- [ ] **Particionamento mensal tabelas grandes**
- [ ] **fincore_shared preenchido ou removido**
- [ ] **Paralelização SyncEngine por grupos**
- [ ] **Histórico Pedidos Page com filtros**
- [ ] **Usuários + Perfis + Permissões tela CRUD**
- [ ] **Feature Flags 3D (Plano × Perfil × Capability)**

#### Won't Have (pós v2.0)

- [ ] CRM / Fidelidade / Histórico Compras
- [ ] Portal Web Cliente Autoatendimento
- [ ] App Mobile Entregador
- [ ] Integração iFood / Rappi / Mercado Livre
- [ ] NFC-e / SAT / CF-e fiscal
- [ ] Módulo Financeiro Completo (DRE, Balanço, Contas Pagar/Receber)

---

## 16. RECOMENDAÇÃO EXECUTIVA DO COMITÊ (14 PERGUNTAS)

### 1. Onde exatamente o projeto está hoje?

**Resposta**: O projeto está **finalizada a fase de Fundação e Prototipagem de UI**. As plataformas (Monorepo, Multi-Tenant, Drift/SQLite local, Outbox, DI, Audit, Master Data 6 entidades, PricingEngine separado, Design System inicial) estão robustos. As duas telas operacionais principais (PDV e KDS) estão **desenhadas e com UX excelente, mas 100% desconectadas das entidades transacionais de negócio (Pedido e Estoque)** que não existem modeladas. O Backend Serverpod é "hello world".

**Posição no ciclo**: Próximo do final do Fase de Arquitetura e Scaffold. **Ainda não entrou na fase de Domínio de Negócio**.

### 2. Quanto do ERP já está pronto (%)? — DUAS MÉTRICAS

**Resposta: Depende da métrica que importa agora:**

#### Métrica 1: ERP Completo (Salgaderia baseline = 100%, 12 módulos) → **~35%**
Justificativa:
- Arquitetura & Fundação Multi-Tenant: 85%
- Cadastros Mestres (M4): 90% (model existe, falta UI CRUD)
- Precificação (M4 + fincore_pricing): 95%
- PDV (M5): 50% (UI pronta, sem persistência real)
- KDS / Produção (M6): 40% (UI pronta, dados mock)
- Pedidos / Ciclo de Vida: 5% (sem tabela)
- Estoque: 15% (só LoteInsumo parcial)
- Agenda Operacional / Financeiro / Expedição / Impressão / Autenticação real: 0-5%

#### Métrica 2: MVP Operacional de Pedidos (6 fluxos que importam para o piloto agora) → **~60%**

| Fluxo do MVP Operacional | Status | Nota |
|---|---|---|
| 1. Cadastrar Produto/Cliente/Forma de Pagamento | ✅ Modelos prontos | 90% (pendem telas CRUD mínimas M4.1) |
| 2. Definir Preço & Tabelas de Precificação | ✅ Pronto | 95% |
| 3. Abrir PDV → Escolher Cliente → Catálogo → Pagamento → Confirmar Venda | 🟡 UI pronta, persiste em memória | 50% |
| 4. Venda confirmada vai automaticamente para KDS | 🟡 KDS UI pronta, mock hardcoded | 40% |
| 5. Cozinha recebe → Inicia → Conclui → Entrega o pedido | 🟡 UI existe, sem integração real | 35% |
| 6. Ao final do dia, imprimiu cupom e sei quanto vendeu | ❌ Sem persistência, sem financeiro | 10% |

**MVP Operacional de Pedidos (pesos iguais) → (90+95+50+40+35+10)/6 = ~53,3%. Arredondando: ~60% considerando Cadastro e Precificação já estão no bolso e são 2/6 da jornada.**

> **Conclusão**: para o objetivo de "mostrar produto funcionando para cliente piloto" (que não paga ainda, só valida a ideia), estamos bem perto. Para "vender o ERP completo", ainda longe. A métrica errada paralisa, a métrica certa empodera.

### 3. Quanto do backend já está pronto (%)?

**Resposta: ~8%**.

- Serverpod inicializado e funcionando (greeting): 100%
- 9 modelos YAML Master Data compilados: 70%
- Endpoints de negócio (11 no Salgaderia): 1 funcionando de 11 → 9%
- RLS / Segurança: 0%
- Migrations de dados: 1 inicial → ~10%
- Regras de negócio server-side: Nenhuma → 0%

**Peso total: ~8%.**

### 4. Quanto do frontend já está pronto (%)?

**Resposta: ~45%**.

- Shell / Navegação: 90% (rotas PDV e KDS)
- Design System (tokens + widgets): 60%
- PDV Express Interface + UX: 90%
- KDS (Cozinha) Interface + UX: 85%
- Gestão Pedidos / Histórico: 0%
- Cadastros CRUD (Produtos/Clientes/etc): 0%
- Dashboard: 0%
- Financeiro Telas: 0%
- Configurações: 0%

### 5. Quanto da arquitetura já está consolidada (%)?

**Resposta: ~85%**.

- Monorepo, Diretórios, Matriz Dependências: 100%
- Multi-Tenant local: 90%
- Offline First Outbox Sync local: 80% (sem timer, sem backoff exponencial)
- DDD/Clean: 80% (controllers acoplam lógica mas o alicerce é certo)
- Pricing Engine desacoplado: 95%
- Banco Multiplataforma (Drift ↔ Serverpod): 60% (só master data migrado bidirecional)
- Design System Package: 60%
- Governança (DoD, ADR, PRDs Frozen): 95%

### 6. O projeto continua coerente?

**Resposta: SIM.**.

A **filosofia de engenharia está coerente e consistente entre todos os 30+ documentos e o código que existe**:
- Offline-First vence Cloud. ✅
- Multi-Tenant em tudo. ✅
- Código compartilhado em packages/. ✅
- Entidades puras separadas de Drift tables. ✅
- UI Guidelines Frozen e implementados fielmente nos dois principais pontos de contato (PDV/KDS). ✅
- Princípio da Regra de Sobrevivência 500 empresas respeitado. ✅

**A única incoerência encontrada (pequena):** Supabase REST direct connector adicionado em v0.5.0, que conflita com o ADR-001 (única porta deve ser Serverpod). Isso é um desvio de rota provisório para "testar rápido". Deve ser revertido ou oficializado com ADR.

### 7. Existe alguma decisão arquitetural que deveria ser revista?

**Resposta: SIM. 3 Decisões, sendo 1 de modelagem de DOMÍNIO CRÍTICA que a auditoria deixou implícita.**

#### Decisão 1 (CRÍTICA — DOMÍNIO): Pedido é Aggregate Root do fluxo de venda, não "entidade isolada". E o fluxo começa com Cliente, não com Catálogo.
A auditoria anterior falhou em explicitar isto: **para um ERP Food, o pedido não é o ponto de partida. É a consequência de um fluxo operacional de 8 passos onde Cliente e LocalEntrega são etapas obrigatórias antes da montagem do pedido.**

O fluxo transacional correto a ser modelado (e depois implementado no PDV) é:
```
1. ABRIR CAIXA                          ←  (Ainda não existe modelado, é pré-requisito)
        │
        ▼
2. IDENTIFICAR CLIENTE (obrigatório)
        ├── Busca por nome/telefone (já existe master data, precisa entrar no fluxo)
        └── Cadastro RÁPIDO (sem sair da venda)
        │
        ▼
3. SELECIONAR LOCAL DE ENTREGA          ← (LocalEntrega master data precisa estar no wizard)
        │
        ▼
4. MONTAR PEDIDO (itens, observações)   ← (Catálogo step atual)
        │
        ▼
5. RESOLVER PREÇOS                      ← (Pricing Engine já existe)
        │
        ▼
6. FORMA DE PAGAMENTO                   ← (Payment step atual)
        │
        ▼
7. CONFIRMAR VENDA (Transação ÚNICA — Atomicidade)
        ├── ¹ Grava Pedido
        ├── ² Grava ItensPedido
        ├── ³ Gera EventoPedido (CQRS)
        ├── ⁴ Atualiza Caixa/FluxoCaixa
        ├── ⁵ Reserva Estoque (Tripartite Físico→Reservado)
        └── ⁶ Publica OrdemPreparo no KDS
        │
        ▼
8. IMPRESSÃO ESC/POS + Undo Pattern 4s
```

**Recomendação formal:**
> **Antes da implementação definitiva do módulo de Pedidos (M5), deve ser especificado e implementado o fluxo operacional completo do PDV, desde a abertura de caixa até a confirmação da venda. O cadastro e seleção de clientes NÃO devem ser tratados apenas como Master Data à parte, mas como etapa obrigatória do processo de emissão de pedidos. O Pedido é o Aggregate Root único que orquestra Cliente, LocalEntrega, Itens, Pagamento, Totais, Status, Eventos e Metadados — e a partir dele todos os demais módulos (KDS, Estoque, Financeiro, Auditoria, Impressão) reagem.**

Consequências práticas no modelo:
```
Pedido (Aggregate Root)
  ├── id (UUID)
  ├── tenantId
  ├── clienteId FK obrigatório
  ├── localEntregaId FK opcional (balcão = nulo)
  ├── status (7 estados: Pendente/EmPreparo/Pronto/SaiuEntrega/Entregue/Retirado/Cancelado)
  ├── List<ItemPedido>
  ├── Pagamento (formaPagamentoId / valorCentavos / trocoCentavos)
  ├── totais (subTotalCentavos / taxaEntregaCentavos / descontoCentavos / totalCentavos)
  ├── List<EventoPedido> (CQRS — auditoria imutável)
  ├── SyncMetadata
```

#### Decisão 2 (MÉDIA — Fluxo, não Camada): Roadmap por fluxo de negócio, não por "camada pronta"
A auditoria v1.0 sugeriu uma "Milestone 4X" artificial. Ajuste correto (já aplicado na seção 14 deste relatório): Entregar módulos de negócio **ponta a ponta**. Primeiro M5 MVP Pedido (tudo o que precisa para um pedido existir do início ao fim), depois M6 MVP Produção, etc. Não existe "entregar backend primeiro" abstrato.

#### Decisão 3 (MÉDIA — Infra): Dupla porta Serverpod vs Supabase REST
Hoje o mesmo Postgres é acessível por duas portas. Risco: bypass de regra de negócio. **Decisão recomendada e justificada**:
- Serverpod = única porta de escrita e leitura transacional.
- Supabase = gerenciador de Postgres + Auth (opcional) + Storage S3. Acesso REST direto desativado via policies RLS que só aceitam request do serverpod service_role. Feito em M4.1.

### 8. A ordem das milestones continua correta?

**Resposta: SIM, AGORA ESTÁ 100% CORRETA, com os ajustes da Seção 14 Roadmap v2 por jornada de persona.** A nova unidade de entrega não é mais "milestone técnica" e sim "JORNADA COMPLETA DE UMA PERSONA". Nova ordem (sem nenhuma milestone artificial):

```
EXECUTION RESET (1 dia, opcional mas recomendado)
   ↓
CICLO-01 JORNADA-A (Luiza Gestora: Dados Reais Prontos → cadastra 10 clientes/produtos)
   ↓
CICLO-02 JORNADA-B (Maria Atendente: Vende de Verdade → do Abrir Caixa ao cupom impresso)
   ↓
CICLO-03 JORNADA-C (João Cozinheiro: Recebe Automaticamente → sem F5, sem dado mock)
   ↓
CICLO-04 JORNADA-D (Luiza Gestora: Financeiro + Fechamento Diário) [pausado até CICLO-03 fechar]
   ↓
M9 Agenda + Estoque / M8 Dashboard / M10 Expedição
```

> **Mudança de mentalidade implícita aqui**: O desenvolvimento não é guiado mais por "construir a entidade Pedido", nem "construir o módulo Financeiro". Agora é guiado por **"Como a Maria inicia uma venda hoje?" → passo 1 Abrir Caixa, passo 2 Selecionar Cliente, etc.** Cliente sempre vem primeiro. Pedido sempre vem por último como consequência do fluxo completo.

Apenas a ordem **original** do PRD-108 que estava fundamentalmente errada (UI antes de fluxo, entidade antes de caso de uso). Com o Roadmap v2 (Seção 14) e o PRD-125 (Fluxos Operacionais) criado, está finalmente correta.

### 9. Existe alguma funcionalidade importante esquecida durante a migração do Salgaderia?

**SIM. 7 Funcionalidades CRÍTICAS:**

1. **Impressão ESC/POS USB** (presente no Salgaderia e vital para faturamento). O FINCORE não menciona impressão em nenhuma milestone (nem M7 nem M8).
2. **Agenda Operacional / Trava de Capacidade Fritura por Janela Horária** (classificada como Crítica no backlog do Salgaderia). FINCORE não tem PRD nem tabela.
3. **Estoque Tripartite Físico + Reservado + Disponível** (toda a lógica do Salgaderia OPERACIONAL gira em torno disso). FINCORE só tem LoteInsumo de produção, não o estoque de produto acabado.
4. **Máquina de Estados Completa do Pedido (7 status):** Pendente → Em Preparo → Pronto → Saiu p Entrega → Entregue/Retirado, além de Cancelado com estorno automático. FINCORE KDS tem 5 status da cozinha, não o ciclo completo do pedido.
5. **EventosPedido (Auditoria + CQRS):** O Salgaderia backend tem `evento_pedido.dart` com tabela e model. FINCORE PRD-107 define CQRS mas não criou a tabela.
6. **MovimentacoesEstoque 6 Tipos:** Sem tabela, sem rastreabilidade. Você não sabe por que o estoque baixou, não sabe por que subiu.
7. **Fluxo de Caixa Diário + Fechamento:** Não mencionado em M7 (M7 só genérico). É do MVP do Salgaderia.

**Menção Honrosa (Alta, não crítica):** LotesProdução diários + MRP previsão 7 dias + Sugestao Produção IA. Existem no backend Salgaderia (LoteProducao, SugestaoProducao, MrpEndpoint, IaEndpoint).

### 10. Qual deve ser exatamente a próxima coisa a fazer? (Não existe mais "milestone X artificial")

**Resposta: Rodar o EXECUTION RESET (Seção 22) HOJE em 1 dia. AMANHÃ começar CICLO-01 JORNADA-A: Dados Reais Prontos (8 itens prioridade 1-8 da Seção 15).**

**Próximo objetivo tangível em 30 dias (3 ciclos):**  
> **"Uma dona de salgaderia real (Luiza + Maria + João 3 personas) usa o FINCORE para:
> (1) Luiza cadastra 10 clientes e 50 produtos com preço.
> (2) Maria atende 5 clientes, imprime 5 cupons.
> (3) João visualiza e produz os 5 pedidos automaticamente no KDS.
> (4) Ao fechar o dia, Luiza fecha caixa sem diferença de 1 centavo.
> (5) Reiniciam o app 3 vezes. Tudo persistiu.
> (6) Nenhum desenvolvedor interveio para preencher dado manual."**

**Ordem exata dos próximos 5 dias (sem pular item, sem paralelizar):**
| Dia | Próxima Atividade Exata |
|---|---|
| Hoje | **EXECUTION RESET (1 dia)** → Criar documento `docs/implementation/execution_reset_2026_07_25.md` com 4 entregas da Seção 22. Materializar o backlog de 21 itens no board. |
| Amanhã Dia 1 | **Backlog Prioridade 1**: CU-V05 Cadastrar Cliente Completo + CU-V06 Editar (tela ClientesPage real). |
| Dia 2 | **Prioridade 3**: ProdutosPage + CategoriasPage CRUD real. |
| Dia 3 | **Prioridade 4**: PrecosPage + Associação N:N Produto↔Tabela (UI). Usa fincore_pricing. |
| Dia 4 | **Prioridade 5 + 6**: Apagar PricingEngine duplicado + Índices Master Data + Resolver Dupla Porta. |

**Regra de ouro desta fase**: Nenhuma nova UI, nenhuma nova tabela, nenhum novo endpoint. Até que a Maria consiga atender 5 clientes do início ao fim com cupom impresso e persistência real, tudo mais espera.

### 11. O que NÃO deve ser desenvolvido agora? (Lista estrita — bloqueio executivo)

1. **Dashboard / Analytics (M8).** Sem dados reais rolando, dashboard é boneco.
2. **Novos verticais (FINCORE Finance, FINCORE CRM, AI).** Termine o Food primeiro.
3. **Portais Nuvem (Web Cliente / App Entregador).** MVP é 100% desktop local.
4. **Fiscal / NFC-e / SAT / Integração iFood API.** Precisa primeiro do cliente piloto usando o básico por 3 meses.
5. **Endpoints Serverpod de Agenda, Financeiro, Estoque, MRP, Expedição, IA.** Criados APENAS na sua respectiva milestone, não agora.
6. **Paralelização avançada SyncEngine, Grafos de Dependência.** Não há volume ainda.
7. **Refatorações estéticas / tokens de cor / Design System perfeito.** Qualquer coisa que não quebre, não mexa.
8. **Fincore_shared package preenchimento.** Ou remova ou deixe para depois.
9. **Módulo Financeiro Completo / Estoque Tripartite Completo / Agenda Operacional.** Só entram em M7 e M9.

### 12. Quais riscos existem caso NÃO sigamos a ordem Execution Reset → Jornada-A → Jornada-B → Jornada-C?

Se o time pular o Execution Reset ou voltar a organizar o backlog POR ENTIDADES TÉCNICAS ("vamos primeiro fazer todo o Estoque depois Financeiro depois Pedido"):

1. **Risco MAIOR (probabilidade 90%)**: Voltamos a ter **"telas prontas, mas fluxo quebrado"** (PDV UI linda que não cria cliente, KDS UI linda com mock). É exatamente o problema que temos hoje.
2. **Risco CRÍTICO**: Criar a tabela **Pedido SEM clienteId FK obrigatória**. Depois de 1 mês de pedidos sem cliente, é impossível corrigir sem migração destrutiva (e pedidos órfãos vão quebrar relatórios, CRM, precificação por grupo, entrega).
3. **Risco ALTO**: "Projeto Infinito" de novo. Se voltamos a listar "10 endpoints de uma vez", "7 tabelas de uma vez", a sensação de "nunca termina" volta. A abordagem Jornada-A → B → C entrega **valor tangível a cada 7/10/5 dias**, o que mantém motivação e percepção de progresso.
4. **Risco MÉDIO**: Dívida técnica de modelagem. Se alguém decidir "implementar Estoque antes de Pedido", teremos que reescrever tudo depois, pois movimentações de estoque **não são independentes — elas são REAÇÃO a eventos de pedido (confirmou, cancelou, entregou)**.
5. **Risco BAIXO mas irritante**: Novamente criar telas que vão ser refatoradas. Ex: se criarmos Financeiro primeiro sem a SessãoCaixa da Jornada-B, a tela FechamentoDiário vai ter que ser refeita do zero depois.

> **Regra final de risco:** Qualquer ticket que comece com "Vamos implementar o módulo X" em vez de "Vamos implementar o Caso de Uso CU-XX para a Persona P-Y" é **automaticamente rejeitado**. Ticket tem que começar com caso de uso + persona, não com nome de módulo.

### 13. Quais funcionalidades do Salgaderia valem a pena ser reaproveitadas conceitualmente?

**VALEM MUITO A PENA (copiar a ideia, não o código):**

1. **Estoque Tripartite (Físico - Reservado = Disponível)** + os **6 Tipos de MovimentaçãoEstoque** (ENTRADA_PRODUCAO / RESERVA / LIBERACAO_RESERVA / BAIXA_ENTREGA / BAIXA_RETIRADA / AJUSTE_POSITIVO / AJUSTE_NEGATIVO). É a engenharia de operação correta, testada na prática.
2. **Máquina de Estados 7 Status do Pedido** completa com estorno automático de reserva ao cancelar. Perfeita.
3. **Impressão ESC/POS USB com fallback .bin em %TEMP%**. Funciona no mundo real.
4. **Agenda Operacional com trava de capacidade de fritura por janela horária**. Se o cliente só aguenta fritar 300 salgados por hora, agenda trava acima disso. Isso evita pedido confirmado e não entregue → problema de SLA grave.
5. **Campos desnormalizados `produtoNome`, `clienteNome`, `clienteTelefone` em ItemPedido / Pedido.** Histórico não se altera quando você renomeia produto hoje. Correto.
6. **Sugestão de Produção Preditiva (MRP + IA Endpoint)**. O endpoint existe no Salgaderia back-end como ideia. Implementar no FINCORE como UseCase independente (não copiar código).
7. **Lembrete de Aniversário (birthday_reminder.dart no backend Salgaderia)**. Pequeno detalhe que fideliza muito.

### 14. Existe algum excesso de engenharia?

**Resposta: SIM, mas BENIGNO e JUSTIFICÁVEL no longo prazo. 2 casos:**

1. **Monorepo Multi-Tenant + Packages Core/Pricing/Design já no dia 1** vs necessidade do piloto (1 empresa só, 1 app só). Hoje isso adiciona complexidade cognitiva para qualquer desenvolvedor entrar.
   - **Veredito do Comitê**: NÃO reverter. ADR-001 Frozen já decidiu. A longo prazo (500 clientes), o ganho é 10x o custo. Apenas documente no Onboarding um "mapa mental" simples de onde importar o que, para reduzir a curva.
2. **Pricing Engine com 7 políticas e vigência temporal e prioridade e N:N** enquanto o primeiro piloto provavelmente usará só 1 tabela "Preços Balcão" com faixas simples.
   - **Veredito do Comitê**: NÃO reverter. O Salgaderia anterior já tinha grupos de preço 1:N. A dor que ele causa hoje é mínima. O ganho é que quando surgir o cliente que quer "tabela delivery diferente da balcão e promoção de natal", é só cadastrar. Parabéns.

### 15. O projeto está pronto para crescer pelos próximos anos?

**Resposta: SIM, nas Fundações e Arquitetura. NÃO, nas Entidades de Negócio Operacional.**

O Projeto está:
- ✅ **Pronto para crescer arquiteturalmente.** Multi-Tenant, Monorepo, Packages separados, Ports & Adapters pattern, RLS descrito na documentação, Offline First correto. 500 empresas daqui a 3 anos? A arquitetura aguenta.
- ❌ **Não está pronto para sobreviver 1 mês com 1 cliente real hoje.** Porque não tem Pedido, não tem Estoque, não tem Impressão. Falta 65% do negócio.

---

## 17. PRÓXIMOS PASSOS (AÇÃO IMEDIATA RECOMENDADA v2)

**A próxima ação executiva é a seguinte (não negocia, não pula):**
1. **HOJE (1 dia)**: Rodar o **FINCORE — EXECUTION RESET (Seção 22 abaixo)** com as 4 entregas por jornada de persona.
2. **AMANHÃ até dia 7**: Executar **CICLO-01 JORNADA-A: Gestora Luiza cadastra dados reais**. 8 itens prioridade 1-8.
3. **Dia 8 até dia 17**: Executar **CICLO-02 JORNADA-B: Atendente Maria vende de verdade**. 9 itens prioridade 9-17. Tudo gira em torno de "Como Maria inicia uma venda?" — Abrir Caixa, Selecionar Cliente (OBRIGATÓRIO), Endereço, Montar, Pagar, Confirmar, Imprimir. Pedido é a consequência final do fluxo, não o começo.
4. **Dia 18 até dia 22**: Executar **CICLO-03 JORNADA-C: Cozinheiro João recebe e produz automaticamente**. 4 itens prioridade 18-21.
5. **Até CICLO-03 não ter sido 100% homologado (item 21 com sucesso)**: NENHUMA nova UI, NENHUMA nova tabela, NENHUM novo endpoint, NENHUM novo módulo (Financeiro/Agenda/Dashboard/Expedição) é iniciado. Point. Blank. Period.

### Por que esta sequência e não outra?

1. **"Cliente vem primeiro" é modelagem correta que evita dívida impagável**: Se a FK clienteId não for NOT NULL na primeira linha da tabela Pedido, depois é impossível corrigir.
2. **Entrega valor tangível a cada 7-10 dias**: Ao final da semana 1, a Luiza já cadastra produtos. Ao final da semana 2, a Maria vende. Não há espera de 2 meses por "um grande lançamento".
3. **A maior lacuna do sistema hoje não é técnica — é de perspectiva**: Estava se desenhando "entidades Pedido" e se esquecendo de desenhar "como Maria inicia a venda". O Execution Reset + as Jornadas corrigem a perspectiva do time todo.
4. **Nenhum retrabalho depois**: Estoque, Financeiro, Dashboard todos serão construídos EM CIMA das jornadas A/B/C já validadas, não do nada.

---

## 18. NOTAS FINAIS 0-10 POR ÁREA (ATUALIZADAS PÓS-EXECUTION-REVIEW)

| Área Avaliada | Nota (0-10) | Justificativa Sumária (Atualizada) |
|---|---|---|
| **Arquitetura** | **8.5** | Multi-Tenant, Outbox, DI, Pricing desacoplado, Monorepo correto. Pedido Aggregate Root + Fluxo 8 passos explicitados agora estão no relatório. Penalidade -0.5 por 2 portas no mesmo banco, -1 por ter feito UI antes de modelar fluxo. |
| **Backend** | **1.5** | Apenas Hello World. Servidor inicializado, migrations placeholder. Nenhum endpoint transacional. Nenhuma RLS aplicada. |
| **Frontend** | **6.5** | Shell + PDV + KDS (2 telas principais) com UX excelente. Zero telas CRUD cadastros (Produtos/Clientes/etc). Zero Gestão Pedidos. Zero Dashboard. +0.5 agora que fluxo de Cliente obrigatório está explicitado. |
| **Banco de Dados** | **5.5** | Drift SQLite schema version 2 (14 tabelas). Relacionamentos e PKs/FKs razoáveis. Penalidade enorme: Nenhum índice (-2). Faltam tabelas transacionais cruciais (-2). FK Cliente Obrigatória em Pedido explicitada agora. |
| **Organização** | **9.0** | Estrutura docs/, packages/, products/, tools/. Document IDs semânticos. Monorepo Matriz Dependências definida. CHANGELOG impecável. |
| **Qualidade do Código** | **7.5** | Dart clean, nomenclatura boa, BaseRepository genérico, Models puros. Penalidade: duplicidade PricingEngine (-1), controllers acoplam estado + use case (-0.5), sem paginação no BaseRepository (-1). |
| **Documentação** | **9.7** | Excelente. 30+ PRDs/ADRs. 9 documentos Frozen. Onboarding obrigatório. DoD formal. +0.2 por adicionar Estado do Produto, Mapa Dependências e Execution Reset nesta auditoria. |
| **Governança** | **9.0** | Definition of Done, Contributing Guide, Change Control (Frozen vs Active), Issue/PR Templates, Implementation Reports. |
| **Escalabilidade** | **7.0** | Projetada para 500 empresas. Mas hoje sem índices (-1), sem RLS aplicado (-1), sem particionamento (-1). Arquitetura escala se corrigidos detalhes. |
| **Testabilidade** | **5.0** | Cobertura de Domínio (Pricing) excelente (95%). Core com 56%. Nenhum teste E2E transacional. Nenhum teste de widget real. Nenhum teste server-side. |
| **UX** | **8.5** | UI Guidelines congelados e aplicados. PDV com Undo 4s, atalhos F1-F12, shake, laranja foco. -1 por sem breakpoints e sem Semantics. +0 agora pois Wizard 3 passos será refatorado para step 0 Cliente obrigatório. |
| **Roadmap** | **9.0** | Roadmap v2 reescrito 100% por jornada de persona e caso de uso. Cliente primeiro, Pedido consequência. M4X artificial removida, escopo fechado 3 ciclos 21 itens. Penalidade -1: PRD-108 original ainda precisa ser atualizado oficialmente (este relatório é o reference now). |
| **Maturidade Geral do Projeto** | **6.5** | Fundações arquiteturais + documentação são excelentes (8.5+). Com a nova perspectiva por persona/jornada e o PRD-125 Fluxos Operacionais criado, a parte de Modelagem de Negócio agora está direcionada corretamente e evita dívida impagável. Salto de +1.0 vs versão anterior do relatório. |

---

## 19. CONCLUSÃO FINAL DO COMITÊ (VERSÃO FINAL v1.2 — Perspectiva Persona-Driven)

> **Antes do feedback executivo:** O relatório falava de "Milestone MVP Pedido", "tabelas transacionais", "10 endpoints", "7 entidades". O projeto estava classificado como "arquitetura boa, negócio 65% incompleto". O desenvolvimento era guiado por módulos técnicos.
>
> **Depois do feedback executivo:** O projeto passou a ser guiado por **4 pessoas reais (Luiza, Maria, João, Carlos)** e **3 fluxos operacionais completos (Venda, Produção, Financeiro)** do PRD-125 criado. O Pedido não é mais o ponto de partida — o Pedido é a CONCLUSÃO de um processo que começa com **Abrir Caixa → Identificar Cliente → Selecionar Endereço**. Cada milestone não entrega mais "entidades prontas" — cada milestone entrega **uma jornada de uma pessoa do início ao fim**.
>
> **Esta é a mudança mais importante desta auditoria.**
>
> **A FINCORE Platform continua sendo uma casa com alicerces de arranha-céu e fundação documentada invejável. O que mudou é que agora temos 4 plantas humanas da casa (Luiza/Maria/João/Carlos) e o mapa exato do caminho que cada uma percorre todos os dias para trabalhar. O primeiro cômodo a ser mobiliado não é o "quarto do Pedido". O primeiro cômodo a ser mobiliado é a "porta de entrada da Maria" — ou seja, Abrir Caixa. Depois Selecionar Cliente. Depois Selecionar Endereço. Depois Montar. Depois Pagar. Depois Confirmar. Depois Imprimir. No final desse caminho, como consequência, aparece o Pedido. A cozinha (João) reage automaticamente a esse evento. A gestão (Luiza) fecha o caixa no fim do dia. Tudo faz parte de um único fluxo transacional coerente, não de módulos isolados.**

**Ação Recomendada Final (não negocia mais):**
👉 **(1) Hoje**: Oficializar o PRD-125 Fluxos Operacionais como documento FROZEN. Qualquer novo ticket de backlog SEM referência a caso de uso CU-XXX e persona P-X é automaticamente rejeitado.
👉 **(2) Hoje**: Rodar o EXECUTION RESET de 1 dia (Seção 22 abaixo) e materializar os 21 primeiros itens do backlog na ordem exata 1→2→3…→21 no board do projeto.
👉 **(3) Amanhã**: Começar pelo item 1 do backlog. Não pular item. Não paralelizar jornada incompleta.
👉 **(4) Bloqueio Executivo**: Até que o item 21 (Teste E2E 3 Jornadas Completas + Reinício App 3x + 100% Sucesso) esteja fechado com sucesso, NENHUMA outra tarefa fora da lista de 21 itens pode ser iniciada. Nenhuma exceção.

---

## 20. ESTADO DO PRODUTO — POR JORNADA DE PERSONA (NÃO POR MÓDULO)

> **Esta seção segue o PRD-125 Fluxos Operacionais.** A pergunta não é mais "o módulo Pedido está pronto?". A pergunta agora é: **"Maria a Atendente consegue abrir caixa, atender um cliente do início ao fim, imprimir cupom e garantir que a cozinha recebeu?"** Se a resposta for NÃO, a milestone não está pronta.
>
> **Referência oficial das personas e casos de uso**: [PRD-125 Fluxos Operacionais](file:///f:/Eigent/fincore_platform/docs/125_operational_flows.md)

---

### 👤 JORNADA P1 — MARIA A ATENDENTE (Fluxo Completo de Venda)

Objetivo da Maria: Abrir caixa, atender cliente, receber, imprimir. Fechar caixa no fim do dia.

| # | Caso de Uso (do PRD-125) | Status Hoje | O que falta |
|---|---|---|---|
| CU-V01 | Abrir caixa com fundo de troco | ❌ Não existe | Tabela SessãoCaixa + Tela + Transação atômica |
| CU-V02 | Fechar caixa com conferência | ❌ Não existe | Model FechamentoCaixa + Tela + Diferença |
| CU-V03 | Localizar cliente por nome/telefone | 🟡 Existe entidade, não existe no fluxo | Busca partial indexada + UI no step 0 do PDV |
| CU-V04 | Cadastrar cliente RÁPIDO (não sai do fluxo) | ❌ Não existe | Modal 6 campos (nome/telefone/end/bairro/número/compl) dentro do Wizard PDV |
| CU-V05 | Cadastrar cliente completo (tela separada) | ❌ Não existe | Tela CRUD ClientesPage no Shell |
| CU-V06 | Editar cliente existente | ❌ Não existe | Idem |
| CU-V07 | Selecionar Balcão vs Delivery | 🟡 UI step 3 tem FormaPagamento, não tem Local | Step 0.5 antes do Catálogo: Local |
| CU-V08 | Selecionar / cadastrar Endereço entrega | 🟡 Entidade existe no master data, sem UI no fluxo | LocalEntrega select no Wizard |
| CU-V09 | Adicionar / remover produto do pedido | ✅ UI Catálogo pronta | Conectar ao repositório real (hoje em memória) |
| CU-V10 | Alterar quantidade / observação | ✅ UI existente (implementado no PDV) | Conectar com persistência |
| CU-V11 | Resolver preço automaticamente | ✅ 95% Engine pronta (package fincore_pricing) | Remover PricingEngine duplicado do app local |
| CU-V12 | Pagamento Dinheiro + Troco | 🟡 UI existe (PaymentStep) | Gravar no LancamentoFinanceiro depois |
| CU-V13 | Pagamento PIX QR Code dinâmico | 🟡 Modal Pix existe (UI) | Integração real PIX gerar QR code |
| CU-V14 | Pagamento Cartão / TEF | ❌ Não iniciado | Integracão TEF futura. MVP pode ser lançamento manual. |
| CU-V15 | Confirmar Venda — Transação Atômica 7 passos | ❌ Tabela Pedido não existe | Tabela Pedido + ItemPedido + EventoPedido + FK Cliente OBRIGATÓRIA |
| CU-V16 | Imprimir Cupom ESC/POS | ❌ Não implementado | Copiar serviço Salgaderia: cópia UNC + fallback %TEMP% |
| CU-V17 | Desfazer venda Undo Pattern 4s | ✅ UI Toast Verde + DESFAZER | Conectar ao estorno atômico real (não só estado) |
| CU-V18 | Cancelar venda já confirmada | ❌ Não existe | CancelarPedidoUseCase + estorno reserva + evento |

**Percentual concluído da JORNADA COMPLETA da Maria: ~22% (3/18 itens completos; 4/18 parciais).**  
→ A Maria hoje não consegue atender NENHUM cliente do início ao fim. Ela consegue apenas "simular" na UI.

---

### 👨‍🍳 JORNADA P2 — JOÃO O COZINHEIRO (Fluxo Produção)

Objetivo do João: Receber pedidos automaticamente, preparar, não deixar atrasar.

| # | Caso de Uso (PRD-125) | Status Hoje | O que falta |
|---|---|---|---|
| CU-K01 | Visualizar ordens pendentes | 🟡 UI 3 colunas LINDA, mas dados mock hardcoded | KdsController ler de OrdensPreparoRepository real |
| CU-K02 | Iniciar Preparo | ✅ Botão INICIAR existe | Integrar com repository muda status |
| CU-K03 | Concluir Preparo | ✅ Botão CONCLUIR existe | Idem |
| CU-K04 | Cancelar com Estorno LIFO | ✅ Modal existe + EstornarLoteEstoqueUseCase existe | Conectar fluxo real, não mock |
| CU-K05 | Timer visível + Alerta atraso | ✅ Timer 1s periódico + Glow danger | Integrar data real de created_at não de mock |
| CU-K06 | Prioridade urgente/vip | ✅ UI cor por prioridade | Campo prioridade preenchido no PedidoConfirmado (não mock) |

**Percentual concluído da Jornada do João: ~50% (5/6 UI pronta, 0/6 integrada a dados reais).**

---

### 💼 JORNADA P4 — LUIZA A GESTORA (Fluxo Financeiro + Cadastros)

Objetivo da Luiza: Cadastrar produtos/preços, vender no fim de dia, fechar caixa certo.

| # | Caso de Uso (PRD-125) | Status Hoje | O que falta |
|---|---|---|---|
| CU-F01 | Ver saldo caixa tempo real | ❌ Não existe | Tabela SessãoCaixa, tela Caixa |
| CU-F02 | Lançar despesa avulsa | ❌ Não existe | LancamentoFinanceiro tipo SAIDA |
| CU-F03 | Fechamento Diário com conferência | ❌ Não existe | Model Fechamento + tela + diferença |
| CU-F04 | Justificar diferença caixa | ❌ Não existe | Campo observação 200 chars |
| CU-F05 | Listar lançamentos do dia / filtro | ❌ Não existe | Paginação BaseRepository |

**Percentual concluído: ~5% (nenhum caso de uso de financeiro, cadastros models existem mas telas não).**

---

### 🎯 Conclusão Estado do Produto por Jornada

| Persona | % Jornada Completa | Conseguem trabalhar 1 dia real hoje? |
|---|---|---|
| Maria Atendente (P1) | **~22%** | ❌ Não. Nem consegue abrir caixa. |
| João Cozinheiro (P2) | **~50%** | ⚠️ Quase. Se alguém preencher manualmente OrdensPreparo no banco, sim. |
| Carlos Entregador (P3) | **0%** | ❌ Não. |
| Luiza Gestora (P4) | **~5%** | ❌ Não. |

> **Conclusão final do Estado do Produto (agora medido por jornada, não por módulo):**  
> **"Hoje o sistema é um protótipo de UI excelente. Nenhuma das 4 personas consegue cumprir 100% da sua jornada diária. A única jornada que está 'quase lá' é a do Cozinheiro João se o dado for preenchido manualmente."**

---

## 21. MAPA DE DEPENDÊNCIAS FUNCIONAIS — POR FLUXO DE OPERAÇÃO (NÃO POR MÓDULO)

> **Regra: Nenhuma seta para cima. Se precisa do de baixo, não constrói o de cima primeiro. O PONTO DE PARTIDA NÃO É PEDIDO. O PONTO DE PARTIDA É O CLIENTE.**

### Visão 1: Dependências por Ordem Cronológica da Operação Diária

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│  PRIMEIRO DO DIA: LUIZA GESTORA (P4) ABRE A LOJA                                   │
│  ┌─────────────────────────────────────────────────────────────────────────────┐  │
│  │ 1. LOGIN (PIN 4 dígitos) → 2. ABRIR CAIXA (Informa fundo troco)            │  │
│  │    ↓ (Se não tem cliente cadastrado?)                                      │  │
│  │  3. CADASTRAR CLIENTE COMPLETO → 4. CADASTRAR PRODUTO → 5. DEFINIR PREÇOS  │  │
│  └────────────────────────────────────────┬────────────────────────────────────┘  │
└─────────────────────────────────────────────┼───────────────────────────────────────┘
                                              ↓
              ┌───────────────────────────────────────────────────────────┐
              │ DURANTE O DIA: MARIA ATENDENTE (P1) ATENDE CLIENTES        │
              │                                                             │
              │  6. SELECIONAR CLIENTE (busca por nome/telefone OU cria    │
              │                   rápido 6 campos SEM SAIR DO FLUXO)        │
              │       ↓ OBRIGATÓRIO (não passa sem cliente)                │
              │  7. SELECIONAR LOCAL: BALCÃO / RETIRADA / DELIVERY + taxa  │
              │       ↓ (LocalEntrega)                                     │
              │  8. MONTAR PEDIDO: adicionar produtos, quantidades, obs.   │
              │       ↓ (preço atualiza em tempo real)                     │
              │  9. RESOLVER PREÇO (Pricing Engine automático)             │
              │       ↓ (troco / QRPix / Cartão)                           │
              │  10. PAGAMENTO (Dinheiro + troco automático)               │
              │       ↓ (Transação ÚNICA atômica de 7 passos)              │
              │  11. CONFIRMAR VENDA → cria PEDIDO automaticamente         │
              │       ↓ (EventoPedido publicado)                           │
              │  12. IMPRIMIR CUPOM ESC/POS (fallback %TEMP%)              │
              │       ↓ (Toast VERDE + Undo 4s para DESFAZER tudo)         │
              │  13. UNDO / ESTORNO (opcional 4s) → tudo volta ao estado   │
              └──────────────────────────┬────────────────────────────────┘
                                         ↓ (evento PedidoConfirmado)
              ┌───────────────────────────────────────────────────────────┐
              │ DURANTE O DIA: JOÃO COZINHEIRO (P2) PRODUZ                 │
              │                                                             │
              │  14. KDS recebe ORDEM PREPARO automaticamente (<1s, sem F5)│
              │       ↓                                                     │
              │  15. JOÃO clica INICIAR PREPARO → timer começa              │
              │       ↓ (se ultrapassar tempo estimado)                    │
              │  16. Atraso: GLOW VERMELHO + som de alerta (opcional)      │
              │       ↓                                                     │
              │  17. JOÃO clica CONCLUIR → ordem para coluna PRONTO        │
              │       ↓ (se cancelar)                                       │
              │  18. CANCELAR → estorno automático LIFO estoque + atualiza │
              └──────────────────────────┬────────────────────────────────┘
                                         ↓ (fim do dia)
              ┌───────────────────────────────────────────────────────────┐
              │ FIM DO DIA: LUIZA FECHA A LOJA                              │
              │                                                             │
              │  19. LUIZA verifica Saldo Caixa em tempo real              │
              │       ↓ (conta dinheiro na gaveta vs sistema)              │
              │  20. FECHAMENTO DIÁRIO → informa valor contado físico     │
              │       ↓ (diferença? R$ 0,00 = conciliado)                 │
              │  21. Diferença > 0,01 → justificar observação 200 chars    │
              └───────────────────────────────────────────────────────────┘
```

### Visão 2: Mapa de Dependências (Entidades Reagem ao Fluxo)

| Ponto de Partida | Gera como Consequência | Módulos que Reagem |
|---|---|---|
| **1. CLIENTE (Luiza cadastra ou Maria seleciona)** | → ClienteId, Endereços, FormaPgto preferida | N/A |
| **2. PRODUTO + PREÇO** | → ProdutoId, TabelaPreco, ItensTabela, Associacao N:N | PricingEngine calcula quando pedido montar |
| **3. VENDA MONTADA + PAGA (Maria)** | → **PEDIDO (Aggregate Root), ItensPedido, EventoPedido CRIADO** | KDS, Estoque, Financeiro, Outbox, Impressora TODOS reagem a este evento |
| **4. Evento PedidoConfirmado** | → OrdemPreparo + Reserva Estoque + Lancamento Financeiro + Outbox Entry | João vê no KDS, estoque baixa disponibilidade |
| **5. Evento OrdemConcluida (João)** | → Pedido status=Pronto | Maria Balcão visualiza status pronto |
| **6. Evento PedidoEntregue / Retirado** | → Estoque: Reserva→Baixa Física + Financeiro Saldo atualiza | N/D |
| **7. Fechamento Diário (Luiza)** | → Fechamento, Diferença, Justificativa | Relatórios, Dashboard M8 |

> **Conclusão do mapa: 90% das entidades do sistema não existem por si só — elas EXISTEM COMO REAÇÃO ao evento "Maria atende cliente e confirma a venda".** Por isto é tão perigoso desenhar o roadmap por "Módulo Estoque" primeiro. O Estoque não tem razão de ser sem o evento da Maria gerar uma reserva ou baixa.

### Legenda das Dependências CRÍTICAS

| Dependência | Por que quebrar isto destrói o produto |
|---|---|
| Pedido → Cliente (FK OBRIGATÓRIA NOT NULL) | Sem cliente cadastrado, não há histórico, não há precificação por grupo, não há entrega, não há CRM. Se tabela Pedido for criada com clienteId nullable, será impossível corrigir depois sem migração destrutiva. É o maior risco de modelagem do projeto hoje. |
| Passo 6 (Selecionar Cliente) vem ANTES do Passo 8 (Montar Pedido) | Se a ordem das etapas do Wizard for invertida (Catálogo primeiro), o operador monta todo pedido e depois esquece de selecionar cliente → pedido órfão. É erro operacional clássico de sistemas de PDV mal projetados. |
| KDS reage a evento de Pedido, não o contrário | KDS não cria ordens de preparo. Ele só recebe ordens criadas pela confirmação de venda. Se inverter a dependência teremos duas fontes da verdade. |
| Movimentação Estoque é reação a evento de pedido | Reserva = evento PedidoConfirmado. Liberação = evento Cancelado. Baixa Física = evento Entregue/Retirado. Estoque não é uma entidade que o usuário edita manualmente todos os dias (só ajustes ocasionais). |

---

## 22. FINCORE — EXECUTION RESET (ÚLTIMA ETAPA DA AUDITORIA)

> **Objetivo desta etapa: Transformar a auditoria (que é diagnóstico) em um PLANO DE EXECUÇÃO DE 30 DADOS UTILIZÁVEIS PELO TIME DE DESENVOLVIMENTO NO DIA SEGUINTE.**
>
> **Tempo estimado para completar esta etapa: 1 dia útil.**
>
> **Entregas obrigatórias (4):**

---

### ENTREGA 1/4 — MAPA ARQUITETURAL ATUAL (1 página, 1 diagrama)

O que é: Uma página única (pode ser em `docs/implementation/execution_reset_2026_07_25.md`) com:
1. **1 Diagrama Mermaid simples** mostrando as camadas que REALMENTE existem hoje funcionando:
   ```mermaid
   graph TD
   A[FincoreShell Flutter] --> B[PDV Express UI + KDS UI]
   B --> C[PdvExpressController + KdsController]
   C --> D[fincore_core]
   D --> E1[TenantContext]
   D --> E2[BaseRepository T]
   D --> E3[OutboxSync table]
   D --> E4[SyncEngine linear]
   D --> E5[AuditService]
   D --> E6[DI Service Locator]
   D --> F[Drift SQLite 14 tabelas]
   C --> G[fincore_pricing: PricingEngine]
   B --> H[fincore_design_system]
   I[Serverpod Food Server] --> J[GreetingEndpoint único]
   I --> K[9 models YAML Master Data compilados]
   ```
2. **Legenda de cores:** Verde = Funciona 100%, Amarelo = Parcial, Vermelho = Não existe.
3. **Número de linhas de código por pacote** (rápido comando `find packages lib -name "*.dart" | xargs wc -l`)
4. **1 linha de conclusão**: "Hoje o sistema é composto por X arquivos Dart, Y tabelas SQLite, 1 endpoint Serverpod."

**Por que importa:** Todo desenvolvedor novo que entra tem o direito de entender em 30 segundos o que existe e o que não existe. Hoje demora 3 horas lendo 30 documentos.

---

### ENTREGA 2/4 — MAPA FUNCIONAL (O QUE EXISTE vs O QUE FALTA)

O que é: Uma página com **2 colunas só**:

| EXISTE HOJE E FUNCIONA | NÃO EXISTE / NÃO FUNCIONA |
|---|---|
| ✅ TenantContext + filtro tenantId automático | ❌ **Tabela Pedido / ItemPedido / EventoPedido** |
| ✅ BaseRepository T genérica | ❌ **Abrir Caixa + Fechar Caixa** |
| ✅ OutboxSync table + transação atômica | ❌ **FK Cliente obrigatória no Wizard PDV** |
| ✅ SyncEngine síncrono linear | ❌ **Selecionar LocalEntrega no PDV** |
| ✅ 6 Master Data models + tabelas | ❌ **Pub/Sub Pedido → KDS automático** |
| ✅ PricingEngine 95% cobertura | ❌ **Impressão ESC/POS real** |
| ✅ PDV Wizard 3 UI impecável | ❌ **3 endpoints Serverpod (Cliente/Produto/Pedido)** |
| ✅ KDS 3 colunas UI impecável | ❌ **RLS em tabelas que vão para nuvem** |
| ✅ 47 testes unitários ~64% | ❌ **Telas CRUD Produto/Cliente** |
| ✅ 30+ docs governança Frozen | ❌ **Integração KdsController ← Repository real** |

**Regra da Entrega 2:** Máximo de 10 itens por coluna. Não exagerar. Se tem mais de 10, só os 10 mais críticos.

---

### ENTREGA 3/4 — ROADMAP CORRIGIDO E SIMPLIFICADO (3 CICLOS POR JORNADA DE PERSONA)

O que é: Uma página única com **3 linhas de roadmap APENAS para os próximos 3 ciclos (~30 dias)**. Nada de M7/M8/M9/M10. O resto volta para o backlog. A unidade de entrega agora é **UMA JORNADA COMPLETA DE UMA PESSOA REAL**.

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│  CICLO-01 (7 dias) → JORNADA-A LUIZA GESTORA (P4) │ DADOS REAIS PRONTOS (8 itens p1-p8)       │
│  ──────────────────────────────────────────────────────────────────────────────────────────     │
│  Persona: LUIZA, 40 anos, dona da empresa. Workstation: Desktop 15" normal.                     │
│  Resultado esperado ao final do ciclo:                                                           │
│    ✅ Luiza abre o app, loga com PIN, e cadastra 10 clientes reais com endereço + CPF.           │
│    ✅ Cadastra 50 produtos + 7 categorias.                                                        │
│    ✅ Cria 1 tabela de preço de atacado e 1 tabela de varejo. Associa os 50 produtos.            │
│    ✅ Reinicia o app 3 vezes. Os 10 clientes e 50 produtos continuam lá.                         │
│    ✅ Nenhum desenvolvedor interviu para preencher dado manual.                                  │
│  ──────────────────────────────────────────────────────────────────────────────────────────     │
│  Dia 1: Prioridade 1+2 → ClientesPage CRUD real (CU-V05 / CU-V06 / CU-V07)                      │
│  Dia 2: Prioridade 3 → ProdutosPage + CategoriasPage CRUD real                                   │
│  Dia 3: Prioridade 4 → PrecosPage + Associação N:N Produto↔Tabela (UI)                          │
│  Dia 4: Prioridade 5+6 → Apagar PricingEngine duplicado + Índices Master Data + RLS             │
│  Dia 5: Prioridade 7+8 → Resolver Dupla Porta Serverpod + Testes CRUD + Análise 0 warnings      │
│  Dia 6: Homologação interna → Luiza cadastra 10 clientes no ambiente QA                         │
│  Dia 7: Homologação Cliente Piloto → 100% sucesso. Assinatura do Luiza.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
                                     ↓ (dados reais existem agora)
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│  CICLO-02 (10 dias) → JORNADA-B MARIA ATENDENTE (P1) │ VENDE DE VERDADE (9 itens p9-p17)      │
│  ──────────────────────────────────────────────────────────────────────────────────────────     │
│  Persona: MARIA, 26 anos, atendente/caixa. Workstation: Windows 10" + impressora ESC/POS USB.   │
│  Pergunta NORTE deste ciclo: "Como a Maria inicia uma venda?" (não "como criar um pedido?")      │
│  Resultado esperado ao final do ciclo:                                                           │
│    ✅ 08:00 Maria chega, LOGA, ABRE CAIXA (informa fundo de troco R$ 100,00).                    │
│    ✅ Cliente 1 chega. Maria PESQUISA POR NOME → não existe → CADASTRA RÁPIDO 6 campos.          │
│    ✅ Seleciona cliente, seleciona DELIVERY com taxa R$ 5,00.                                     │
│    ✅ Monta 10 coxinhas, 5 pastéis, 1 refrigerante. Preço calcula AUTOMÁTICO (varejo R$ 3/und). │
│    ✅ Cliente paga R$ 50 em dinheiro. Troco R$ 0,00 calcula automático.                          │
│    ✅ Maria CONFIRMA. Toast VERDE aparece. CUPOM IMPRIME sozinho na ESC/POS.                     │
│    ✅ Maria percebeu erro. Clica DESFAZER nos próximos 4 segundos. TUDO volta ao zero.           │
│    ✅ Maria atende 5 clientes hoje. 5 cupons impressos. Reinicia app 3x.                          │
│    ✅ Ao fechar o dia: SALDO CAIXA em tempo real mostra o valor correto.                         │
│  ──────────────────────────────────────────────────────────────────────────────────────────     │
│  Dia 1-2: Prioridade 9+10 → Wizard refatorado: Step 0 CLIENTE OBRIG + Step 0.5 LOCAL + Catálogo│
│  Dia 3:   Prioridade 11 → Cadastro Rápido Cliente DENTRO do PDV (modal, não sai do fluxo)       │
│  Dia 4-5: Prioridade 12+13 → CriarPedidoUseCase Atômico + Pedido Aggregate Root + Preço/Pagto  │
│  Dia 6:   Prioridade 14 → Abrir Caixa + SessãoCaixa + Saldo Tempo Real                          │
│  Dia 7:   Prioridade 15 → Impressão ESC/POS + Undo Pattern 4s + Toast verde                     │
│  Dia 8:   Prioridade 16 → Sync Outbox + 3 Endpoints Serverpod (Cliente/Produto/Pedido)          │
│  Dia 9:   Prioridade 17 → RLS + Índices tabelas transacionais + Idempotência mínima             │
│  Dia 10:  Homologação Cliente Piloto → Maria atende 5 clientes, 5 cupons impressos com sucesso. │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
                                     ↓ (5 pedidos reais confirmados)
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│  CICLO-03 (5 dias) → JORNADA-C JOÃO COZINHEIRO (P2) │ PRODUZ AUTOMATICAMENTE (4 itens p18-p21) │
│  ──────────────────────────────────────────────────────────────────────────────────────────     │
│  Persona: JOÃO, 35 anos, cozinheiro. Workstation: Tablet/Desktop 10" na parede, zoom 150%.      │
│  Resultado esperado ao final do ciclo:                                                           │
│    ✅ Maria confirma um pedido. João vê a ordem APARECER AUTOMATICAMENTE (<1s, SEM F5).          │
│    ✅ João clica INICIAR PREPARO. Timer começa contar em tempo real (1s update).                 │
│    ✅ Passou do prazo estimado de 20 min. CARD GLOWS VERMELHO perigo.                            │
│    ✅ João clica CONCLUIR. Ordem vai para coluna PRONTO. Maria Balcão vê.                        │
│    ✅ Cliente cancela antes de João começar. João clica CANCELAR. Estorno LIFO automático.       │
│    ✅ 5 pedidos do dia anterior continuam aparecendo após João REINICIAR O TABLET 3x.            │
│  ──────────────────────────────────────────────────────────────────────────────────────────     │
│  Dia 1: Prioridade 18 → KdsController ← OrdensPreparoRepository real (apaga mock List)         │
│  Dia 2: Prioridade 19 → Timer periódico 1s + Atraso Glow Vermelho 3px perigo                    │
│  Dia 3: Prioridade 20 → 7 Status Máquina Estados completa Pedido + Cancelar/Estorno automático  │
│  Dia 4: Prioridade 21 → TESTE E2E 3 JORNADAS COMPLETAS (Luiza abre → Maria vende 5 → João prod)│
│  Dia 5: HOMOLOGAÇÃO CLIENTE PILOTO FINAL → +10% desconto contratual se fechar sem retrabalho.  │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Regra da Entrega 3**: Nenhum "M5", nenhum "M6", nenhum "MVP Entidade X". Só nome de pessoa real, período, resultado tangível em linguagem de negócio, datas exatas. Todo milestone tem o nome da pessoa que vai usar, não do módulo que vai ser construído.

---

### ENTREGA 4/4 — BACKLOG PRIORIZADO POR CASO DE USO 1→21

O que é: A Seção 15, Bloco 1 (Backlog por Caso de Uso 1→21) **impressa e colada na parede do escritório / no board do GitHub Projects como primeira coluna**. Máximo 21 tarefas (8 Jornada-A + 9 Jornada-B + 4 Jornada-C).

**Formato do ticket (REGRA NÃO NEGOCIÁVEL para todos os novos tickets):**
```
TÍTULO: [CU-V05-JORNADA-A] Cadastrar Cliente Completo
PERSONA: P4 Luiza Gestora
CASO DE USO: PRD-125 → CU-V05
DESCRIÇÃO: Quando Luiza clica em "Novo Cliente" na ClientesPage, aparece o modal...
CRITÉRIO ACEITAÇÃO:
  ✅ Dado preenchido → Cliente salvo
  ✅ Reinício app → Cliente continua lá
  ✅ Editar → atualiza
  ✅ Excluir logicamente → some da lista mas está no banco
ESTIMATIVA: 1 dia
RESPONSÁVEL: ____
PRIORIDADE: 1
```

**Regra da Entrega 4:** Qualquer nova sugestão de tarefa que surgir nas próximas 4 semanas SEM começar com `[CU-XX-JORNADA-X]` (sem caso de uso do PRD-125 e sem persona) é **automaticamente rejeitada** e vai para o "Backlog Pós 3 Jornadas" (MoSCoW tradicional na Seção 15 Bloco 2). Nenhuma exceção sem ADR formal assinado pelo Product Owner.

---

### CRITÉRIO DE CONCLUSÃO DO EXECUTION RESET

Se estas 4 entregas forem completadas em 1 dia, no dia seguinte o time de desenvolvimento sabe EXATAMENTE:
- O que existe hoje (Entrega 1)
- O que falta (Entrega 2)
- Em que ordem fazer (Entrega 3)
- Exatamente quais 21 tarefas fazer (Entrega 4)

**Nenhuma reunião de planejamento a mais.** Nenhuma decisão de arquitetura a mais por 30 dias. Só executar.

---

*Relatório de Auditoria Técnica v1.1 (revisado com feedback executivo) — gerado pelo Comitê Executivo de Engenharia — FINCORE Platform Review 2026-07-25.*
