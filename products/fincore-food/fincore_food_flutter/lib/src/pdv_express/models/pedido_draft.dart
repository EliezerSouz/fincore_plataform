import 'package:uuid/uuid.dart';

class PedidoDraft {
  final String id;
  final String tenantId;
  final String? clienteId;
  final String tipoLogistica; // 'Entrega' ou 'Retirada'
  final String canalVenda; // 'PDV'
  final String status; // 'Criado'
  final int valorSubtotalCentavos;
  final int valorTaxaEntregaCentavos;
  final int valorTaxaServicoCentavos;
  final int valorDescontoCentavos;
  final int valorTotalCentavos;
  final String? formaPagamentoId;
  final int? trocoParaCentavos;
  final List<ItemPedidoDraft> itens;
  final List<PagamentoItemDraft> pagamentos;
  final DateTime dataHoraCriacao;
  final String operadorId;
  final String? observacoes;

  PedidoDraft({
    String? id,
    required this.tenantId,
    this.clienteId,
    required this.tipoLogistica,
    this.canalVenda = 'PDV',
    this.status = 'Criado',
    required this.valorSubtotalCentavos,
    required this.valorTaxaEntregaCentavos,
    this.valorTaxaServicoCentavos = 0,
    this.valorDescontoCentavos = 0,
    required this.valorTotalCentavos,
    this.formaPagamentoId,
    this.trocoParaCentavos,
    required this.itens,
    this.pagamentos = const [],
    DateTime? dataHoraCriacao,
    required this.operadorId,
    this.observacoes,
  })  : id = id ?? const Uuid().v4(),
        dataHoraCriacao = dataHoraCriacao ?? DateTime.now();

  PedidoDraft copyWith({
    String? id,
    String? tenantId,
    String? Function()? clienteId,
    String? tipoLogistica,
    String? canalVenda,
    String? status,
    int? valorSubtotalCentavos,
    int? valorTaxaEntregaCentavos,
    int? valorTaxaServicoCentavos,
    int? valorDescontoCentavos,
    int? valorTotalCentavos,
    String? Function()? formaPagamentoId,
    int? Function()? trocoParaCentavos,
    List<ItemPedidoDraft>? itens,
    List<PagamentoItemDraft>? pagamentos,
    DateTime? dataHoraCriacao,
    String? operadorId,
    String? Function()? observacoes,
  }) {
    return PedidoDraft(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      clienteId: clienteId != null ? clienteId() : this.clienteId,
      tipoLogistica: tipoLogistica ?? this.tipoLogistica,
      canalVenda: canalVenda ?? this.canalVenda,
      status: status ?? this.status,
      valorSubtotalCentavos: valorSubtotalCentavos ?? this.valorSubtotalCentavos,
      valorTaxaEntregaCentavos: valorTaxaEntregaCentavos ?? this.valorTaxaEntregaCentavos,
      valorTaxaServicoCentavos: valorTaxaServicoCentavos ?? this.valorTaxaServicoCentavos,
      valorDescontoCentavos: valorDescontoCentavos ?? this.valorDescontoCentavos,
      valorTotalCentavos: valorTotalCentavos ?? this.valorTotalCentavos,
      formaPagamentoId: formaPagamentoId != null ? formaPagamentoId() : this.formaPagamentoId,
      trocoParaCentavos: trocoParaCentavos != null ? trocoParaCentavos() : this.trocoParaCentavos,
      itens: itens ?? this.itens,
      pagamentos: pagamentos ?? this.pagamentos,
      dataHoraCriacao: dataHoraCriacao ?? this.dataHoraCriacao,
      operadorId: operadorId ?? this.operadorId,
      observacoes: observacoes != null ? observacoes() : this.observacoes,
    );
  }
}

class ItemPedidoDraft {
  final String id;
  final String produtoId;
  final String nome;
  final double quantidade;
  final int valorUnitarioCentavos;
  final int valorTotalCentavos;
  final String? observacoes;

  ItemPedidoDraft({
    String? id,
    required this.produtoId,
    required this.nome,
    required this.quantidade,
    required this.valorUnitarioCentavos,
    required this.valorTotalCentavos,
    this.observacoes,
  }) : id = id ?? const Uuid().v4();

  ItemPedidoDraft copyWith({
    String? id,
    String? produtoId,
    String? nome,
    double? quantidade,
    int? valorUnitarioCentavos,
    int? valorTotalCentavos,
    String? Function()? observacoes,
  }) {
    return ItemPedidoDraft(
      id: id ?? this.id,
      produtoId: produtoId ?? this.produtoId,
      nome: nome ?? this.nome,
      quantidade: quantidade ?? this.quantidade,
      valorUnitarioCentavos: valorUnitarioCentavos ?? this.valorUnitarioCentavos,
      valorTotalCentavos: valorTotalCentavos ?? this.valorTotalCentavos,
      observacoes: observacoes != null ? observacoes() : this.observacoes,
    );
  }
}

/// Item de pagamento fracionado (Split Payment - AUD-006)
class PagamentoItemDraft {
  final String id;
  final String? formaPagamentoId;
  final String formaPagamentoNome;
  final int valorCentavos;
  final int trocoCentavos;
  final String? bandeira;
  final String? nsu;
  final String? observacao;

  PagamentoItemDraft({
    String? id,
    this.formaPagamentoId,
    required this.formaPagamentoNome,
    required this.valorCentavos,
    this.trocoCentavos = 0,
    this.bandeira,
    this.nsu,
    this.observacao,
  }) : id = id ?? const Uuid().v4();

  PagamentoItemDraft copyWith({
    String? id,
    String? Function()? formaPagamentoId,
    String? formaPagamentoNome,
    int? valorCentavos,
    int? trocoCentavos,
    String? Function()? bandeira,
    String? Function()? nsu,
    String? Function()? observacao,
  }) {
    return PagamentoItemDraft(
      id: id ?? this.id,
      formaPagamentoId: formaPagamentoId != null ? formaPagamentoId() : this.formaPagamentoId,
      formaPagamentoNome: formaPagamentoNome ?? this.formaPagamentoNome,
      valorCentavos: valorCentavos ?? this.valorCentavos,
      trocoCentavos: trocoCentavos ?? this.trocoCentavos,
      bandeira: bandeira != null ? bandeira() : this.bandeira,
      nsu: nsu != null ? nsu() : this.nsu,
      observacao: observacao != null ? observacao() : this.observacao,
    );
  }
}

