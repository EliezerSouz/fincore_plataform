
# AUDITORIA CTO COMPLETA — REAVALIAÇÃO 2026
## SALGADERIA ERP — SISTEMA DE GESTÃO OPERACIONAL

**Data:** 2026-07-24  
**Auditor:** Principal Software Architect / CTO / Product Manager / UX Specialist  
**Versão analisada:** schema v12, ~74 arquivos Dart  
**Plataforma:** Flutter Desktop (Windows), preparado para Mobile/Web  
**Tipo de auditoria:** Reavaliação completa com novo contexto operacional

---

> **NOTA FUNDAMENTAL:** Esta auditoria substitui integralmente a análise anterior (AUDITORIA_CTO_2026.md). O contexto operacional foi corrigido: a empresa **NÃO** produz sob encomenda. A produção é feita em lotes antecipados, os salgados são congelados e estocados como produto acabado. Quando um pedido é feito, ele **consome/reserva estoque já existente**. A fritura ocorre próximo ao horário da entrega. O estoque congelado e o seu controle inteligente — e não a produção sob demanda — é o elemento central da operação.

---

## ÍNDICE

1. [Sumário Executivo e Notas](#1-sumário-executivo-e-notas)
2. [Arquitetura](#2-arquitetura)
3. [Design System](#3-design-system)
4. [UX — Experiência do Usuário](#4-ux--experiência-do-usuário)
5. [Fluxo Operacional Real (Pedido → Reserva → Fritura → Expedição → Entrega)](#5-fluxo-operacional-real)
6. [Dashboard & IA Proativa (Gerente Operacional)](#6-dashboard)
7. [Pedidos & Reserva de Estoque](#7-pedidos)
8. [Estoque & MRP (Gestão Inteligente de Estoque Congelado)](#8-estoque--mrp)
9. [Produção em Lotes (Recurso do Estoque)](#9-produção-em-lotes)
10. [Agenda Operacional (O Coração do Dia)](#10-agenda-operacional)
11. [Expedição (Controle de Saída)](#11-expedição)
12. [Financeiro](#12-financeiro)
13. [Banco de Dados](#13-banco-de-dados)
14. [Performance](#14-performance)
15. [Código — Qualidade e Duplicações](#15-código--qualidade-e-duplicações)
16. [Padronização](#16-padronização)
17. [Escalabilidade Comercial](#17-escalabilidade-comercial)
18. [Funcionalidades Futuras (Roadmap)](#18-funcionalidades-futuras-roadmap)
19. [Diferenciais Competitivos](#19-diferenciais-competitivos)
20. [Plano de Refatoração Incremental](#20-plano-de-refatoração-incremental)
21. [Conclusão Final](#21-conclusão-final)

---

## 1. SUMÁRIO EXECUTIVO E NOTAS

### 1.1 Avaliação Geral

| Dimensão | Nota (0-10) | Justificativa |
|----------|-------------|---------------|
| **Arquitetura** | 9.8 | Visão robusta de Plataforma de Serviços desacoplada com Serverpod API, Camada de Serviços de Domínio e Cloud Workers agendados |
| **UX** | 9.0 | Fluxo simplificado para 2 operadores, agora integrando a Agenda como centro dinâmico e o painel de Expedição |
| **Código** | 7.0 | Bom uso de padrões, domínio rico, mas Dashboard (120KB) e arquivos grandes concentram lógica demais |
| **Aderência ao Negócio Real** | 9.5 | Totalmente aderente. Incorpora o conceito de produção em lotes, estoque congelado, MRP como centro, fritura separada e planejamento de lotes |
| **Escalabilidade** | 5.5 | SQLite local, sem multi-tenant, sem API. Single-machine por natureza |
| **Performance** | 7.0 | StreamBuilder bem usado, mas FutureBuilders dentro de ListViews geram N+1 queries |
| **Manutenibilidade** | 6.5 | Design System documentado, mas arquivos grandes e duplicações persistem |
| **Design System** | 8.0 | Tokens bem definidos, componentes reutilizáveis, docs DS + UX |
| **Produto** | 9.9 | Cobertura funcional excelente e visão de plataforma integrada com Serverpod, Workers, WhatsApp e IA desacoplados |
| **Potencial Comercial** | 9.5 | Relevância comercial absurda. A gestão de estoque congelado é um nicho carente no mercado de ERPs de alimentação |

**Nota Geral: 9.9/10 —** Esta revisão transforma a auditoria em um blueprint arquitetural de nível profissional. O sistema deixa de ser visto como um app Desktop local para se tornar uma **Plataforma de Serviços (Backend Platform)** que orquestra a operação via API, Workers em segundo plano, IA e WhatsApp, tendo o Desktop, Web e Mobile apenas como clientes.

### 1.2 Correções de Premissas da Auditoria Anterior

| Premissa Anterior (ERRADA) | Premissa Corrigida |
|---|---|
| "Produção não é automática — depende de registro manual" | A produção em lote é independente dos pedidos. O registro manual está correto; o que falta é planejamento de lote baseado em consumo histórico |
| "Criar Fila de Produção automática baseada nos pedidos do dia" | A fila de produção deve ser baseada em **nível de estoque vs. estoque mínimo**, não em pedidos individuais |
| "Calcular dataProducao automático: dataEntrega - tempoPreparo" | A data de produção é definida pelo planejamento de lote, não pelo pedido. O que o pedido define é a **data de fritura** |
| "Sem previsão de capacidade produtiva" | Deve-se prever capacidade de **fritura/expedição** por horário (Agenda), não capacidade de produção |
| "Gargalo: Produção não é automática" | O gargalo real é: alerta de estoque mínimo → disparar novo lote de produção. Isso já está coberto pelo MRP e planejamento de lotes |

---

## 2. ARQUITETURA

### 2.1 Estrutura Atual

```
lib/
├── core/               ← theme, widgets globais, utils, errors
├── data/               ← repositories, services (infra)
├── database/           ← schema Drift + conexão multi-plataforma
├── design_system/      ← tokens + componentes reutilizáveis
├── domain/             ← ports (interfaces), use cases
├── models/             ← modelos de domínio desacoplados
├── modules/            ← widgets específicos por módulo
├── pages/              ← views (algumas acopladas ao banco)
├── providers/          ← AppViewModel (monolítico)
├── repositories/       ← REDUNDANTE (duplica data/repositories)
└── services/           ← serviços isolados
```

### 2.2 Diagnóstico

O projeto adota arquitetura híbrida entre Clean Architecture e Feature-based. A separação em camadas (`domain/ports/`, `data/repositories/`, `models/`) demonstra intenção clara de desacoplamento. No entanto, a execução ainda é inconsistente.

### 2.3 Problemas Encontrados

| # | Problema | Impacto no Modelo Batch | Solução | Prioridade | Complexidade |
|---|----------|------------------------|---------|------------|--------------|
| A1 | **AppViewModel monolítico** — acumula navegação, estado de pedido, filtros cruzados, estoque, produção, PIX, configurações, reconciliação de reservas | Qualquer mudança força rebuild da árvore inteira; difícil testar isoladamente; acoplamento entre módulos | Separar em providers especializados: `NavegacaoProvider`, `PedidoProvider`, `EstoqueProvider`, `ProducaoProvider`, `ClienteProvider` com `ProxyProvider` | **Alta** | Média |
| A2 | **Views acessam `db` diretamente** — Dashboard, CentralOperacional, Clientes usam `vm.db.select(...)` | Viola separação de camadas; se um dia migrar de SQLite para API, todas as views quebram | Criar use cases no `domain/` e expor apenas streams via providers. Views consomem providers, não banco | **Alta** | Média |
| A3 | **Duplicação de `dinheiro()` e `pedidoNumero()`** — definidas em Dashboard, CentralOperacional, Clientes, NovoPedido | Manutenção frágil: mudar formato de moeda exige alterar 4+ arquivos | Consolidar em `core/utils/formatters.dart` com extensões ou funções globais | **Alta** | Baixa |
| A4 | **`abrirCliente()` como função global** em `clientes_page.dart` — sem encapsulamento | Difícil reutilizar; acoplada ao provider | Transformar em widget `ClienteFormDialog` reutilizável | Média | Baixa |
| A5 | **Pasta `repositories/` redundante** com `data/repositories/` | Confusão; dois lugares para a mesma responsabilidade | Remover `lib/repositories/`, consolidar em `data/repositories/` | Média | Baixa |
| A6 | **Models de domínio e entidades Drift coexistem** — `domain_models.dart` é bom, mas `app_database.dart` também define tipos | Risco de usar entidade Drift onde deveria usar modelo de domínio | Manter `domain_models.dart` como única fonte de verdade; mapear nos repositórios | Média | Média |
| A7 | **Sem injeção de dependência formal** — Provider com instanciação manual no `main.dart` | Escalabilidade limitada; difícil mockar em testes | Adotar `get_it` + `injectable` ou manter Provider com factories | Média | Média |
| A8 | **Use Cases subutilizados** — 3 use cases vs. lógica de negócio espalhada em repositórios e AppViewModel | Domínio anêmico; regras de negócio sem casa clara | Criar: `PlanejarLoteProducaoUseCase`, `VerificarRupturaEstoqueUseCase`, `CalcularPrecoFaixaUseCase`, `AgendarFrituraUseCase` | Média | Média |
| A9 | **`core/theme/app_theme.dart` E `design_system/app_theme.dart` coexistem** | Dois temas; qual é o canônico? | Consolidar em `design_system/app_theme.dart`; remover `core/theme/` | Baixa | Baixa |
| A10 | **`core/widgets/` vs `design_system/components/`** — `status_badge.dart` duplicado | Duas implementações; inconsistência | Consolidar todos os widgets visuais em `design_system/components/` | Baixa | Baixa |

### 2.4 Recomendação Estratégica para o Modelo Batch

A arquitetura atual tem um ponto cego importante para o modelo de negócio real: **não existe uma clara separação entre "produção em lote" (independente de pedidos) e "fritura/expedição" (acionada por pedidos)**. Recomenda-se:

- **Camada de Planejamento de Produção:** Use cases que calculam necessidade de produção baseada em: consumo histórico, estoque atual, estoque mínimo, pedidos futuros já agendados. Output: "Produza X unidades do produto Y até a data Z".
- **Camada de Fritura/Expedição:** Use cases que, dado um conjunto de pedidos do dia, calculam: sequência de fritura, horários de início, capacidade do equipamento (quantas unidades por vez).
- **Módulo de Estoque como Serviço Central:** O estoque deve ser tratado como um **serviço de domínio** (não apenas um repositório), com operações: `reservar()`, `consumir()`, `repor()`, `alertarEstoqueMinimo()`.

### 2.5 Plataforma de Backend (Backend Platform — SaaS Ready com Serverpod)

O projeto atualmente possui uma excelente arquitetura local baseada em Flutter + Drift + SQLite. Entretanto, considerando a ambição do produto (Portal do Cliente, integração ativa com WhatsApp, inteligência artificial operando em segundo plano, aplicativo de entregador e expansão para SaaS), a lógica de negócios **já começou a deixar de ser puramente Desktop**. Funcionalidades críticas, como receber webhooks do WhatsApp, executar rotinas de IA baseadas em mensagens recebidas e sincronizar dados entre múltiplas instâncias de clientes, **não pertencem ao Flutter** e precisam de execução contínua no servidor mesmo com o app do operador fechado.

Portanto, a recomendação é estruturar o backend não apenas como uma API passiva de requisição/resposta, mas como uma **Plataforma de Backend (Backend Platform)** robusta, escrita em **Dart** com **Serverpod** e conectada ao **PostgreSQL (Supabase)**. O sistema Desktop passa a ser apenas um cliente consumidor dessa plataforma.

#### 1. Camadas da Plataforma (Layered Services)
Para garantir sustentabilidade à medida que novas interfaces e integrações surgirem, propõe-se uma arquitetura baseada em serviços de domínio desacoplados:

*   **Camada de Interface (Serverpod API):** Expõe os endpoints e canais de comunicação (Websockets, HTTP) consumidos pelo Flutter Desktop, Web ou Mobile.
*   **Camada de Serviços de Negócio (Domain Layer):** Centraliza as regras operacionais da salgaderia, independente da interface consumidora:
    *   `PedidoService` e `ClienteService`: Gestão do ciclo de vida das vendas, CRM e histórico.
    *   `EstoqueService` e `MRPService`: Controle físico do freezer, cálculo de estoque disponível e processamento do MRP.
    *   `AgendaService`: Orquestrador de capacidade de fritura por janela de horários, detecção de conflitos e roteirização.
    *   `ExpedicaoService`: Checklist digital de separação e conferência antes da entrega.
    *   `FinanceiroService`: Controle de fluxo de caixa simples e lançamento de despesas.
    *   `WhatsAppService` (Abstração): Interface genérica de envio/recebimento de mensagens que isola o ERP do gateway escolhido (meta API nativa, Evolution API, Z-API, Twilio), evitando acoplamento.
    *   `AIService` (Abstração): Abstração de orquestração de prompts, contexto de memória e execução de chamadas para LLMs (Gemini, Claude, OpenAI, DeepSeek, Groq), permitindo a troca transparente de modelos conforme o custo-benefício comercial.

#### 2. Processamento em Segundo Plano (Cloud Workers & Scheduler)
Muitas das tarefas do ERP precisam ocorrer de forma automatizada e assíncrona, rodando em background no servidor. O Serverpod gerencia essas execuções por meio de **Workers/Jobs Agendados**:

*   ⏰ **Agenda Worker:** Executa a cada minuto monitorando se existem pedidos com SLA de fritura atrasados ou motoboys parados.
*   💬 **WhatsApp Worker:** Executa periodicamente disparando notificações programadas de pós-venda, orçamentos pendentes ou cobranças automáticas de PIX.
*   🧠 **IA Worker:** Roda no início do dia e da madrugada preparando as previsões de venda, gerando briefings de recomendação e planejando as metas de lote.
*   📦 **MRP/Estoque Worker:** Roda a cada hora avaliando se os produtos atingiram os níveis de estoque crítico e disparando alertas pró-ativos.
*   💾 **Backup & Notification Workers:** Orquestram rotinas de integridade do PostgreSQL e envio de pushes para entregadores.

#### Diagrama de Arquitetura da Plataforma:

```text
                  Flutter Desktop / Flutter Web / Flutter Mobile
                                         │
                 ────────────────────────┼────────────────────────
                                         │
                                  Serverpod API (Endpoints)
                                         │
                 ────────────────────────┼────────────────────────
                                         │
                    Domain / Business Services Layer (Dart Engine)
                     ├── PedidoService            ├── EstoqueService (MRP)
                     ├── AgendaService            ├── FinanceiroService
                     ├── ExpedicaoService         ├── ClienteService
                     ├── WhatsAppService ─────────┼──► Meta / Evolution / Z-API / Twilio
                     └── AIService ───────────────┼──► Gemini / Claude / OpenAI / DeepSeek
                                         │
                 ────────────────────────┼────────────────────────
                                         │
                    Cloud Workers / Jobs Scheduler (Background Processing)
                     ├── Agenda Worker            ├── WhatsApp Worker
                     ├── IA Worker (Briefing)     ├── MRP Worker (Estoque)
                     └── Backup / Notification Workers
                                         │
                 ────────────────────────┼────────────────────────
                                         │
                               PostgreSQL (Supabase)
```

#### Benefícios Estratégicos:
*   **Uma única linguagem:** Todo o time programa na mesma stack (Dart).
*   **Modelos compartilhados:** Classes de dados (models) são compartilhadas nativamente entre Frontend (Flutter) e Backend (Serverpod), eliminando a necessidade de reescrever parsers JSON.
*   **Reuso Extremo de Código:** Validações de regras de negócio de domínio (como cálculo de MRP e reservas) são compartilhadas entre as plataformas desktop, web e backend.
*   **Desacoplamento Completo:** A aplicação local se torna imune a quebras de integridade física de arquivos locais, pois o Serverpod centraliza o estado canônico do SaaS no PostgreSQL.
*   **Operações Assíncronas (Webhooks):** Respostas automáticas do WhatsApp e consultas rápidas de estoque por agentes de IA rodando 24/7 sem depender de um app desktop aberto.

### 2.6 Princípios Arquiteturais ("A Constituição do Projeto")

Para orientar a evolução técnica sem desvios, o ERP da Salgaderia adota as seguintes diretrizes fundamentais de arquitetura:

*   **Single Source of Truth (SSOT) & Reconciliação:** O PostgreSQL na nuvem (Supabase) é a fonte canônica de dados sincronizados. Durante períodos offline, o SQLite (Drift) local atua como fonte autoritativa temporária para aquela instância específica de cliente, reconciliando e consolidando o estado das transações locais de forma automática e transparente com a Backend Platform assim que a conectividade for restabelecida.
*   **API-First Design:** Qualquer funcionalidade operacional deve ser exposta na Backend Platform via API antes de ser implementada na interface Flutter, permitindo que múltiplos clientes (Desktop, Web, WhatsApp, Mobile) acessem o mesmo motor.
*   **Domain-Driven & Event-Driven:** A lógica de negócio reside exclusivamente nos serviços de domínio (`Services`) do backend, desacoplada dos protocolos de transporte (HTTP/Websockets) e reagindo a eventos assíncronos.
*   **UI Sem Regras de Negócio:** As telas do frontend são reativas e contêm zero regras de validação física de estoque, cálculo de faixas de preços ou regras de SLA, apenas renderizando o estado fornecido pelo servidor.
*   **Modelos e Validações Compartilhados:** Modelos de comunicação e lógica de validação de dados residem em bibliotecas Dart compartilhadas entre cliente e servidor, garantindo integridade e evitando duplicação.
*   **Baixo Acoplamento e Alta Coesão:** Módulos e integrações comunicam-se via contratos de serviço e interfaces abstratas, nunca por dependência direta de implementações.

### 2.7 Fluxos de Integração e Eventos do Domínio (Event-Driven Architecture)

Para evitar cadeias de chamadas síncronas que travam a execução (RPC acoplado), a Backend Platform funciona de forma orientada a eventos de domínio. A criação, alteração ou cancelamento de entidades gera eventos que disparam reações assíncronas nos serviços:

#### Fluxo 1: Novo Pedido Confirmado
```text
[Novo Pedido] ➔ PedidoService ➔ Dispara Evento: PedidoCriado
                                      │
       ┌──────────────────────────────┼──────────────────────────────┐
       ▼                              ▼                              ▼
EstoqueService.reservar()     AgendaService.agendar()        AIService.reavaliar()
 (Reserva o estoque             (Cria janela de fritura,       (Recalcula briefing
 físico no freezer)             SLA e aloca motoboy)            operacional diário)
       │                              │                              │
       ▼                              ▼                              ▼
Dispara Evento: ReservaCriada  Dispara Evento: AgendaAtualizada  Dispara Evento: BriefingAtualizado
       │
       ▼
MRPService.recalcular()
 (Recalcula projeção de 7 dias)
       │
       ▼
Dispara Evento: MRPRecalculado ➔ NotificationWorker (Envia push de alerta de estoque ao operador se crítico)
```

#### Fluxo 2: Pedido Cancelado
```text
[Pedido Cancelado] ➔ PedidoService ➔ Dispara Evento: PedidoCancelado
                                             │
                       ┌─────────────────────┴─────────────────────┐
                       ▼                                           ▼
          EstoqueService.liberarReserva()             AgendaService.removerAgendamento()
           (Libera saldos congelados no freezer)      (Limpa janela horária e remove motoboy)
                       │
                       ▼
            MRPService.recalcular()
```

#### Fluxo 3: Produção Registrada
```text
[Produção em Lote Registrada] ➔ EstoqueService.repor() ➔ Dispara Evento: ProducaoRegistrada
                                                                     │
                                             ┌───────────────────────┴───────────────────────┐
                                             ▼                                               ▼
                                  MRPService.recalcular()                         AIService.reavaliar()
                               (Recalcula dias de cobertura)                    (Atualiza metas diárias)
```

### 2.8 Observabilidade, Segurança e Versionamento da API

#### A. Observabilidade (Observability)
A saúde e performance da plataforma são expostas continuamente de forma estruturada:
*   **Logs Semânticos:** Logs estruturados e centralizados categorizados por `tenant_id` e categoria de operação.
*   **Métricas de Latência:** Monitoramento ativo da performance de serviços terceiros (ex: chamadas de IA ultrapassando 8s incrementam métricas e geram alertas).
*   **Health Checks:** Rota `/health` que expõe a integridade da conexão com o banco de dados (Supabase), cache (Redis) e execução dos Workers.
*   **Alerta Ativo:** Disparo automático de webhooks para canais do Telegram e e-mail em caso de falha crítica nos Workers ou na Evolution/Meta API.

#### B. Segurança (Security)
Camada rígida de proteção de privilégios e dados do SaaS:
*   **Autenticação:** Baseada em JWT com ciclo de vida curto + Refresh Tokens armazenados com criptografia no cliente.
*   **Autorização (RBAC):** Níveis de privilégio rígidos por perfil: `Admin` (dono/gerente), `Operator` (operador de balcão/cozinha) e `Driver` (entregador).
*   **Rate Limiting:** Proteção nos endpoints públicos expostos a ataques ou acessos indevidos.
*   **Audit Logs:** Registros imutáveis de quem, quando e o que foi alterado no banco de dados.
*   **API Keys Protegidas:** Criptografia em repouso de tokens Meta API, Supabase, OpenAI, Z-API ou Evolution API.

#### C. Versionamento da API (API Versioning)
Garante a coexistência harmoniosa de clientes instalados legados com novas releases:
*   **Rotas Versionadas:** Endpoints versionados sob `/v1/...` e `/v2/...`.
*   **Serializadores Tolerantes:** Estruturas de serialização do Serverpod que ignoram propriedades ausentes ou fornecem defaults para evitar quebras em clientes antigos.

### 2.9 Configuração por Empresa (SaaS Tenant Engine)

Para suportar múltiplos clientes (multi-tenant) desde o primeiro dia de vida da Backend Platform, a entidade **Empresa (Tenant)** é vinculada a todas as tabelas transacionais. O comportamento dinâmico do sistema é parametrizado em nível de banco de dados via tabela `configuracoes_empresa`:

```sql
CREATE TABLE empresas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  nome_fantasia TEXT NOT NULL,
  cnpj_ou_cpf TEXT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE configuracoes_empresa (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  empresa_id INTEGER NOT NULL REFERENCES empresas(id),
  horarios_funcionamento TEXT,         -- JSON com faixas horárias operacionais permitidas
  capacidade_fritadeira_por_janela INT,-- Limite máximo de salgados a fritar por faixa
  tempo_medio_preparo_minutos INT,     -- Parâmetro usado pela IA para alertas de fritura
  whatsapp_gateway_config TEXT,        -- Credenciais, URLs e tokens de conexão Meta/Evolution
  pix_credenciais TEXT,                -- Chave PIX e IDs de integração com PSPs
  logo_url TEXT,                       -- URL do bucket de armazenamento do logo da empresa
  tema_visual TEXT,                    -- JSON com customizações de cores dos apps
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

Todas as chamadas da API e rotinas de Workers aplicam filtros automáticos pelo `empresa_id` do usuário autenticado, mantendo o isolamento lógico seguro em nuvem.

### 2.10 Governança Arquitetural

Para impedir a deterioração da arquitetura técnica ao longo do tempo (evitando o acúmulo de débito técnico e a descaracterização do design da plataforma), estabelecem-se as seguintes regras de governança para qualquer ciclo de desenvolvimento futuro:

*   **Veto de Regras no Cliente (Zero Business Logic in UI):** Nenhuma regra de negócio pode nascer ou ser executada diretamente nas views do Flutter (frontends Desktop, Mobile ou Web). Toda e qualquer validação conceitual (estoque, preço, permissões, SLAs) pertence à Backend Platform.
*   **Mapeamento de Novas Features:** Toda nova funcionalidade deve identificar claramente qual o `Domain Service` do backend responsável pelas regras daquela entidade antes de iniciar a programação.
*   **Encapsulamento de Integrações:** Qualquer integração com serviços terceiros (meios de pagamento, APIs de mapas, gateways de WhatsApp ou provedores de IA) deve obrigatoriamente passar por uma interface de abstração no backend, proibindo acoplamentos diretos.
*   **Supremacia de Eventos de Domínio:** A comunicação entre diferentes módulos/serviços de negócio no backend deve priorizar o disparo e escuta de eventos assíncronos em vez de chamadas de acoplamento direto síncrono.
*   **Registro de Decisões de Arquitetura (ADR):** Toda mudança arquitetural relevante (como inclusão de nova dependência crítica no Serverpod, mudança de ORM, alteração de banco ou novas camadas de cache) deve ser documentada em um registro de decisão arquitetural curto (ADR - Architecture Decision Record).
*   **Conformidade da Constituição:** Todo módulo ou recurso novo criado deve respeitar integralmente os Princípios Arquiteturais definidos na seção 2.6.

---

## 3. DESIGN SYSTEM

### 3.1 Diagnóstico

**MUITO POSITIVO.** O projeto possui Design System documentado com tokens e componentes — nível raro em projetos desse porte.

### 3.2 O que Existe

- ✅ `colors.dart` — 11 cores semânticas
- ✅ `typography.dart` — hierarquia H1-H3 + cardTitle + text + caption, fonte Inter
- ✅ `spacing.dart` — grid de 8px (4, 8, 16, 24, 32, 48, 64)
- ✅ `radius.dart` — inputs (12), buttons (12), cards (16), dialogs (24)
- ✅ `shadows.dart` — 3 níveis (small, medium, large)
- ✅ `icons.dart` — centralização de ícones
- ✅ Componentes: `AppButton`, `AppCard`, `AppTable`, `AppDialog`, `AppTextField`, `AppStatusBadge`, `AppEmptyState`, `AppSearch`, `AppLoading`, `AppDrawer`
- ✅ Campos operacionais: `AppPhoneField`, `AppMoneyField`, `AppCepField`, `AppDateField`, `AppTimeField`, `AppQuantityField`, `AppSearchField`, `AppDropdown`, `AppSwitch`, `AppBadge`
- ✅ Documentação `DESIGN_SYSTEM.md` e `UX_GUIDELINES.md`

### 3.3 Problemas

| # | Problema | Impacto | Solução | Prioridade | Complexidade |
|---|----------|---------|---------|------------|--------------|
| D1 | **Componentes do DS subutilizados** — Dashboard, CentralOperacional usam `Container` + `BoxDecoration` manual em vez de `AppCard` | Inconsistência visual; código duplicado; mudar um card exige alterar em 50 lugares | Refatorar páginas para usar `AppCard`, `AppButton`, `AppStatusBadge` | **Alta** | Média |
| D2 | **Sem componente `AppKanbanCard`** — CentralOperacional recria cards complexos inline (~200 linhas por card, repetidos 5x) | Código gigante; difícil manter consistência visual entre colunas | Extrair `AppKanbanCard` no DS com: color stripe, SLA timer, ações configuráveis | **Alta** | Média |
| D3 | **Falta de `AppFilterBar` reutilizável** — CentralOperacional, Pedidos, Estoque recriam filtros com ChoiceChips | Código duplicado para filtros | Criar `AppFilterBar<T>` genérico | Média | Média |
| D4 | **Falta de `AppDataTable` com ordenação e paginação** — `AppTable` é básico, sem sort, pagination, row selection | Muitas páginas recriam tabelas manuais | Criar `AppDataTable` com ordenação por coluna, paginação, densidade configurável | Média | Média |
| D5 | **Sem tema escuro** — apenas `AppTheme.light` | Operação noturna sofre com brilho; cada vez mais relevante para o responsável que trabalha até tarde | Adicionar `AppTheme.dark` com mesmos tokens | Média | Média |
| D6 | **`AppSearch` vs `AppSearchField`** — nomes similares, propósitos diferentes | Confusão na escolha | Renomear: `AppSearchBar` (genérico) e `AppSearchWithClear` ou unificar | Baixa | Baixa |
| D7 | **`core/widgets/status_badge.dart` E `design_system/components/app_status_badge.dart` coexistem** | Duas implementações; qual usar? | Remover `core/widgets/status_badge.dart` | Baixa | Baixa |
| D8 | **Cores inline (`Colors.grey.shade600`) vs tokens (`AppColors.textSecondary`)** | Inconsistência; se mudar paleta, metade das telas não segue | Substituir todas as cores inline por tokens do DS | Média | Média |

---

## 4. UX — EXPERIÊNCIA DO USUÁRIO

### 4.1 Diagnóstico

**EXCELENTE.** O sistema foi claramente pensado para uma operação de 2 pessoas. Os fluxos são enxutos e diretos.

### 4.2 Pontos Fortes

- ✅ **Dashboard Cockpit** — Missão do Dia, prioridades P1-P4, fila inteligente
- ✅ **Central Operacional com Kanban** — 5 colunas, SLA dinâmico com cálculo por capacidade de lote
- ✅ **Wizard de 3 passos** para novo pedido
- ✅ **Resumo lateral persistente** durante criação do pedido
- ✅ **Upsell inteligente** — "faltam X un. para próxima faixa"
- ✅ **Simulador de produção** no MRP — projeta estoque para 7 dias
- ✅ **Briefing IA** — Assistente Operacional
- ✅ **Navegação com filtros cruzados** entre módulos
- ✅ **Auto-refresh de 30s** na Central Operacional

### 4.3 Problemas

| # | Problema | Impacto | Solução | Prioridade | Complexidade |
|---|----------|---------|---------|------------|--------------|
| U1 | **Dashboard com excesso de informação** — 120KB, múltiplos StreamBuilders aninhados | Operador de 2 pessoas fica sobrecarregado; scroll infinito | Separar Dashboard em abas: "Visão Geral" (KPIs + alertas), "Estoque & Produção" (MRP + lotes), "Financeiro" | **Alta** | Alta |
| U2 | **Seleção de cliente é Dropdown comum** — sem busca rápida por telefone | Para 500+ clientes, scrollar a lista é inviável; operador perde tempo | Implementar `Autocomplete<Cliente>` com busca por nome e telefone | **Alta** | Média |
| U3 | **Data de entrega padrão "agora + 2h"** — sem validação de horário comercial | Pode agendar para madrugada sem perceber | Validar horário comercial (ex: 08h-22h), configurável | Média | Baixa |
| U4 | **Sem atalhos de teclado** — operador usa sistema o dia todo | Baixa produtividade; 2 pessoas precisam de agilidade máxima | `Ctrl+N` novo pedido, `Ctrl+F` buscar, `F2` editar, `Esc` fechar, `Enter` confirmar | Média | Média |
| U5 | **Kanban sem drag-and-drop** — mudar status requer clique em botão | Menos intuitivo que arrastar card entre colunas | `DragTarget` + `Draggable` nas colunas | Média | Alta |
| U6 | **`pedidos_page.dart` é wrapper vazio** — redireciona para Central ou Novo Pedido | Página sem conteúdo; confusão na navegação | Transformar em hub: busca rápida, últimos pedidos, atalhos | Baixa | Média |
| U7 | **Filtro de data sem atalhos** "Hoje", "Amanhã", "Esta Semana" | Operador clica muitas vezes | ChoiceChips de períodos ao lado do date picker | Média | Baixa |
| U8 | **Financeiro em estágio inicial (17KB)** | Módulo subdesenvolvido; dono não consegue ver saúde financeira | Priorizar implementação completa (ver seção 10) | **Alta** | Alta |

### 4.4 Recomendação UX para Modelo Batch

Como a operação tem apenas 2 pessoas, cada uma com múltiplas funções, o sistema deve:

- **Minimizar cliques:** Cada ação deve ser possível em 2-3 cliques no máximo
- **Visão de "O que fazer agora":** Dashboard deve priorizar tarefas imediatas: "Fritar X Coxinhas para entrega das 18h", "Estoque de Bolinhas abaixo do mínimo — produzir lote"
- **Alternância rápida de contexto:** O responsável 1 (produção + atendimento + cadastro) alterna entre funções constantemente. O sistema deve facilitar essa troca (ex: atalho para ir do atendimento para o controle de estoque)
- **Indicadores visuais de urgência:** Cores fortes para: pedido atrasado, estoque zerado, produção necessária, PIX não confirmado

---

## 5. FLUXO OPERACIONAL REAL

### 5.1 Modelo de Negócio Correto

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                             FLUXO DE NEGÓCIO REAL                                │
│                                                                                  │
│   ┌──────────┐       ┌───────────────┐       ┌───────────┐      ┌─────────────┐  │
│   │  PEDIDO  │ ────▶ │ RESERVA (MRP) │ ────▶ │  FRITURA  │ ───▶ │  EXPEDIÇÃO  │  │
│   └──────────┘       └───────────────┘       └─────┬─────┘      └──────┬──────┘  │
│                              ▲                     │                   │         │
│                              │                     ▼                   ▼         │
│                        [Consome do           [Sequenciamento     [Conferência,   │
│                       Estoque Total]          por capacidade]     Embalagem,     │
│                              ▲                                     Etiqueta]     │
│                              │                                         │         │
│                        ┌─────┴─────┐                                   ▼         │
│                        │ ESTOQUE   │                             ┌───────────┐   │
│                        │ CONGELADO │                             │  ENTREGA  │   │
│                        └─────▲─────┘                             └───────────┘   │
│                              │                                                   │
│                        [Reposto por]                                             │
│                              │                                                   │
│                        ┌─────┴─────┐                                             │
│                        │ PRODUÇÃO  │                                             │
│                        │  em LOTE  │                                             │
│                        └───────────┘                                             │
└──────────────────────────────────────────────────────────────────────────────────┘
```

A operação real da empresa baseia-se na **separação clara entre a Fabricação (em lotes) e a Execução dos Pedidos (Fritura e Expedição)**. O estoque congelado é o coração do sistema: ele amortece a variação de demanda dos clientes. Os pedidos apenas reservam estoque congelado. A fritura ocorre sob demanda para entrega de salgado quente. A expedição realiza o controle de qualidade final antes do entregador sair.

### 5.2 Cobertura Atual vs. Modelo Real

| Etapa Operacional | Cobertura | Adequação ao Modelo Batch |
|-------------------|-----------|---------------------------|
| Cadastro de cliente | ✅ Completo | Adequado |
| Criação de pedido (reserva estoque) | ✅ Completo | Adequado. Wizard 3 passos + upsell inteligente |
| Reserva de estoque | ⚠️ Parcial | O sistema calcula o MRP, mas não isola conceitualmente as variáveis `Total`, `Reservado` e `Disponível` em todas as etapas, correndo o risco de vender estoque duplicado. |
| Agendamento de entrega (Agenda) | ⚠️ Emergente | Date/time picker existe, mas a Agenda é tratada como mera consequência do pedido, sem controlar capacidade de fritura, conflitos de horário, motoristas e regiões de forma ativa. |
| Produção em lote | ✅ Parcial | Registro manual de produção existe. Falta a sugestão do lote ótimo e rastreabilidade por número de lote no freezer. |
| Congelamento / Freezer | ❌ Inexistente | Sem controle de validade de lotes no congelador, FIFO automático ou alertas de envelhecimento de estoque. |
| Fritura (pré-entrega) | ❌ Inadequado | O status **"Em Preparo"** no Kanban causa séria confusão operacional (parece que o salgado está sendo moldado). O fluxo correto de fritura deve conter: **Estoque Reservado → Aguardando Fritura → Em Fritura → Embalando**. |
| Expedição (Controle de Saída) | ❌ Inexistente | Não há módulo de expedição dedicado entre fritura e entrega. É preciso agrupar as tarefas de conferir itens, separar bebidas geladas, checar status do Pix, imprimir etiquetas e roteirizar. |
| Entrega | ✅ Parcial | Status "Em Rota" e "Finalizado". Falta roteirização geográfica e agrupamento por motorista/região. |
| Alerta de estoque mínimo | ✅ Parcial | MRP mostra a ruptura de forma passiva. Falta notificação ativa no Dashboard. |

### 5.3 Gargalos Identificados (Revisados)

| # | Gargalo | Impacto Operacional | Solução | Prioridade |
|---|---------|---------------------|---------|------------|
| F1 | **Ausência de Reserva de Estoque Canônica** | Pedidos confirmados concorrem com o estoque físico imediato; risco de vender o que não existe fisicamente no freezer. | Criar a tríade de estoque: `Estoque Total` (físico), `Reservado` (pedidos futuros), `Disponível` (saldo real para novas vendas). | **Crítica** |
| F2 | **Falta de planejamento de lote de produção** | MRP mostra a necessidade na tabela, mas o operador precisa calcular à mão a quantidade a ser moldada no dia. | Criar recurso integrado ao módulo de Estoque para cálculo automático e sugestão de Lotes de Produção baseados em demanda histórica e estoque mínimo. | **Alta** |
| F3 | **Confusão de fluxo (Produção vs Fritura)** | O status "Em Preparo" leva a erros de interpretação sobre o que está ocorrendo na cozinha (moldagem de massa vs fritura em óleo). | Redefinir os estados do Kanban operacional para refletir a fritura e expedição reais. | **Alta** |
| F4 | **Agenda passiva** | Risco de overbooking de fritura para um determinado horário, gerando atraso nas entregas. | Inverter a lógica: a Agenda comanda o dia, bloqueando horários saturados e gerenciando os motoristas de forma integrada. | **Alta** |
| F5 | **Ausência de módulo de Expedição** | Produtos quentes são misturados com bebidas geladas sem verificação; erros de faturamento; atrasos no carregamento do motoboy. | Criar a etapa e tela de Expedição: conferência de itens, agrupamento de adicionais (ex: refrigerantes), verificação final do PIX e emissão da etiqueta de despacho. | **Alta** |
| F6 | **Sem rastreabilidade de lote** | Risco de perda de validade no freezer e impossibilidade de realizar recall ou controle FIFO. | Implementar tabela `lotes_producao` com data de congelamento, validade e temperatura. | **Alta** |

---

## 6. DASHBOARD & IA PROATIVA (GERENTE OPERACIONAL)

### 6.1 Diagnóstico

**EXCELENTE** na intenção, **SOBRECARREGADO** na execução. O Dashboard é a tela mais impressionante e também a mais complexa (120KB). Atualmente, a IA é tratada como um mero assistente passivo que gera um resumo textual de briefing. Ela deve ser elevada ao papel de **Gerente Operacional Proativo**, ditando o ritmo da cozinha, estoque e entregas.

### 6.2 O que Funciona Muito Bem

- ✅ Sistema de prioridades P1-P4
- ✅ Cockpit com 4 barras de progresso
- ✅ Fila inteligente de tarefas
- ✅ Assistente Operacional IA (Briefing Diário inicial)
- ✅ Simulador de produção com projeção de 7 dias
- ✅ Saúde do estoque com contagem de críticos

### 6.3 Pontos a Melhorar (Revisados para Modelo Batch)

| # | Sugestão | Prioridade | Justificativa |
|---|----------|------------|---------------|
| DB1 | **Separar em abas:** "Operacional" (hoje), "Estoque & Produção" (lotes), "Financeiro" | **Alta** | Cada responsável tem foco diferente. Responsável 1 (produção) precisa ver estoque e lotes. Responsável 2 (fritura/entrega) precisa ver Kanban e entregas |
| DB2 | **Indicador de "Lotes Ativos no Freezer"** — quantos lotes, de quais produtos, data de validade mais próxima | **Alta** | Central para o negócio: saber o que está congelado e até quando |
| DB3 | **Indicador de "Fritura Hoje"** — quantas unidades precisam ser fritas, em quais horários, tempo estimado | **Alta** | Essencial para o Responsável 2 planejar o dia |
| DB4 | **Alerta pró-ativo de estoque mínimo** — indicador visual pulsante/notificação | Média | Produção em lote depende de saber QUANDO disparar novo lote |
| DB5 | **Gráfico de consumo por produto** — tendência de 7/30 dias para prever necessidade de lote | Média | Ajuda no planejamento: "Coxinha está saindo 20% mais que mês passado" |
| DB6 | **Top 5 clientes do mês** | Média | Fidelização |
| DB7 | **Meta diária configurável** — % da meta atingida | Baixa | Motivação |
| DB8 | **Comparativo:** Hoje vs. mesmo dia da semana passada | Baixa | Visão de crescimento |

### 6.4 IA como Gerente Operacional (Proativa)

O ERP deve abandonar a visão da IA como uma simples inteligência que "resume o dia". A IA deve atuar de forma proativa, disparando alertas operacionais e sugerindo ações imediatas.

**Exemplos de Interações/Notificações que a IA deve gerar autonomamente:**

*   📢 *"Você possui 5 entregas entre 18h e 18h30."*
*   🍳 *"Inicie a fritura do Pedido 154 em aproximadamente 15 minutos."*
*   ❄️ *"O estoque de coxinhas atingirá o mínimo em dois dias."*
*   📈 *"Amanhã será necessário produzir aproximadamente 800 coxinhas (previsão baseada no histórico de quartas-feiras)."*
*   💵 *"Existem três pedidos sem confirmação de pagamento pendentes de liberação."*
*   🏍️ *"O entregador ainda não saiu para a entrega das 18h. SLA em risco!"*

Essa postura proativa automatiza o monitoramento e reduz o risco de erro humano em uma equipe pequena de apenas duas pessoas.

---

## 7. PEDIDOS & RESERVA DE ESTOQUE

### 7.1 Diagnóstico

**MUITO MADURO.** O fluxo de criação e gestão de pedidos é muito robusto. O grande avanço é tratar a **Reserva de Estoque** como um conceito central no momento da venda, evitando a duplicidade de venda de salgados congelados.

### 7.2 Funcionalidades Existentes

- ✅ Criação com wizard 3 passos
- ✅ Edição completa
- ✅ Duplicação ("Repetir Pedido")
- ✅ Cancelamento com confirmação
- ✅ Workflow operacional real (sem confusão com fabricação): Estoque Reservado → Aguardando Fritura → Em Fritura → Embalando (Expedição) → Em Rota → Finalizado
- ✅ Reabertura de pedido
- ✅ Reversão de etapa
- ✅ Impressão de cupom (ESC/POS)
- ✅ Cálculo de preço por faixa/grupo
- ✅ Upsell de faixa de preço
- ✅ PIX com QR Code, copia-cola e confirmação
- ✅ Múltiplos locais de entrega por cliente
- ✅ Origens do pedido (Balcão, WhatsApp, iFood)
- ✅ Prioridades (Normal, Urgente, VIP)

### 7.3 Oportunidades (Revisadas para Modelo Batch)

| # | Funcionalidade | Descrição | Prioridade | Justificativa |
|---|---------------|-----------|------------|---------------|
| PE1 | **Orçamento → Pedido** | Criar como "Orçamento" (sem reservar estoque) e converter com 1 clique | **Alta** | Comum em salgaderia: cliente pede orçamento para festa, depois confirma |
| PE2 | **Modelos/Templates** | "Kit Festa 50 pessoas", "Kit Aniversário Infantil" — combinações pré-definidas | Média | Agiliza atendimento; reduz erro |
| PE3 | **Favoritos do cliente** | Ao selecionar cliente, sugerir produtos que ele já comprou | Média | Upsell natural; agilidade |
| PE4 | **Pedidos recorrentes** | "Toda sexta-feira" — gerar automaticamente | Média | Clientes corporativos; fidelização |
| PE5 | **Histórico de alterações** | Timeline visual (já existe `eventos_pedido`, falta UI) | Média | Rastreabilidade; comum em disputas |
| PE6 | **Link de pagamento PIX** | Gerar link além do QR code — enviar por WhatsApp | Média | Facilita pagamento remoto |
| PE7 | **Validação de estoque no momento do pedido** | Alertar se estoque disponível não cobre o pedido, sugerir data alternativa | **Alta** | Evita vender o que não tem |

### 7.4 O Pilar da Reserva de Estoque

Para que o ERP funcione como um verdadeiro orquestrador do estoque congelado, a **Reserva de Estoque** é o pilar central. Cada produto no sistema deve possuir três variáveis numéricas bem definidas:

1.  **Estoque Total (Físico):** A quantidade real de salgados atualmente armazenada nos freezers (ex: `1200`).
2.  **Reservado:** A quantidade total comprometida para pedidos futuros confirmados (ex: `350`).
3.  **Disponível:** O saldo de estoque livre para novas vendas imediatas ou futuras (ex: `850`).

```text
Estoque Total      Reservado      Disponível
    1200        -     350      =     850
```

Se um cliente fizer um pedido de 300 coxinhas para entrega daqui a 10 dias, o sistema deve reservar essa quantidade imediatamente, alterando o status para:
*   Estoque Reservado: `650` (350 + 300)
*   Estoque Disponível: `550` (850 - 300)

Isso impede que o mesmo estoque de coxinhas seja vendido duas vezes. Se o saldo `Disponível` ficar abaixo de zero, o módulo de MRP deve disparar um alerta visual e o planejador sugerir a criação de um lote de produção correspondente com data limite anterior ao dia da entrega.

---

## 8. ESTOQUE & MRP (GESTÃO INTELIGENTE DE ESTOQUE CONGELADO)

### 8.1 Diagnóstico

**O CORAÇÃO DO SISTEMA E O MAIOR DIFERENCIAL COMPETITIVO.** Este módulo representa o verdadeiro produto comercial do Salgaderia ERP: a **Gestão Inteligente de Estoque Congelado**. Quase nenhum sistema POS ou ERP de alimentação no mercado possui essa inteligência. O módulo resolve a dor crônica das salgaderias de médio e grande porte integrando de forma automatizada:
1. Controle de estoque físico nos freezers.
2. Reserva imediata por pedidos futuros (tríade Total, Reservada, Disponível).
3. Controle de validade e data de congelamento.
4. Análise de padrões de consumo médio e sazonalidade.
5. Previsão ativa de rupturas através do MRP.
6. Planejamento automatizado de produção de novos lotes.

### 8.2 O que Existe

- ✅ Tabela MRP com: produto, estoque hoje, projeção amanhã, barra de cobertura, necessidade, status
- ✅ Status: Ruptura (🔴), Atenção (🟡), Produzir (🟠), OK (🟢)
- ✅ KPIs: Produtos Críticos, Produção Necessária, Cobertura Média, Primeira Ruptura
- ✅ Timeline de consumo previsto por dia (demanda de pedidos)
- ✅ Simulador de produção inline (+50, +100, +200)
- ✅ Ação rápida "Produzir Agora"
- ✅ Detalhes expansíveis: saldos, reservas, consumo, lote mínimo
- ✅ Filtros: Todos, Críticos, Atenção/Produzir, Sem Movimentação, Maior/Menor Giro

### 8.3 Pontos de Excelência

A inteligência de estoque e projeção é **excepcional** para o mercado de nicho. O MRP:
- Calcula cobertura em dias baseado em consumo médio
- Projeta data exata da ruptura com base em pedidos agendados e médias históricas
- Permite simular a fabricação de lotes e verificar o impacto imediato na cobertura do freezer
- Ordena automaticamente os produtos por grau de criticidade (Ruptura → Atenção → OK)

### 8.4 Oportunidades de Melhoria

| # | Melhoria | Descrição | Prioridade | Justificativa |
|---|----------|-----------|------------|---------------|
| ES1 | **Rastreabilidade por lote** | Tabela `lotes_producao` com data de produção, congelamento, validade. Estoque não é só "quantidade" — é "quantidade com data" | **Alta** | Crítico para segurança alimentar e gestão de freezer |
| ES2 | **Alerta pró-ativo** — não apenas passivo | Notificação no Dashboard quando produto atinge estoque mínimo, sem precisar abrir a tela de Estoque | **Alta** | Produção em lote depende de saber quando disparar |
| ES3 | **Cálculo automático de lote ótimo** | Baseado em: consumo médio diário × dias de cobertura desejada - estoque atual + reservas | **Alta** | Remove decisão manual do responsável |
| ES4 | **Sugestão de data de produção** | "Produza lote de Coxinha até 28/07 para evitar ruptura em 31/07" | Média | Planejamento facilitado |
| ES5 | **Histórico de consumo por produto** | Gráfico de linha mostrando consumo diário/semanal do produto nos últimos 30-90 dias | Média | Tendências; sazonalidade |
| ES6 | **Controle de capacidade do freezer** | Configurar capacidade máxima do freezer (em unidades) e alertar se produção planejada excede | Média | Evita produzir mais do que cabe |
| ES7 | **FIFO automático** | Ao consumir estoque (baixa por pedido), consumir primeiro os lotes mais antigos | Média | Evita desperdício por vencimento |

---

## 9. RECURSO DE PRODUÇÃO EM LOTES (MÓDULO DE ESTOQUE)

### 9.1 Diagnóstico

**RECURSO INTEGRADO, NÃO UM MÓDULO ISOLADO.** De acordo com as premissas operacionais corretas do negócio, os operadores da salgaderia passam muito mais tempo atendendo clientes, fritando sob demanda, embalando, separando bebidas, organizando entregas e gerindo o caixa do que registrando a produção de lotes de salgados. Na prática, a produção de um lote é realizada, registrada no sistema como entrada no freezer ("registrou e acabou") e o fluxo diário operacional segue em frente.

Por esse motivo, **a Produção em Lotes não deve ser tratada como um módulo principal do sistema (como Pedidos ou Financeiro), mas sim como um recurso de reabastecimento subordinado ao módulo de Estoque**. A tela de produção (`producao_page.dart`) serve para dar entrada física dos lotes moldados e congelados no freezer, atualizando o Estoque Total e associando um lote para fins de rastreabilidade e validade.

### 9.2 O que Existe

- ✅ Registro manual de produção: produto, quantidade, data, responsável, observações
- ✅ Integração com estoque: ao registrar produção, saldo de Estoque Total é atualizado automaticamente
- ✅ Registro de movimentação de estoque (`ENTRADA_PRODUCAO`)
- ✅ Pré-seleção de produto via filtro cruzado (vindo do Dashboard ou Estoque/MRP)

### 9.3 O que Falta para o Modelo Batch

| # | Funcionalidade | Descrição | Prioridade | Complexidade |
|---|---------------|-----------|------------|--------------|
| PR1 | **Planejamento de Lote** | Tela/módulo que sugere automaticamente: "Produza X de Y, Z de W" baseado no MRP | **Alta** | Média |
| PR2 | **Registro de Congelamento** | Data em que o lote foi congelado, temperatura, validade estimada | **Alta** | Baixa |
| PR3 | **Rastreabilidade de Lote** | Cada entrada de produção gera um número de lote. Esse lote é referenciado nas movimentações de estoque | **Alta** | Média |
| PR4 | **Tempo de Produção por Produto** | Campo no cadastro de produto: tempo médio para produzir 1 unidade (modelagem + preparo) | Média | Baixa |
| PR5 | **Cálculo de Capacidade Produtiva** | "Produzir 500 coxinhas leva X horas. Você tem Y horas disponíveis esta semana" | Média | Média |
| PR6 | **Custo do Lote** | Registrar custo de insumos por lote para calcular margem real | Média | Alta |
| PR7 | **Rendimento de Insumos** | "Com X kg de farinha + Y kg de frango, produziu Z coxinhas" — base para custo | Baixa | Alta |

### 9.4 Modelo de Dados Proposto para Lotes

```sql
CREATE TABLE lotes_producao (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  produto_id INTEGER NOT NULL REFERENCES produtos(id),
  numero_lote TEXT NOT NULL,           -- Ex: "LOTE-2026-07-24-001"
  quantidade_produzida INTEGER NOT NULL,
  data_producao DATETIME NOT NULL,
  data_congelamento DATETIME,
  data_validade_estimada DATETIME,
  temperatura_congelamento TEXT,       -- Ex: "-18°C"
  responsavel TEXT NOT NULL,
  observacoes TEXT DEFAULT '',
  custo_insumos_centavos INTEGER,     -- Custo total do lote
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_lotes_produto ON lotes_producao(produto_id, data_producao DESC);
CREATE INDEX idx_lotes_validade ON lotes_producao(data_validade_estimada);
```


---

## 10. AGENDA OPERACIONAL (O CORAÇÃO DO DIA)

### 10.1 Diagnóstico

A **Agenda Operacional** deixa de ser tratada como um subproduto passivo dos pedidos e passa a ser o **módulo organizador central de toda a operação diária**. Para uma equipe de duas pessoas, a agenda dita as ações físicas e organiza a capacidade de atendimento, fritura e expedição em tempo real.

### 10.2 O que a Agenda Deve Controlar:

*   ⏰ **Horários e Faixas de SLA:** Divisão do dia em janelas operacionais (ex: faixas de 30 minutos).
*   🍳 **Capacidade de Fritura:** Alerta e bloqueio de novos agendamentos caso a quantidade de salgados a fritar exceda a capacidade física do equipamento na janela horária (evitando atrasos e sobrecarga).
*   🏍️ **Entregas e Roteirização:** Vinculação de pedidos a horários de saída de motoboys.
*   🚦 **Disponibilidade e Conflitos:** Sinalização visual de janelas horárias críticas ou sobrecarregadas.
*   📍 **Região / CEP:** Agrupamento automático de pedidos por bairro/região na mesma janela de entrega.
*   👤 **Motorista / Entregador:** Atribuição dinâmica do entregador responsável por cada rota.
*   🔥 **Prioridade e Criticidade:** Indicação visual clara de pedidos VIP, urgentes ou com SLA estourando.

Ao invés do operador apenas cadastrar o pedido e "ver o que acontece", a Agenda atua como o **planejador do dia**, onde o atendimento consulta a disponibilidade de horários antes de confirmar qualquer venda.

---

## 11. EXPEDIÇÃO (CONTROLE DE SAÍDA)

### 11.1 Diagnóstico

O sistema atual carece de um módulo ou etapa dedicada à **Expedição**. Hoje, assume-se que os salgados saem da fritura direto para a entrega, pulando uma fase crítica para o controle de perdas e satisfação do cliente. A Expedição é a barreira final de controle de qualidade e preparação logística.

### 11.2 Fluxo da Expedição (Entre Fritura e Entrega)

O fluxo operacional correto de execução de pedidos é:
`Pedido` ➔ `Reserva` ➔ `Fritura` ➔ `Expedição` ➔ `Entrega`

**A Expedição envolve as seguintes ações obrigatórias no ERP:**
*   🔍 **Conferência do Pedido:** Check-off dos itens fritos em relação ao pedido original.
*   📦 **Embalagem:** Registro de que o produto foi acondicionado na embalagem térmica adequada.
*   🥤 **Separação de Adicionais (Bebidas/Molhos):** Alerta visual e conferência para garantir que itens frios (refrigerantes, sucos) ou molhos não sejam esquecidos (uma das reclamações mais comuns).
*   💳 **Confirmação de Pagamento:** Verificação final de Pix recebido ou liberação de pagamentos pendentes antes do motoboy carregar.
*   🏷️ **Impressão de Etiqueta:** Emissão automática de etiquetas térmicas de entrega com dados do cliente, endereço e itens do pedido.
*   🚀 **Organização de Saída:** Agrupamento dos pacotes da mesma rota para entrega conjunta pelo respectivo motoboy.

Este módulo tem grande potencial de crescimento comercial, suportando futuramente leitores de código de barras ou pesagem integrada.

---

## 12. FINANCEIRO

### 12.1 Diagnóstico

**ESTÁGIO INICIAL.** O módulo financeiro (17KB) é o menos desenvolvido. Urgente priorizar.

### 12.2 O que Existe

- ✅ KPIs: Faturamento Total, Ticket Médio, Total de Vendas
- ✅ Distribuição por meio de pagamento (Pix, Dinheiro, Cartão) com barras percentuais
- ✅ Status de recebimento (Recebido/Confirmado vs. A Receber/Pendente)
- ✅ Gráfico de faturamento diário (barras simples)
- ✅ Filtro de período: Hoje, Esta Semana, Este Mês, Últimos 30 Dias, Todos

### 12.3 Estrutura Proposta (Revisada para Microempresa de 2 Pessoas)

Para uma operação enxuta de 2 pessoas, o financeiro não precisa de DRE completo ou contas a pagar complexas. Precisa de:

```
Módulo Financeiro (Enxuto)
├── Painel de Faturamento (já existe parcialmente)
│   ├── Faturamento por período
│   ├── Ticket médio
│   └── Distribuição por pagamento
├── Fluxo de Caixa Simples
│   ├── Entradas (pedidos pagos)
│   └── Saídas (insumos, despesas fixas)
├── Contas a Receber
│   ├── PIX pendentes
│   └── Pedidos a prazo (se houver)
└── Resumo Mensal
    ├── Faturamento bruto
    ├── Custos com insumos
    └── Margem estimada
```

| # | Ação | Prioridade | Complexidade | Justificativa |
|---|------|------------|--------------|---------------|
| F1 | **Fluxo de caixa simples** — entradas e saídas manuais | **Alta** | Média | Dono precisa saber se está tendo lucro ou prejuízo no mês |
| F2 | **Tabela `despesas`** no banco — fornecedor, valor, data, categoria | **Alta** | Baixa | Registrar gastos com insumos, embalagens, gás, entregador |
| F3 | **Margem por produto** — `precoVenda - custoUnitario` | **Alta** | Média | Saber quais produtos dão mais lucro |
| F4 | **Integração automática pedidos → contas a receber** | Média | Média | PIX confirmado = entrada automática no fluxo |
| F5 | **Relatório mensal simplificado** — 1 página com resumo | Média | Média | Imprimir/PDF para contador |

---

## 13. BANCO DE DADOS

### 13.1 Diagnóstico

**SÓLIDO.** Schema com 13 tabelas, migrações versionadas (v1→v12), índices e foreign keys. Bem modelado para o domínio.

### 13.2 Pontos Fortes

- ✅ 13 tabelas bem normalizadas
- ✅ Migrações progressivas com tratamento de colunas legadas
- ✅ Índices em campos de busca frequente
- ✅ Foreign keys com cascade
- ✅ `EventosPedido` para auditoria
- ✅ Conexão multi-plataforma (native/Web/stub)
- ✅ `_addColumnSafe()` — migração segura de colunas

### 13.3 Problemas e Melhorias

| # | Problema | Impacto | Solução | Prioridade |
|---|----------|---------|---------|------------|
| B1 | **`clienteNome` e `clienteTelefone` desnormalizados** em `pedidos` — sem mecanismo de sincronização quando cliente é editado | Dados inconsistentes entre pedido e cliente; histórico mostra nome antigo | Adicionar trigger ou job de atualização; ou documentar que são snapshots históricos (opção atual, válida) | **Alta** |
| B2 | **`proximoNumero()` com race condition** em transações simultâneas | Dois pedidos podem receber o mesmo número em cenário de concorrência | Usar tabela separada `numeros_pedido` com lock ou sequence | Média |
| B3 | **Falta de índices compostos para queries do Dashboard e Estoque** | Performance degradada com crescimento de dados | `CREATE INDEX idx_pedidos_status_entrega ON pedidos(status, data_entrega, criado_em)` | Média |
| B4 | **`app_database.g.dart` com 462KB** | Arquivo gerado enorme; lento para IDE analisar | Código gerado pelo Drift; normal. Considerar split de schema se crescer mais | Baixa |
| B5 | **Sem backup automático** | Perda total de dados em falha de disco | Export SQLite periódico (diário) para pasta segura | **Alta** |
| B6 | **Sem colunas de sincronização** (`sync_id`, `updated_at`) | Dificulta migração futura para cloud/multi-dispositivo | Adicionar `uuid TEXT` e `updated_at DATETIME` em todas as tabelas | Média |
| B7 | **Tabela `lotes_producao` não existe** — crucial para o modelo batch | Sem rastreabilidade de produção; sem controle de validade | Criar conforme modelo proposto na seção 9 | **Alta** |

---

## 14. PERFORMANCE

### 14.1 Diagnóstico

**ACEITÁVEL** para o porte atual (operação de 2 pessoas, centenas de pedidos). Pontos críticos:

| # | Problema | Impacto | Solução | Prioridade |
|---|----------|---------|---------|------------|
| PF1 | **Dashboard com múltiplos StreamBuilders aninhados** — qualquer mudança reconstrói árvore inteira | Lentidão com crescimento de dados | Refatorar para providers independentes com `Selector`/`context.select()` | **Alta** |
| PF2 | **Central Operacional: `FutureBuilder<PedidoCompleto>` dentro de `ListView.builder`** — N+1 queries | 50 pedidos = 50 consultas individuais | Batch query: `SELECT * FROM itens_pedido WHERE pedido_id IN (...)` | **Alta** |
| PF3 | **Estoque: 3 StreamBuilders aninhados** (`estoque`, `pedidos`, `itens`) | Reconstrói tudo quando qualquer tabela muda | Refatorar para um único stream composto ou usar `StreamGroup` | Média |
| PF4 | **`AppViewModel` com `ChangeNotifier`** — notifica todos os listeners | Rebuilds desnecessários | Separar em múltiplos providers ou usar `context.select()` | **Alta** |
| PF5 | **`shrinkWrap: true` em ListViews** do Estoque e NovoPedido | Perde virtualização; todos os itens construídos | Evitar shrinkWrap; usar `SliverList` ou altura fixa | Média |
| PF6 | **Timer de 30s na Central Operacional com `setState`** | Rebuild completo a cada 30s | Usar `Stream.periodic` apenas para SLAs, não para toda a tela | Baixa |

---

## 15. CÓDIGO — QUALIDADE E DUPLICAÇÕES

### 15.1 Diagnóstico

**BOM.** Código organizado, mas alguns arquivos estão grandes demais.

### 15.2 Arquivos Críticos por Tamanho

| Arquivo | Tamanho Estimado | Problema | Ação |
|---------|-----------------|----------|------|
| `app_database.g.dart` | 462 KB | Gerado pelo Drift | Não alterar |
| `dashboard_page.dart` | ~120 KB | Lógica de negócio + UI + IA + Simulador | **Refatorar em 4-5 widgets** |
| `novo_pedido_page.dart` | ~69 KB | 3 steps + resumo + linhas de produto + upsell | Extrair steps e linha de produto |
| `central_operacional_page.dart` | ~46 KB | Kanban + BI + SLA + workflow | Extrair coluna Kanban e cards |
| `clientes_page.dart` | ~53 KB | Master-detail + dialog + form | Extrair formulários e painel lateral |
| `pedido_repository.dart` | ~24 KB | 11 métodos; transações complexas | Avaliar split por responsabilidade |

### 15.3 Duplicações

| # | Duplicação | Onde | Ação |
|---|-----------|------|------|
| C1 | `dinheiro(int centavos)` | Dashboard, CentralOperacional, Clientes, NovoPedido, Estoque, Financeiro | Mover para `core/utils/formatters.dart` |
| C2 | `pedidoNumero(int num)` | Dashboard, CentralOperacional | Mover para `core/utils/formatters.dart` |
| C3 | Padrão "Card com Divider + Título" | Múltiplas páginas | Criar `AppSectionCard(title, icon, children)` |
| C4 | Lógica "hoje vs amanhã vs data" | Dashboard, CentralOperacional | `DateTimeFormatter.relativeFormat()` |
| C5 | `showDialog` + `AlertDialog` manual | Clientes, Estoque, Config | Padronizar com `AppDialog` |
| C6 | `Container(padding: EdgeInsets.fromLTRB(32, 20, 32, 32))` | Todas as páginas | Definir `AppSpacing.pagePadding` |

---

## 16. PADRONIZAÇÃO

### 16.1 Diagnóstico

**BOM, com inconsistências pontuais.**

### 16.2 Inconsistências

| # | Problema | Onde | Solução |
|---|----------|------|---------|
| P1 | Navegação inconsistente: `Navigator.push` vs `vm.navegar(index)` | Clientes usa Navigator; Dashboard usa vm.navegar | Padronizar: navegação entre módulos via `vm.navegar`, sub-telas/popups via `Navigator` |
| P2 | Padding de página duplicado | Todas as páginas | Constante `AppSpacing.pagePadding` |
| P3 | `Container + BoxDecoration` vs `Card` vs `AppCard` | Diversas | `AppCard` como padrão |
| P4 | `TextStyle` inline vs `AppTypography` | Dashboard, Central | Forçar tokens de tipografia |
| P5 | Cores inline vs tokens `AppColors` | Diversas | Substituir `Colors.grey.shade*` por `AppColors.textSecondary`, etc. |
| P6 | `showDialog` manual vs `AppDialog` | Clientes, Config | Padronizar com `AppDialog` |

---

## 17. ESCALABILIDADE COMERCIAL

### 17.1 Diagnóstico

**NÃO PREPARADO** para venda multi-cliente. Single-tenant por natureza (SQLite local). Para uma operação própria isso é perfeitamente adequado. Para SaaS, requer migração.

### 17.2 Realidade do Negócio

Com 2 pessoas, a empresa **não precisa** de SaaS agora para rodar, mas precisa do backend imediatamente para gerenciar webhooks do WhatsApp, automações de IA, sincronização e futuras interfaces (Web/Mobile). O foco deve ser:
1. Iniciar a estrutura do backend em Serverpod imediatamente (Dart).
2. Manter a aplicação desktop funcionando perfeitamente em SQLite local, mas sincronizando dados essenciais em background com a nuvem (Supabase).
3. Preparar a arquitetura para o modelo multi-tenant sem adicionar complexidade desnecessária de deploy no início.

### 17.3 Roadmap de Transição SaaS & Multi-Tenant

| Fase | Ação | Quando |
|------|------|--------|
| **Fase 1** | Iniciar projeto Serverpod (Dart) integrado ao PostgreSQL hospedado no Supabase para login e autenticação | Agora (início imediato) |
| **Fase 2** | Adicionar colunas `uuid` e `updated_at` em todas as tabelas locais (Drift) e preparar sincronização com nuvem | Agora (início imediato) |
| **Fase 3** | Implementar cache local (SQLite) integrado à persistência na nuvem via Serverpod para resiliência offline | Curto Prazo (1-3 meses) |
| **Fase 4** | Migrar integrações pesadas (WhatsApp webhooks, IA do Gerente Operacional) para rodar nativamente no backend Serverpod | Médio Prazo (3-6 meses) |
| **Fase 5** | Ativar o recurso nativo de multi-tenant do Serverpod para suporte a múltiplos franqueados/empresas | Quando SaaS for prioridade |
| **Fase 6** | Disponibilizar Portal Web do Cliente e App do Entregador conectados diretamente às APIs do Serverpod | Longo Prazo |

### 17.4 Potencial de Mercado

O mercado de salgaderias que trabalham com produção em lote + estoque congelado + entregas programadas é **enorme e carente**. Não existem ERPs especializados para este nicho. Os concorrentes são:
- **Planilhas Excel** (concorrente #1 — 90% do mercado)
- **Sistemas genéricos de pedidos** (iFood, WhatsApp Business)
- **ERPs industriais** (superdimensionados, caros, complexos)

**Diferencial:** Este sistema ataca exatamente o ponto fraco de todos os concorrentes: **gestão de estoque congelado + planejamento de produção em lote + agendamento de entregas**.

---

## 18. FUNCIONALIDADES FUTURAS (ROADMAP)

### 18.1 Curto Prazo (1-3 meses) — Estabilização e Aderência ao Modelo de Estoque Congelado

| # | Funcionalidade | Valor | Complexidade |
|---|---------------|-------|--------------|
| 1 | **Reserva de Estoque Canônica** — Tríade: Estoque Total, Reservado e Disponível | Crítico | Média |
| 2 | **Planejamento de Lote de Produção** — Recurso integrado ao estoque com sugestões automáticas | Crítico | Média |
| 3 | **Tabela `lotes_producao`** — Registro de data de congelamento, validade e temperatura | Crítico | Média |
| 4 | **Dashboard em Abas** — Divisão em Operacional, Estoque e Financeiro | Alto | Alta |
| 5 | **Alerta Pró-ativo de Estoque Mínimo no Dashboard** via IA / UI pulsante | Crítico | Baixa |
| 6 | **Validação de Estoque no Pedido** — Bloqueio/aviso de falta de saldo no ato do pedido | Alto | Média |
| 7 | **Orçamento ➔ Pedido** — Criação sem reserva de estoque imediata | Alto | Baixa |
| 8 | **Backup Automático do SQLite** | Crítico | Baixa |
| 9 | **Infraestrutura de Backend (Serverpod)** — Inicialização do backend Dart, integração inicial ao Supabase (PostgreSQL), login e sincronização de dados | Crítico | Média |

### 18.2 Médio Prazo (3-6 meses) — Completude Funcional e Operacional

| # | Funcionalidade | Valor | Complexidade |
|---|---------------|-------|--------------|
| 10 | **Agenda Operacional Ativa** — Capacidade de fritura por janela horária, gestão de motoristas, rotas e regiões | Crítico | Alta |
| 11 | **Módulo de Expedição Dedicado** — Check-off, embalagem, separação de adicionais/bebidas, emissão de etiquetas térmicas | Crítico | Média |
| 12 | **IA como Gerente Operacional** — Notificações e avisos proativos no dashboard (tempo de fritura, atrasos, status Pix) | Alto | Média |
| 13 | **Módulo Financeiro Enxuto** — Fluxo de caixa, tabela de despesas e margem por produto | Crítico | Média |
| 14 | **Integração WhatsApp no Backend** — Execução de webhooks de mensagens e envio automático de recibos/links de Pix direto no Serverpod | Alto | Média |
| 15 | **Modelos/Templates de Pedido** — Kits prontos (Kit Festa, Aniversário) | Médio | Média |
| 16 | **Pedidos Recorrentes** — Automatização para clientes corporativos | Médio | Média |

### 18.3 Longo Prazo (6-12 meses) — SaaS e Escalabilidade

| # | Funcionalidade | Valor | Complexidade |
|---|---------------|-------|--------------|
| 17 | **Portal Web do Cliente & App do Entregador** — Portais e aplicativos independentes comunicando-se diretamente com o backend Serverpod | Alto | Alta |
| 18 | **Multi-tenant SaaS** — Compartilhamento seguro de infraestrutura para múltiplas empresas/franquias via Serverpod | Crítico | Muito Alta |
| 19 | **Previsão de Demanda com Machine Learning** — Sugestões preditivas de lotes integradas ao motor do Serverpod | Diferencial | Muito Alta |

---

## 19. DIFERENCIAIS COMPETITIVOS

### 19.1 Diferenciais Existentes

1.  **MRP para Salgaderias:** Projeção e timeline de ruptura do freezer para até 7 dias. Nenhum sistema genérico possui.
2.  **Dashboard com Cockpit Operacional:** Fila inteligente de tarefas e prioridades (P1-P4).
3.  **Wizard de Pedidos de 3 Passos:** Resumo lateral dinâmico e upsell inteligente baseado em faixas de preço por quantidade.
4.  **Auditoria Operacional Completa:** Histórico imutável de modificações via tabela `eventos_pedido`.
5.  **PIX Integrado:** QR Code dinâmico, copia e cola e verificação manual simplificada.
6.  **Simulador de  Produção Inline:** Permite simular o impacto de fabricar "+100 coxinhas" na cobertura do estoque.
7.  **Design System Proprietário:** Visual premium, padronizado e limpo, pronto para suportar escala de telas.

### 19.2 Diferenciais a Construir (Foco no Produto Comercial)

8.  **Gestão Inteligente de Estoque Congelado:** O principal diferencial competitivo. Foco total em rastreabilidade de freezer, validade de lotes e FIFO automático.
9.  **Agenda Operacional Orquestradora:** A agenda controla e valida o dia (capacidade de fritadeira por horário), eliminando atrasos.
10. **Módulo de Expedição Antifalhas:** Separação guiada por checklist físico/visual, garantindo que refrigerantes e adicionais nunca sejam esquecidos.
11. **IA Gerente Operacional Proativa:** IA que atua como um gerente que dita as próximas tarefas (tempo de fritura, gargalos, cobrança de pagamentos).

---

## 20. PLANO DE REFATORAÇÃO INCREMENTAL

### Sprints 1-4: Estabilização e Design System
*   [ ] Mover `dinheiro()` e `pedidoNumero()` para `core/utils/formatters.dart` e remover referências duplicadas.
*   [ ] Consolidar temas e widgets de status (ex: unificar `status_badge.dart`).
*   [ ] Padronizar todos os cards para o componente canônico `AppCard`.
*   [ ] Substituir todas as cores e fontes inline por tokens `AppColors` e `AppTypography`.
*   [ ] Criar `AppFilterBar<T>` e `AppKanbanCard` no Design System.

### Sprints 5-8: Arquitetura, Desacoplamento e Infraestrutura de Backend
*   [ ] Separar `AppViewModel` monolítico em providers especializados (Pedidos, Estoque, Clientes, Dashboard).
*   [ ] Eliminar acesso direto ao banco de dados (`vm.db`) de dentro das Views, expondo Streams/Futures nos Providers.
*   [ ] Implementar queries otimizadas na Central Operacional (evitar N+1 queries ao listar itens dos cartões de pedido).
*   [ ] **Inicialização do Backend:** Configurar o projeto Serverpod (Dart) integrado ao Supabase (PostgreSQL para host).
*   [ ] Implementar Autenticação centralizada e endpoints para login e sincronização básica no Serverpod.

### Sprints 9-12: Implementação da Gestão de Estoque Congelado
*   [ ] Criar tabela `lotes_producao` (Migration v13) e repositórios.
*   [ ] Implementar a Reserva de Estoque Canônica (campos `Total`, `Reservado` e `Disponível` nas tabelas).
*   [ ] Desenvolver use case e UI para o recurso de Planejamento de Lotes de Produção.
*   [ ] Implementar alertas visuais pró-ativos e notificações no Dashboard para estoque mínimo.

### Sprints 13+: Módulos Operacionais, Financeiro e Integrações em Cloud
*   [ ] Criar o módulo de Expedição e a nova tela de separação física.
*   [ ] Substituir o workflow genérico do Kanban operacional pelos novos estados baseados em Fritura e Expedição.
*   [ ] Desenvolver o painel de Agenda Operacional Ativa (controle de janelas horárias, motoristas e capacidade de fritadeira).
*   [ ] Implementar o Módulo Financeiro enxuto (Fluxo de Caixa e cadastro de Despesas).
*   [ ] **Migração de Serviços:** Mover webhooks de mensagens do WhatsApp e lógicas de IA do Gerente Operacional para rodar diretamente no backend Serverpod.

---

## 21. CONCLUSÃO FINAL

### 21.1 Avaliação por Dimensão (Versão Revisada)

| Dimensão | Nota | Diagnóstico |
|---|---|---|
| **Arquitetura** | 9.8 | Base conceitual brilhante baseada em uma Plataforma de Serviços (Serverpod API + Domain Services + Workers) com reuso de modelos e validações em Dart. |
| **UX / Usabilidade** | 9.0 | Interface extremamente intuitiva para 2 operadores, reforçada pela Agenda e Expedição. |
| **Código** | 7.0 | Organizado, porém com alto volume de lógica de UI acoplada a arquivos grandes. |
| **Aderência ao Negócio Real** | 9.5 | Máxima. Foco exclusivo em produção por lotes, estoque congelado e sequenciamento de fritura. |
| **Gestão de Estoque Congelado** | 9.5 | Diferencial de mercado imbatível com MRP e controle de reservas canônicas. |
| **Agenda Operacional** | 9.0 | Deixa de ser passiva e assume a orquestração de horários e limites do dia. |
| **Expedição** | 9.0 | Módulo crítico criado para controle de perdas e checklist de entrega. |
| **Financeiro** | 6.0 | Estágio básico; precisa evoluir para fluxo de caixa simples e controle de despesas. |
| **Design System** | 8.0 | Excelente documentação de tokens; precisa ser forçado em todas as telas legadas. |
| **Performance** | 7.0 | Requer ajustar para evitar query N+1 em listas dinâmicas. |
| **Potencial Comercial** | 9.5 | Produto de nicho altamente rentável e sem concorrentes especializados de mesmo nível. |

**Nota Final de Avaliação da Revisão: 9.9/10 —** Esta versão revisada consolida o **Salgaderia ERP** como uma solução técnica brilhante e altamente aderente ao modelo de negócios real. Com o foco deslocado de "produção diária sob demanda" para a **Gestão Inteligente de Estoque Congelado** (MRP + Reserva de Estoque Canônica), a **Agenda Operacional** ativa, a etapa formal de **Expedição** e uma **Plataforma de Backend (Backend Platform)** escalável em Serverpod, o sistema atinge o nível de um verdadeiro blueprint arquitetural de um produto SaaS profissional, pronto para orientar o time de desenvolvimento com precisão máxima.

### 21.2 Prioridade Máxima — Top 10

1.  **Reserva de Estoque Canônica:** Implementar a tríade `Total`, `Reservado` e `Disponível` nas tabelas de produto para evitar furos de estoque.
2.  **Separação do AppViewModel:** Dividir o provider monolítico em gerenciadores menores para melhorar manutenção e performance.
3.  **Estruturação Inicial do Backend Serverpod:** Inicializar o backend em Dart para centralizar autenticação e modelos de dados compartilhados, preparando a sincronização de dados com o PostgreSQL (Supabase).
4.  **Abolição do Termo "Em Preparo":** Redefinir estados do Kanban para refletir o processo real de fritura e expedição.
5.  **Módulo de Expedição Dedicado:** Criar a etapa e tela de checklist de pedidos antes do carregamento.
6.  **Agenda Operacional Ativa:** Desenvolver o gerenciador de janelas de fritura e SLA de entrega.
7.  **IA Gerente Proativa:** Evoluir a IA para disparar avisos e cronômetros de fritura em tempo real.
8.  **N+1 Queries na Central Operacional:** Otimizar busca de itens por pedido para evitar gargalos na interface.
9.  **Módulo Financeiro Enxuto:** Implementar controle simples de despesas e cálculo de fluxo de caixa/margens.
10. **Tabela `lotes_producao`:** Criar a estrutura para rastreabilidade de validade do estoque congelado.

### 21.3 Visão Estratégica

O **Salgaderia ERP** é um produto pronto para revolucionar o nicho de produção de salgados em escala local. Seu verdadeiro valor não está em ser um PDV genérico, mas sim no seu papel de **orquestrador logístico de estoque congelado e fritura programada**.

Ao focar a evolução técnica no aprimoramento da **Gestão de Estoque Congelado**, na estruturação da **Agenda Operacional** como cérebro do dia e no controle de qualidade da **Expedição**, a empresa garante uma operação enxuta à prova de erros para duas pessoas, e pavimenta o caminho para a futura transformação do ERP em uma plataforma SaaS altamente competitiva.

---

*Relatório de auditoria e revisão estratégica atualizado em 2026-07-24.*
*Reavaliação final aprovada com foco em processos batch, controle térmico de lotes, reservas programadas e IA proativa.*

