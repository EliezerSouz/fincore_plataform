import '../database/app_database.dart';

/// Tipos de movimentação de estoque de produtos acabados.
enum TipoMovimentacaoEstoque {
  producao('PRODUCAO', 'Entrada por Produção', true),
  venda('VENDA', 'Saída por Venda (Pedido)', false),
  cancelamentoVenda('CANCELAMENTO_VENDA', 'Entrada por Cancelamento', true),
  ajusteEntrada('AJUSTE_ENTRADA', 'Ajuste de Entrada', true),
  ajusteSaida('AJUSTE_SAIDA', 'Ajuste de Saída', false),
  perda('PERDA', 'Saída por Perda/Avaria', false),
  doacao('DOACAO', 'Saída por Doação', false),
  inventario('INVENTARIO', 'Correção de Inventário', true);

  final String codigo;
  final String descricao;
  final bool ehEntrada;

  const TipoMovimentacaoEstoque(this.codigo, this.descricao, this.ehEntrada);

  static TipoMovimentacaoEstoque porCodigo(String codigo) {
    return TipoMovimentacaoEstoque.values.firstWhere(
      (t) => t.codigo == codigo,
      orElse: () => TipoMovimentacaoEstoque.ajusteEntrada,
    );
  }
}

class MovimentacaoEstoqueInput {
  final int produtoId;
  final TipoMovimentacaoEstoque tipo;
  final int quantidade;
  final String motivo;
  final int? pedidoId;

  const MovimentacaoEstoqueInput({
    required this.produtoId,
    required this.tipo,
    required this.quantidade,
    this.motivo = '',
    this.pedidoId,
  });
}

class FaixaInput {
  final int minima;
  final int? maxima;
  final int valorCentavos;
  const FaixaInput(this.minima, this.maxima, this.valorCentavos);

  bool atende(int quantidade) =>
      quantidade >= minima && (maxima == null || quantidade <= maxima!);
}

class ProdutoComGrupo {
  final Produto produto;
  final GruposPrecoData grupo;
  const ProdutoComGrupo(this.produto, this.grupo);
}

class ItemCarrinho {
  final Produto produto;
  final GruposPrecoData grupo;
  int quantidade;
  int valorUnitarioCentavos;
  ItemCarrinho(
      {required this.produto,
      required this.grupo,
      required this.quantidade,
      this.valorUnitarioCentavos = 0});
  int get totalCentavos => quantidade * valorUnitarioCentavos;
}

class ResumoGrupo {
  final GruposPrecoData grupo;
  final int quantidade;
  final int valorUnitarioCentavos;
  const ResumoGrupo(this.grupo, this.quantidade, this.valorUnitarioCentavos);
}

class PedidoCompleto {
  final Pedido pedido;
  final Cliente cliente;
  final List<ItensPedidoData> itens;
  const PedidoCompleto(this.pedido, this.cliente, this.itens);
}

class ProdutoComEstoque {
  final Produto produto;
  final int saldoAtual;
  final int reservado;
  final int reservadoComercial;
  final int reservadoOperacional;
  final int estoqueMinimo;
  final int estoqueIdeal;
  final int loteMinimo;

  int get disponivel => (saldoAtual - reservado);

  const ProdutoComEstoque({
    required this.produto,
    required this.saldoAtual,
    required this.reservado,
    this.reservadoComercial = 0,
    this.reservadoOperacional = 0,
    required this.estoqueMinimo,
    required this.estoqueIdeal,
    required this.loteMinimo,
  });
}
