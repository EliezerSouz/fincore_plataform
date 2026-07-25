# CONTRATOS DE INTERFACE — SISTEMA SALGADERIA

> **Sprint 0 — Definição de contratos**  
> Este documento define as interfaces que cada componente deverá implementar ou respeitar, servindo como contrato entre camadas. A implementação acontece nos sprints seguintes.

---

## 0. CONTEXTO — POR QUE ESSES CONTRATOS EXISTEM

O sistema está sendo construído em **Fase 1** (Flutter Desktop + SQLite), mas projetado para **Fase 2** (Flutter Desktop + API Go + PostgreSQL).

**Os contratos definidos aqui (ports/interfaces) são o que torna essa migração cirúrgica:**

```
FASE 1                              FASE 2
────────────────────────────────    ────────────────────────────────
IProdutoRepository                  IProdutoRepository
    ↑                                   ↑
ProdutoRepository (Drift)           ProdutoRepositoryHttp (HTTP)
    ↓                                   ↓
AppDatabase (SQLite)                ApiClient → Backend Go → PostgreSQL
```

O `domain/usecases/` e todos os clientes Flutter **nunca enxergam a implementação** — apenas o contrato `IProdutoRepository`. Por isso, trocar de Drift para HTTP exige alterar apenas `data/repositories/`, não as telas nem os use cases.

**Regra fundamental:**
> Nenhuma regra de negócio vive nos repositórios. Os repositórios apenas persistem e recuperam dados. As regras vivem nos `domain/usecases/` — e amanhã estarão no backend Go.

---

## 1. PORTS DE REPOSITÓRIO

### 1.1 `IGrupoPrecoRepository`

```dart
// Caminho futuro: lib/domain/ports/grupo_preco_repository_port.dart

abstract interface class IGrupoPrecoRepository {
  /// Stream reativo de todos os grupos ativos, ordenados por nome.
  Stream<List<GrupoPreco>> observar();

  /// Retorna as faixas de um grupo, ordenadas por quantidadeMinima.
  Future<List<FaixaPreco>> faixas(int grupoId);

  /// Busca o preço unitário (em centavos) para [quantidade] unidades no grupo.
  /// Retorna null se nenhuma faixa cobre a quantidade.
  Future<int?> preco(int grupoId, int quantidade);

  /// Salva (cria ou atualiza) um grupo e suas faixas atomicamente.
  /// Lança [ValidacaoException] se as faixas forem inválidas.
  Future<int> salvar({
    int? id,
    required String nome,
    String descricao = '',
    required List<FaixaPrecoInput> faixas,
  });

  /// Desativa um grupo (soft delete).
  Future<void> desativar(int id);
}
```

### 1.2 `IProdutoRepository`

```dart
// Caminho futuro: lib/domain/ports/produto_repository_port.dart

abstract interface class IProdutoRepository {
  /// Stream reativo de todos os produtos ativos, ordenados por nome.
  Stream<List<Produto>> observar();

  /// Retorna produto + grupo associado, ou null se sem grupo.
  Future<ProdutoComGrupo?> comGrupo(int produtoId);

  /// Salva (cria ou atualiza) um produto.
  Future<int> salvar({
    int? id,
    required String nome,
    required String categoria,
    required int grupoPrecoId,
    bool ativo = true,
  });

  /// Desativa um produto (soft delete).
  Future<void> desativar(int id);

  /// Retorna todas as categorias distintas cadastradas.
  Future<List<String>> categorias();
}
```

### 1.3 `IClienteRepository`

```dart
// Caminho futuro: lib/domain/ports/cliente_repository_port.dart

abstract interface class IClienteRepository {
  /// Stream reativo de todos os clientes ativos, ordenados por nome.
  Stream<List<Cliente>> observar();

  /// Busca um cliente pelo telefone exato. Retorna null se não encontrado.
  Future<Cliente?> porTelefone(String telefone);

  /// Busca clientes por nome (busca parcial, case-insensitive).
  Future<List<Cliente>> buscarPorNome(String nome);

  /// Salva (cria ou atualiza) um cliente.
  /// Lança [ValidacaoException] se o nome estiver vazio.
  Future<int> salvar(ClienteInput dados, {int? id});

  /// Desativa um cliente (soft delete).
  Future<void> desativar(int id);
}
```

### 1.4 `IPedidoRepository`

```dart
// Caminho futuro: lib/domain/ports/pedido_repository_port.dart

abstract interface class IPedidoRepository {
  /// Stream reativo de pedidos, com busca opcional e filtros.
  Stream<List<Pedido>> observar({
    String busca = '',
    String? status,
    String? tipoEntrega,
    DateTime? dataInicio,
    DateTime? dataFim,
    int limit = 50,
    int offset = 0,
  });

  /// Retorna um pedido completo (cabeçalho + cliente + itens).
  Future<PedidoCompleto> completo(int id);

  /// Cria um novo pedido em transação atômica.
  /// Lança [ValidacaoException] se itens estiverem vazios.
  Future<int> criar({
    required Cliente cliente,
    required DateTime entrega,
    required String tipoEntrega,
    required String formaPagamento,
    int? trocoParaCentavos,
    required String observacoes,
    required int taxaEntregaCentavos,
    required List<ItemCarrinho> itens,
  });

  /// Altera o status de um pedido.
  /// Status válidos: 'Pendente', 'Pronto', 'Entregue', 'Cancelado'
  Future<void> alterarStatus(int id, String status);

  /// Duplica um pedido existente (novo número, data = agora+2h, mesmos itens/cliente).
  Future<int> duplicar(int id);

  /// Exclui um pedido (soft delete via status 'Cancelado').
  Future<void> cancelar(int id);

  /// Retorna o próximo número de pedido de forma atômica (sem race condition).
  Future<int> proximoNumero();
}
```

---

## 2. PORT DE IMPRESSÃO

```dart
// Caminho: lib/domain/ports/impressora_port.dart
// Este é o único arquivo que telas e providers PODEM conhecer sobre impressão.

/// Configuração da impressora — separada de AppSettings para coesão.
class ConfiguracaoImpressora {
  final String endereco;    // UNC, IP:porta, ou 'LPT1'
  final int larguraMm;      // 58 ou 80
  final String rodape;
  final String nomeEmpresa;

  const ConfiguracaoImpressora({
    required this.endereco,
    this.larguraMm = 80,
    this.rodape = 'Obrigado pela preferência!',
    this.nomeEmpresa = 'Minha Salgaderia',
  });
}

/// Exceção lançada quando a impressão falha.
class ImpressoraException implements Exception {
  final String mensagem;
  final Object? causa;
  const ImpressoraException(this.mensagem, {this.causa});

  @override
  String toString() => 'ImpressoraException: $mensagem';
}

/// Contrato que toda implementação de impressora deve satisfazer.
abstract interface class IImpressoraPort {
  /// Imprime o pedido.
  /// Lança [ImpressoraException] se a impressão falhar.
  Future<void> imprimir(
    PedidoCompleto pedido,
    ConfiguracaoImpressora config,
  );

  /// Retorna o cupom formatado como texto puro (para preview).
  Future<String> gerarPreviewTexto(
    PedidoCompleto pedido,
    ConfiguracaoImpressora config,
  );

  /// Exporta o cupom como bytes de PDF.
  /// Retorna null se a implementação não suportar PDF.
  Future<Uint8List?> exportarPdf(
    PedidoCompleto pedido,
    ConfiguracaoImpressora config,
  );
}
```

---

## 3. USE CASES — CONTRATOS DE ENTRADA/SAÍDA

### 3.1 `SalvarPedidoUseCase`

```dart
// Entrada
class SalvarPedidoInput {
  final Cliente cliente;
  final DateTime dataEntrega;
  final String tipoEntrega;       // 'Entrega' | 'Retirada'
  final String formaPagamento;    // 'Pix' | 'Dinheiro' | 'Cartão Débito' | 'Cartão Crédito'
  final int? trocoParaCentavos;
  final String observacoes;
  final int taxaEntregaCentavos;
  final List<ItemCarrinho> itens;
}

// Saída
class SalvarPedidoOutput {
  final int pedidoId;
  final int numeroPedido;
}

// Contrato
abstract interface class ISalvarPedidoUseCase {
  Future<SalvarPedidoOutput> executar(SalvarPedidoInput input);
}
```

### 3.2 `RecalcularPrecoUseCase`

```dart
// Recalcula preços de todos os itens por grupo.
// Lança [StateError] se algum grupo não cobrir a quantidade.
abstract interface class IRecalcularPrecoUseCase {
  Future<RecalculoResult> executar(List<ItemCarrinho> itens);
}

class RecalculoResult {
  final List<ItemCarrinho> itensAtualizados; // com valorUnitarioCentavos preenchido
  final List<ResumoGrupo> resumos;
}
```

### 3.3 `BuscarClientePorTelefoneUseCase`

```dart
// Busca cliente pelo telefone. Retorna null se não encontrado.
abstract interface class IBuscarClientePorTelefoneUseCase {
  Future<Cliente?> executar(String telefone);
}
```

### 3.4 `ValidarFaixasPrecoUseCase`

```dart
// Valida consistência de faixas. Lança [ValidacaoException] se inválidas.
abstract interface class IValidarFaixasPrecoUseCase {
  void executar(List<FaixaPrecoInput> faixas);
}
```

---

## 4. EXCEPTIONS DE DOMÍNIO

```dart
// lib/core/errors/app_exceptions.dart

/// Erro de validação de regra de negócio.
class ValidacaoException implements Exception {
  final String mensagem;
  final String? campo; // campo específico que falhou, se aplicável
  const ValidacaoException(this.mensagem, {this.campo});
}

/// Erro de impressão.
class ImpressoraException implements Exception {
  final String mensagem;
  final Object? causa;
  const ImpressoraException(this.mensagem, {this.causa});
}

/// Recurso não encontrado.
class NaoEncontradoException implements Exception {
  final String recurso;
  const NaoEncontradoException(this.recurso);
}
```

---

## 5. INPUT OBJECTS (Value Objects)

```dart
// Usado em vez de passar classes Drift diretamente para use cases

class FaixaPrecoInput {
  final int minima;
  final int? maxima;     // null = sem limite superior
  final int valorCentavos;
}

class ClienteInput {
  final String nome;
  final String telefone;
  final String logradouro;
  final String numero;
  final String bairro;
  final String cidade;
  final String cep;
  final String referencia;
  final String observacoes;
}
```

---

## 6. REGRAS DE VALIDAÇÃO — CENTRALIZADAS

As seguintes regras de negócio devem estar **exclusivamente** nos use cases ou no domínio, nunca nas telas:

| Regra | Localização atual | Localização alvo |
|-------|------------------|-----------------|
| Faixas não podem se sobrepor | `GrupoPrecoRepository.validarFaixas()` | `ValidarFaixasPrecoUseCase` |
| Faixa sem quantidade/preço > 0 | `GrupoPrecoRepository.validarFaixas()` | `ValidarFaixasPrecoUseCase` |
| Pedido sem itens é inválido | verificação inline na tela | `SalvarPedidoUseCase` |
| Cliente deve ter nome | verificação inline | `ClienteRepository.salvar()` |
| Quantidade do grupo sem faixa = erro | `CalculadoraPrecoGrupo` | `RecalcularPrecoUseCase` |
| Valor de faixa deve ser > 0 | ausente (crash) | `ValidarFaixasPrecoUseCase` |

---

*Gerado em Sprint 0. Serve como contrato de desenvolvimento — qualquer desvio deve ser discutido antes de implementar.*
