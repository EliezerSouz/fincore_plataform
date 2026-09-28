import 'domain_primitives.dart';

enum UnidadeVenda {
  un,
  cento,
  kg,
  l,
  bandeja,
  caixa,
}

enum ProductStatus {
  disponivel,
  indisponivel,
  descontinuado,
}

enum TipoFormaPagamento {
  dinheiro,
  pix,
  cartaoCredito,
  cartaoDebito,
  notaPrazo,
  consumoInterno,
  outro,
}

enum TipoRegraTaxaEntrega {
  bairro,
  cep,
  fixo,
}

class Categoria {
  final String id;
  final String tenantId;
  final String? parentId;
  final String nome;
  final String descricao;
  final int ordemExibicao;
  final bool ativo;
  final String? icone;
  final String? cor;
  final String? metadataPayload;
  final SyncMetadata metadata;

  const Categoria({
    required this.id,
    required this.tenantId,
    this.parentId,
    required this.nome,
    required this.descricao,
    required this.ordemExibicao,
    required this.ativo,
    this.icone,
    this.cor,
    this.metadataPayload,
    required this.metadata,
  });

  Categoria copyWith({
    String? id,
    String? tenantId,
    String? parentId,
    String? nome,
    String? descricao,
    int? ordemExibicao,
    bool? ativo,
    String? icone,
    String? cor,
    String? metadataPayload,
    SyncMetadata? metadata,
  }) {
    return Categoria(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      parentId: parentId ?? this.parentId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ordemExibicao: ordemExibicao ?? this.ordemExibicao,
      ativo: ativo ?? this.ativo,
      icone: icone ?? this.icone,
      cor: cor ?? this.cor,
      metadataPayload: metadataPayload ?? this.metadataPayload,
      metadata: metadata ?? this.metadata,
    );
  }
}

class Produto {
  final String id;
  final String tenantId;
  final String? codigo;
  final String nome;
  final String? descricao;
  final String categoriaId;
  final UnidadeVenda unidadeVenda;
  final ProductStatus statusComercial;
  final int tempoMedioMinutos;
  final bool controlaEstoque;
  final int ordemProducao;
  final bool ativo;
  final String? sku;
  final String? codigoBarras;
  final String? imagem;
  final String? corEtiqueta;
  final String? metadataPayload;
  final SyncMetadata metadata;

  const Produto({
    required this.id,
    required this.tenantId,
    this.codigo,
    required this.nome,
    this.descricao,
    required this.categoriaId,
    required this.unidadeVenda,
    required this.statusComercial,
    required this.tempoMedioMinutos,
    required this.controlaEstoque,
    required this.ordemProducao,
    required this.ativo,
    this.sku,
    this.codigoBarras,
    this.imagem,
    this.corEtiqueta,
    this.metadataPayload,
    required this.metadata,
  });

  Produto copyWith({
    String? id,
    String? tenantId,
    String? codigo,
    String? nome,
    String? descricao,
    String? categoriaId,
    UnidadeVenda? unidadeVenda,
    ProductStatus? statusComercial,
    int? tempoMedioMinutos,
    bool? controlaEstoque,
    int? ordemProducao,
    bool? ativo,
    String? sku,
    String? codigoBarras,
    String? imagem,
    String? corEtiqueta,
    String? metadataPayload,
    SyncMetadata? metadata,
  }) {
    return Produto(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      codigo: codigo ?? this.codigo,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      categoriaId: categoriaId ?? this.categoriaId,
      unidadeVenda: unidadeVenda ?? this.unidadeVenda,
      statusComercial: statusComercial ?? this.statusComercial,
      tempoMedioMinutos: tempoMedioMinutos ?? this.tempoMedioMinutos,
      controlaEstoque: controlaEstoque ?? this.controlaEstoque,
      ordemProducao: ordemProducao ?? this.ordemProducao,
      ativo: ativo ?? this.ativo,
      sku: sku ?? this.sku,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      imagem: imagem ?? this.imagem,
      corEtiqueta: corEtiqueta ?? this.corEtiqueta,
      metadataPayload: metadataPayload ?? this.metadataPayload,
      metadata: metadata ?? this.metadata,
    );
  }
}

class Cliente {
  final String id;
  final String tenantId;
  final String nome;
  final String telefone;
  final String? email;
  final String? documento;
  final String observacoes;
  final bool ativo;
  final SyncMetadata metadata;
  final bool aceitaWhatsapp;
  final bool aceitaMarketing;
  final String? apelido;
  final DateTime? dataNascimento;
  final String? preferenciaEntrega;
  final int? limiteCredito;

  const Cliente({
    required this.id,
    required this.tenantId,
    required this.nome,
    required this.telefone,
    this.email,
    this.documento,
    required this.observacoes,
    required this.ativo,
    required this.metadata,
    this.aceitaWhatsapp = true,
    this.aceitaMarketing = false,
    this.apelido,
    this.dataNascimento,
    this.preferenciaEntrega,
    this.limiteCredito,
  });

  Cliente copyWith({
    String? id,
    String? tenantId,
    String? nome,
    String? telefone,
    String? Function()? email,
    String? Function()? documento,
    String? observacoes,
    bool? ativo,
    SyncMetadata? metadata,
    bool? aceitaWhatsapp,
    bool? aceitaMarketing,
    String? Function()? apelido,
    DateTime? Function()? dataNascimento,
    String? Function()? preferenciaEntrega,
    int? Function()? limiteCredito,
  }) {
    return Cliente(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      email: email != null ? email() : this.email,
      documento: documento != null ? documento() : this.documento,
      observacoes: observacoes ?? this.observacoes,
      ativo: ativo ?? this.ativo,
      metadata: metadata ?? this.metadata,
      aceitaWhatsapp: aceitaWhatsapp ?? this.aceitaWhatsapp,
      aceitaMarketing: aceitaMarketing ?? this.aceitaMarketing,
      apelido: apelido != null ? apelido() : this.apelido,
      dataNascimento: dataNascimento != null ? dataNascimento() : this.dataNascimento,
      preferenciaEntrega: preferenciaEntrega != null ? preferenciaEntrega() : this.preferenciaEntrega,
      limiteCredito: limiteCredito != null ? limiteCredito() : this.limiteCredito,
    );
  }

  /// Retorna o nome formatado com o apelido (se cadastrado), ex: "João Paulo (Memac)"
  String get nomeExibicao {
    if (apelido != null && apelido!.trim().isNotEmpty) {
      return '$nome (${apelido!.trim()})';
    }
    return nome;
  }

  /// Retorna o telefone devidamente normalizado para 11 dígitos (ou 10 se fixo)
  String get telefoneNormalizado => normalizarTelefone(telefone);

  /// Retorna o telefone formatado para exibição, ex: "(35) 99250-3114"
  String get telefoneFormatado => formatarTelefone(telefone);
}

class LocalEntrega {
  final String id;
  final String tenantId;
  final String clienteId;
  final String nomeIdentificador;
  final String logradouro;
  final String numero;
  final String bairro;
  final String cidade;
  final String cep;
  final String referencia;
  final bool ativo;
  final SyncMetadata metadata;

  const LocalEntrega({
    required this.id,
    required this.tenantId,
    required this.clienteId,
    required this.nomeIdentificador,
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.cep,
    required this.referencia,
    required this.ativo,
    required this.metadata,
  });
}

class FormaPagamento {
  final String id;
  final String tenantId;
  final String nome;
  final TipoFormaPagamento tipo;
  final int ordem;
  final bool ativo;
  final bool permiteTroco;
  final bool isUsoInterno;
  final bool movimentaFinanceiro;
  final bool movimentaEstoque;
  final String? bandeiraPadrao;
  final String? descricao;
  final String? pixChave;
  final String? pixTipoChave;
  final String? pixTipoBanco;
  final SyncMetadata metadata;

  const FormaPagamento({
    required this.id,
    required this.tenantId,
    required this.nome,
    required this.tipo,
    required this.ordem,
    required this.ativo,
    required this.permiteTroco,
    this.isUsoInterno = false,
    this.movimentaFinanceiro = true,
    this.movimentaEstoque = true,
    this.bandeiraPadrao,
    this.descricao,
    this.pixChave,
    this.pixTipoChave,
    this.pixTipoBanco,
    required this.metadata,
  });

  FormaPagamento copyWith({
    String? id,
    String? tenantId,
    String? nome,
    TipoFormaPagamento? tipo,
    int? ordem,
    bool? ativo,
    bool? permiteTroco,
    bool? isUsoInterno,
    bool? movimentaFinanceiro,
    bool? movimentaEstoque,
    String? bandeiraPadrao,
    String? descricao,
    String? pixChave,
    String? pixTipoChave,
    String? pixTipoBanco,
    SyncMetadata? metadata,
  }) {
    return FormaPagamento(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      ordem: ordem ?? this.ordem,
      ativo: ativo ?? this.ativo,
      permiteTroco: permiteTroco ?? this.permiteTroco,
      isUsoInterno: isUsoInterno ?? this.isUsoInterno,
      movimentaFinanceiro: movimentaFinanceiro ?? this.movimentaFinanceiro,
      movimentaEstoque: movimentaEstoque ?? this.movimentaEstoque,
      bandeiraPadrao: bandeiraPadrao ?? this.bandeiraPadrao,
      descricao: descricao ?? this.descricao,
      pixChave: pixChave ?? this.pixChave,
      pixTipoChave: pixTipoChave ?? this.pixTipoChave,
      pixTipoBanco: pixTipoBanco ?? this.pixTipoBanco,
      metadata: metadata ?? this.metadata,
    );
  }
}

class TaxaEntrega {
  final String id;
  final String tenantId;
  final String nome;
  final TipoRegraTaxaEntrega tipoRegra;
  final String? bairro;
  final String? cepInicial;
  final String? cepFinal;
  final int valorCentavos;
  final bool ativo;
  final int pedidoMinimoCentavos;
  final String? prazoEstimado;
  final String? observacoes;
  final SyncMetadata metadata;

  const TaxaEntrega({
    required this.id,
    required this.tenantId,
    required this.nome,
    required this.tipoRegra,
    this.bairro,
    this.cepInicial,
    this.cepFinal,
    required this.valorCentavos,
    required this.ativo,
    this.pedidoMinimoCentavos = 0,
    this.prazoEstimado,
    this.observacoes,
    required this.metadata,
  });

  TaxaEntrega copyWith({
    String? id,
    String? tenantId,
    String? nome,
    TipoRegraTaxaEntrega? tipoRegra,
    String? bairro,
    String? cepInicial,
    String? cepFinal,
    int? valorCentavos,
    bool? ativo,
    int? pedidoMinimoCentavos,
    String? prazoEstimado,
    String? observacoes,
    SyncMetadata? metadata,
  }) {
    return TaxaEntrega(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      nome: nome ?? this.nome,
      tipoRegra: tipoRegra ?? this.tipoRegra,
      bairro: bairro ?? this.bairro,
      cepInicial: cepInicial ?? this.cepInicial,
      cepFinal: cepFinal ?? this.cepFinal,
      valorCentavos: valorCentavos ?? this.valorCentavos,
      ativo: ativo ?? this.ativo,
      pedidoMinimoCentavos: pedidoMinimoCentavos ?? this.pedidoMinimoCentavos,
      prazoEstimado: prazoEstimado ?? this.prazoEstimado,
      observacoes: observacoes ?? this.observacoes,
      metadata: metadata ?? this.metadata,
    );
  }
}
