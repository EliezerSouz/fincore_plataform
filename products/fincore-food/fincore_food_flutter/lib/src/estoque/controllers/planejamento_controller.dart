import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:uuid/uuid.dart';
import 'estoque_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PlanoProducaoController
// ─────────────────────────────────────────────────────────────────────────────

/// Controller de Planejamento de Produção.
///
/// Responsabilidades:
/// - CRUD do ciclo de vida dos planos de produção ([PlanoProducaoData])
/// - Cálculo de demanda futura (derivado dos pedidos ativos)
/// - Cálculo de estoque projetado (disponível + planejado - demanda)
/// - Avaliação de atendibilidade por pedido
/// - Geração de sugestões de plano (sem automatismo perigoso)
/// - Integração com [EstoqueController] ao concluir um plano
class PlanoProducaoController extends ChangeNotifier {
  final FincoreDatabase _db;
  final TenantContext _context;
  final EstoqueController _estoqueCtrl;

  List<PlanoProducaoData> _planos = [];
  List<EstoqueProjetado> _projecoes = [];
  List<SugestaoPlano> _sugestoes = [];
  bool _loading = false;
  String? _error;
  Map<String, EstoqueProdutoData> _estoqueMap = {};

  PlanoProducaoController()
      : _db = DependencyInjection().get<FincoreDatabase>(),
        _context = DependencyInjection().get<TenantContext>(),
        _estoqueCtrl = DependencyInjection().get<EstoqueController>() {
    _carregar();
  }

  // ── Getters públicos ──────────────────────────────────────────────────────

  List<PlanoProducaoData> get planos => _planos;
  List<PlanoProducaoData> get planosAtivos =>
      _planos.where((p) => _isAtivo(p.status)).toList();
  List<EstoqueProjetado> get projecoes => _projecoes;
  List<SugestaoPlano> get sugestoes => _sugestoes;
  bool get loading => _loading;
  String? get error => _error;

  bool _isAtivo(String status) =>
      status == 'planejada' ||
      status == 'em_preparacao' ||
      status == 'em_producao' ||
      status == 'parcial';

  // ── Carregamento ──────────────────────────────────────────────────────────

  Future<void> _carregar() async {
    if (!_context.hasContext) return;
    _loading = true;
    notifyListeners();

    try {
      final tenantId = _context.tenantId;

      // 1. Planos de produção (todos exceto cancelados/concluídos mais antigos que 30 dias)
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      _planos = await (_db.select(_db.planejamentoProducaoTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.deletedAt.isNull() &
                // Mostra ativos + concluídos/cancelados dos últimos 30 dias
                (t.status.isIn(['planejada', 'em_preparacao', 'em_producao', 'parcial']) |
                    t.dataPlano.isBiggerThanValue(cutoff)))
            ..orderBy([(t) => OrderingTerm(expression: t.dataPlano)]))
          .get();

      // 2. Calcula projeções de estoque
      _projecoes = await _calcularProjecoes(tenantId);

      // 3. Gera sugestões de produção
      _sugestoes = _gerarSugestoes();

      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar planejamento: $e';
      debugPrint('[PlanoProducaoController] $_error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _carregar();

  // ── Criar Plano ───────────────────────────────────────────────────────────

  /// Cria um novo plano de produção.
  /// [quantidadePlanejada] deve ser > 0.
  /// [dataPlano] é a data da campanha de produção.
  Future<PlanoProducaoData> criarPlano({
    required String produtoId,
    required DateTime dataPlano,
    required int quantidadePlanejada,
    int capacidadeCampanha = 0,
    String? observacoes,
    String? necessidadeOrigem,
  }) async {
    assert(quantidadePlanejada > 0, 'Quantidade planejada deve ser maior que zero');

    final tenantId = _context.tenantId;
    final operadorId = _context.usuario.id;
    final now = DateTime.now().toUtc();
    final uuid = const Uuid();

    // Obtém a capacidade da campanha do parâmetro do produto (se não informada)
    if (capacidadeCampanha == 0) {
      final est = await (_db.select(_db.estoqueProdutosTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.produtoId.equals(produtoId) &
                t.deletedAt.isNull().equals(true)))
          .getSingleOrNull();
      capacidadeCampanha = est?.capacidadeCampanha ?? 0;
    }

    final planoId = uuid.v4();

    // Proteção de duplicidade transacional no banco de dados contra condições de concorrência
    final inserted = await _db.transaction(() async {
      final existingActive = await (_db.select(_db.planejamentoProducaoTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.produtoId.equals(produtoId) &
                t.dataPlano.equals(dataPlano.toUtc()) &
                t.status.isIn(['planejada', 'em_preparacao', 'em_producao', 'parcial']) &
                t.deletedAt.isNull()))
          .getSingleOrNull();

      if (existingActive != null) {
        await _logAuditoriaBloqueio(
          produtoId: produtoId,
          dataPlano: dataPlano,
          planoExistenteId: existingActive.id,
          operadorId: operadorId,
        );
        throw Exception('Já existe uma produção planejada para este produto nesta data.');
      }

      await _db.into(_db.planejamentoProducaoTable).insert(
        PlanejamentoProducaoTableCompanion.insert(
          id: planoId,
          tenantId: tenantId,
          produtoId: produtoId,
          dataPlano: dataPlano.toUtc(),
          quantidadePlanejada: quantidadePlanejada,
          quantidadeProduzida: const Value(0),
          capacidadeCampanha: Value(capacidadeCampanha),
          status: const Value('planejada'),
          observacoes: Value(observacoes),
          operadorId: Value(operadorId),
          necessidadeOrigem: Value(necessidadeOrigem),
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: operadorId,
          updatedBy: operadorId,
        ),
      );

      // Enfileira no Outbox para sync com Supabase
      await _enqueueOutbox(planoId, 'create', tenantId: tenantId);

      // Auditoria
      await _logAuditoria(
        planoId: planoId,
        action: 'CREATE',
        produtoId: produtoId,
        status: 'planejada',
        diff: {
          'produtoId': produtoId,
          'quantidadePlanejada': quantidadePlanejada,
          'dataPlano': dataPlano.toIso8601String(),
          'capacidadeCampanha': capacidadeCampanha,
          'status': 'planejada',
          'observacoes': observacoes,
          'necessidadeOrigem': necessidadeOrigem,
        },
      );

      final inserted = await (_db.select(_db.planejamentoProducaoTable)
            ..where((t) => t.id.equals(planoId)))
          .getSingle();
      return inserted;
    });

    await _carregar();
    return inserted;
  }

  /// Ajusta a quantidade planejada de um plano existente (necessidade adicional).
  Future<void> ajustarQuantidade({
    required String planoId,
    required int novaQuantidadePlanejada,
    String? motivo,
  }) async {
    assert(novaQuantidadePlanejada > 0, 'Quantidade planejada deve ser maior que zero');

    final now = DateTime.now().toUtc();
    final operadorId = _context.usuario.id;
    final tenantId = _context.tenantId;

    final plano = await (_db.select(_db.planejamentoProducaoTable)
          ..where((t) => t.id.equals(planoId)))
        .getSingleOrNull();

    if (plano == null) throw Exception('Plano $planoId não encontrado');

    final activeStatus = {'planejada', 'em_preparacao', 'em_producao', 'parcial'};
    if (!activeStatus.contains(plano.status)) {
      throw Exception('Apenas campanhas ativas podem ser ajustadas.');
    }

    final qtdAnterior = plano.quantidadePlanejada;
    final acrescimo = novaQuantidadePlanejada - qtdAnterior;

    await (_db.update(_db.planejamentoProducaoTable)
          ..where((t) => t.id.equals(planoId)))
        .write(PlanejamentoProducaoTableCompanion(
      quantidadePlanejada: Value(novaQuantidadePlanejada),
      operadorId: Value(operadorId),
      updatedAt: Value(now),
      updatedBy: Value(operadorId),
      syncStatus: const Value(SyncStatus.pending),
    ));

    // Auditoria
    await _logAuditoria(
      planoId: planoId,
      action: 'UPDATE',
      produtoId: plano.produtoId,
      status: plano.status,
      diff: {
        'quantidadePlanejadaAntes': qtdAnterior,
        'quantidadePlanejadaDepois': novaQuantidadePlanejada,
        'acrescimo': acrescimo,
        'motivo': motivo ?? 'Necessidade adicional de estoque/pedidos.',
      },
    );

    await _enqueueOutbox(planoId, 'update', tenantId: tenantId);
    await _carregar();
  }

  Future<void> _logAuditoriaBloqueio({
    required String produtoId,
    required DateTime dataPlano,
    required String planoExistenteId,
    required String operadorId,
  }) async {
    try {
      final auditLogRepo = DependencyInjection().get<AuditLogRepository>();
      final prod = await (_db.select(_db.produtosTable)
            ..where((t) => t.id.equals(produtoId)))
          .getSingleOrNull();
      final nomeProduto = prod?.nome ?? 'Produto';

      await auditLogRepo.log(
        entityName: 'planejamento_producao',
        entityId: planoExistenteId,
        userId: operadorId,
        action: 'BLOCK',
        entityDisplayName: 'Bloqueio de Duplicidade - $nomeProduto',
        entityModule: 'Produção',
        diff: {
          'produtoId': produtoId,
          'dataPlano': dataPlano.toIso8601String(),
          'mensagem': 'Tentativa de criação de planejamento duplicado',
          'campanhaExistenteId': planoExistenteId,
        },
      );
    } catch (e) {
      debugPrint('[PlanoProducaoController] Falha ao registrar log de bloqueio: $e');
    }
  }

  // ── Avançar Status ────────────────────────────────────────────────────────

  /// Avança o status do plano: planejada → em_preparacao
  Future<void> iniciarPreparacao(String planoId) async {
    await _atualizarStatus(planoId, 'em_preparacao');
  }

  /// Avança o status do plano: em_preparacao → em_producao
  Future<void> iniciarProducao(String planoId) async {
    await _atualizarStatus(planoId, 'em_producao');
  }

  // ── Registrar Produção Parcial ────────────────────────────────────────────

  /// Registra uma quantidade parcialmente produzida.
  /// Atualiza [quantidadeProduzida] e define status como 'parcial'.
  /// NÃO altera o estoque físico ainda — só ao concluir.
  Future<void> registrarParcial({
    required String planoId,
    required int quantidadeProduzida,
  }) async {
    assert(quantidadeProduzida > 0, 'Quantidade deve ser maior que zero');

    final now = DateTime.now().toUtc();
    final operadorId = _context.usuario.id;
    final tenantId = _context.tenantId;

    final plano = await (_db.select(_db.planejamentoProducaoTable)
          ..where((t) => t.id.equals(planoId)))
        .getSingleOrNull();

    if (plano == null) throw Exception('Plano $planoId não encontrado');

    final novaQtdProduzida =
        (plano.quantidadeProduzida + quantidadeProduzida).clamp(0, 999999);
    final novoStatus = novaQtdProduzida >= plano.quantidadePlanejada
        ? 'concluida'
        : 'parcial';

    await (_db.update(_db.planejamentoProducaoTable)
          ..where((t) => t.id.equals(planoId)))
        .write(PlanejamentoProducaoTableCompanion(
      quantidadeProduzida: Value(novaQtdProduzida),
      status: Value(novoStatus),
      operadorId: Value(operadorId),
      updatedAt: Value(now),
      updatedBy: Value(operadorId),
      syncStatus: const Value(SyncStatus.pending),
    ));

    // Lançamento FÍSICO incremental no estoque
    await _entradaEstoqueDeProducao(
      planoId: planoId,
      produtoId: plano.produtoId,
      quantidade: quantidadeProduzida,
      tenantId: tenantId,
    );

    // Auditoria
    await _logAuditoria(
      planoId: planoId,
      action: 'UPDATE',
      produtoId: plano.produtoId,
      status: novoStatus,
      diff: {
        'quantidadeAnterior': plano.quantidadeProduzida,
        'quantidadeAdicionada': quantidadeProduzida,
        'quantidadeAcumulada': novaQtdProduzida,
        'status': novoStatus,
      },
    );

    await _enqueueOutbox(planoId, 'update', tenantId: tenantId);
    await _carregar();
  }

  // ── Concluir Plano ────────────────────────────────────────────────────────

  /// Conclui o plano com a quantidade final produzida.
  /// Gera automaticamente a entrada de estoque (tipo 'producao') apenas para a quantidade restante.
  Future<void> concluirPlano({
    required String planoId,
    required int quantidadeFinalProduzida,
  }) async {
    assert(quantidadeFinalProduzida > 0, 'Quantidade deve ser maior que zero');

    final now = DateTime.now().toUtc();
    final operadorId = _context.usuario.id;
    final tenantId = _context.tenantId;

    final plano = await (_db.select(_db.planejamentoProducaoTable)
          ..where((t) => t.id.equals(planoId)))
        .getSingleOrNull();

    if (plano == null) throw Exception('Plano $planoId não encontrado');

    await (_db.update(_db.planejamentoProducaoTable)
          ..where((t) => t.id.equals(planoId)))
        .write(PlanejamentoProducaoTableCompanion(
      quantidadeProduzida: Value(quantidadeFinalProduzida),
      status: const Value('concluida'),
      operadorId: Value(operadorId),
      updatedAt: Value(now),
      updatedBy: Value(operadorId),
      syncStatus: const Value(SyncStatus.pending),
    ));

    // Lançamento FÍSICO incremental no estoque (apenas a diferença não lançada)
    final incremental = (quantidadeFinalProduzida - plano.quantidadeProduzida).clamp(0, 999999);
    if (incremental > 0) {
      await _entradaEstoqueDeProducao(
        planoId: planoId,
        produtoId: plano.produtoId,
        quantidade: incremental,
        tenantId: tenantId,
      );
    }

    // Auditoria
    await _logAuditoria(
      planoId: planoId,
      action: 'UPDATE',
      produtoId: plano.produtoId,
      status: 'concluida',
      diff: {
        'quantidadePlanejada': plano.quantidadePlanejada,
        'quantidadeFinalProduzida': quantidadeFinalProduzida,
        'quantidadeAnterior': plano.quantidadeProduzida,
        'quantidadeIncremental': incremental,
        'status': 'concluida',
      },
    );

    await _enqueueOutbox(planoId, 'update', tenantId: tenantId);
    await _carregar();
  }

  // ── Cancelar Plano ────────────────────────────────────────────────────────

  /// Cancela o plano. [motivo] é obrigatório.
  /// Se [estornarProduzido] for true e houver `quantidadeProduzida > 0`,
  /// reverte as unidades produzidas no estoque físico via `estornarProducao` e
  /// zera a `quantidadeProduzida` do plano.
  Future<void> cancelarPlano({
    required String planoId,
    required String motivo,
    bool estornarProduzido = false,
  }) async {
    assert(motivo.trim().isNotEmpty, 'Motivo é obrigatório para cancelamento');

    final now = DateTime.now().toUtc();
    final operadorId = _context.usuario.id;
    final tenantId = _context.tenantId;

    final plano = await (_db.select(_db.planejamentoProducaoTable)
          ..where((t) => t.id.equals(planoId)))
        .getSingleOrNull();

    if (plano == null) throw Exception('Plano $planoId não encontrado');

    int qtdEstornada = 0;
    if (estornarProduzido && plano.quantidadeProduzida > 0) {
      qtdEstornada = plano.quantidadeProduzida;
      await _estoqueCtrl.estornarProducao(
        produtoId: plano.produtoId,
        quantidade: qtdEstornada,
        motivo: 'Estorno por cancelamento total da ordem #${planoId.substring(0, 8).toUpperCase()} ($motivo)',
        dataEstorno: now,
      );
    }

    await (_db.update(_db.planejamentoProducaoTable)
          ..where((t) => t.id.equals(planoId)))
        .write(PlanejamentoProducaoTableCompanion(
      status: const Value('cancelada'),
      motivoCancelamento: Value(motivo),
      quantidadeProduzida: estornarProduzido ? const Value(0) : Value(plano.quantidadeProduzida),
      operadorId: Value(operadorId),
      updatedAt: Value(now),
      updatedBy: Value(operadorId),
      syncStatus: const Value(SyncStatus.pending),
    ));

    await _logAuditoria(
      planoId: planoId,
      action: 'UPDATE',
      produtoId: plano.produtoId,
      status: 'cancelada',
      diff: {
        'status': 'cancelada',
        'motivoCancelamento': motivo,
        'estornarProduzido': estornarProduzido,
        'quantidadeProduzidaAntes': plano.quantidadeProduzida,
        'quantidadeEstornada': qtdEstornada,
      },
    );

    await _enqueueOutbox(planoId, 'update', tenantId: tenantId);
    await _carregar();
  }

  // ── Demanda Futura ────────────────────────────────────────────────────────

  /// Calcula a demanda futura para todos os produtos com controlaEstoque=true.
  ///
  /// Fonte: pedidos com status confirmado/em_preparo/pronto que tenham
  /// dataHoraEntregaPrevista ou reservas em movimentacoes_estoque.
  Future<Map<String, DemandaFutura>> calcularDemandaFutura() async {
    if (!_context.hasContext) return {};
    final tenantId = _context.tenantId;

    final statusAtivos = {'confirmado', 'em_preparo', 'pronto'};

    // Busca pedidos ativos
    final pedidos = await (_db.select(_db.pedidosTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.status.isIn(statusAtivos.toList()) &
              t.deletedAt.isNull()))
        .get();

    final Map<String, DemandaFutura> demanda = {};

    for (final pedido in pedidos) {
      final itens = await (_db.select(_db.itensPedidoTable)
            ..where((t) =>
                t.pedidoId.equals(pedido.id) & t.deletedAt.isNull()))
          .get();

      for (final item in itens) {
        // Verifica se o produto controla estoque
        final produto = await (_db.select(_db.produtosTable)
              ..where((t) => t.id.equals(item.produtoId)))
            .getSingleOrNull();
        if (produto == null || !produto.controlaEstoque) continue;

        final qtd = item.quantidade.toInt();
        final dataEntrega = pedido.dataHoraEntregaPrevista;

        final demandaItem = DemandaItem(
          pedidoId: pedido.id,
          numeroPedido: pedido.numeroPedido ?? 0,
          clienteNome: pedido.clienteNomeAvulso ?? 'Cliente',
          quantidade: qtd,
          dataEntregaPrevista: dataEntrega,
        );

        if (demanda.containsKey(item.produtoId)) {
          final existing = demanda[item.produtoId]!;
          final novosPorData = Map<DateTime, int>.from(existing.porData);
          if (dataEntrega != null) {
            final diaKey = DateTime(
                dataEntrega.year, dataEntrega.month, dataEntrega.day);
            novosPorData[diaKey] = (novosPorData[diaKey] ?? 0) + qtd;
          }
          demanda[item.produtoId] = DemandaFutura(
            produtoId: existing.produtoId,
            nomeProduto: existing.nomeProduto,
            quantidadeTotal: existing.quantidadeTotal + qtd,
            porData: novosPorData,
            itens: [...existing.itens, demandaItem],
          );
        } else {
          final porData = <DateTime, int>{};
          if (dataEntrega != null) {
            final diaKey = DateTime(
                dataEntrega.year, dataEntrega.month, dataEntrega.day);
            porData[diaKey] = qtd;
          }
          demanda[item.produtoId] = DemandaFutura(
            produtoId: item.produtoId,
            nomeProduto: item.nomeProduto,
            quantidadeTotal: qtd,
            porData: porData,
            itens: [demandaItem],
          );
        }
      }
    }

    return demanda;
  }

  // ── Estoque Projetado ─────────────────────────────────────────────────────

  Future<List<EstoqueProjetado>> _calcularProjecoes(String tenantId) async {
    final demandaMap = await calcularDemandaFutura();

    // Soma produção planejada (planos ativos) por produto
    final Map<String, int> producaoPlanejadaPorProduto = {};
    for (final plano in _planos.where((p) => _isAtivo(p.status))) {
      producaoPlanejadaPorProduto[plano.produtoId] =
          (producaoPlanejadaPorProduto[plano.produtoId] ?? 0) +
              (plano.quantidadePlanejada - plano.quantidadeProduzida)
                  .clamp(0, 999999);
    }

    final estoques = await (_db.select(_db.estoqueProdutosTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) & t.deletedAt.isNull().equals(true)))
        .get();

    final produtos = await (_db.select(_db.produtosTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.controlaEstoque.equals(true) &
              t.deletedAt.isNull().equals(true)))
        .get();

    final estoquesMap = {for (final e in estoques) e.produtoId: e};
    _estoqueMap = estoquesMap;

    final projecoes = <EstoqueProjetado>[];
    for (final produto in produtos) {
      final est = estoquesMap[produto.id];
      final fisico = est?.quantidadeAtual ?? 0;
      final reservado = est?.quantidadeReservada ?? 0;
      final seguranca = est?.quantidadeSeguranca ?? 0;
      final minimo = est?.quantidadeMinima ?? 0;
      final critica = est?.quantidadeCritica ?? 0;
      final demanda = demandaMap[produto.id]?.quantidadeTotal ?? 0;
      final planejado = producaoPlanejadaPorProduto[produto.id] ?? 0;
      final situacao = _calcularSituacao(
        fisico: fisico,
        reservado: reservado,
        planejado: planejado,
      );

      projecoes.add(EstoqueProjetado(
        produtoId: produto.id,
        nomeProduto: produto.nome,
        corEtiqueta: produto.corEtiqueta,
        fisico: fisico,
        reservado: reservado,
        seguranca: seguranca,
        minimo: minimo,
        critica: critica,
        demandaFutura: demanda,
        producaoPlanejada: planejado,
        situacao: situacao,
      ));
    }

    projecoes.sort((a, b) {
      // Ordena: não atendível → via planejamento → ok
      final o = a.situacao.index.compareTo(b.situacao.index);
      if (o != 0) return o;
      return a.nomeProduto.compareTo(b.nomeProduto);
    });

    return projecoes;
  }

  StatusAtendibilidade _calcularSituacao({
    required int fisico,
    required int reservado,
    required int planejado,
  }) {
    if (reservado <= 0) return StatusAtendibilidade.atendivel;
    if (fisico >= reservado) return StatusAtendibilidade.atendivel;
    if (fisico + planejado >= reservado) {
      return StatusAtendibilidade.atendivelViaPlanejamento;
    }
    return StatusAtendibilidade.naoAtendivel;
  }

  // ── Atendibilidade por Pedido ─────────────────────────────────────────────

  /// Avalia se um pedido específico pode ser atendido com o estoque e produção atual.
  Future<AtendibilidadePedido> verificarAtendibilidade(String pedidoId) async {
    final tenantId = _context.tenantId;

    final pedido = await (_db.select(_db.pedidosTable)
          ..where((t) => t.id.equals(pedidoId)))
        .getSingleOrNull();

    if (pedido == null) {
      throw Exception('Pedido $pedidoId não encontrado');
    }

    final itens = await (_db.select(_db.itensPedidoTable)
          ..where((t) =>
              t.pedidoId.equals(pedidoId) & t.deletedAt.isNull()))
        .get();

    final dataEntrega = pedido.dataHoraEntregaPrevista;

    // Produção planejada antes da data de entrega por produto
    Future<int> producaoPlanejadaAteData(String prodId) async {
      if (dataEntrega == null) return 0;
      final planosDosProdutos = await (_db.select(_db.planejamentoProducaoTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.produtoId.equals(prodId) &
                t.dataPlano.isSmallerThanValue(dataEntrega) &
                t.status.isIn(['planejada', 'em_preparacao', 'em_producao', 'parcial']) &
                t.deletedAt.isNull()))
          .get();
      return planosDosProdutos.fold<int>(
          0,
          (sum, p) =>
              sum + (p.quantidadePlanejada - p.quantidadeProduzida).clamp(0, 999999));
    }

    final atendibilidadeItens = <AtendibilidadeItem>[];

    for (final item in itens) {
      final produto = await (_db.select(_db.produtosTable)
            ..where((t) => t.id.equals(item.produtoId)))
          .getSingleOrNull();
      if (produto == null || !produto.controlaEstoque) continue;

      final est = await (_db.select(_db.estoqueProdutosTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.produtoId.equals(item.produtoId) &
                t.deletedAt.isNull().equals(true)))
          .getSingleOrNull();

      final disponivel = ((est?.quantidadeAtual ?? 0) -
              (est?.quantidadeReservada ?? 0))
          .clamp(0, 999999);
      final pedido_ = item.quantidade.toInt();
      final planejado = await producaoPlanejadaAteData(item.produtoId);

      final StatusAtendibilidade statusItem;
      if (disponivel >= pedido_) {
        statusItem = StatusAtendibilidade.atendivel;
      } else if (disponivel + planejado >= pedido_) {
        statusItem = StatusAtendibilidade.atendivelViaPlanejamento;
      } else {
        statusItem = StatusAtendibilidade.naoAtendivel;
      }

      atendibilidadeItens.add(AtendibilidadeItem(
        produtoId: item.produtoId,
        nomeProduto: item.nomeProduto,
        quantidadePedida: pedido_,
        disponivelAtual: disponivel,
        producaoPlanejadaAteEntrega: planejado,
        status: statusItem,
      ));
    }

    return AtendibilidadePedido.fromItens(
      pedidoId: pedidoId,
      numeroPedido: pedido.numeroPedido ?? 0,
      dataEntregaPrevista: dataEntrega,
      itens: atendibilidadeItens,
    );
  }

  // ── Sugestões de Plano ────────────────────────────────────────────────────

  List<SugestaoPlano> _gerarSugestoes() {
    final sugestoes = <SugestaoPlano>[];

    for (final proj in _projecoes) {
      final est = _estoqueMap[proj.produtoId];
      final capacidade = est?.capacidadeCampanha ?? 100;
      final lote = capacidade > 0 ? capacidade : 100;

      // 1. Caso A: Reservas excedem físico (necessidade física imediata de cobertura)
      if (proj.reservado > proj.fisico) {
        final deficit = proj.reservado - proj.fisico;
        final qtdSugerida = ((deficit / lote).ceil() * lote);

        String motivo = 'Estoque insuficiente para cobrir as reservas atuais.\n'
            '- ${proj.reservado} un. reservadas\n'
            '- ${proj.fisico} un. físicas atuais\n'
            '- Estoque disponível insuficiente.';

        if (capacidade > 0 && qtdSugerida > capacidade) {
          motivo += '\n⚠️ CAPACIDADE INSUFICIENTE: A necessidade ($qtdSugerida un.) excede a capacidade diária ($capacidade un.). Sugerido planejar a produção em mais de um dia.';
        }

        sugestoes.add(SugestaoPlano(
          produtoId: proj.produtoId,
          nomeProduto: proj.nomeProduto,
          quantidadeSugerida: qtdSugerida,
          capacidadeCampanha: lote,
          motivo: motivo,
        ));
        continue;
      }

      // 2. Caso B: Disponível abaixo do estoque mínimo
      if (proj.disponivel <= proj.minimo && proj.minimo > 0) {
        final deficitTotal = proj.minimo - proj.disponivel - proj.producaoPlanejada;
        if (deficitTotal <= 0) continue; // produção planejada já cobrirá

        final qtdSugerida = ((deficitTotal / lote).ceil() * lote);
        final bufferInfo = proj.seguranca > 0 
            ? '\n- Estoque de segurança (${proj.seguranca} un.) será preservado.'
            : '';

        String motivo = 'Estoque abaixo do mínimo.\n'
            '- ${proj.disponivel} un. disponíveis\n'
            '- Mínimo ideal de ${proj.minimo} un.$bufferInfo\n'
            '- Sugerido produzir para restabelecer margem de atenção.';

        if (capacidade > 0 && qtdSugerida > capacidade) {
          motivo += '\n⚠️ CAPACIDADE INSUFICIENTE: A necessidade ($qtdSugerida un.) excede a capacidade diária ($capacidade un.). Sugerido planejar a produção em mais de um dia.';
        }

        sugestoes.add(SugestaoPlano(
          produtoId: proj.produtoId,
          nomeProduto: proj.nomeProduto,
          quantidadeSugerida: qtdSugerida,
          capacidadeCampanha: lote,
          motivo: motivo,
        ));
        continue;
      }

      // 3. Caso C: Projetado abaixo do mínimo (demanda futura consumirá o disponível)
      if (proj.projetado < proj.minimo && proj.demandaFutura > 0) {
        final deficit = proj.minimo - proj.disponivel - proj.producaoPlanejada;
        if (deficit <= 0) continue;

        final qtdSugerida = ((deficit / lote).ceil() * lote);

        String motivo = 'Demanda futura e estoque mínimo não cobertos pela produção planejada.\n'
            '- ${proj.demandaFutura} un. em pedidos ativos\n'
            '- ${proj.disponivel} un. disponíveis\n'
            '- ${proj.producaoPlanejada} un. já planejadas.';

        if (capacidade > 0 && qtdSugerida > capacidade) {
          motivo += '\n⚠️ CAPACIDADE INSUFICIENTE: A necessidade ($qtdSugerida un.) excede a capacidade diária ($capacidade un.). Sugerido planejar a produção em mais de um dia.';
        }

        sugestoes.add(SugestaoPlano(
          produtoId: proj.produtoId,
          nomeProduto: proj.nomeProduto,
          quantidadeSugerida: qtdSugerida,
          capacidadeCampanha: lote,
          motivo: motivo,
        ));
        continue;
      }
    }

    return sugestoes;
  }

  // ── Helpers Internos ──────────────────────────────────────────────────────

  Future<void> _atualizarStatus(String planoId, String novoStatus) async {
    final now = DateTime.now().toUtc();
    final operadorId = _context.usuario.id;
    final tenantId = _context.tenantId;

    final plano = await (_db.select(_db.planejamentoProducaoTable)
          ..where((t) => t.id.equals(planoId)))
        .getSingleOrNull();
    if (plano == null) return;

    await (_db.update(_db.planejamentoProducaoTable)
          ..where((t) => t.id.equals(planoId)))
        .write(PlanejamentoProducaoTableCompanion(
      status: Value(novoStatus),
      operadorId: Value(operadorId),
      updatedAt: Value(now),
      updatedBy: Value(operadorId),
      syncStatus: const Value(SyncStatus.pending),
    ));

    // Auditoria
    await _logAuditoria(
      planoId: planoId,
      action: 'UPDATE',
      produtoId: plano.produtoId,
      status: novoStatus,
      diff: {
        'status': novoStatus,
        'statusAnterior': plano.status,
      },
    );

    await _enqueueOutbox(planoId, 'update', tenantId: tenantId);
    await _carregar();
  }

  /// Gera a entrada de estoque ao concluir o plano.
  /// Chama [EstoqueController.registrarProducao()] para manter a rastreabilidade.
  Future<void> _entradaEstoqueDeProducao({
    required String planoId,
    required String produtoId,
    required int quantidade,
    required String tenantId,
  }) async {
    await _estoqueCtrl.registrarProducao(
      produtoId: produtoId,
      quantidade: quantidade,
      motivo: 'Conclusão do plano de produção #${planoId.substring(0, 8).toUpperCase()}',
      dataProducao: DateTime.now().toUtc(),
    );
  }

  Future<void> _enqueueOutbox(
    String planoId,
    String action, {
    required String tenantId,
  }) async {
    final plano = await (_db.select(_db.planejamentoProducaoTable)
          ..where((t) => t.id.equals(planoId)))
        .getSingleOrNull();

    if (plano == null) return;

    await _db.into(_db.outboxSync).insertOnConflictUpdate(
      OutboxSyncCompanion.insert(
        tenantId: tenantId,
        entity: 'planejamento_producao',
        entityId: planoId,
        action: action,
        payload: _planoToJson(plano),
        status: 'pending',
        version: plano.syncVersion,
        createdAt: DateTime.now(),
        attemptsCount: const Value(0),
      ),
    );
  }

  String _planoToJson(PlanoProducaoData p) {
    return '{'
        '"id":"${p.id}",'
        '"tenantId":"${p.tenantId}",'
        '"produtoId":"${p.produtoId}",'
        '"dataPlano":"${p.dataPlano.toIso8601String()}",'
        '"quantidadePlanejada":${p.quantidadePlanejada},'
        '"quantidadeProduzida":${p.quantidadeProduzida},'
        '"capacidadeCampanha":${p.capacidadeCampanha},'
        '"status":"${p.status}",'
        '"motivoCancelamento":${p.motivoCancelamento != null ? '"${p.motivoCancelamento}"' : 'null'},'
        '"observacoes":${p.observacoes != null ? '"${p.observacoes}"' : 'null'},'
        '"operadorId":${p.operadorId != null ? '"${p.operadorId}"' : 'null'},'
        '"necessidadeOrigem":${p.necessidadeOrigem != null ? '"${p.necessidadeOrigem}"' : 'null'},'
        '"createdAt":"${p.createdAt.toIso8601String()}",'
        '"updatedAt":"${p.updatedAt.toIso8601String()}",'
        '"createdBy":"${p.createdBy}",'
        '"updatedBy":"${p.updatedBy}",'
        '"syncVersion":${p.syncVersion}'
        '}';
  }

  /// Edita data, quantidade e observações de um plano ainda não iniciado (status 'planejada').
  Future<void> editarPlano({
    required String planoId,
    required DateTime dataPlano,
    required int quantidadePlanejada,
    String? observacoes,
  }) async {
    assert(quantidadePlanejada > 0, 'Quantidade planejada deve ser maior que zero');

    final now = DateTime.now().toUtc();
    final operadorId = _context.usuario.id;
    final tenantId = _context.tenantId;

    final plano = await (_db.select(_db.planejamentoProducaoTable)
          ..where((t) => t.id.equals(planoId)))
        .getSingleOrNull();

    if (plano == null) throw Exception('Plano $planoId não encontrado');

    if (plano.status != 'planejada') {
      throw Exception('Apenas campanhas planejadas que não foram iniciadas podem ser editadas.');
    }

    await (_db.update(_db.planejamentoProducaoTable)
          ..where((t) => t.id.equals(planoId)))
        .write(PlanejamentoProducaoTableCompanion(
      dataPlano: Value(dataPlano.toUtc()),
      quantidadePlanejada: Value(quantidadePlanejada),
      observacoes: Value(observacoes),
      operadorId: Value(operadorId),
      updatedAt: Value(now),
      updatedBy: Value(operadorId),
      syncStatus: const Value(SyncStatus.pending),
    ));

    // Auditoria
    await _logAuditoria(
      planoId: planoId,
      action: 'UPDATE',
      produtoId: plano.produtoId,
      status: plano.status,
      diff: {
        'quantidadePlanejadaAnterior': plano.quantidadePlanejada,
        'quantidadePlanejadaNova': quantidadePlanejada,
        'dataPlanoAnterior': plano.dataPlano.toIso8601String(),
        'dataPlanoNova': dataPlano.toIso8601String(),
        'observacoesAnterior': plano.observacoes,
        'observacoesNova': observacoes,
      },
    );

    await _enqueueOutbox(planoId, 'update', tenantId: tenantId);
    await _carregar();
  }

  Future<void> _logAuditoria({
    required String planoId,
    required String action,
    required String produtoId,
    required String status,
    required Map<String, dynamic> diff,
  }) async {
    try {
      final auditLogRepo = DependencyInjection().get<AuditLogRepository>();
      final operadorId = _context.usuario.id;

      final prod = await (_db.select(_db.produtosTable)
            ..where((t) => t.id.equals(produtoId)))
          .getSingleOrNull();
      final nomeProduto = prod?.nome ?? 'Produto';

      await auditLogRepo.log(
        entityName: 'planejamento_producao',
        entityId: planoId,
        userId: operadorId,
        action: action,
        entityDisplayName: 'Plano de Produção - $nomeProduto (Status: $status)',
        entityModule: 'Produção',
        diff: diff,
      );
    } catch (e) {
      debugPrint('[PlanoProducaoController] Falha ao registrar log de auditoria: $e');
    }
  }
}
