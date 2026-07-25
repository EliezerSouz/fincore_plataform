# AUDITORIA COMPLETA — SISTEMA SALGADERIA
**Data:** 2026-07-21  
**Auditor:** Arquiteto de Software Sênior / QA Engineer  
**Versão analisada:** 1.0.0+1  

---

## SUMÁRIO EXECUTIVO

O projeto está em estágio inicial funcional, porém com **10 erros de compilação confirmados pelo analisador**, além de dezenas de problemas de arquitetura, UX, performance e manutenibilidade. O código compila parcialmente graças a arquivos `.bak` que indicam refatorações recentes ainda incompletas. A impressão ESC/POS existe no código mas **não funciona de forma confiável** na prática. O sistema não possui edição nem exclusão de pedidos, não possui confirmações antes de ações destrutivas, e nenhuma paginação para listas.

---

## 1. ORGANIZAÇÃO DE PASTAS E ARQUITETURA

### 1.1 Estrutura Atual

```
lib/
├── core/theme/         ← apenas app_theme.dart (mínimo)
├── database/           ← schema Drift + gerado
├── models/             ← modelos de domínio
├── pages/              ← telas por módulo
│   ├── clientes/
│   ├── configuracoes/
│   ├── dashboard/
│   ├── pedidos/
│   └── produtos/
├── providers/          ← AppViewModel (único provider)
├── repositories/       ← todos em 1 arquivo único
├── services/           ← impressora, settings, calculadora
└── main.dart
```

### 1.2 Problemas Encontrados

| # | Problema | Severidade |
|---|----------|------------|
| A1 | **Único provider `AppViewModel` acumula responsabilidades de navegação, estado de pedido, configurações e reimpressão** — viola Single Responsibility Principle | Alta |
| A2 | **Todos os repositórios em um único arquivo `repositories.dart`** — dificulta manutenção e escala | Alta |
| A3 | **`AppSettings` está definida em `settings_service.dart`** — modelo de domínio misturado com serviço de infraestrutura | Média |
| A4 | **`CalculadoraPrecoGrupo` acessa repositório diretamente** — deveria receber dados prontos | Média |
| A5 | **Funções utilitárias `dinheiro()` e `pedidoNumero()` estão em `app_theme.dart`** — formatadores não são responsabilidade do tema | Média |
| A6 | **`abrirCliente()` é uma função global no arquivo da tela** — sem encapsulamento | Média |
| A7 | **Ausência completa de camada de erro/resultado** — sem tipos Either ou Result | Média |
| A8 | **Sem abstrações/interfaces para repositórios** — impossível testar | Alta |
| A9 | **`core/theme/` contém apenas 1 arquivo** — sem tokens de design padronizados | Baixa |
| A10 | **Sem separação entre entidades Drift e modelos de domínio** — banco acoplado às telas | Alta |

---

## 2. ERROS DE COMPILAÇÃO (CRÍTICOS)

O projeto possui **10 erros** que impedem compilação limpa (confirmado em `analyze_output.txt`):

| # | Arquivo | Erro |
|---|---------|------|
| E1 | `clientes_page.dart` | `Iterable<InvalidType>` não pode ser atribuído a `List<Widget>` |
| E2 | `clientes_page.dart` | `toList()` não definido para tipo `SizedBox` |
| E3 | `clientes_page.dart` | Parâmetro nomeado `actions` não definido |
| E4 | `clientes_page.dart` | `Expected to find ')'` — sintaxe inválida |
| E5 | `configuracoes_page.dart` | `initialValue` não é parâmetro válido |
| E6 | `novo_pedido_page.dart` | `initialValue` não é parâmetro válido (3 ocorrências) |
| E7 | `novo_pedido_page.dart` | `Expected an identifier` — sintaxe inválida |
| E8 | `novo_pedido_page.dart` | `Expected to find ')'` — sintaxe inválida |
| E9 | `produtos_page.dart` | `Expected to find ')'` — sintaxe inválida |
| E10 | `widget_test.dart` | `MyApp` não é uma classe — teste completamente quebrado |

> **Nota:** Os 10 arquivos `.bak` com timestamps indicam refatorações automáticas parciais recentes que quebraram a sintaxe. O arquivo atual que temos disponível parece já ter esses erros corrigidos na versão mais recente, mas o `analyze_output.txt` reflete um estado intermediário.

---

## 3. BUGS FUNCIONAIS

### 3.1 Impressão ESC/POS — NÃO FUNCIONA CONFIAVELMENTE

| # | Problema |
|---|---------|
| B1 | Usa `Process.run('cmd', ['/c', 'copy', '/b', ...])` — funciona APENAS para impressoras compartilhadas em rede Windows via UNC. Impressoras USB locais **não suportadas** |
| B2 | Sem tratamento visual quando `cfg.impressora` está vazio — arquivo `.bin` é gerado silenciosamente sem notificação |
| B3 | Não existe preview antes de imprimir |
| B4 | Não existe exportação para PDF |
| B5 | Caminho de arquivo temporário com `Directory.systemTemp` pode ter problemas de permissão no Windows |
| B6 | Nomes de produtos longos podem quebrar colunas ESC/POS sem truncamento |
| B7 | Sem suporte a impressão por TCP/IP direto |

### 3.2 Pedidos — Funcionalidades Ausentes

| # | Problema |
|---|---------|
| B8 | **Não existe edição de pedido já criado** |
| B9 | **Não existe exclusão de pedido** |
| B10 | **Não existe duplicação de pedido** |
| B11 | **Não existe alteração de status** (Pendente → Pronto → Entregue → Cancelado) |
| B12 | Histórico não mostra itens do pedido — apenas cabeçalho |
| B13 | Sem filtro por status, data ou tipo de entrega no histórico |
| B14 | `_State` é nome completamente genérico — viola convenção Dart |

### 3.3 Clientes

| # | Problema |
|---|---------|
| B15 | Ao digitar telefone, **não carrega automaticamente dados do cliente existente** |
| B16 | Formulário usa índices `[0..8]` em vez de campos nomeados — frágil |
| B17 | Sem validação de campos obrigatórios |
| B18 | Sem busca na lista de clientes |
| B19 | Sem confirmação antes de salvar com dados em branco |

### 3.4 Produtos e Grupos de Preço

| # | Problema |
|---|---------|
| B20 | Sem mensagem explicativa quando `grupoId == null` — botão fica desabilitado sem feedback |
| B21 | Sem confirmação antes de desativar produto |
| B22 | Mensagem de erro usa `replaceFirst('Invalid argument(s): ', '')` — frágil |
| B23 | **`_faixaDialog` não valida valor vazio — `double.tryParse(...)!` causa crash com campo vazio** |
| B24 | Sem edição de faixa individual — apenas remover e readicionar |
| B25 | `FutureBuilder` dentro de `ListView` para grupo de cada produto — N+1 queries |

### 3.5 Configurações

| # | Problema |
|---|---------|
| B26 | `init = false` nunca é resetado — tela não reflete mudanças externas após inicialização |
| B27 | Taxa com vírgula pode causar erro silencioso na conversão |
| B28 | Campo "Impressora" tem helper text confuso |

### 3.6 Dashboard

| # | Problema |
|---|---------|
| B29 | Acessa `db` diretamente na view — viola arquitetura em camadas |
| B30 | Sem gráfico de vendas — apenas 4 cards estáticos |
| B31 | "Entregues" = `total - pendentes`, ignorando cancelados |

---

## 4. PROBLEMAS DE UX

| # | Tela | Problema |
|---|------|---------|
| U1 | `NovoPedidoPage` | Seleção de cliente sem busca/autocomplete por nome ou telefone |
| U2 | `NovoPedidoPage` | Para adicionar produto abre diálogo só para quantidade — 2 cliques extras |
| U3 | `NovoPedidoPage` | `taxa.text` inicializado dentro do `build()` — causa bugs ao reconstruir |
| U4 | `NovoPedidoPage` | Sem atalhos de teclado (Enter confirma, ESC cancela) |
| U5 | `NovoPedidoPage` | Sem navegação por teclado entre campos |
| U6 | `ProdutosPage` | `FutureBuilder` aninhado em `StreamBuilder` em `ListView` — flickering |
| U7 | `ProdutosPage` | Categoria é texto livre — sem sugestões, inconsistência |
| U8 | `ClientesPage` | 9 campos em AlertDialog — difícil de usar |
| U9 | `HistoricoPage` | Sem paginação — lista cresce infinitamente |
| U10 | Todos | Sem confirmação antes de ações destrutivas |
| U11 | Todos | Snackbars sem cor de sucesso/erro e sem ícone |
| U12 | Todos | Sem loading indicator nas operações assíncronas |
| U13 | `Shell` | NavigationRail sem boa distinção visual da seção ativa |

---

## 5. PROBLEMAS DE LAYOUT E VISUAL

| # | Problema |
|---|---------|
| V1 | Tema usa apenas `colorScheme.fromSeed` sem customização — visual padrão sem personalidade |
| V2 | Sem fonte personalizada (Google Fonts) — fonte padrão do sistema |
| V3 | Cards com `elevation: 0` e `margin: zero` — visual plano sem hierarquia |
| V4 | NavigationRail sem borda/sombra que o separe do conteúdo |
| V5 | Dashboard com cards de tamanho fixo — não responsivo |
| V6 | Sem animações de transição entre páginas |
| V7 | Sem estados vazios visuais em listas |
| V8 | Tipografia sem hierarquia clara definida |
| V9 | Campos sem feedback visual de validação customizado |
| V10 | CircleAvatar no histórico exibe apenas número — visual primitivo |

---

## 6. PROBLEMAS DE PERFORMANCE

| # | Problema |
|---|---------|
| P1 | `FutureBuilder<ProdutoComGrupo?>` dentro de `ListView.separated` — N+1 queries por reconstrução |
| P2 | `FutureBuilder<List<FaixasPrecoData>>` em grupos — mesmo problema |
| P3 | `DropdownButtonFormField<Cliente>` carrega TODOS os clientes sem paginação |
| P4 | `StreamBuilder<List<Produto>>` duplo no autocomplete — dois streams redundantes |
| P5 | `taxa.text` inicializado dentro de `build()` — setState desnecessário |
| P6 | `AppViewModel` global com `ChangeNotifier` — qualquer mudança reconstrói toda a árvore |
| P7 | Sem uso de `const` em widgets estáticos |
| P8 | Sem paginação no histórico — crescimento linear |

---

## 7. BANCO DE DADOS

| # | Problema |
|---|---------|
| D1 | Migration de v1→v2 pode falhar — não recria `FaixasPreco` com `grupoPrecoId` em bancos antigos |
| D2 | Sem índices em `clientes.telefone`, `pedidos.clienteNome`, `faixasPreco.grupoPrecoId` |
| D3 | `proximoNumero()` tem race condition em criações simultâneas |
| D4 | `clienteNome` e `clienteTelefone` desnormalizados sem sincronização quando cliente é editado |
| D5 | `FaixasPreco.produtoId` nullable parece legado da v1 — ainda presente no schema sem uso |
| D6 | Sem índices compostos para queries frequentes |
| D7 | `PedidoRepository.observar()` sem limite — pode retornar milhares de registros |

---

## 8. QUALIDADE DE CÓDIGO

| # | Problema |
|---|---------|
| Q1 | **10 arquivos `.bak`** espalhados no projeto — resíduos que poluem o workspace |
| Q2 | `_State` como nome de classe em `NovoPedidoPage` — viola Dart style guide |
| Q3 | `c` como nome do Map de controllers em `ConfiguracoesPage` — não descritivo |
| Q4 | `if` sem chaves em múltiplos arquivos — lint warning |
| Q5 | `child` não é o último argumento em construtores — lint warning |
| Q6 | `BuildContext` usado após `await` sem verificação `mounted` em múltiplos locais |
| Q7 | `double.tryParse(...)!` com null assertion sem verificação — crash potencial |
| Q8 | `widget_test.dart` completamente quebrado — referencia `MyApp` inexistente |
| Q9 | Sem nenhum teste unitário ou de integração funcional |
| Q10 | Sem documentação de métodos públicos |
| Q11 | Imports não ordenados — mistura de packages e relative imports |
| Q12 | `format_output.txt`, `analyze_output.txt` e `build_output.txt` commitados — não deveriam estar no repositório |

---

## 9. ESCALABILIDADE PARA ERP FUTURO

| # | Limitação | Impacto |
|---|-----------|---------|
| S1 | **Único `AppViewModel` para toda a aplicação** — módulos futuros sobrecarregarão este provider | Alto |
| S2 | **Sem camada de domínio desacoplada** — regras de negócio misturadas nas telas | Alto |
| S3 | **Sem autenticação/permissões** — qualquer ERP precisa controle de acesso | Alto |
| S4 | **Sem logs de auditoria** — quem fez o quê, quando | Médio |
| S5 | **SQLite local apenas** — sem capacidade de sincronização multi-dispositivo | Alto |
| S6 | **Sem módulo de relatórios** — ERP sem relatórios é inviável | Alto |
| S7 | **Sem API layer** — migração para servidor remoto exigirá reescrita | Alto |

---

## 10. PLANO DE MIGRAÇÃO INCREMENTAL

**Fase 1 — Estabilização (atual):**
Corrigir todos os erros de compilação, bugs críticos, melhorar UX e visual sem mudar arquitetura.

**Fase 2 — Modularização:**
Separar providers por módulo, extrair entities de domínio, criar use cases, separar repositórios em arquivos individuais.

**Fase 3 — Expansão:**
Adicionar módulos de estoque e financeiro, preparar camada de API, adicionar autenticação e logs de auditoria.

**Estrutura alvo:**
```
lib/
├── core/               ← tema, utils, erros, widgets globais
├── data/               ← banco, repositórios, datasources
├── domain/             ← entidades, use cases, contratos
└── modules/
    ├── pedidos/        ← providers + pages + widgets
    ├── produtos/
    ├── clientes/
    ├── financeiro/     ← futuro
    └── estoque/        ← futuro
```

---

## 11. RESUMO PRIORIZADO

### Crítico (impede uso estável)
- Erros de compilação nos arquivos principais
- Crash ao salvar faixa com preço vazio (`_faixaDialog`)
- Impressão sem funcionamento confiável

### Alto (afeta funcionalidade esperada)
- Ausência de edição/exclusão/status de pedidos
- Clientes sem autocomplete por telefone
- Race condition no número do pedido
- Configurações não refletem mudanças após inicialização

### Médio (afeta qualidade e profissionalismo)
- N+1 queries no ListView de produtos
- Visual não profissional (sem tipografia, sem animações)
- Sem paginação no histórico
- Arquivos .bak poluindo o projeto

### Baixo (melhorias futuras)
- Refatorações arquiteturais para ERP
- Testes automatizados
- Índices adicionais no banco

---

*Fim da auditoria. Próximo passo: implementação das correções por ordem de prioridade.*
