import 'domain_primitives.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums de Produção
// ─────────────────────────────────────────────────────────────────────────────

/// Ciclo de vida de um plano de produção.
///
/// Máquina de estados:
/// ```
/// PLANEJADA → EM_PREPARACAO → EM_PRODUCAO → CONCLUIDA
///                   ↓               ↓
///               CANCELADA      PARCIAL → CONCLUIDA
/// ```
enum StatusPlanoProducao {
  /// Plano criado, aguardando início da preparação.
  planejada,

  /// Ingredientes/insumos em preparação (massas, recheios).
  emPreparacao,

  /// Produção em andamento (modelagem, fritura, etc.).
  emProducao,

  /// Parte da quantidade planejada foi produzida; restam unidades.
  parcial,

  /// Toda a quantidade planejada foi produzida e registrada no estoque.
  concluida,

  /// Plano cancelado antes da conclusão (motivo obrigatório).
  cancelada,
}

/// Estratégia de produção do produto/campanha.
enum EstrategiaProducao {
  /// Uma campanha inteira dedicada a um único produto (padrão atual).
  concentrada,

  /// Campanha com múltiplos produtos produzidos em paralelo ou sequência.
  mista,

  /// Planejamento automático futuro baseado em capacidade e demanda.
  flexivel,
}

/// Resultado de atendibilidade: o estoque consegue atender o pedido?
enum StatusAtendibilidade {
  /// Estoque disponível atual já cobre a demanda do pedido.
  atendivel,

  /// Estoque insuficiente agora, mas a produção planejada antes da entrega cobre.
  atendivelViaPlanejamento,

  /// Nem o estoque disponível nem a produção planejada são suficientes.
  naoAtendivel,
}

// ─────────────────────────────────────────────────────────────────────────────
// PlanoProducao — Intenção Formal de Produção
// ─────────────────────────────────────────────────────────────────────────────

/// Representa a intenção administrativa de produzir N unidades de um produto
/// em uma determinada data/campanha.
///
/// NÃO é criado automaticamente — sempre requer ação do planejador/admin.
///
/// Ao ser concluído, gera automaticamente uma movimentação de estoque
/// do tipo 'producao' com referência ao [id] deste plano.
class PlanoProducao {
  final String id;
  final String tenantId;

  /// Produto que será produzido nesta campanha.
  final String produtoId;
  final String nomeProduto;

  /// Data em que a produção será executada (data da campanha).
  final DateTime dataPlano;

  /// Quantidade que o planejador pretende produzir.
  final int quantidadePlanejada;

  /// Quantidade efetivamente produzida (atualizada ao longo da produção).
  final int quantidadeProduzida;

  /// Referência da capacidade máxima desta campanha (do parâmetro do produto).
  /// Usado apenas como referência visual — não é um limite hard.
  final int capacidadeCampanha;

  /// Status atual do ciclo de vida.
  final StatusPlanoProducao status;

  /// Motivo de cancelamento (obrigatório quando status == cancelada).
  final String? motivoCancelamento;

  /// Observações livres do planejador.
  final String? observacoes;

  /// UUID do operador que criou/modificou o plano.
  final String? operadorId;

  /// ID da necessidade de origem.
  final String? necessidadeOrigem;

  final SyncMetadata metadata;

  const PlanoProducao({
    required this.id,
    required this.tenantId,
    required this.produtoId,
    required this.nomeProduto,
    required this.dataPlano,
    required this.quantidadePlanejada,
    required this.quantidadeProduzida,
    required this.capacidadeCampanha,
    required this.status,
    this.motivoCancelamento,
    this.observacoes,
    this.operadorId,
    this.necessidadeOrigem,
    required this.metadata,
  });

  /// Quantidade restante a produzir (nunca negativa).
  int get quantidadeRestante =>
      (quantidadePlanejada - quantidadeProduzida).clamp(0, 999999);

  /// Percentual de execução do plano (0.0 a 1.0).
  double get percentualExecucao {
    if (quantidadePlanejada <= 0) return 0.0;
    return (quantidadeProduzida / quantidadePlanejada).clamp(0.0, 1.0);
  }

  bool get estaAtivo =>
      status == StatusPlanoProducao.planejada ||
      status == StatusPlanoProducao.emPreparacao ||
      status == StatusPlanoProducao.emProducao ||
      status == StatusPlanoProducao.parcial;

  bool get estaConcluido => status == StatusPlanoProducao.concluida;
  bool get estaCancelado => status == StatusPlanoProducao.cancelada;

  PlanoProducao copyWith({
    String? id,
    String? tenantId,
    String? produtoId,
    String? nomeProduto,
    DateTime? dataPlano,
    int? quantidadePlanejada,
    int? quantidadeProduzida,
    int? capacidadeCampanha,
    StatusPlanoProducao? status,
    String? Function()? motivoCancelamento,
    String? Function()? observacoes,
    String? Function()? operadorId,
    String? Function()? necessidadeOrigem,
    SyncMetadata? metadata,
  }) {
    return PlanoProducao(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      produtoId: produtoId ?? this.produtoId,
      nomeProduto: nomeProduto ?? this.nomeProduto,
      dataPlano: dataPlano ?? this.dataPlano,
      quantidadePlanejada: quantidadePlanejada ?? this.quantidadePlanejada,
      quantidadeProduzida: quantidadeProduzida ?? this.quantidadeProduzida,
      capacidadeCampanha: capacidadeCampanha ?? this.capacidadeCampanha,
      status: status ?? this.status,
      motivoCancelamento:
          motivoCancelamento != null ? motivoCancelamento() : this.motivoCancelamento,
      observacoes: observacoes != null ? observacoes() : this.observacoes,
      operadorId: operadorId != null ? operadorId() : this.operadorId,
      necessidadeOrigem: necessidadeOrigem != null ? necessidadeOrigem() : this.necessidadeOrigem,
      metadata: metadata ?? this.metadata,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DemandaFutura — Agregado Computado (não persistido)
// ─────────────────────────────────────────────────────────────────────────────

/// Representa a demanda futura **total** de um produto, derivada de todos os
/// pedidos ativos com data de entrega.
///
/// É sempre **computada em tempo real** — nunca persistida como tabela separada.
/// Fonte: pedidos com status [confirmado|em_preparo|pronto] + seus itens.
class DemandaFutura {
  final String produtoId;
  final String nomeProduto;

  /// Total de unidades comprometidas com pedidos futuros.
  final int quantidadeTotal;

  /// Discriminado por data de entrega (data → quantidade).
  final Map<DateTime, int> porData;

  /// Lista de pedidos que compõem esta demanda.
  final List<DemandaItem> itens;

  const DemandaFutura({
    required this.produtoId,
    required this.nomeProduto,
    required this.quantidadeTotal,
    required this.porData,
    required this.itens,
  });

  /// Data de entrega mais próxima que possui demanda.
  DateTime? get proximaEntrega {
    if (porData.isEmpty) return null;
    return porData.keys.reduce((a, b) => a.isBefore(b) ? a : b);
  }
}

/// Um item de demanda — vínculo entre um pedido e a quantidade de um produto.
class DemandaItem {
  final String pedidoId;
  final int numeroPedido;
  final String clienteNome;
  final int quantidade;
  final DateTime? dataEntregaPrevista;

  const DemandaItem({
    required this.pedidoId,
    required this.numeroPedido,
    required this.clienteNome,
    required this.quantidade,
    this.dataEntregaPrevista,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// EstoqueProjetado — View Model Computado (não persistido)
// ─────────────────────────────────────────────────────────────────────────────

/// Combinação de todos os saldos e projeções de um produto.
///
/// Fórmula:
/// ```
/// projetado = disponivel + producaoPlanejada - demandaFutura
/// ```
///
/// Onde:
/// - disponivel = fisico - reservado
/// - producaoPlanejada = soma de PlanoProducao.quantidadePlanejada dos planos ativos
/// - demandaFutura = soma de itens de pedidos ativos com entrega futura
class EstoqueProjetado {
  final String produtoId;
  final String nomeProduto;
  final String? corEtiqueta;

  // ── Saldos atuais ─────────────────────────────────────────────────────────
  final int fisico;
  final int reservado;
  final int seguranca;
  final int minimo;
  final int critica;

  /// Disponível = max(físico - reservado, 0) (comercialmente limitado a zero).
  int get disponivel => (fisico - reservado).clamp(0, 999999);

  /// Déficit Atual = max(reservado - físico, 0).
  int get deficitAtual => (reservado - fisico).clamp(0, 999999);

  // ── Projeção ──────────────────────────────────────────────────────────────
  final int demandaFutura;
  final int producaoPlanejada;

  /// Estoque projetado = Físico + Produção Planejada - Reservado.
  /// REGRA DE OURO: NUNCA usar Disponível + Produção Planejada quando Disponível for limitado a zero.
  int get projetado => fisico + producaoPlanejada - reservado;

  // ── Situação ──────────────────────────────────────────────────────────────
  final StatusAtendibilidade situacao;

  const EstoqueProjetado({
    required this.produtoId,
    required this.nomeProduto,
    this.corEtiqueta,
    required this.fisico,
    required this.reservado,
    required this.seguranca,
    required this.minimo,
    required this.critica,
    required this.demandaFutura,
    required this.producaoPlanejada,
    required this.situacao,
  });

  /// 🟢 Demanda atendível com estoque atual.
  bool get isOk => situacao == StatusAtendibilidade.atendivel;

  /// 🟡 Atendível apenas se a produção planejada for concluída.
  bool get isAtendivelViaPlanejamento =>
      situacao == StatusAtendibilidade.atendivelViaPlanejamento;

  /// 🔴 Não atendível nem com produção planejada.
  bool get isNaoAtendivel => situacao == StatusAtendibilidade.naoAtendivel;

  /// Abaixo do estoque mínimo?
  bool get abaixoDoMinimo => disponivel <= minimo;

  /// Abaixo do estoque crítico?
  bool get abaixoDoCritico => disponivel <= critica;
}

// ─────────────────────────────────────────────────────────────────────────────
// AtendibilidadePedido — Avaliação por Pedido (não persistido)
// ─────────────────────────────────────────────────────────────────────────────

/// Resultado da análise de atendibilidade de um pedido específico.
class AtendibilidadePedido {
  final String pedidoId;
  final int numeroPedido;
  final DateTime? dataEntregaPrevista;
  final StatusAtendibilidade status;

  /// Itens do pedido com detalhamento de atendibilidade.
  final List<AtendibilidadeItem> itens;

  const AtendibilidadePedido({
    required this.pedidoId,
    required this.numeroPedido,
    this.dataEntregaPrevista,
    required this.status,
    required this.itens,
  });

  /// Retorna o pior status entre os itens
  /// (hierarquia: naoAtendivel > viaPlanejamento > atendivel).
  static StatusAtendibilidade _piorStatus(List<AtendibilidadeItem> itens) {
    if (itens.any((i) => i.status == StatusAtendibilidade.naoAtendivel)) {
      return StatusAtendibilidade.naoAtendivel;
    }
    if (itens.any((i) => i.status == StatusAtendibilidade.atendivelViaPlanejamento)) {
      return StatusAtendibilidade.atendivelViaPlanejamento;
    }
    return StatusAtendibilidade.atendivel;
  }

  factory AtendibilidadePedido.fromItens({
    required String pedidoId,
    required int numeroPedido,
    DateTime? dataEntregaPrevista,
    required List<AtendibilidadeItem> itens,
  }) {
    return AtendibilidadePedido(
      pedidoId: pedidoId,
      numeroPedido: numeroPedido,
      dataEntregaPrevista: dataEntregaPrevista,
      status: _piorStatus(itens),
      itens: itens,
    );
  }
}

/// Detalhe de atendibilidade por item/produto de um pedido.
class AtendibilidadeItem {
  final String produtoId;
  final String nomeProduto;
  final int quantidadePedida;
  final int disponivelAtual;
  final int producaoPlanejadaAteEntrega;
  final StatusAtendibilidade status;

  const AtendibilidadeItem({
    required this.produtoId,
    required this.nomeProduto,
    required this.quantidadePedida,
    required this.disponivelAtual,
    required this.producaoPlanejadaAteEntrega,
    required this.status,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SugestaoPlano — Assistente de Planejamento (não persistido)
// ─────────────────────────────────────────────────────────────────────────────

/// Sugestão gerada pelo sistema para um novo plano de produção.
/// NÃO cria o plano automaticamente — apenas sugere ao planejador.
class SugestaoPlano {
  final String produtoId;
  final String nomeProduto;

  /// Quantidade sugerida = demanda futura - disponível - produção já planejada.
  final int quantidadeSugerida;

  /// Capacidade de referência de campanha do produto.
  final int capacidadeCampanha;

  /// Razão da sugestão (texto legível para o planejador).
  final String motivo;

  /// Data sugerida para execução (calculada a partir da próxima entrega - tempo de preparo).
  final DateTime? dataSugerida;

  const SugestaoPlano({
    required this.produtoId,
    required this.nomeProduto,
    required this.quantidadeSugerida,
    required this.capacidadeCampanha,
    required this.motivo,
    this.dataSugerida,
  });
}
