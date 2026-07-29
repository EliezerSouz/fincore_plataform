import 'package:fincore_core/common/domain_primitives.dart';

enum PricingPolicyType {
  unitario,
  faixaQuantidade,
  fracionado,
  peso,
  cento,
  combo,
  promocional,
}

class TabelaPrecificacao {
  final String id;
  final String tenantId;
  final String nome;
  final String descricao;
  final PricingPolicyType tipoPolitica;
  final int prioridade;
  final bool ativo;
  final SyncMetadata metadata;

  const TabelaPrecificacao({
    required this.id,
    required this.tenantId,
    required this.nome,
    required this.descricao,
    required this.tipoPolitica,
    required this.prioridade,
    required this.ativo,
    required this.metadata,
  });
}

class ItemTabelaPrecificacao {
  final String id;
  final String tenantId;
  final String tabelaPrecificacaoId;
  final int quantidadeMinima;
  final int? quantidadeMaxima;
  final int valorUnitarioCentavos;
  final int ordem;
  final SyncMetadata metadata;

  const ItemTabelaPrecificacao({
    required this.id,
    required this.tenantId,
    required this.tabelaPrecificacaoId,
    required this.quantidadeMinima,
    this.quantidadeMaxima,
    required this.valorUnitarioCentavos,
    required this.ordem,
    required this.metadata,
  });
}

class ProdutoTabelaPrecificacao {
  final String id;
  final String tenantId;
  final String produtoId;
  final String tabelaPrecificacaoId;
  final bool ativo;
  final int prioridade;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final SyncMetadata metadata;

  const ProdutoTabelaPrecificacao({
    required this.id,
    required this.tenantId,
    required this.produtoId,
    required this.tabelaPrecificacaoId,
    required this.ativo,
    required this.prioridade,
    this.dataInicio,
    this.dataFim,
    required this.metadata,
  });
}
