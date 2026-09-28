import 'package:fincore_core/common/domain_primitives.dart';

// ────────────────────────────────────────────────────────────────────
// Enums do KDS
// ────────────────────────────────────────────────────────────────────

enum StatusOrdemPreparo {
  pendente,         // Ordem criada, aguardando início
  emPreparo,        // Cozinheiro iniciou o preparo (timer ativo)
  pronto,           // Preparo concluído, aguardando saída/retirada
  saiuParaEntrega,  // Saiu para entrega (Em trânsito)
  entregue,         // Pedido entregue / concluído
  cancelado,        // Cancelado antes ou durante o preparo
}

enum PrioridadeOrdem {
  normal,
  urgente,
  vip,
  programado,
}

enum StatusLoteInsumo {
  ativo,      // Lote disponível para consumo
  zerado,     // Quantidade chegou a 0
  vencido,    // Passou da data de validade
  cancelado,  // Cancelado manualmente
}

// ────────────────────────────────────────────────────────────────────
// Modelos de Domínio do KDS (puros, independentes de Drift)
// ────────────────────────────────────────────────────────────────────

/// Item dentro de uma ordem de preparo.
class ItemOrdemPreparo {
  final String produtoId;
  final String nomeProduto;
  final double quantidade;
  final String unidade;

  const ItemOrdemPreparo({
    required this.produtoId,
    required this.nomeProduto,
    required this.quantidade,
    required this.unidade,
  });

  Map<String, dynamic> toJson() => {
    'produtoId': produtoId,
    'nomeProduto': nomeProduto,
    'quantidade': quantidade,
    'unidade': unidade,
  };

  factory ItemOrdemPreparo.fromJson(Map<String, dynamic> json) =>
    ItemOrdemPreparo(
      produtoId: json['produtoId'] as String,
      nomeProduto: json['nomeProduto'] as String,
      quantidade: (json['quantidade'] as num).toDouble(),
      unidade: json['unidade'] as String? ?? 'un',
    );
}

/// Ordem de preparo do KDS — unidade de trabalho da cozinha.
///
/// Máquina de estados:
/// ```
/// PENDENTE → EM_PREPARO → PRONTO → ENTREGUE
///              ↓             ↓
///           CANCELADO    CANCELADO
/// ```
class OrdemPreparo {
  final String id;
  final String tenantId;
  final String pedidoId;
  final List<ItemOrdemPreparo> itens;
  final StatusOrdemPreparo status;
  final PrioridadeOrdem prioridade;
  final String? operadorId;
  final DateTime criadaEm;
  final DateTime? iniciadaEm;
  final DateTime? concluidaEm;
  final DateTime? canceladaEm;
  final int tempoEstimadoSegundos;
  final String? observacoes;
  final SyncMetadata metadata;

  const OrdemPreparo({
    required this.id,
    required this.tenantId,
    required this.pedidoId,
    required this.itens,
    required this.status,
    required this.prioridade,
    this.operadorId,
    required this.criadaEm,
    this.iniciadaEm,
    this.concluidaEm,
    this.canceladaEm,
    required this.tempoEstimadoSegundos,
    this.observacoes,
    required this.metadata,
  });

  /// Tempo decorrido desde o início do preparo (null se não iniciado)
  Duration? get tempoDecorrido {
    if (iniciadaEm == null) return null;
    final fim = concluidaEm ?? canceladaEm ?? DateTime.now();
    return fim.difference(iniciadaEm!);
  }

  /// Indica se a ordem está atrasada (acima do tempo estimado)
  bool get estaAtrasada {
    if (iniciadaEm == null || status == StatusOrdemPreparo.pronto) return false;
    return tempoDecorrido != null &&
        tempoDecorrido!.inSeconds > tempoEstimadoSegundos;
  }

  /// Cor semântica de prioridade
  String get corPrioridade {
    switch (prioridade) {
      case PrioridadeOrdem.urgente: return 'danger';
      case PrioridadeOrdem.vip:     return 'warning';
      default:                       return 'primary';
    }
  }

  OrdemPreparo copyWith({
    StatusOrdemPreparo? status,
    String? operadorId,
    DateTime? iniciadaEm,
    DateTime? concluidaEm,
    DateTime? canceladaEm,
    SyncMetadata? metadata,
  }) =>
    OrdemPreparo(
      id: id,
      tenantId: tenantId,
      pedidoId: pedidoId,
      itens: itens,
      status: status ?? this.status,
      prioridade: prioridade,
      operadorId: operadorId ?? this.operadorId,
      criadaEm: criadaEm,
      iniciadaEm: iniciadaEm ?? this.iniciadaEm,
      concluidaEm: concluidaEm ?? this.concluidaEm,
      canceladaEm: canceladaEm ?? this.canceladaEm,
      tempoEstimadoSegundos: tempoEstimadoSegundos,
      observacoes: observacoes,
      metadata: metadata ?? this.metadata,
    );
}

/// Lote de insumo — unidade de rastreabilidade de estoque.
///
/// O controle segue a política FIFO para consumo e LIFO para estorno.
/// Veja [EstornarLoteEstoqueUseCase] para o algoritmo de devolução.
class LoteInsumo {
  final String id;
  final String tenantId;
  final String produtoId;
  final String? codigoLote;
  final int quantidadeInicial;      // em centésimos
  final int quantidadeDisponivel;   // em centésimos
  final int quantidadeReservada;    // em centésimos
  final String unidade;
  final DateTime? dataValidade;
  final DateTime dataEntrada;
  final StatusLoteInsumo statusLote;
  final SyncMetadata metadata;

  const LoteInsumo({
    required this.id,
    required this.tenantId,
    required this.produtoId,
    this.codigoLote,
    required this.quantidadeInicial,
    required this.quantidadeDisponivel,
    required this.quantidadeReservada,
    required this.unidade,
    this.dataValidade,
    required this.dataEntrada,
    required this.statusLote,
    required this.metadata,
  });

  /// Quantidade efetivamente disponível (descontando reservas)
  int get quantidadeLivre => quantidadeDisponivel - quantidadeReservada;

  /// Indica se o lote está vencido
  bool get estaVencido {
    if (dataValidade == null) return false;
    return DateTime.now().isAfter(dataValidade!);
  }

  /// Percentual de utilização do lote (0.0 a 1.0)
  double get percentualUtilizado {
    if (quantidadeInicial == 0) return 1.0;
    return 1.0 - (quantidadeDisponivel / quantidadeInicial);
  }

  LoteInsumo copyWith({
    int? quantidadeDisponivel,
    int? quantidadeReservada,
    StatusLoteInsumo? statusLote,
    SyncMetadata? metadata,
  }) =>
    LoteInsumo(
      id: id,
      tenantId: tenantId,
      produtoId: produtoId,
      codigoLote: codigoLote,
      quantidadeInicial: quantidadeInicial,
      quantidadeDisponivel: quantidadeDisponivel ?? this.quantidadeDisponivel,
      quantidadeReservada: quantidadeReservada ?? this.quantidadeReservada,
      unidade: unidade,
      dataValidade: dataValidade,
      dataEntrada: dataEntrada,
      statusLote: statusLote ?? this.statusLote,
      metadata: metadata ?? this.metadata,
    );
}

/// Resultado do algoritmo LIFO de estorno de estoque.
class ResultadoEstorno {
  /// Lista de lotes atualizados pelo estorno
  final List<LoteInsumo> lotesAtualizados;

  /// Quantidade total que foi devolvida ao estoque (centésimos)
  final int quantidadeDevolvida;

  /// Quantidade que não pôde ser devolvida (lotes fechados/vencidos)
  final int quantidadeNaoDevolvida;

  /// Mensagem de diagnóstico do estorno
  final String mensagem;

  const ResultadoEstorno({
    required this.lotesAtualizados,
    required this.quantidadeDevolvida,
    required this.quantidadeNaoDevolvida,
    required this.mensagem,
  });

  bool get sucesso => quantidadeNaoDevolvida == 0;
}

/// Registro da linha do tempo/histórico operacional de uma ordem de preparo.
class HistoricoOrdemPreparo {
  final String id;
  final String tenantId;
  final String ordemPreparoId;
  final String titulo;
  final String descricao;
  final String operadorNome;
  final DateTime criadaEm;
  final String versao;
  final SyncMetadata metadata;

  const HistoricoOrdemPreparo({
    required this.id,
    required this.tenantId,
    required this.ordemPreparoId,
    required this.titulo,
    required this.descricao,
    required this.operadorNome,
    required this.criadaEm,
    required this.versao,
    required this.metadata,
  });
}
