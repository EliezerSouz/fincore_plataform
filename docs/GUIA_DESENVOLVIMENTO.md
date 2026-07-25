# GUIA DE DESENVOLVIMENTO — SISTEMA SALGADERIA

> **Versão:** 1.0 — Sprint 0  
> **Propósito:** Garantir consistência e previsibilidade à medida que o projeto cresce, especialmente ao adicionar novos módulos (estoque, financeiro).

---

## 1. ONDE CADA TIPO DE CÓDIGO VIVE

### Regra geral: seguir o fluxo de dependência

```
módulo/tela → provider → use case → port (interface) ← repository/service
```

### Tabela de decisão rápida

| O que você quer escrever | Onde vai | Muda na Fase 2? |
|--------------------------|----------|----------------|
| Regra de negócio (ex: faixas não se sobrepõem) | `domain/usecases/` | ❌ Não — migra para backend |
| Cálculo de preço | `domain/usecases/recalcular_preco_usecase.dart` | ❌ Não — vai para o backend |
| Interface/contrato de repositório | `domain/ports/` | ❌ Não — contrato estável |
| Modelo de negócio puro (sem Drift) | `domain/entities/` | ❌ Não — agnóstico |
| Query ao banco de dados | `data/repositories/` | ✅ Sim — vira chamada HTTP |
| Comunicação com impressora | `data/services/impressora_*.dart` | ❌ Não — local ao desktop |
| Configurações via SharedPreferences | `data/services/settings_service.dart` | ❌ Não — local ao desktop |
| Estado de UI de uma tela específica | `modules/<modulo>/providers/` | ❌ Não |
| Estado global (navegação, configurações carregadas) | `providers/app_view_model.dart` | ❌ Não |
| Widget usado em um módulo específico | `modules/<modulo>/widgets/` | ❌ Não |
| Widget usado em múltiplos módulos | `core/widgets/` | ❌ Não |
| Formatador de data/moeda | `core/utils/formatters.dart` | ❌ Não |
| Validador de formulário | `core/utils/validators.dart` | ❌ Não |
| Constantes visuais (cores, espaçamento) | `core/theme/app_theme.dart` | ❌ Não |
| Configuração de módulo futuro | `modules/estoque/README.md` ou `modules/financeiro/README.md` | — |

---

## 2. CONVENÇÕES DE NOMENCLATURA

### Arquivos

| Tipo | Sufixo | Exemplo |
|------|--------|---------|
| Página principal | `_page.dart` | `novo_pedido_page.dart` |
| Widget reutilizável | `_widget.dart` ou nome descritivo | `status_badge.dart` |
| Provider/ViewModel | `_provider.dart` ou `_view_model.dart` | `pedido_provider.dart` |
| Use case | `_usecase.dart` | `salvar_pedido_usecase.dart` |
| Repositório (implementação) | `_repository.dart` | `produto_repository.dart` |
| Port/Interface | `_port.dart` | `impressora_port.dart` |
| Serviço de infraestrutura | `_service.dart` | `settings_service.dart` |
| Entidade de domínio | nome simples | `produto.dart`, `cliente.dart` |
| Exceção | `_exception.dart` | (consolidadas em `app_exceptions.dart`) |

### Classes

| Tipo | Convenção | Exemplo |
|------|-----------|---------|
| Widget/Page | `PascalCase` | `NovoPedidoPage` |
| State interno | `_NomeDaPageState` | `_NovoPedidoPageState` |
| Provider | `NomeProvider` | `PedidoProvider` |
| Use case | `NomeUseCase` | `SalvarPedidoUseCase` |
| Interface/Port | `INome` (prefixo I) | `IImpressoraPort`, `IPedidoRepository` |
| Implementação concreta | `NomeTecnologia` | `ImpressoraEscPos`, `ImpressoraPdf` |
| Input object | `NomeInput` | `ClienteInput`, `FaixaPrecoInput` |
| Output object | `NomeOutput` ou `NomeResult` | `SalvarPedidoOutput` |

### Variáveis e métodos

- `camelCase` para variáveis e métodos
- `SCREAMING_SNAKE_CASE` para constantes
- Evitar abreviações crípticas: prefira `controller` a `c`, `repository` a `repo`, `viewModel` a `vm`
- Nomes de variáveis em português (consistente com o domínio existente)

---

## 3. REGRAS INEGOCIÁVEIS

### 3.0 A regra mais importante do ecossistema

> **Toda regra de negócio deve viver em `domain/usecases/`, nunca nas telas, nunca nos repositórios.**
>
> Hoje os use cases são executados localmente (SQLite). Amanhã serão executados no backend Go e os repositórios simplesmente chamarão a API. **O código dos use cases não muda entre Fase 1 e Fase 2 — apenas `data/repositories/` é trocado.**
>
> Isso significa: se você escrever uma validação de preço em uma tela hoje, ela precisará ser reescrita quando migrarmos para o backend. Se você escrevê-la em um use case, ela migra sem custo.


### 3.1 Nunca acessar o banco diretamente nas telas

```dart
// ❌ PROIBIDO
final db = context.read<AppViewModel>().db;
final pedidos = await db.select(db.pedidos).get();

// ✅ CORRETO
final pedidoProvider = context.read<PedidoProvider>();
final pedidos = pedidoProvider.pedidos; // já carregados pelo provider
```

### 3.2 Nunca usar implementação concreta de impressora nas telas

```dart
// ❌ PROIBIDO
final escpos = ImpressoraEscPos();
await escpos.imprimir(pedido, config);

// ✅ CORRETO
final impressora = context.read<IImpressoraPort>();
await impressora.imprimir(pedido, config);
```

### 3.3 Nunca colocar regra de negócio em widget/page

```dart
// ❌ PROIBIDO (em qualquer arquivo de page ou widget)
if (faixas.isEmpty) throw ArgumentError('Cadastre ao menos uma faixa.');
final total = itens.fold(0, (v, i) => v + i.totalCentavos);

// ✅ CORRETO
// Na tela:
final resultado = await context.read<PedidoProvider>().salvar(input);
// No use case:
if (input.itens.isEmpty) throw ValidacaoException('Adicione ao menos um item.');
```

### 3.4 Sempre verificar `mounted` após await em Widgets

```dart
// ❌ PROIBIDO
await vm.salvar();
ScaffoldMessenger.of(context).showSnackBar(...); // context pode estar inválido

// ✅ CORRETO
await vm.salvar();
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(...);
```

### 3.5 Nunca usar null assertion sem verificação prévia

```dart
// ❌ PROIBIDO
final valor = double.tryParse(controller.text)! * 100;

// ✅ CORRETO
final valor = double.tryParse(controller.text.replaceAll(',', '.'));
if (valor == null || valor <= 0) {
  setState(() => erro = 'Informe um valor válido.');
  return;
}
final centavos = (valor * 100).round();
```

---

## 4. PADRÃO DE FEEDBACK VISUAL

Use sempre os widgets padronizados em `core/widgets/`:

```dart
// Sucesso
AppSnackbar.sucesso(context, 'Pedido salvo com sucesso!');

// Erro
AppSnackbar.erro(context, 'Falha ao imprimir: $mensagem');

// Confirmação antes de ação destrutiva
final confirmar = await ConfirmDialog.mostrar(
  context,
  titulo: 'Excluir pedido?',
  mensagem: 'Esta ação não poderá ser desfeita.',
  acaoDestructiva: true,
);
if (confirmar != true) return;
```

---

## 5. PADRÃO DE ESTADO EM PROVIDERS

```dart
class MeuProvider extends ChangeNotifier {
  bool _carregando = false;
  String? _erro;
  List<MeuDado> _dados = [];

  bool get carregando => _carregando;
  String? get erro => _erro;
  List<MeuDado> get dados => List.unmodifiable(_dados);

  Future<void> carregar() async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      _dados = await _repository.buscarTodos();
    } catch (e) {
      _erro = e.toString();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }
}
```

---

## 6. PADRÃO DE TELA

```dart
class MinhaTela extends StatelessWidget {
  const MinhaTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pagina),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Cabecalho(),          // título + ação principal
          const SizedBox(height: AppSpacing.secao),
          Expanded(child: _Conteudo()),
        ],
      ),
    );
  }
}

// Widgets privados da tela como classes separadas (não funções)
class _Cabecalho extends StatelessWidget { ... }
class _Conteudo extends StatelessWidget { ... }
```

**Preferir classes a funções retornando Widget:**  
`_meuWidget()` → `class _MeuWidget extends StatelessWidget`

---

## 7. COMENTÁRIOS E DOCUMENTAÇÃO

- **Métodos públicos de repositórios e use cases:** obrigatório `///` doc comment
- **Métodos privados:** comentário apenas se não óbvio
- **Código comentado (`// código antigo`):** proibido — usar Git para histórico
- **TODOs:** formato `// TODO(autor): descrição` com prazo quando possível
- **FIXMEs:** tratar antes do PR; nunca subir FIXME para produção

---

## 8. ADICIONANDO UM NOVO MÓDULO (ex: Estoque)

1. Criar pasta `lib/modules/estoque/`
2. Definir entidades em `lib/domain/entities/` (ex: `movimento_estoque.dart`)
3. Definir port em `lib/domain/ports/estoque_repository_port.dart`
4. Implementar repositório em `lib/data/repositories/estoque_repository.dart`
5. Criar use cases em `lib/domain/usecases/`
6. Criar provider em `lib/modules/estoque/providers/`
7. Criar páginas em `lib/modules/estoque/pages/`
8. Registrar provider em `main.dart`
9. Adicionar item no `NavigationRail` em `main.dart`
10. Adicionar tabela ao schema em `app_database.dart` + migration

---

## 9. CHECKLIST ANTES DE CADA COMMIT

- [ ] `flutter analyze` — zero erros
- [ ] Nenhuma regra de negócio nas telas
- [ ] Nenhum acesso direto ao banco nas telas
- [ ] Toda impressão via `IImpressoraPort`
- [ ] `mounted` verificado após todo `await` em widgets
- [ ] Sem null assertions sem guard (`!` sem verificação)
- [ ] Sem `print()` esquecido — usar logger ou remover
- [ ] Sem código comentado

---

*Gerado em Sprint 0. Revisado a cada mudança de arquitetura significativa.*
