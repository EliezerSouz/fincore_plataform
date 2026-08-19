
/// Dados do pedido necessários para gerar o template de impressão.
/// Imutável — contém tudo que um template precisa para renderizar.
class PrintData {
  final String pedidoId;
  final String? clienteNome;
  final String? clienteTelefone;
  final String tipoLogistica; // 'Entrega', 'Retirada', 'Mesa'
  final String? endereco;
  final String? bairro;
  final String? referencia;
  final String? mesa;
  final String formaPagamento;
  final int totalCentavos;
  final int? taxaEntregaCentavos;
  final int? descontoCentavos;
  final List<PrintDataItem> itens;
  final DateTime dataHora;
  final String? observacao;

  const PrintData({
    required this.pedidoId,
    this.clienteNome,
    this.clienteTelefone,
    required this.tipoLogistica,
    this.endereco,
    this.bairro,
    this.referencia,
    this.mesa,
    required this.formaPagamento,
    required this.totalCentavos,
    this.taxaEntregaCentavos,
    this.descontoCentavos,
    required this.itens,
    required this.dataHora,
    this.observacao,
  });

  String get shortId =>
      pedidoId.length > 8 ? pedidoId.substring(0, 8).toUpperCase() : pedidoId.toUpperCase();
}

class PrintDataItem {
  final String nome;
  final double quantidade;
  final int precoUnitarioCentavos;
  final int totalCentavos;
  final String? observacao;

  const PrintDataItem({
    required this.nome,
    required this.quantidade,
    required this.precoUnitarioCentavos,
    required this.totalCentavos,
    this.observacao,
  });
}
