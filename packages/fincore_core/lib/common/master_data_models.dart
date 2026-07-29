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
  final SyncMetadata metadata;

  const Categoria({
    required this.id,
    required this.tenantId,
    this.parentId,
    required this.nome,
    required this.descricao,
    required this.ordemExibicao,
    required this.ativo,
    required this.metadata,
  });
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
    required this.metadata,
  });
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
    );
  }
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
  final SyncMetadata metadata;

  const FormaPagamento({
    required this.id,
    required this.tenantId,
    required this.nome,
    required this.tipo,
    required this.ordem,
    required this.ativo,
    required this.permiteTroco,
    required this.metadata,
  });
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
    required this.metadata,
  });
}
