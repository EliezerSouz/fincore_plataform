import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/repository/audit_log_repository.dart';
import 'package:fincore_core/sync/outbox_service.dart';
import 'package:fincore_core/sync/sync_engine.dart';
import 'package:uuid/uuid.dart';
import '../../shared/data/sync/supabase_sync_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modelo de View — EstoqueItem (usado na UI)
// ─────────────────────────────────────────────────────────────────────────────

/// View model para exibição de estoque na tela.
/// Combina os dados da tabela com cálculos de disponibilidade.
class EstoqueItem {
  final EstoqueProdutoData estoque;
  final String nomeProduto;
  final String? corEtiqueta;
  final EstoqueStatus status;
  final int producaoPlanejada;

  const EstoqueItem({
    required this.estoque,
    required this.nomeProduto,
    this.corEtiqueta,
    required this.status,
    required this.producaoPlanejada,
  });

  /// Estoque físico real no freezer
  int get quantidadeAtual => estoque.quantidadeAtual;

  /// Comprometido com pedidos futuros (não saiu fisicamente)
  int get quantidadeReservada => estoque.quantidadeReservada;

  /// Disponível para venda = max(Físico - Reservado, 0)
  /// Comercializado nunca como negativo na interface.
  int get quantidadeDisponivel =>
      (estoque.quantidadeAtual - estoque.quantidadeReservada).clamp(0, 999999);

  /// Déficit Atual = max(Reservado - Físico, 0)
  /// Representa quanto do estoque reservado não consegue ser atendido pelo estoque físico existente.
  int get deficitAtual =>
      (estoque.quantidadeReservada - estoque.quantidadeAtual).clamp(0, 999999);

  int get quantidadeMinima => estoque.quantidadeMinima;
  int get quantidadeMaxima => estoque.quantidadeMaxima;
  int get quantidadeProducaoLote => estoque.quantidadeProducaoLote;
  int get diasCoberturaAlvo => estoque.diasCoberturaAlvo;
  int get quantidadeSeguranca => estoque.quantidadeSeguranca;
  int get quantidadeCritica => estoque.quantidadeCritica;
  int get capacidadeCampanha => estoque.capacidadeCampanha;
  int get tempoPreparacao => estoque.tempoPreparacao;
  String get unidade => estoque.unidade;

  /// Déficit em relação ao estoque mínimo
  int get deficitMinimo =>
      (quantidadeMinima - quantidadeDisponivel).clamp(0, 999999);

  /// Déficit em relação ao estoque crítico
  int get deficitCritico =>
      (quantidadeCritica - quantidadeDisponivel).clamp(0, 999999);

  /// Estoque projetado = Físico + Produção Planejada - Reservado
  /// REGRA DE OURO: NUNCA usar Disponível + Produção Planejada quando Disponível for limitado a zero.
  int get estoqueProjetado =>
      quantidadeAtual + producaoPlanejada - quantidadeReservada;

  /// Motivo textual claro do status operacional
  String get motivoStatus {
    final def = deficitAtual;
    if (def > 0) {
      if (producaoPlanejada >= def) {
        return 'Déficit atual de $def $unidade — coberto por produção planejada ($producaoPlanejada $unidade).';
      } else if (producaoPlanejada > 0) {
        return 'Déficit atual de $def $unidade — produção planejada insuficiente ($producaoPlanejada $unidade).';
      } else {
        return 'Déficit atual de $def $unidade para atender as reservas existentes ($quantidadeReservada $unidade).';
      }
    }
    switch (status) {
      case EstoqueStatus.critico:
        if (producaoPlanejada > 0) {
          return 'Disponível ($quantidadeDisponivel $unidade) <= Crítico ($quantidadeCritica $unidade) — possui produção planejada ($producaoPlanejada $unidade).';
        }
        return 'Disponível ($quantidadeDisponivel $unidade) abaixo do estoque crítico ($quantidadeCritica $unidade).';
      case EstoqueStatus.baixo:
        if (producaoPlanejada > 0) {
          return 'Disponível ($quantidadeDisponivel $unidade) <= Mínimo ($quantidadeMinima $unidade) — possui produção planejada ($producaoPlanejada $unidade).';
        }
        return 'Disponível ($quantidadeDisponivel $unidade) abaixo do estoque mínimo ($quantidadeMinima $unidade).';
      case EstoqueStatus.normal:
        return 'Estoque disponível ($quantidadeDisponivel $unidade) suficiente para operação.';
      case EstoqueStatus.producaoNecessaria:
        return 'Produção necessária para cobrir demanda planejada.';
    }
  }

  /// Texto explicativo de cobertura de produção
  String get coberturaProducaoTexto {
    if (producaoPlanejada > 0) {
      return '$producaoPlanejada $unidade planejadas';
    }
    return 'Nenhuma planejada';
  }

  /// Indica se o produto exige intervenção imediata do usuário
  bool get precisaAcao {
    if (deficitAtual > 0 && producaoPlanejada < deficitAtual) {
      return true;
    }
    if ((status == EstoqueStatus.critico || status == EstoqueStatus.baixo) &&
        producaoPlanejada == 0) {
      return true;
    }
    if (producaoPlanejada > 0 && (estoqueProjetado < quantidadeMinima)) {
      return true;
    }
    return false;
  }

  /// Quantidade sugerida a produzir para atingir o estoque alvo
  int get sugestaoProducao {
    final lote = quantidadeProducaoLote > 0 ? quantidadeProducaoLote : 100;
    
    if (quantidadeReservada > quantidadeAtual) {
      final deficit = quantidadeReservada - quantidadeAtual - producaoPlanejada;
      if (deficit <= 0) return 0;
      return ((deficit / lote).ceil() * lote);
    } else {
      final deficit = quantidadeMinima - quantidadeDisponivel - producaoPlanejada;
      if (deficit <= 0) return 0;
      return ((deficit / lote).ceil() * lote);
    }
  }
}

/// Status de disponibilidade do estoque
enum EstoqueStatus {
  /// Disponível >= Mínimo → verde (normal)
  normal,
  /// Disponível entre crítico e mínimo → amarelo/laranja (atenção)
  baixo,
  /// Disponível < Crítico → vermelho (crítico)
  critico,
  /// Planejamento indica necessidade de produção → azul/roxo (produção necessária)
  producaoNecessaria,
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelo para Agenda de Reservas
// ─────────────────────────────────────────────────────────────────────────────

class ReservaAgendada {
  final MovimentacaoEstoqueData movimentacao;
  final String nomeProduto;
  final DateTime dataEntrega;
  final int quantidade;

  const ReservaAgendada({
    required this.movimentacao,
    required this.nomeProduto,
    required this.dataEntrega,
    required this.quantidade,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// EstoqueController
// ─────────────────────────────────────────────────────────────────────────────

/// Controller principal do Módulo de Estoque e Produção.
///
/// Gerencia:
/// - Saldo físico (quantidadeAtual)
/// - Saldo reservado (quantidadeReservada)
/// - Registro de produções diárias
/// - Agenda de reservas futuras (relatório preditivo)
/// - Alertas de nível crítico/baixo baseados em disponível = físico - reservado
class EstoqueController extends ChangeNotifier {
  final FincoreDatabase _db;
  final TenantContext _context;

  List<EstoqueItem> _itens = [];
  List<ReservaAgendada> _reservasAgendadas = [];
  bool _loading = false;
  String? _error;
  StreamSubscription? _syncSub;

  EstoqueController()
      : _db = DependencyInjection().get<FincoreDatabase>(),
        _context = DependencyInjection().get<TenantContext>() {
    _carregar();
    try {
      final syncService = DependencyInjection().get<SupabaseSyncService>();
      _syncSub = syncService.onDataSynced.listen((_) => _carregar(isFromSync: true));
    } catch (_) {}
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  List<EstoqueItem> get itens => _itens;
  List<ReservaAgendada> get reservasAgendadas => _reservasAgendadas;

  List<EstoqueItem> get itensCriticos =>
      _itens.where((i) => i.status == EstoqueStatus.critico).toList();

  List<EstoqueItem> get itensBaixos =>
      _itens.where((i) => i.status == EstoqueStatus.baixo).toList();

  List<EstoqueItem> get itensNormais =>
      _itens.where((i) => i.status == EstoqueStatus.normal).toList();

  List<EstoqueItem> get itensComProducao =>
      _itens.where((i) => i.producaoPlanejada > 0).toList();

  List<EstoqueItem> get itensSemProducao =>
      _itens.where((i) => i.producaoPlanejada == 0).toList();

  List<EstoqueItem> get itensPrecisamAcao =>
      _itens.where((i) => i.precisaAcao).toList();

  bool get loading => _loading;
  String? get error => _error;
  bool get temAlertas => itensCriticos.isNotEmpty || itensBaixos.isNotEmpty;

  /// Número de produtos que precisam produção urgente (para badge no shell)
  int get qtdAlertasUrgentes => itensCriticos.length + itensBaixos.length;

  Future<void> _carregar({bool isFromSync = false}) async {
    if (!_context.hasContext) return;
    _loading = true;
    notifyListeners();

    try {
      final tenantId = _context.tenantId;

      // 0. Auto-healing: Recalcula reservas de pedidos agendados e converte baixas indevidas
      await recalcularReservasEEstoques(isFromSync: isFromSync);

      // 1. Todos os registros de estoque ativos
      final estoques = await (
        _db.select(_db.estoqueProdutosTable)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull().equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)])
      ).get();

      // 1b. Todos os planos de produção ativos para computar o planejado em andamento
      final planosAtivos = await (
        _db.select(_db.planejamentoProducaoTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.status.isIn(['planejada', 'em_preparacao', 'em_producao', 'parcial']) &
              t.deletedAt.isNull())
      ).get();
      final Map<String, int> producaoPlanejadaPorProduto = {};
      for (final p in planosAtivos) {
        producaoPlanejadaPorProduto[p.produtoId] =
            (producaoPlanejadaPorProduto[p.produtoId] ?? 0) +
                (p.quantidadePlanejada - p.quantidadeProduzida).clamp(0, 999999);
      }

      // 2. Todos os produtos com controle de estoque ativo
      final produtos = await (
        _db.select(_db.produtosTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull().equals(true) &
              t.controlaEstoque.equals(true))
      ).get();

      final produtosMap = {for (final p in produtos) p.id: p};
      final estoquesMap = {for (final e in estoques) e.produtoId: e};

      // 3. Monta os EstoqueItems (1 por produto com controlaEstoque=true)
      final itens = <EstoqueItem>[];
      for (final produto in produtos) {
        final e = estoquesMap[produto.id];
        final planejado = producaoPlanejadaPorProduto[produto.id] ?? 0;
        if (e != null) {
          final disponivel = (e.quantidadeAtual - e.quantidadeReservada).clamp(0, 999999);
          final deficit = (e.quantidadeReservada - e.quantidadeAtual).clamp(0, 999999);
          itens.add(EstoqueItem(
            estoque: e,
            nomeProduto: produto.nome,
            corEtiqueta: produto.corEtiqueta,
            status: _calcularStatus(disponivel, e.quantidadeMinima, e.quantidadeCritica, deficitAtual: deficit),
            producaoPlanejada: planejado,
          ));
        } else {
          // Produto sem registro → critico com saldo zero
          final fakeEstoque = EstoqueProdutoData(
            id: '',
            tenantId: tenantId,
            produtoId: produto.id,
            quantidadeAtual: 0,
            quantidadeReservada: 0,
            quantidadeMinima: 0,
            quantidadeMaxima: 9999,
            quantidadeProducaoLote: 100,
            diasCoberturaAlvo: 3,
            capacidadeCampanha: 0,
            estrategiaProducao: 'concentrada',
            tempoPreparacao: 0,
            quantidadeSeguranca: 0,
            quantidadeCritica: 0,
            unidade: 'un',
            syncStatus: SyncStatus.pending,
            syncVersion: 1,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: '',
            updatedBy: '',
          );
          itens.add(EstoqueItem(
            estoque: fakeEstoque,
            nomeProduto: produto.nome,
            corEtiqueta: produto.corEtiqueta,
            status: EstoqueStatus.critico,
            producaoPlanejada: planejado,
          ));
        }
      }

      // Ordena por severidade operacional: Críticos com déficit > Críticos > Atenção > Normais
      itens.sort((a, b) {
        final prioA = calcularPrioridadeOperacional(a);
        final prioB = calcularPrioridadeOperacional(b);
        if (prioA != prioB) return prioA.compareTo(prioB);

        if (a.deficitAtual != b.deficitAtual) {
          return b.deficitAtual.compareTo(a.deficitAtual);
        }

        final diffA = a.quantidadeDisponivel - a.quantidadeMinima;
        final diffB = b.quantidadeDisponivel - b.quantidadeMinima;
        if (diffA != diffB) return diffA.compareTo(diffB);

        return a.nomeProduto.toLowerCase().compareTo(b.nomeProduto.toLowerCase());
      });
      _itens = itens;

      // 4. Carrega agenda de reservas futuras baseando-se no fluxo operacional real do KDS
      final ordensAtivas = await (
        _db.select(_db.ordensPreparoTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.status.isIn(['pendente', 'em_preparo']) &
              t.prioridade.equals('Entrega Programada') &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.criadaEm)])
      ).get();

      final List<ReservaAgendada> listAgendados = [];
      for (final ord in ordensAtivas) {
        try {
          final List<dynamic> rawItens = jsonDecode(ord.itensJson) as List<dynamic>;
          for (final x in rawItens) {
            final itemMap = x as Map<String, dynamic>;
            final String prodId = itemMap['produtoId'] ?? '';
            final String nomeProd = itemMap['nomeProduto'] ?? produtosMap[prodId]?.nome ?? 'Produto desconhecido';
            final double qtdDouble = (itemMap['quantidade'] ?? 0).toDouble();
            final int qtd = qtdDouble.round();

            final fakeMov = MovimentacaoEstoqueData(
              id: ord.id,
              tenantId: tenantId,
              produtoId: prodId,
              tipo: 'reserva',
              quantidade: qtd,
              quantidadeAntes: 0,
              quantidadeDepois: 0,
              motivo: 'Reserva para entrega',
              dataHora: ord.criadaEm,
              createdAt: ord.createdAt,
              updatedAt: ord.updatedAt,
              createdBy: ord.createdBy,
              updatedBy: ord.updatedBy,
              syncVersion: 1,
              syncStatus: SyncStatus.pending,
            );

            listAgendados.add(ReservaAgendada(
              movimentacao: fakeMov,
              nomeProduto: nomeProd,
              dataEntrega: ord.criadaEm.toLocal(),
              quantidade: qtd,
            ));
          }
        } catch (e) {
          debugPrint('[EstoqueController] Erro ao processar itens da ordem ${ord.id}: $e');
        }
      }

      _reservasAgendadas = listAgendados;

      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar estoque: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _carregar();

  /// Calcula o peso de prioridade operacional de um item para ordenação de urgência
  static int calcularPrioridadeOperacional(EstoqueItem item) {
    // 0: Déficit com insuficiência projetada -> URGÊNCIA MÁXIMA
    if (item.deficitAtual > 0 && item.estoqueProjetado < 0) return 0;
    
    // 1: Déficit atual (reservas sem cobertura de estoque físico)
    if (item.deficitAtual > 0) return 1;

    // 2: Crítico sem produção planejada
    if (item.status == EstoqueStatus.critico && item.producaoPlanejada == 0) return 2;

    // 3: Crítico com produção planejada
    if (item.status == EstoqueStatus.critico) return 3;

    // 4: Atenção sem produção planejada (abaixo do mínimo)
    if (item.status == EstoqueStatus.baixo && item.producaoPlanejada == 0) return 4;

    // 5: Atenção com produção planejada
    if (item.status == EstoqueStatus.baixo) return 5;

    // 6: Produção Necessária
    if (item.status == EstoqueStatus.producaoNecessaria) return 6;

    // 7: Normal
    return 7;
  }

  EstoqueStatus _calcularStatus(int disponivel, int minimo, int critico, {int deficitAtual = 0}) {
    if (deficitAtual > 0) return EstoqueStatus.critico;
    if (critico > 0) {
      if (disponivel <= critico) return EstoqueStatus.critico;
    } else {
      if (disponivel <= 0 && minimo > 0) return EstoqueStatus.critico;
    }
    if (disponivel <= minimo) return EstoqueStatus.baixo;
    return EstoqueStatus.normal;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ① REGISTRAR PRODUÇÃO (entrada formal de produção diária)
  // ─────────────────────────────────────────────────────────────────────────

  /// Registra um lote de produção.
  /// Incrementa `quantidadeAtual` e gera movimentação `tipo: 'producao'`.
  /// [motivo] é obrigatório — ex: "Produção turno manhã — 16/08/2026"
  Future<void> registrarProducao({
    required String produtoId,
    required int quantidade,
    required String motivo,
    DateTime? dataProducao,
  }) async {
    assert(motivo.trim().isNotEmpty, 'Motivo obrigatório para produção');
    assert(quantidade > 0, 'Quantidade deve ser maior que zero');

    final tenantId = _context.tenantId;
    final operadorId = _context.usuario.id;
    final now = DateTime.now().toUtc();
    final dataHora = dataProducao ?? now;

    await _movimentarEstoque(
      produtoId: produtoId,
      tipo: 'producao',
      quantidade: quantidade,
      motivo: motivo,
      operadorId: operadorId,
      tenantId: tenantId,
      now: now,
      dataHora: dataHora,
      isEntradaFisica: true,
      isEntradaReserva: false,
    );

    await _carregar();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ①.1 ESTORNAR PRODUÇÃO (reversão de lote de produção produzido por engano)
  // ─────────────────────────────────────────────────────────────────────────

  /// Estorna um lote ou parte da produção realizada por engano/cancelamento total.
  /// Decrementa `quantidadeAtual` e gera movimentação `tipo: 'estorno_producao'`.
  /// [motivo] é obrigatório.
  Future<void> estornarProducao({
    required String produtoId,
    required int quantidade,
    required String motivo,
    DateTime? dataEstorno,
  }) async {
    assert(motivo.trim().isNotEmpty, 'Motivo obrigatório para estorno de produção');
    assert(quantidade > 0, 'Quantidade de estorno deve ser maior que zero');

    final tenantId = _context.tenantId;
    final operadorId = _context.usuario.id;
    final now = DateTime.now().toUtc();
    final dataHora = dataEstorno ?? now;

    await _movimentarEstoque(
      produtoId: produtoId,
      tipo: 'estorno_producao',
      quantidade: quantidade,
      motivo: motivo,
      operadorId: operadorId,
      tenantId: tenantId,
      now: now,
      dataHora: dataHora,
      isEntradaFisica: false,
      isSaidaFisica: true,
      isEntradaReserva: false,
    );

    await _carregar();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ② RESERVAR ESTOQUE (para pedido futuro)
  // ─────────────────────────────────────────────────────────────────────────

  /// Reserva unidades para um pedido com entrega futura.
  /// Incrementa `quantidadeReservada` (não toca `quantidadeAtual`).
  Future<void> reservarEstoque({
    required String produtoId,
    required int quantidade,
    required String pedidoId,
    required DateTime dataEntregaPrevista,
    String? motivo,
  }) async {
    final tenantId = _context.tenantId;
    final operadorId = _context.usuario.id;
    final now = DateTime.now().toUtc();

    await _movimentarEstoque(
      produtoId: produtoId,
      tipo: 'reserva',
      quantidade: quantidade,
      motivo: motivo ?? 'Reserva para pedido',
      operadorId: operadorId,
      tenantId: tenantId,
      now: now,
      pedidoId: pedidoId,
      dataEntregaPrevista: dataEntregaPrevista,
      isEntradaFisica: false,
      isEntradaReserva: true,
    );

    await _carregar();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ③ LIBERAR RESERVA (pedido cancelado)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> liberarReserva({
    required String produtoId,
    required int quantidade,
    required String pedidoId,
  }) async {
    final tenantId = _context.tenantId;
    final operadorId = _context.usuario.id;
    final now = DateTime.now().toUtc();

    await _movimentarEstoque(
      produtoId: produtoId,
      tipo: 'liberacao_reserva',
      quantidade: quantidade,
      motivo: 'Cancelamento de pedido — reserva liberada',
      operadorId: operadorId,
      tenantId: tenantId,
      now: now,
      pedidoId: pedidoId,
      isEntradaFisica: false,
      isEntradaReserva: false, // libera reserva (decrementa quantidadeReservada)
      isSaidaReserva: true,
    );

    await _carregar();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ④ EXPEDIÇÃO (entrega realizada — baixa física definitiva)
  // ─────────────────────────────────────────────────────────────────────────

  /// Conclui a entrega: decrementa `quantidadeAtual` e `quantidadeReservada`.
  Future<void> expedir({
    required String produtoId,
    required int quantidade,
    required String pedidoId,
  }) async {
    final tenantId = _context.tenantId;
    final operadorId = _context.usuario.id;
    final now = DateTime.now().toUtc();

    await _movimentarEstoque(
      produtoId: produtoId,
      tipo: 'expedicao',
      quantidade: quantidade,
      motivo: 'Entrega realizada',
      operadorId: operadorId,
      tenantId: tenantId,
      now: now,
      pedidoId: pedidoId,
      isEntradaFisica: false,
      isEntradaReserva: false,
      isSaidaFisica: true,
      isSaidaReserva: true, // expedição baixa reserva E físico
    );

    await _carregar();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ⑤ AJUSTE MANUAL (motivo obrigatório)
  // ─────────────────────────────────────────────────────────────────────────

  /// Ajuste manual de estoque com tipos formalizados.
  ///
  /// [tipo] aceita: 'ajuste_positivo' | 'ajuste_negativo' | 'inventario'
  /// [motivo] é OBRIGATÓRIO para todos os ajustes.
  Future<void> ajustarEstoque({
    required String produtoId,
    required int quantidade,
    required String tipo,
    required String motivo,
  }) async {
    assert(motivo.trim().isNotEmpty, 'Motivo obrigatório para ajuste de estoque');
    assert(
      ['ajuste_positivo', 'ajuste_negativo', 'inventario', 'entrada'].contains(tipo),
      'Tipo inválido: use ajuste_positivo, ajuste_negativo, inventario ou entrada',
    );

    final tenantId = _context.tenantId;
    final operadorId = _context.usuario.id;
    final now = DateTime.now().toUtc();

    final isEntrada = tipo == 'ajuste_positivo' || tipo == 'entrada';
    final isInventario = tipo == 'inventario';

    if (isInventario) {
      await _inventariar(
        produtoId: produtoId,
        novaQuantidade: quantidade,
        motivo: motivo,
        operadorId: operadorId,
        tenantId: tenantId,
        now: now,
      );
    } else {
      await _movimentarEstoque(
        produtoId: produtoId,
        tipo: tipo,
        quantidade: quantidade,
        motivo: motivo,
        operadorId: operadorId,
        tenantId: tenantId,
        now: now,
        isEntradaFisica: isEntrada,
        isEntradaReserva: false,
      );
    }

    await _carregar();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ⑥ CONFIGURAR PARÂMETROS DE PRODUÇÃO
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> configurarParametros({
    required String estoqueId,
    int? quantidadeMinima,
    int? quantidadeProducaoLote,
    int? diasCoberturaAlvo,
    int? quantidadeSeguranca,
    int? quantidadeCritica,
    int? capacidadeCampanha,
    int? tempoPreparacao,
  }) async {
    final now = DateTime.now().toUtc();
    final operadorId = _context.usuario.id;
    final tenantId = _context.tenantId;

    // Busca o registro atual antes da alteração para gerar logs de auditoria e preparar o push do outbox
    final anterior = await (_db.select(_db.estoqueProdutosTable)
          ..where((t) => t.id.equals(estoqueId)))
        .getSingleOrNull();

    if (anterior == null) return;

    await (
      _db.update(_db.estoqueProdutosTable)
        ..where((t) => t.id.equals(estoqueId))
    ).write(EstoqueProdutosTableCompanion(
      quantidadeMinima: quantidadeMinima != null ? Value(quantidadeMinima) : const Value.absent(),
      quantidadeProducaoLote: quantidadeProducaoLote != null ? Value(quantidadeProducaoLote) : const Value.absent(),
      diasCoberturaAlvo: diasCoberturaAlvo != null ? Value(diasCoberturaAlvo) : const Value.absent(),
      quantidadeSeguranca: quantidadeSeguranca != null ? Value(quantidadeSeguranca) : const Value.absent(),
      quantidadeCritica: quantidadeCritica != null ? Value(quantidadeCritica) : const Value.absent(),
      capacidadeCampanha: capacidadeCampanha != null ? Value(capacidadeCampanha) : const Value.absent(),
      tempoPreparacao: tempoPreparacao != null ? Value(tempoPreparacao) : const Value.absent(),
      updatedAt: Value(now),
      updatedBy: Value(operadorId),
      syncStatus: const Value(SyncStatus.pending),
    ));

    final atual = await (_db.select(_db.estoqueProdutosTable)
          ..where((t) => t.id.equals(estoqueId)))
        .getSingleOrNull();

    if (atual != null) {
      // 1. Auditoria individualizada das alterações
      final auditLogRepo = DependencyInjection().get<AuditLogRepository>();

      if (quantidadeMinima != null && quantidadeMinima != anterior.quantidadeMinima) {
        await auditLogRepo.log(
          entityName: 'estoque_produto',
          entityId: estoqueId,
          userId: operadorId,
          action: 'UPDATE',
          entityDisplayName: 'Estoque mínimo alterado',
          entityModule: 'Estoque',
          reason: 'Alteração de parâmetro de estoque mínimo de ${anterior.quantidadeMinima} para $quantidadeMinima',
          diff: {'de': anterior.quantidadeMinima, 'para': quantidadeMinima},
        );
      }
      if (quantidadeCritica != null && quantidadeCritica != anterior.quantidadeCritica) {
        await auditLogRepo.log(
          entityName: 'estoque_produto',
          entityId: estoqueId,
          userId: operadorId,
          action: 'UPDATE',
          entityDisplayName: 'Estoque crítico alterado',
          entityModule: 'Estoque',
          reason: 'Alteração de parâmetro de estoque crítico de ${anterior.quantidadeCritica} para $quantidadeCritica',
          diff: {'de': anterior.quantidadeCritica, 'para': quantidadeCritica},
        );
      }
      if (quantidadeSeguranca != null && quantidadeSeguranca != anterior.quantidadeSeguranca) {
        await auditLogRepo.log(
          entityName: 'estoque_produto',
          entityId: estoqueId,
          userId: operadorId,
          action: 'UPDATE',
          entityDisplayName: 'Estoque de segurança alterado',
          entityModule: 'Estoque',
          reason: 'Alteração de parâmetro de estoque de segurança de ${anterior.quantidadeSeguranca} para $quantidadeSeguranca',
          diff: {'de': anterior.quantidadeSeguranca, 'para': quantidadeSeguranca},
        );
      }

      // 2. Enfileira na outbox do Supabase
      await _syncEstoqueOnly(estoqueId);
    }

    await _carregar();
  }

  /// Lê os parâmetros de estoque/produção do metadataPayload do produto (ou da categoria herdada)
  /// e aplica em EstoqueProdutosTable. Chamado sempre que um produto ou categoria é salvo.
  Future<void> aplicarParametrosProduto(String produtoId) async {
    if (!_context.hasContext) return;
    final tenantId = _context.tenantId;

    // 1. Busca produto
    final produto = await (_db.select(_db.produtosTable)
          ..where((t) => t.id.equals(produtoId) & t.tenantId.equals(tenantId)))
        .getSingleOrNull();
    if (produto == null || !produto.controlaEstoque) return;

    // 2. Busca categoria do produto se houver
    CategoriaData? categoria;
    if (produto.categoriaId.isNotEmpty) {
      categoria = await (_db.select(_db.categoriasTable)
            ..where((t) => t.id.equals(produto.categoriaId) & t.tenantId.equals(tenantId)))
          .getSingleOrNull();
    }

    // Parse JSON do produto e da categoria
    Map<String, dynamic> prodJson = {};
    if (produto.metadata != null && produto.metadata!.isNotEmpty) {
      try {
        prodJson = jsonDecode(produto.metadata!);
      } catch (_) {}
    }

    Map<String, dynamic> catJson = {};
    if (categoria != null && categoria.metadataPayload != null && categoria.metadataPayload!.isNotEmpty) {
      try {
        catJson = jsonDecode(categoria.metadataPayload!);
      } catch (_) {}
    }

    final bool herdarEstoque = prodJson['herdar_estoque'] ?? prodJson['herdar_categoria'] ?? true;
    final bool herdarProducao = prodJson['herdar_producao'] ?? prodJson['herdar_categoria'] ?? true;

    // Resolver parâmetros de estoque (Produto override -> Categoria -> Default)
    final int seq = herdarEstoque
        ? (catJson['estoque_seguranca'] as num?)?.toInt() ?? 0
        : (prodJson['estoque_seguranca'] as num?)?.toInt() ?? (catJson['estoque_seguranca'] as num?)?.toInt() ?? 0;

    final int crit = herdarEstoque
        ? (catJson['estoque_critico'] as num?)?.toInt() ?? 0
        : (prodJson['estoque_critico'] as num?)?.toInt() ?? (catJson['estoque_critico'] as num?)?.toInt() ?? 0;

    final int min = herdarEstoque
        ? (catJson['estoque_minimo'] as num?)?.toInt() ?? 100
        : (prodJson['estoque_minimo'] as num?)?.toInt() ?? (catJson['estoque_minimo'] as num?)?.toInt() ?? 100;

    final int max = herdarEstoque
        ? (catJson['estoque_maximo'] as num?)?.toInt() ?? 1000
        : (prodJson['estoque_maximo'] as num?)?.toInt() ?? (catJson['estoque_maximo'] as num?)?.toInt() ?? 1000;

    // Resolver parâmetros de produção (Produto override -> Categoria -> Default)
    final int lote = herdarProducao
        ? (catJson['lote_producao'] as num?)?.toInt() ?? 100
        : (prodJson['lote_producao'] as num?)?.toInt() ?? (catJson['lote_producao'] as num?)?.toInt() ?? 100;

    final int cobertura = herdarProducao
        ? (catJson['dias_cobertura_alvo'] as num?)?.toInt() ?? 3
        : (prodJson['dias_cobertura_alvo'] as num?)?.toInt() ?? (catJson['dias_cobertura_alvo'] as num?)?.toInt() ?? 3;

    final int cap = herdarProducao
        ? (catJson['capacidade_campanha'] as num?)?.toInt() ?? 0
        : (prodJson['capacidade_campanha'] as num?)?.toInt() ?? (catJson['capacidade_campanha'] as num?)?.toInt() ?? 0;

    final int prep = herdarProducao
        ? (catJson['tempo_preparacao'] as num?)?.toInt() ?? 0
        : (prodJson['tempo_preparacao'] as num?)?.toInt() ?? (catJson['tempo_preparacao'] as num?)?.toInt() ?? 0;

    // Garante que registro de estoque existe
    final estoqueRows = await (_db.select(_db.estoqueProdutosTable)
          ..where((t) => t.tenantId.equals(tenantId) & t.produtoId.equals(produtoId) & t.deletedAt.isNull().equals(true)))
        .get();
    var estoque = estoqueRows.firstOrNull;

    final now = DateTime.now().toUtc();
    final operadorId = _context.usuario.id;

    if (estoque == null) {
      final estoqueId = const Uuid().v4();
      await _db.into(_db.estoqueProdutosTable).insertOnConflictUpdate(
        EstoqueProdutosTableCompanion.insert(
          id: estoqueId,
          tenantId: tenantId,
          produtoId: produtoId,
          quantidadeAtual: const Value(0),
          quantidadeReservada: const Value(0),
          quantidadeSeguranca: Value(seq),
          quantidadeCritica: Value(crit),
          quantidadeMinima: Value(min),
          quantidadeMaxima: Value(max),
          quantidadeProducaoLote: Value(lote),
          diasCoberturaAlvo: Value(cobertura),
          capacidadeCampanha: Value(cap),
          tempoPreparacao: Value(prep),
          unidade: const Value('un'),
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: operadorId,
          updatedBy: operadorId,
        ),
      );
      await _syncEstoqueOnly(estoqueId);
    } else {
      await configurarParametros(
        estoqueId: estoque.id,
        quantidadeSeguranca: seq,
        quantidadeCritica: crit,
        quantidadeMinima: min,
        quantidadeProducaoLote: lote,
        diasCoberturaAlvo: cobertura,
        capacidadeCampanha: cap,
        tempoPreparacao: prep,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers Internos
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _movimentarEstoque({
    required String produtoId,
    required String tipo,
    required int quantidade,
    required String motivo,
    required String operadorId,
    required String tenantId,
    required DateTime now,
    String? pedidoId,
    DateTime? dataHora,
    DateTime? dataEntregaPrevista,
    bool isEntradaFisica = false,
    bool isEntradaReserva = false,
    bool isSaidaFisica = false,
    bool isSaidaReserva = false,
  }) async {
    final uuid = const Uuid();

    // 1. Busca ou cria o registro de estoque (safe: usa firstOrNull para evitar Bad state com duplicatas)
    final _estoqueRows = await (
      _db.select(_db.estoqueProdutosTable)
        ..where((t) =>
            t.tenantId.equals(tenantId) &
            t.produtoId.equals(produtoId) &
            t.deletedAt.isNull().equals(true))
        ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)])
    ).get();
    var estoque = _estoqueRows.firstOrNull;

    final estoqueId = estoque?.id ?? uuid.v4();

    if (estoque == null) {
      await _db.into(_db.estoqueProdutosTable).insertOnConflictUpdate(
        EstoqueProdutosTableCompanion.insert(
          id: estoqueId,
          tenantId: tenantId,
          produtoId: produtoId,
          quantidadeAtual: const Value(0),
          quantidadeReservada: const Value(0),
          quantidadeMinima: const Value(0),
          quantidadeMaxima: const Value(9999),
          quantidadeProducaoLote: const Value(100),
          diasCoberturaAlvo: const Value(3),
          unidade: const Value('un'),
          syncVersion: const Value(1),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: operadorId,
          updatedBy: operadorId,
        ),
      );
      estoque = (await (
        _db.select(_db.estoqueProdutosTable)
          ..where((t) => t.id.equals(estoqueId))
      ).get()).firstOrNull;
    }

    final qAtualAntes = estoque?.quantidadeAtual ?? 0;
    final qReservadaAntes = estoque?.quantidadeReservada ?? 0;

    // 2. Calcula novos saldos
    int qAtualDepois = qAtualAntes;
    int qReservadaDepois = qReservadaAntes;

    if (isEntradaFisica) qAtualDepois += quantidade;
    if (isSaidaFisica) qAtualDepois = (qAtualDepois - quantidade).clamp(-999999, 999999);
    if (isEntradaReserva) qReservadaDepois += quantidade;
    if (isSaidaReserva) qReservadaDepois = (qReservadaDepois - quantidade).clamp(0, 999999);

    // Para expedição (baixa física + libera reserva)
    // já tratado pelos dois flags acima

    // 3. Atualiza os saldos no estoque
    final nextVersion = (estoque?.syncVersion ?? 0) + 1;
    await (
      _db.update(_db.estoqueProdutosTable)
        ..where((t) => t.id.equals(estoqueId))
    ).write(EstoqueProdutosTableCompanion(
      quantidadeAtual: Value(qAtualDepois),
      quantidadeReservada: Value(qReservadaDepois),
      updatedAt: Value(now),
      updatedBy: Value(operadorId),
      syncVersion: Value(nextVersion),
      syncStatus: const Value(SyncStatus.pending),
    ));

    // 4. Registra a movimentação no log
    final movId = uuid.v4();
    await _db.into(_db.movimentacoesEstoqueTable).insert(
      MovimentacoesEstoqueTableCompanion.insert(
        id: movId,
        tenantId: tenantId,
        produtoId: produtoId,
        pedidoId: Value(pedidoId),
        tipo: tipo,
        quantidade: quantidade,
        quantidadeAntes: qAtualAntes,
        quantidadeDepois: qAtualDepois,
        quantidadeReservadaAntes: Value(qReservadaAntes),
        quantidadeReservadaDepois: Value(qReservadaDepois),
        motivo: Value(motivo),
        operadorId: Value(operadorId),
        dataHora: dataHora ?? now,
        dataEntregaPrevista: Value(dataEntregaPrevista),
        syncVersion: const Value(1),
        syncStatus: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
        createdBy: operadorId,
        updatedBy: operadorId,
      ),
    );

    // 5. Enfileira modificações no outbox da sincronização
    await _syncEstoqueOutbox(estoqueId, movId);
  }

  /// Recontagem de inventário — redefine o saldo absoluto
  Future<void> _inventariar({
    required String produtoId,
    required int novaQuantidade,
    required String motivo,
    required String operadorId,
    required String tenantId,
    required DateTime now,
  }) async {
    final uuid = const Uuid();

    final _invRows = await (
      _db.select(_db.estoqueProdutosTable)
        ..where((t) =>
            t.tenantId.equals(tenantId) &
            t.produtoId.equals(produtoId) &
            t.deletedAt.isNull().equals(true))
        ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)])
    ).get();
    var estoque = _invRows.firstOrNull;

    final estoqueId = estoque?.id ?? uuid.v4();
    final qAntes = estoque?.quantidadeAtual ?? 0;
    final qReservada = estoque?.quantidadeReservada ?? 0;

    final nextVersion = (estoque?.syncVersion ?? 0) + 1;

    if (estoque == null) {
      await _db.into(_db.estoqueProdutosTable).insertOnConflictUpdate(
        EstoqueProdutosTableCompanion.insert(
          id: estoqueId,
          tenantId: tenantId,
          produtoId: produtoId,
          quantidadeAtual: Value(novaQuantidade),
          quantidadeReservada: const Value(0),
          quantidadeMinima: const Value(0),
          quantidadeMaxima: const Value(9999),
          quantidadeProducaoLote: const Value(100),
          diasCoberturaAlvo: const Value(3),
          unidade: const Value('un'),
          syncVersion: Value(nextVersion),
          syncStatus: SyncStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: operadorId,
          updatedBy: operadorId,
        ),
      );
    } else {
      await (
        _db.update(_db.estoqueProdutosTable)
          ..where((t) => t.id.equals(estoqueId))
      ).write(EstoqueProdutosTableCompanion(
        quantidadeAtual: Value(novaQuantidade),
        updatedAt: Value(now),
        updatedBy: Value(operadorId),
        syncVersion: Value(nextVersion),
        syncStatus: const Value(SyncStatus.pending),
      ));
    }

    // Log de inventário
    final movId = uuid.v4();
    final delta = novaQuantidade - qAntes;
    await _db.into(_db.movimentacoesEstoqueTable).insert(
      MovimentacoesEstoqueTableCompanion.insert(
        id: movId,
        tenantId: tenantId,
        produtoId: produtoId,
        tipo: 'inventario',
        quantidade: delta.abs(),
        quantidadeAntes: qAntes,
        quantidadeDepois: novaQuantidade,
        quantidadeReservadaAntes: Value(qReservada),
        quantidadeReservadaDepois: Value(qReservada),
        motivo: Value(motivo.isNotEmpty ? motivo : 'Recontagem de inventário'),
        operadorId: Value(operadorId),
        dataHora: now,
        syncVersion: const Value(1),
        syncStatus: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
        createdBy: operadorId,
        updatedBy: operadorId,
      ),
    );

    // Enfileira modificações no outbox da sincronização
    await _syncEstoqueOutbox(estoqueId, movId);
  }

  /// Carrega o histórico de movimentações de um produto específico
  Future<List<MovimentacaoEstoqueData>> carregarHistorico({
    required String produtoId,
    int limit = 30,
  }) async {
    if (!_context.hasContext) return [];
    final tenantId = _context.tenantId;
    return (
      _db.select(_db.movimentacoesEstoqueTable)
        ..where((t) =>
            t.tenantId.equals(tenantId) &
            t.produtoId.equals(produtoId) &
            t.deletedAt.isNull().equals(true))
        ..orderBy([(t) => OrderingTerm(expression: t.dataHora, mode: OrderingMode.desc)])
        ..limit(limit)
    ).get();
  }

  /// Recalcula o saldo de reservas e estorna baixas indevidas de pedidos agendados pendentes.
  Future<void> recalcularReservasEEstoques({bool isFromSync = false}) async {
    if (!_context.hasContext) return;
    final tenantId = _context.tenantId;
    final now = DateTime.now().toUtc();

    // 0. Deduplicação: se houver registros duplicados de estoque para o mesmo produto,
    //    mantém apenas o mais recentemente atualizado e marca os demais como deletados.
    final todosEstoquesDup = await (_db.select(_db.estoqueProdutosTable)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull().equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
        .get();
    final seenProdutos = <String>{};
    for (final e in todosEstoquesDup) {
      if (!seenProdutos.add(e.produtoId)) {
        // Duplicata: marca como deletado
        await (_db.update(_db.estoqueProdutosTable)..where((t) => t.id.equals(e.id)))
            .write(EstoqueProdutosTableCompanion(deletedAt: Value(now)));
      }
    }

    // 1. Carrega todos os pedidos e filtra apenas os verdadeiramente PENDENTES/EM PREPARO/PRONTO
    final todosPedidos = await (_db.select(_db.pedidosTable)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull().equals(true)))
        .get();

    final statusFinalizados = {'entregue', 'concluido', 'concluído', 'cancelado', 'finalizado', 'despachado', 'enviado'};

    final pedidosPendentes = todosPedidos
        .where((p) => !statusFinalizados.contains(p.status.toLowerCase().trim()))
        .toList();

    // 2. Soma reservas por produto para TODOS os pedidos pendentes (independente de logística)
    //    Antes: só contava 'Entrega'. Agora conta qualquer tipo, pois o produto está comprometido.
    final Map<String, int> reservasPorProduto = {};
    for (final p in pedidosPendentes) {
      final itens = await (_db.select(_db.itensPedidoTable)
            ..where((t) => t.pedidoId.equals(p.id) & t.deletedAt.isNull().equals(true)))
          .get();
      for (final item in itens) {
        reservasPorProduto[item.produtoId] =
            (reservasPorProduto[item.produtoId] ?? 0) + item.quantidade.toInt();
      }
    }

    // 3. Garante que existe um registro de estoque para cada produto referenciado,
    //    inclusive pedidos legados que foram criados antes do sistema de estoque existir.
    final operadorId = _context.usuario.id;
    for (final produtoId in reservasPorProduto.keys) {
      final rows = await (_db.select(_db.estoqueProdutosTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.produtoId.equals(produtoId) &
                t.deletedAt.isNull().equals(true))
            ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
          .get();
      if (rows.isEmpty) {
        // Cria registro zerado — a reserva será aplicada na etapa 5
        await _db.into(_db.estoqueProdutosTable).insertOnConflictUpdate(
          EstoqueProdutosTableCompanion.insert(
            id: const Uuid().v4(),
            tenantId: tenantId,
            produtoId: produtoId,
            quantidadeAtual: const Value(0),
            quantidadeReservada: const Value(0),
            quantidadeMinima: const Value(0),
            quantidadeMaxima: const Value(9999),
            quantidadeProducaoLote: const Value(100),
            diasCoberturaAlvo: const Value(3),
            unidade: const Value('un'),
            syncVersion: const Value(1),
            syncStatus: SyncStatus.pending,
            createdAt: now,
            updatedAt: now,
            createdBy: operadorId,
            updatedBy: operadorId,
          ),
        );
      }
    }

    // 4. Processa baixas físicas (expedição) para pedidos ENTREGUES que ainda não tiveram baixa
    final pedidosEntregues = todosPedidos
        .where((p) => statusFinalizados.contains(p.status.toLowerCase().trim()) &&
            p.status.toLowerCase().trim() != 'cancelado')
        .toList();

    final uuid = const Uuid();

    for (final p in pedidosEntregues) {
      final movExpedicao = await (_db.select(_db.movimentacoesEstoqueTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.pedidoId.equals(p.id) &
                t.tipo.equals('expedicao') &
                t.deletedAt.isNull().equals(true)))
          .get();

      if (movExpedicao.isEmpty) {
        final itens = await (_db.select(_db.itensPedidoTable)
              ..where((t) => t.pedidoId.equals(p.id) & t.deletedAt.isNull().equals(true)))
            .get();

        for (final item in itens) {
          final estRows = await (_db.select(_db.estoqueProdutosTable)
                ..where((t) =>
                    t.tenantId.equals(tenantId) &
                    t.produtoId.equals(item.produtoId) &
                    t.deletedAt.isNull().equals(true))
                ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
              .get();
          final est = estRows.firstOrNull;

          if (est != null) {
            final qty = item.quantidade.toInt();
            final qFisicoAntes = est.quantidadeAtual;
            final qFisicoDepois = (qFisicoAntes - qty).clamp(-999999, 999999);
            final qResAntes = est.quantidadeReservada;

            await (_db.update(_db.estoqueProdutosTable)
                  ..where((t) => t.id.equals(est.id)))
                .write(EstoqueProdutosTableCompanion(
              quantidadeAtual: Value(qFisicoDepois),
              updatedAt: Value(now),
              syncStatus: const Value(SyncStatus.pending),
            ));

            await _db.into(_db.movimentacoesEstoqueTable).insert(
              MovimentacoesEstoqueTableCompanion.insert(
                id: uuid.v4(),
                tenantId: tenantId,
                produtoId: item.produtoId,
                pedidoId: Value(p.id),
                tipo: 'expedicao',
                quantidade: qty,
                quantidadeAntes: qFisicoAntes,
                quantidadeDepois: qFisicoDepois,
                quantidadeReservadaAntes: Value(qResAntes),
                quantidadeReservadaDepois: Value((qResAntes - qty).clamp(0, 999999)),
                motivo: Value('Expedição / Pedido entregue ${p.numeroPedido != null ? "#${p.numeroPedido.toString().padLeft(4, '0')}" : "#${p.id.substring(0, 4).toUpperCase()}"}'),
                operadorId: Value(operadorId),
                dataHora: now,
                syncVersion: const Value(1),
                syncStatus: SyncStatus.pending,
                createdAt: now,
                updatedAt: now,
                createdBy: operadorId,
                updatedBy: operadorId,
              ),
            );
          }
        }
      }
    }

    // 5. Aplica o valor correto de quantidadeReservada em TODOS os registros de estoque.
    //    Isso é idempotente: sobrescreve sempre com o valor calculado dos pedidos ativos.
    final todosEstoques = await (_db.select(_db.estoqueProdutosTable)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull().equals(true)))
        .get();

    for (final est in todosEstoques) {
      final reservadoCorreto = reservasPorProduto[est.produtoId] ?? 0;

      // Estorna baixas físicas indevidas: movimentações 'saida' vinculadas a pedidos ainda pendentes
      final movsSaida = await (_db.select(_db.movimentacoesEstoqueTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.produtoId.equals(est.produtoId) &
                t.tipo.equals('saida') &
                t.deletedAt.isNull().equals(true)))
          .get();

      int estornoFisico = 0;
      for (final mov in movsSaida) {
        if (mov.pedidoId != null) {
          final isPendente = pedidosPendentes.any((p) => p.id == mov.pedidoId);
          if (isPendente) {
            estornoFisico += mov.quantidade;
            await (_db.update(_db.movimentacoesEstoqueTable)
                  ..where((t) => t.id.equals(mov.id)))
                .write(MovimentacoesEstoqueTableCompanion(
              tipo: const Value('reserva'),
              motivo: Value('Convertido: saída física → reserva (pedido ainda ativo)'),
              updatedAt: Value(now),
            ));
          }
        }
      }

      // Estorna baixas físicas (expedições) de pedidos que foram revertidos e não estão mais no status Entregue
      final movsExpInvalida = await (_db.select(_db.movimentacoesEstoqueTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.produtoId.equals(est.produtoId) &
                t.tipo.equals('expedicao') &
                t.deletedAt.isNull().equals(true)))
          .get();

      for (final mov in movsExpInvalida) {
        if (mov.pedidoId != null) {
          final isAindaEntregue = pedidosEntregues.any((p) => p.id == mov.pedidoId);
          if (!isAindaEntregue) {
            await (_db.update(_db.movimentacoesEstoqueTable)
                  ..where((t) => t.id.equals(mov.id)))
                .write(MovimentacoesEstoqueTableCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now),
              syncStatus: const Value(SyncStatus.pending),
            ));
          }
        }
      }

      // Recalcular saldo físico real do produto a partir do histórico completo de movimentações (partindo do inventário)
      final movsProd = await (_db.select(_db.movimentacoesEstoqueTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.produtoId.equals(est.produtoId) &
                t.deletedAt.isNull().equals(true))
            ..orderBy([(t) => OrderingTerm(expression: t.dataHora, mode: OrderingMode.asc)]))
          .get();

      int novoFisico = est.quantidadeAtual;
      if (movsProd.isNotEmpty) {
        int runningFisico = 0;
        for (final m in movsProd) {
          final tipo = m.tipo ?? '';
          final isInventario = tipo.contains('inventario');
          final isReserva = tipo.contains('reserva');
          final isEntrada = !isReserva && !isInventario && (tipo.contains('entrada') || tipo.contains('positivo') || tipo.contains('producao'));
          final isSaida = !isReserva && !isInventario && (tipo.contains('saida') || tipo.contains('expedicao') || tipo.contains('negativo'));

          if (isInventario) {
            runningFisico = m.quantidadeDepois > 0 ? m.quantidadeDepois : m.quantidade;
          } else if (isEntrada) {
            runningFisico += m.quantidade;
          } else if (isSaida) {
            runningFisico -= m.quantidade;
          }
        }
        novoFisico = runningFisico + estornoFisico;
      } else {
        novoFisico = (est.quantidadeAtual + estornoFisico).clamp(0, 999999);
      }

      final reservadoMudou = est.quantidadeReservada != reservadoCorreto;
      final fisicoMudou = est.quantidadeAtual != novoFisico;

      if (reservadoMudou || fisicoMudou) {
        final nextVersion = est.syncVersion + (isFromSync ? 0 : 1);
        await (_db.update(_db.estoqueProdutosTable)
              ..where((t) => t.id.equals(est.id)))
            .write(EstoqueProdutosTableCompanion(
          quantidadeAtual: fisicoMudou ? Value(novoFisico) : Value(est.quantidadeAtual),
          quantidadeReservada: Value(reservadoCorreto),
          updatedAt: Value(now),
          syncVersion: Value(nextVersion),
          syncStatus: Value(isFromSync ? SyncStatus.synced : SyncStatus.pending),
        ));

        // Sincroniza o estoque recalculado no Outbox APENAS se a ação foi originada localmente e alterou o saldo físico
        if (!isFromSync && fisicoMudou) {
          await _syncEstoqueOnly(est.id);
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers de Sincronização do Outbox
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _syncEstoqueOnly(String estoqueId) async {
    final tenantId = _context.tenantId;

    final est = await (_db.select(_db.estoqueProdutosTable)
          ..where((t) => t.id.equals(estoqueId)))
        .getSingleOrNull();

    if (est != null) {
      try {
        final outboxService = DependencyInjection().get<OutboxService>();
        await outboxService.enqueue(
          entity: 'estoque_produto',
          entityId: estoqueId,
          action: 'UPSERT',
          payload: {
            'id': estoqueId,
            'tenantId': tenantId,
            'produtoId': est.produtoId,
            'quantidadeAtual': est.quantidadeAtual,
            'quantidadeReservada': est.quantidadeReservada,
            'quantidadeSeguranca': est.quantidadeSeguranca,
            'quantidadeMinima': est.quantidadeMinima,
            'quantidadeCritica': est.quantidadeCritica,
            'quantidadeMaxima': est.quantidadeMaxima,
            'quantidadeProducaoLote': est.quantidadeProducaoLote,
            'diasCoberturaAlvo': est.diasCoberturaAlvo,
            'capacidadeCampanha': est.capacidadeCampanha,
            'estrategiaProducao': est.estrategiaProducao,
            'tempoPreparacao': est.tempoPreparacao,
            'unidade': est.unidade,
            'syncVersion': est.syncVersion,
            'createdAt': est.createdAt.toIso8601String(),
            'updatedAt': est.updatedAt.toIso8601String(),
            'createdBy': est.createdBy,
            'updatedBy': est.updatedBy,
          },
          version: est.syncVersion,
        );

        final syncEngine = DependencyInjection().get<SyncEngine>();
        syncEngine.processPendingQueue();
      } catch (_) {}
    }
  }

  Future<void> _syncEstoqueOutbox(String estoqueId, String movId) async {
    final tenantId = _context.tenantId;

    // 1. Sincroniza estoque
    await _syncEstoqueOnly(estoqueId);

    // 2. Sincroniza movimentação
    final mov = await (_db.select(_db.movimentacoesEstoqueTable)
          ..where((t) => t.id.equals(movId)))
        .getSingleOrNull();

    if (mov != null) {
      try {
        final outboxService = DependencyInjection().get<OutboxService>();
        await outboxService.enqueue(
          entity: 'movimentacao_estoque',
          entityId: movId,
          action: 'INSERT',
          payload: {
            'id': movId,
            'tenantId': tenantId,
            'produtoId': mov.produtoId,
            'pedidoId': mov.pedidoId,
            'tipo': mov.tipo,
            'quantidade': mov.quantidade,
            'quantidadeAntes': mov.quantidadeAntes,
            'quantidadeDepois': mov.quantidadeDepois,
            'quantidadeReservadaAntes': mov.quantidadeReservadaAntes,
            'quantidadeReservadaDepois': mov.quantidadeReservadaDepois,
            'motivo': mov.motivo,
            'operadorId': mov.operadorId,
            'dataHora': mov.dataHora.toIso8601String(),
            'dataEntregaPrevista': mov.dataEntregaPrevista?.toIso8601String(),
            'syncVersion': mov.syncVersion,
            'createdAt': mov.createdAt.toIso8601String(),
            'updatedAt': mov.updatedAt.toIso8601String(),
            'createdBy': mov.createdBy,
            'updatedBy': mov.updatedBy,
          },
          version: mov.syncVersion,
        );

        final syncEngine = DependencyInjection().get<SyncEngine>();
        syncEngine.processPendingQueue();
      } catch (_) {}
    }
  }
}
