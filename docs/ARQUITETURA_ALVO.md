# ARQUITETURA ALVO — SISTEMA SALGADERIA

> **Versão-alvo:** 2.0.0 (ERP-ready)  
> **Estratégia:** Migração incremental — cada sprint move o sistema um passo em direção a esta arquitetura, sem quebrar funcionalidades existentes.

---

## 1. PRINCÍPIOS ARQUITETURAIS

### 1.1 Separação de responsabilidades (Clean-ish Architecture)

O sistema é dividido em **4 camadas**. A regra é simples: dependências apontam sempre para dentro (em direção ao domínio).

```
┌─────────────────────────────────────────────────────┐
│                  CAMADA DE APRESENTAÇÃO              │
│           (pages/, widgets/, providers/)             │
│     Conhece: Domain. Não conhece: Data layer.        │
├─────────────────────────────────────────────────────┤
│                  CAMADA DE APLICAÇÃO                 │
│              (domain/usecases/)                      │
│    Orquestra: entidades + contratos de repositório   │
├─────────────────────────────────────────────────────┤
│                  CAMADA DE DOMÍNIO                   │
│          (domain/entities/, domain/ports/)           │
│   Regras de negócio puras. Sem Flutter, sem Drift.   │
├─────────────────────────────────────────────────────┤
│                  CAMADA DE DADOS                     │
│         (data/repositories/, data/database/)         │
│  Implementa contratos do domínio. Conhece Drift.     │
└─────────────────────────────────────────────────────┘
```

### 1.2 Regra da impressão

A impressão é um **efeito colateral externo**. A tela nunca chama uma implementação concreta. O fluxo é:

```
Tela → UseCase → ImpressoraPort (interface)
                      ↑
             Injetado via Provider
                      │
         ┌────────────┴──────────────┐
         │                           │
  ImpressoraEscPos           ImpressoraPdf
  (USB/Rede/UNC)            (Preview/PDF)
```

### 1.3 Regra das telas

As telas **apenas:**
1. Observam estado via `watch<Provider>()`
2. Disparam ações via métodos do provider/use case
3. Exibem feedback visual (loading, erro, sucesso)

As telas **nunca:**
- Acessam repositórios diretamente
- Acessam o banco diretamente (`vm.db`)
- Contêm lógica de cálculo de preço
- Contêm lógica de validação de negócio

---

## 2. ESTRUTURA DE PASTAS ALVO

```
lib/
├── core/
│   ├── theme/
│   │   └── app_theme.dart              # ThemeData + tokens
│   ├── utils/
│   │   ├── formatters.dart             # dinheiro(), pedidoNumero()
│   │   └── validators.dart             # validadores reutilizáveis
│   └── widgets/
│       ├── app_snackbar.dart           # Snackbars padronizadas
│       ├── confirm_dialog.dart         # Diálogo de confirmação
│       ├── empty_state.dart            # Estado vazio
│       └── status_badge.dart           # Badge de status colorido
│
├── domain/
│   ├── entities/                       # Modelos puros de negócio (sem Drift)
│   │   ├── produto.dart
│   │   ├── cliente.dart
│   │   ├── pedido.dart
│   │   ├── item_pedido.dart
│   │   ├── faixa_preco.dart
│   │   └── grupo_preco.dart
│   ├── ports/                          # Interfaces (contratos)
│   │   ├── impressora_port.dart        # IImpressoraPort
│   │   ├── produto_repository_port.dart
│   │   ├── cliente_repository_port.dart
│   │   ├── pedido_repository_port.dart
│   │   └── grupo_preco_repository_port.dart
│   └── usecases/                       # Regras de negócio
│       ├── salvar_pedido_usecase.dart
│       ├── recalcular_preco_usecase.dart
│       ├── buscar_cliente_por_telefone_usecase.dart
│       ├── validar_faixas_preco_usecase.dart
│       └── duplicar_pedido_usecase.dart
│
├── data/
│   ├── database/
│   │   ├── app_database.dart           # Schema Drift
│   │   └── app_database.g.dart         # Gerado
│   ├── repositories/                   # Implementações dos ports
│   │   ├── produto_repository.dart
│   │   ├── cliente_repository.dart
│   │   ├── pedido_repository.dart
│   │   ├── grupo_preco_repository.dart
│   │   └── repositories.dart           # Barrel export
│   └── services/
│       ├── impressora_escpos.dart      # Impl. ESC/POS
│       ├── impressora_pdf.dart         # Impl. PDF/Preview
│       └── settings_service.dart
│
├── modules/
│   ├── dashboard/
│   │   └── pages/dashboard_page.dart
│   ├── pedidos/
│   │   ├── providers/pedido_provider.dart
│   │   ├── pages/
│   │   │   ├── novo_pedido_page.dart
│   │   │   └── historico_page.dart
│   │   └── widgets/
│   │       ├── pedido_detalhe.dart
│   │       └── preview_cupom.dart
│   ├── produtos/
│   │   └── pages/produtos_page.dart
│   ├── clientes/
│   │   └── pages/clientes_page.dart
│   ├── configuracoes/
│   │   └── pages/configuracoes_page.dart
│   ├── estoque/                        # FUTURO
│   │   └── README.md
│   └── financeiro/                     # FUTURO
│       └── README.md
│
├── providers/
│   ├── app_view_model.dart             # Navegação + settings + DB lifecycle
│   └── pedido_provider.dart            # Estado do pedido em andamento
│
└── main.dart
```

---

## 3. DIAGRAMA DE DEPENDÊNCIAS ALVO

```
┌────────────────────────────────────────────────────────────┐
│                         modules/ (telas)                    │
│  Acessa: providers/  Nunca acessa: data/ ou domain/ports/  │
└────────────────────┬───────────────────────────────────────┘
                     │ via Provider
                     ▼
┌────────────────────────────────────────────────────────────┐
│                        providers/                           │
│  AppViewModel: navegação, settings                          │
│  PedidoProvider: carrinho, cliente, cálculos               │
│  Acessa: domain/usecases/                                   │
└────────────────────┬───────────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────────┐
│                     domain/usecases/                        │
│  Recebe: domain/ports/ (interfaces)                         │
│  Retorna: domain/entities/                                  │
│  Nunca acessa: Drift, Flutter, IO                           │
└──────────┬─────────────────────────────────────────────────┘
           │ implementa
           ▼
┌────────────────────────────────────────────────────────────┐
│              domain/ports/ (interfaces)                     │
│  IImpressoraPort, IProdutoRepository, etc.                  │
└──────────────────────────────────────────────────────────┬─┘
                                                           │ implementado por
                                              ┌────────────┴──────────────────┐
                                              │        data/                  │
                                              │  repositories/ (Drift impl.)   │
                                              │  services/ (IO impl.)          │
                                              └───────────────────────────────┘
```

---

## 4. INTERFACE DE IMPRESSÃO — DETALHE

```dart
// domain/ports/impressora_port.dart
abstract interface class IImpressoraPort {
  /// Imprime o pedido no dispositivo configurado.
  /// Lança [ImpressoraException] em caso de falha.
  Future<void> imprimir(PedidoCompleto pedido, ConfiguracaoImpressora config);

  /// Gera um preview do cupom como texto formatado.
  Future<String> gerarPreviewTexto(PedidoCompleto pedido, ConfiguracaoImpressora config);

  /// Exporta o cupom para PDF.
  Future<Uint8List> exportarPdf(PedidoCompleto pedido, ConfiguracaoImpressora config);
}

// data/services/impressora_escpos.dart
final class ImpressoraEscPos implements IImpressoraPort {
  // Implementação USB / TCP-IP / UNC
}

// data/services/impressora_pdf.dart
final class ImpressoraPdf implements IImpressoraPort {
  // Geração de PDF via 'pdf' package
}
```

**Injeção:**
```dart
// main.dart
MultiProvider(providers: [
  Provider<IImpressoraPort>(create: (_) => ImpressoraEscPos()),
  ChangeNotifierProvider(create: (_) => AppViewModel(...)),
  ChangeNotifierProvider(create: (ctx) => PedidoProvider(
    ctx.read<IPedidoRepository>(),
    ctx.read<IImpressoraPort>(),
  )),
])
```

---

## 5. EVOLUÇÃO PARA MÓDULOS FUTUROS

### Estoque

O módulo de estoque precisará dos seguintes contratos:

```
IEstoqueRepository
  - observarMovimentos(): Stream<List<MovimentoEstoque>>
  - entrar(produtoId, quantidade, motivo): Future<void>
  - sair(produtoId, quantidade, motivo): Future<void>
  - saldoAtual(produtoId): Future<int>

Nova tabela: MovimentosEstoque
  - id, produtoId FK, tipo (entrada/saida), quantidade, motivo, criadoEm
```

### Financeiro

```
ILancamentoRepository
  - observarPorPeriodo(inicio, fim): Stream<List<Lancamento>>
  - salvar(Lancamento): Future<int>
  - categorias(): Stream<List<Categoria>>

Novas tabelas: Lancamentos, CategoriaFinanceira
```

**Estes módulos não afetarão o código existente** — apenas adicionam novas pastas em `modules/`, novas tabelas no banco e novos ports no domínio.

---

## 6. ESTADO DE MIGRAÇÃO — ERP WINDOWS

| Componente | Atual | Alvo | Sprint |
|-----------|-------|------|--------|
| Formatadores | em `app_theme.dart` | `core/utils/formatters.dart` | 1 |
| Validação de faixas | em `repositories.dart` | `domain/usecases/` | 2 |
| Regra de preço | em `CalculadoraPrecoGrupo` | `domain/usecases/` | 2 |
| Interface impressão | acoplada | `domain/ports/IImpressoraPort` | 2 |
| Repositórios | 1 arquivo | 4 arquivos individuais | 2 |
| Estado do pedido | em `AppViewModel` | `PedidoProvider` | 2 |
| Acesso ao DB nas telas | direto | via provider | 3 |
| Pastas de módulos | `pages/` plano | `modules/` por domínio | 4 |
| Módulo estoque | ausente | `modules/estoque/` | futuro |
| Módulo financeiro | ausente | `modules/financeiro/` | futuro |

---

## 7. VISÃO DE LONGO PRAZO — ARQUITETURA MULTICANAL

> **Esta seção documenta a direção estratégica do ecossistema completo.**  
> O ERP Windows em construção hoje se tornará o **painel administrativo** de um ecossistema multicanal. Nenhuma decisão tomada agora deve tornar esse caminho mais difícil.

### 7.1 Diagrama do Ecossistema

```
                        PostgreSQL
                             ▲
                             │
                      Backend (Go)
                      API REST / GraphQL
                             ▲
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
          ▼                  ▼                  ▼

  Flutter Desktop      Flutter Web        Flutter Android
  ERP (funcionários)   Portal (clientes)  App (entregadores)

  ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
  │ Cadastros    │    │ Login       │    │ Pedidos do   │
  │ Produtos     │    │ Produtos    │    │ dia          │
  │ Clientes     │    │ Quantidade  │    │ Saiu p/      │
  │ Pedidos      │    │ Entrega     │    │ entrega      │
  │ Financeiro   │    │ Pagamento   │    │ Entregue     │
  │ Estoque      │    │ Confirmar   │    │ Assinatura   │
  │ Relatórios   │    │ pedido      │    │ Foto         │
  └──────────────┘    └─────────────┘    └──────────────┘
```

### 7.2 Regra Arquitetural Fundamental

> **Toda regra de negócio — cálculo de preços por faixa, validação de pedidos, gestão de status, descontos, estoque e integrações de pagamento — deve residir exclusivamente no backend.**
>
> **Os aplicativos (Windows, Web e Mobile) são apenas consumidores da API. Eles nunca duplicam lógica de negócio.**

Isso garante:
- **Consistência total:** uma faixa de preço cadastrada no ERP é a mesma que o portal web usa
- **Zero duplicação:** a regra de "100 coxinhas = R$0,85 cada" existe em um único lugar
- **Evolução sem retrabalho:** alterar a regra no backend propaga para todos os clientes automaticamente

### 7.3 Como o ERP Atual Se Encaixa

O ERP Windows em construção hoje já está sendo projetado com essa visão em mente:

```
FASE 1 (agora)
  Flutter Desktop → SQLite
  Valida todo o fluxo operacional.
  As regras de negócio ficam em domain/usecases/ — prontas para migrar.

FASE 2 (próxima)
  Flutter Desktop → API (Go) → PostgreSQL
  O Desktop muda apenas a camada data/ (repositories apontam para API).
  domain/usecases/ permanece idêntico — não precisa ser reescrito.

FASE 3
  Flutter Web → mesma API → mesmo PostgreSQL
  Portal do cliente. Reutiliza domain/entities/ e domain/usecases/.

FASE 4
  Flutter Android → mesma API → mesmo PostgreSQL
  App do entregador. Mesmos contratos, novo cliente.
```

**O que muda na Fase 2:** apenas `data/repositories/` — de chamadas Drift/SQLite para chamadas HTTP à API.  
**O que não muda:** `domain/`, `modules/` (telas), `providers/`, `core/`. Nenhuma regra de negócio é reescrita.

### 7.4 Por Que Essa Arquitetura Funciona Agora

A decisão de usar `domain/ports/` (interfaces) para repositórios e impressão não é burocracia — é exatamente o que torna a Fase 2 uma troca cirúrgica, não uma reescrita:

```dart
// HOJE (Fase 1): implementação Drift
class ProdutoRepository implements IProdutoRepository {
  final AppDatabase db;
  // queries SQL via Drift
}

// AMANHÃ (Fase 2): implementação HTTP — mesmo contrato
class ProdutoRepositoryHttp implements IProdutoRepository {
  final ApiClient api;
  // chamadas REST
}

// O resto do sistema não muda nada.
// Apenas o main.dart troca qual implementação injeta.
```

### 7.5 Fluxo do Pedido no Ecossistema Completo

```
Portal Web (cliente)              ERP Windows (funcionário)
      │                                    │
      │  POST /api/pedidos                 │  Notificação em tempo real
      ▼                                    ▼
  Backend Go                          WebSocket / SSE
      │                            ──────────────────
      ├── Valida itens                NOVO PEDIDO Nº 251
      ├── Calcula preços (faixas)     Cliente: José
      ├── Verifica estoque            Status: Em aberto
      ├── Gera número único           [Aceitar] [Imprimir]
      └── Persiste no PostgreSQL
                │
                ▼
         App Entregador
         Pedido aparece na fila
         [Saiu para entrega]
         [Entregue] + Foto
```

### 7.6 Integrações Futuras

Todas pela API — os clientes Flutter não sabem quem provê o serviço:

| Integração | Como entra | Impacto nos clientes |
|-----------|-----------|---------------------|
| PIX (Pagar.me, Asaas) | Backend gera QR Code, retorna URL | Nenhum — exibe QR |
| Mercado Pago | Webhook no backend | Nenhum |
| WhatsApp (Z-API) | Backend dispara após pedido criado | Nenhum |
| Rastreamento entregador | App envia GPS, backend retém | Portal exibe status |
| Nota fiscal | Backend aciona SEFAZ | ERP exibe NF |

### 7.7 Tecnologias Recomendadas por Camada

| Camada | Tecnologia | Justificativa |
|--------|-----------|---------------|
| Backend | Go | Performance, binário único, excelente para APIs REST, tipagem forte |
| Banco de dados | PostgreSQL | Multiusuário, transações ACID, JSON nativo, escalável |
| ERP Desktop | Flutter Windows | Já em uso; reutiliza domain/ e entities/ |
| Portal Web | Flutter Web | Reutiliza código Flutter; mesmos widgets com adaptações |
| App Entregador | Flutter Android | Mesmo ecossistema; código compartilhado |
| Comunicação real-time | WebSocket (Go) | Notificações de novos pedidos no ERP |
| Autenticação | JWT + Refresh Token | Stateless, compatível com todos os clientes |

---

## 8. REGRAS DE DECISÃO — ONDE A LÓGICA VIVE

Quando surgir a dúvida "onde coloco este código?", aplicar esta árvore:

```
É uma regra de negócio?
  ├── Sim → domain/usecases/ (hoje) → backend Go (amanhã)
  └── Não → É uma query ao banco?
               ├── Sim → data/repositories/ (hoje) → HTTP client (amanhã)
               └── Não → É apresentação/feedback visual?
                            ├── Sim → modules/<modulo>/pages ou widgets/
                            └── Não → core/ (utils, widgets reutilizáveis)
```

---

*Gerado em Sprint 0 — Visão multicanal incorporada em 2026-07-21.*  
*Revisar antes de cada sprint para refletir o estado real.*
