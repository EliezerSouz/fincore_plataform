# ARQUITETURA ATUAL — SISTEMA SALGADERIA

> **Versão:** 1.0.0+1 | **Auditada em:** 2026-07-21  
> **Objetivo deste documento:** registrar fielmente o estado atual, sem julgamentos. Os problemas identificados estão em `AUDITORIA.md`.

---

## 1. VISÃO GERAL

O sistema é um aplicativo **Flutter Desktop (Windows)** de gestão de pedidos para salgaderia.

Banco de dados local: **Drift (SQLite)**.  
Gerenciamento de estado: **Provider (`ChangeNotifier`)**.  
Impressão: **ESC/POS via `esc_pos_utils_plus`**, enviado via `cmd /c copy /b` para compartilhamento Windows.

---

## 2. ESTRUTURA DE PASTAS

```
lib/
├── core/
│   └── theme/
│       └── app_theme.dart          # ThemeData + dinheiro() + pedidoNumero()
├── database/
│   ├── app_database.dart           # Schema Drift (tabelas + migrations)
│   └── app_database.g.dart         # Gerado pelo drift_dev
├── models/
│   └── domain_models.dart          # FaixaInput, ProdutoComGrupo, ItemCarrinho,
│                                   # ResumoGrupo, PedidoCompleto
├── pages/
│   ├── clientes/
│   │   └── clientes_page.dart      # Lista + form em AlertDialog + fn abrirCliente()
│   ├── configuracoes/
│   │   └── configuracoes_page.dart # Form de configurações (StatefulWidget)
│   ├── dashboard/
│   │   └── dashboard_page.dart     # 4 cards de métricas do dia
│   ├── pedidos/
│   │   ├── historico_page.dart     # Lista com busca + botão reimprimir
│   │   └── novo_pedido_page.dart   # Fluxo completo de criação de pedido
│   └── produtos/
│       └── produtos_page.dart      # Tabs: Produtos | Grupos de preço
├── providers/
│   └── app_view_model.dart         # Único provider: navegação + pedido + settings
├── repositories/
│   └── repositories.dart           # Todos os repos em 1 arquivo
├── services/
│   ├── calculadora_preco_grupo.dart # Recalcula preços por grupo
│   ├── impressora_service.dart      # ESC/POS + envio para impressora
│   └── settings_service.dart        # AppSettings + SharedPreferences
└── main.dart                        # SalgaderiaApp + Shell (NavigationRail)
```

---

## 3. DIAGRAMA DE DEPENDÊNCIAS

```
┌─────────────────────────────────────────────────────────────┐
│                         TELAS (pages/)                       │
│  DashboardPage  NovoPedidoPage  HistoricoPage  ProdutosPage  │
│  ClientesPage   ConfiguracoesPage                            │
└────────────┬──────────────────────────────┬─────────────────┘
             │ context.watch/read            │ context.read
             ▼                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    AppViewModel (Provider)                    │
│  - int pagina              - ProdutoRepository produtos      │
│  - bool ocupado            - GrupoPrecoRepository gruposPreco│
│  - AppSettings settings    - ClienteRepository clientes      │
│  - salvarPedido()          - PedidoRepository pedidos        │
│  - reimprimir()            - SettingsService settingsService  │
│  - salvarSettings()        - ImpressoraService impressora    │
└────────┬──────────────────────────────────────────┬─────────┘
         │                                          │
         ▼                                          ▼
┌─────────────────────┐                ┌────────────────────────┐
│   repositories.dart  │                │     services/           │
│  GrupoPrecoRepository│                │  ImpressoraService     │
│  ProdutoRepository   │                │  SettingsService        │
│  ClienteRepository   │                │  CalculadoraPrecoGrupo │
│  PedidoRepository    │                └────────────────────────┘
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   AppDatabase       │
│   (Drift / SQLite)  │
└─────────────────────┘
```

**Observação crítica:** As telas acessam `AppViewModel` que agrega repositórios, services e estado de navegação — violando SRP. O Dashboard ainda acessa `db` diretamente via `context.read<AppViewModel>().db`.

---

## 4. SCHEMA DO BANCO DE DADOS

### Versão atual: `schemaVersion = 2`

```
┌─────────────────────┐    ┌──────────────────────────┐
│     GruposPreco      │    │        Produtos           │
│─────────────────────│    │──────────────────────────│
│ id          PK      │◄───│ id          PK            │
│ nome        UNIQUE  │    │ nome                      │
│ descricao           │    │ categoria  DEFAULT Salgados│
│ ativo       DEFAULT T│   │ grupoPrecoId  FK→GruposPreco│
└─────────────────────┘    │ ativo       DEFAULT T     │
                           └──────────────────────────┘
                                        │
                                        │ (legado v1, não usado)
                                        ▼
┌─────────────────────────────────────────────────────┐
│                    FaixasPreco                       │
│─────────────────────────────────────────────────────│
│ id                    PK                            │
│ produtoId             FK→Produtos (nullable, LEGADO) │
│ grupoPrecoId          FK→GruposPreco (nullable)      │
│ quantidadeMinima                                    │
│ quantidadeMaxima      nullable (null = sem limite)  │
│ valorUnitarioCentavos                               │
└─────────────────────────────────────────────────────┘

┌──────────────────────┐    ┌──────────────────────────────────┐
│      Clientes         │    │           Pedidos                 │
│──────────────────────│    │──────────────────────────────────│
│ id          PK       │◄───│ id                  PK           │
│ nome                 │    │ numero              UNIQUE        │
│ telefone             │    │ clienteId           FK→Clientes   │
│ logradouro           │    │ clienteNome         (denorm.)     │
│ numero               │    │ clienteTelefone     (denorm.)     │
│ bairro               │    │ dataEntrega                      │
│ cidade               │    │ tipoEntrega                      │
│ cep                  │    │ formaPagamento                   │
│ referencia           │    │ trocoParaCentavos   nullable      │
│ observacoes          │    │ observacoes                      │
│ ativo       DEFAULT T│    │ subtotalCentavos                 │
└──────────────────────┘    │ taxaEntregaCentavos DEFAULT 0    │
                            │ totalCentavos                    │
                            │ status         DEFAULT Pendente  │
                            │ criadoEm       DEFAULT NOW()     │
                            └──────────────────────────────────┘
                                          │
                                          ▼
                            ┌──────────────────────────────────┐
                            │          ItensPedido              │
                            │──────────────────────────────────│
                            │ id                  PK           │
                            │ pedidoId            FK→Pedidos CASCADE│
                            │ produtoId           FK→Produtos  │
                            │ produtoNome         (denorm.)    │
                            │ quantidade                       │
                            │ valorUnitarioCentavos            │
                            │ valorTotalCentavos               │
                            └──────────────────────────────────┘
```

**Notas de design:**
- `clienteNome`, `clienteTelefone`, `produtoNome` são desnormalizados intencionalmente para preservar histórico
- `FaixasPreco.produtoId` é coluna legado da v1 — mantida por compatibilidade, não usada na v2
- **Não existem índices** além das PKs e UNIQUE constraints

---

## 5. FLUXO DE DADOS — NOVO PEDIDO

```
Usuário seleciona cliente
        │
        ▼
NovoPedidoPage._cliente() → StreamBuilder<List<Cliente>>
        │                   → DropdownButtonFormField
        │
Usuário busca produto
        │
        ▼
NovoPedidoPage._produtos() → StreamBuilder<List<Produto>>
        │                    → Autocomplete<Produto>
        │
        ▼ onSelected(produto)
NovoPedidoPage._adicionar()
        │
        ├── vm.produtos.comGrupo(produto)  [query assíncrona]
        │
        ├── showDialog(quantidade)          [input do usuário]
        │
        └── itens.add(ItemCarrinho)
                │
                ▼
        _recalcular()
                │
                └── CalculadoraPrecoGrupo.recalcular(itens)
                            │
                            └── GrupoPrecoRepository.preco(grupoId, qtd)
                                        │
                                        └── SQL: SELECT faixa WHERE minima≤qtd≤maxima

Usuário clica "Salvar e imprimir"
        │
        ▼
vm.salvarPedido(...)
        │
        ├── PedidoRepository.criar(...)    [transação SQL]
        │
        └── ImpressoraService.imprimir()
                │
                ├── Gera bytes ESC/POS
                ├── Salva .bin em systemTemp
                └── Process.run('cmd', ['/c', 'copy', '/b', arquivo, destino])
```

---

## 6. MODELO DE ESTADOS

```
AppViewModel {
  pagina: int           → qual aba está ativa (0-5)
  ocupado: bool         → true durante salvarPedido()
  settings: AppSettings → configurações carregadas via SharedPreferences
}

NovoPedidoPage._State {
  cliente: Cliente?         → cliente selecionado
  itens: List<ItemCarrinho> → carrinho
  resumos: List<ResumoGrupo>→ resumo de preços calculados
  tipo: String              → 'Entrega' | 'Retirada'
  pagamento: String         → 'Pix' | 'Dinheiro' | etc.
  entrega: DateTime         → data/hora de entrega
  taxa: TextEditingController
  troco: TextEditingController
  obs: TextEditingController
  erroPreco: String?        → mensagem de erro ao calcular
}
```

---

## 7. DEPENDÊNCIAS EXTERNAS

| Pacote | Versão | Uso |
|--------|--------|-----|
| `drift` | ^2.20.3 | ORM SQLite |
| `drift_flutter` | ^0.2.0 | Conexão SQLite no Flutter |
| `provider` | ^6.1.2 | Gerenciamento de estado |
| `intl` | ^0.19.0 | Formatação de moeda e data |
| `shared_preferences` | ^2.3.2 | Persistência de configurações |
| `esc_pos_utils_plus` | ^2.0.4 | Geração de bytes ESC/POS |
| `uuid` | ^4.5.1 | Presente em pubspec, **não utilizado no código** |
| `flutter_localizations` | sdk | Localização pt_BR |
| `path_provider` | ^2.1.4 | Caminhos de sistema |

**Observação:** `uuid` está declarado mas não há nenhuma importação ou uso encontrado nos arquivos de código.

---

## 8. PONTOS DE ACOPLAMENTO IDENTIFICADOS

| Local | Acoplamento | Problema |
|-------|-------------|---------|
| `dashboard_page.dart:11` | `context.read<AppViewModel>().db` | Tela acessa banco diretamente |
| `clientes_page.dart:112` | `vm.db.select(vm.db.clientes)` | Tela acessa banco diretamente |
| `novo_pedido_page.dart:9` | `import '../clientes/clientes_page.dart'` | Módulo pedidos acopla a módulo clientes |
| `app_theme.dart:4-6` | `dinheiro()`, `pedidoNumero()` | Formatadores no arquivo de tema |
| `repositories.dart:58` | `static validarFaixas()` | Validação de negócio em repositório |
| `impressora_service.dart:4` | `import '../core/theme/app_theme.dart'` | Serviço de impressão importa tema |

---

*Gerado em Sprint 0. Atualizar a cada mudança estrutural significativa.*
