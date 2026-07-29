# CHANGELOG — FINCORE Platform

> Todas as alterações notáveis, marcos arquiteturais e correções deste monorepo serão registradas neste arquivo, seguindo o padrão de versionamento semântico.

---

## [0.6.0-kds-production] — 2026-07-25
### Added (Milestone 6 — Módulo de Produção / KDS)
* **Tabelas do KDS no Drift**: Adicionadas as tabelas `OrdensPreparoTable` (fila ativa e máquina de estados da cozinha) e `LotesInsumoTable` (controle e validade FIFO).
* **Modelos do KDS**: Criados `OrdemPreparo`, `ItemOrdemPreparo` e `LoteInsumo` independentes de infraestrutura.
* **Repositórios KDS**: Criados `OrdemPreparoRepository` (busca filas ativas KDS) e `LoteInsumoRepository` (abastecimento FIFO e LIFO).
* **Estorno de Insumos LIFO**: Implementado o caso de uso `EstornarLoteEstoqueUseCase` que devolve as matérias-primas ao lote mais novo/recente que possuir capacidade livre.
* **Ergonomia no Workspace Cozinha**: Criada a tela `KdsScreen` com fontes 150% maiores (visíveis à distância) e botões de ação touch gigantes (64x64 dp).
* **Timer Ativo e Alerta de Atraso**: KDS exibe timer dinâmico de produção e aplica glow/border vermelho (`FincoreColors.danger`) se ultrapassar o tempo estimado.
* **FincoreShell Reativo**: Mapeamento do item de menu lateral "Produção / Cozinha" para exibir a `KdsScreen` ativa no lugar do antigo Empty State.

---

## [0.5.1-pdv-keyboard] — 2026-07-25
### Added (Task 1.2 — Épico I, PRD-008)
* **Atalhos de Teclado F1–F12 no PDV Express**: Mapa completo implementado conforme PRD-006 e PRD-008 Task 1.2.
  * `F1` → Catálogo de Produtos (foca automaticamente a barra de busca)
  * `F2` → Identificação do Cliente
  * `F3` → Ir direto para Pagamento
  * `F4` → Avançar Etapa (sequencial)
  * `F5` → Voltar Etapa
  * `F9` → Reimprimir Cupom Térmico
  * `F12` → Confirmar Venda (dispara `AguardandoPIX` ou finaliza diretamente)
  * `ESC` → Limpar/Resetar PDV completo
* **Borda de Foco Laranja Forno 2px**: Elemento ativo do teclado exibe `FincoreColors.primary` em 2px de border conforme diretrizes de acessibilidade (PRD-006).
* **Animação Shake (200ms)**: TweenSequence horizontal disparado em ação inválida (carrinho vazio, campos incompletos), conforme Motion Guidelines do PRD-006.
* **Flash Visual de Tecla no Footer**: Footer de atalhos exibe destaque visual animado na tecla pressionada com fundo `primary.withValues(alpha: 0.15)` por 400ms.
* **StepperHeader Aprimorado**: Cada etapa exibe o atalho correspondente `[F1]`, `[F2]`, `[F3]` abaixo do rótulo; etapa ativa tem glow sutil Laranja Forno.

---

## [0.5.0-supabase-infra] — 2026-07-25
### Changed
* **Arquitetura de Backend Definida**: Stack oficial consolidada — `Drift SQLite (local offline-first)` → `Serverpod API (regras de negócio)` → `Supabase PostgreSQL (banco central)`.
* **Supabase Integrado ao Flutter**: `supabase_flutter` adicionado ao `fincore_food_flutter` e inicializado no `DatabaseInitializer` via `flutter_dotenv`.
* **SupabaseConnector**: Implementação de `CoreServerConnector` que sincroniza as entradas da `OutboxSync` com as tabelas públicas do Supabase via REST.
* **Serverpod → Supabase PostgreSQL**: `config/development.yaml` atualizado para apontar ao banco PostgreSQL gerenciado pelo Supabase (`db.nlaxdeqbordmovukyypk.supabase.co:5432`). `config/production.yaml` atualizado com domínio FINCORE.
* **Segurança de Credenciais**: `.env` adicionado ao `.gitignore` do app Flutter. `config/passwords.yaml` do Serverpod já estava protegido.
* **DatabaseInitializer Refatorado**: Leitura de variáveis via `flutter_dotenv`, inicialização do Supabase SDK condicional (não executa em testes in-memory), e registro do `SupabaseConnector` no DI.

---

## [0.4.0-master-data-pricing] — 2026-07-25
### Added
* **Master Data Tables & Repositories**: Categorias, Produtos, Clientes, Locais de Entrega, Formas de Pagamento e Taxas de Entrega persistidos no Drift SQLite.
* **Pricing Engine Package**: Criação do pacote `fincore_pricing` contendo `PricingEngine` de cálculo de preços de faixas e prioridades, vigências de tabelas temporais e resolução de conflitos (PRD-122 e PRD-123).
* **N:N Pricing Tables**: Implementação da associação intermediária `ProdutoTabelaPrecificacao` para permitir que produtos pertençam a múltiplas tabelas.
* **Massa de Dados Inicial (Seeds)**: Efetivação do PRD-124 populando Empresa, Admin, Categorias, Produtos, Tabelas e Clientes no boot de teste.
* **Serverpod Postgres Models**: Modelagem de 9 esquemas de dados YAML no backend do Food.

## [0.3.0-platform-core] — 2026-07-25
### Added
* **Platform Core Package**: Criação do pacote `fincore_core` encapsulando infraestrutura multi-tenant, persistência local e remote sync.
* **TenantContext**: Singleton central de tenancy que valida obrigatoriamente a presença de contexto de sessão ativa.
* **BaseRepository**: Repositório abstrato com filtro implícito por inquilino ativo.
* **Outbox & SyncEngine**: Fila de escrita transacional SQLite e motor worker reativo de pushing de mutações locais.
* **AuditService**: Logs imutáveis de transações gravando autor, dispositivo e payload de dados.
* **DependencyInjection**: Service Locator desacoplado nativo em Dart.

## [0.0.2-monorepo] — 2026-07-25
### Added
* **Monorepo Directory Setup**: Criação oficial dos diretórios `/products/`, `/packages/` e `/tools/` contendo READMEs descritivos de acoplamento e responsabilidade de diretórios.
* **FINCORE Food Entry**: Definição inicial do vertical de alimentação `/products/fincore-food/` com README detalhando metas e escopo.
* **Monorepo Structure Guidelines**: Matriz de dependências permitidas e proibidas entre produtos e pacotes ([docs/MONOREPO_STRUCTURE.md](file:///f:/Eigent/fincore_platform/docs/MONOREPO_STRUCTURE.md)).

## [0.0.1-foundation] — 2026-07-25
### Added
* **Platform Charter**: Definição institucional de propósito, missão e padrões arquiteturais da **FINCORE** ([PLATFORM_CHARTER.md](file:///f:/Eigent/fincore_platform/PLATFORM_CHARTER.md)).
* **Engineering Guide**: Guia unificado de engenharia com o **Princípio da Reimplementação Consciente** e uso prático de IA ([ENGINEERING_GUIDE.md](file:///f:/Eigent/fincore_platform/ENGINEERING_GUIDE.md)).
* **Onboarding Path**: Rota obrigatória de leitura para novos colaboradores e IAs ([ONBOARDING.md](file:///f:/Eigent/fincore_platform/ONBOARDING.md)).
* **Product Reset v1.0.0**: Cópia física de todos os 11 documentos de governança congelados na pasta local `docs/`.
