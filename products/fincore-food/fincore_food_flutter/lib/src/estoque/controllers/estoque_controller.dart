import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:uuid/uuid.dart';

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

  const EstoqueItem({
    required this.estoque,
    required this.nomeProduto,
    this.corEtiqueta,
    required this.status,
  });

  /// Estoque físico real no freezer
  int get quantidadeAtual => estoque.quantidadeAtual;

  /// Comprometido com pedidos futuros (não saiu fisicamente)
  int get quantidadeReservada => estoque.quantidadeReservada;

  /// Disponível para venda = Físico - Reservado
  int get quantidadeDisponivel =>
      (estoque.quantidadeAtual - estoque.quantidadeReservada).clamp(0, 999999);

  int get quantidadeMinima => estoque.quantidadeMinima;
  int get quantidadeMaxima => estoque.quantidadeMaxima;
  int get quantidadeProducaoLote => estoque.quantidadeProducaoLote;
  int get diasCoberturaAlvo => estoque.diasCoberturaAlvo;
  String get unidade => estoque.unidade;

  /// Quantidade sugerida a produzir para atingir o estoque alvo
  int get sugestaoProducao {
    final deficit = quantidadeMinima - quantidadeDisponivel;
    if (deficit <= 0) return 0;
    // Arredonda para cima para o próximo lote completo
    final lote = quantidadeProducaoLote > 0 ? quantidadeProducaoLote : 100;
    return ((deficit / lote).ceil() * lote);
  }
}

/// Status de disponibilidade do estoque
enum EstoqueStatus {
  /// Disponível > Mínimo → verde
  normal,
  /// Disponível entre 1 e mínimo → laranja (produzir em breve)
  baixo,
  /// Disponível = 0 ou negativo → vermelho (produzir URGENTE)
  critico,
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

  EstoqueController()
      : _db = DependencyInjection().get<FincoreDatabase>(),
        _context = DependencyInjection().get<TenantContext>() {
    _carregar();
  }

  List<EstoqueItem> get itens => _itens;
  List<ReservaAgendada> get reservasAgendadas => _reservasAgendadas;

  List<EstoqueItem> get itensCriticos =>
      _itens.where((i) => i.status == EstoqueStatus.critico).toList();

  List<EstoqueItem> get itensBaixos =>
      _itens.where((i) => i.status == EstoqueStatus.baixo).toList();

  bool get loading => _loading;
  String? get error => _error;
  bool get temAlertas => itensCriticos.isNotEmpty || itensBaixos.isNotEmpty;

  /// Número de produtos que precisam produção urgente (para badge no shell)
  int get qtdAlertasUrgentes => itensCriticos.length + itensBaixos.length;

  Future<void> _carregar() async {
    if (!_context.hasContext) return;
    _loading = true;
    notifyListeners();

    try {
      final tenantId = _context.tenantId;

      // 0. Auto-healing: Recalcula reservas de pedidos agendados e converte baixas indevidas
      await recalcularReservasEEstoques();

      // 1. Todos os registros de estoque ativos
      final estoques = await (
        _db.select(_db.estoqueProdutosTable)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull().equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)])
      ).get();

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
        if (e != null) {
          final disponivel = e.quantidadeAtual - e.quantidadeReservada;
          itens.add(EstoqueItem(
            estoque: e,
            nomeProduto: produto.nome,
            corEtiqueta: produto.corEtiqueta,
            status: _calcularStatus(disponivel, e.quantidadeMinima),
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
          ));
        }
      }

      // Ordena: críticos primeiro, depois baixos, depois normais
      itens.sort((a, b) => a.status.index.compareTo(b.status.index));
      _itens = itens;

      // 4. Carrega agenda de reservas futuras
      final agora = DateTime.now().toUtc();
      final reservas = await (
        _db.select(_db.movimentacoesEstoqueTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.tipo.equals('reserva') &
              t.deletedAt.isNull() &
              t.dataEntregaPrevista.isBiggerThanValue(agora))
          ..orderBy([(t) => OrderingTerm(expression: t.dataEntregaPrevista)])
      ).get();

      _reservasAgendadas = reservas
          .where((r) => r.dataEntregaPrevista != null)
          .map((r) => ReservaAgendada(
                movimentacao: r,
                nomeProduto: produtosMap[r.produtoId]?.nome ?? 'Produto desconhecido',
                dataEntrega: r.dataEntregaPrevista!,
                quantidade: r.quantidade,
              ))
          .toList();

      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar estoque: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _carregar();

  EstoqueStatus _calcularStatus(int disponivel, int minimo) {
    if (disponivel <= 0) return EstoqueStatus.critico;
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
      ['ajuste_positivo', 'ajuste_negativo', 'inventario'].contains(tipo),
      'Tipo inválido: use ajuste_positivo, ajuste_negativo ou inventario',
    );

    final tenantId = _context.tenantId;
    final operadorId = _context.usuario.id;
    final now = DateTime.now().toUtc();

    final isEntrada = tipo == 'ajuste_positivo';
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
  }) async {
    final now = DateTime.now().toUtc();
    final operadorId = _context.usuario.id;

    await (
      _db.update(_db.estoqueProdutosTable)
        ..where((t) => t.id.equals(estoqueId))
    ).write(EstoqueProdutosTableCompanion(
      quantidadeMinima: quantidadeMinima != null ? Value(quantidadeMinima) : const Value.absent(),
      quantidadeProducaoLote: quantidadeProducaoLote != null ? Value(quantidadeProducaoLote) : const Value.absent(),
      diasCoberturaAlvo: diasCoberturaAlvo != null ? Value(diasCoberturaAlvo) : const Value.absent(),
      updatedAt: Value(now),
      updatedBy: Value(operadorId),
      syncStatus: const Value(SyncStatus.pending),
    ));

    await _carregar();
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

    // 1. Busca ou cria o registro de estoque
    var estoque = await (
      _db.select(_db.estoqueProdutosTable)
        ..where((t) =>
            t.tenantId.equals(tenantId) &
            t.produtoId.equals(produtoId) &
            t.deletedAt.isNull().equals(true))
    ).getSingleOrNull();

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
      estoque = await (
        _db.select(_db.estoqueProdutosTable)
          ..where((t) => t.id.equals(estoqueId))
      ).getSingleOrNull();
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
    await (
      _db.update(_db.estoqueProdutosTable)
        ..where((t) => t.id.equals(estoqueId))
    ).write(EstoqueProdutosTableCompanion(
      quantidadeAtual: Value(qAtualDepois),
      quantidadeReservada: Value(qReservadaDepois),
      updatedAt: Value(now),
      updatedBy: Value(operadorId),
      syncVersion: const Value(1),
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

    var estoque = await (
      _db.select(_db.estoqueProdutosTable)
        ..where((t) =>
            t.tenantId.equals(tenantId) &
            t.produtoId.equals(produtoId) &
            t.deletedAt.isNull().equals(true))
    ).getSingleOrNull();

    final estoqueId = estoque?.id ?? uuid.v4();
    final qAntes = estoque?.quantidadeAtual ?? 0;
    final qReservada = estoque?.quantidadeReservada ?? 0;

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
          syncVersion: const Value(1),
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
  Future<void> recalcularReservasEEstoques() async {
    if (!_context.hasContext) return;
    final tenantId = _context.tenantId;
    final now = DateTime.now().toUtc();

    // 1. Carrega todos os pedidos e filtra apenas os verdadeiramente PENDENTES/EM PREPARO
    final todosPedidos = await (_db.select(_db.pedidosTable)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull().equals(true)))
        .get();

    final pedidosPendentes = todosPedidos.where((p) {
      final st = p.status.toLowerCase().trim();
      final isFinalizado = st == 'entregue' ||
          st == 'concluido' ||
          st == 'concluído' ||
          st == 'cancelado' ||
          st == 'finalizado' ||
          st == 'despachado' ||
          st == 'enviado';
      return !isFinalizado;
    }).toList();

    final Map<String, int> reservasPorProduto = {};

    for (final p in pedidosPendentes) {
      if (p.tipoLogistica == 'Entrega') {
        final itens = await (_db.select(_db.itensPedidoTable)
              ..where((t) => t.pedidoId.equals(p.id) & t.deletedAt.isNull().equals(true)))
            .get();
        for (final item in itens) {
          reservasPorProduto[item.produtoId] =
              (reservasPorProduto[item.produtoId] ?? 0) + item.quantidade.toInt();
        }
      }
    }

    // 3. Processa baixas físicas (expedição) para pedidos ENTREGUES de Entrega que ainda não tiveram baixa física
    final pedidosEntregues = todosPedidos.where((p) {
      final st = p.status.toLowerCase().trim();
      return (st == 'entregue' || st == 'concluido' || st == 'concluído' || st == 'despachado') &&
          p.tipoLogistica == 'Entrega';
    }).toList();

    final uuid = const Uuid();

    for (final p in pedidosEntregues) {
      final movExpedicao = await (_db.select(_db.movimentacoesEstoqueTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.pedidoId.equals(p.id) &
                t.tipo.equals('expedicao') &
                t.deletedAt.isNull().equals(true)))
          .getSingleOrNull();

      if (movExpedicao == null) {
        final itens = await (_db.select(_db.itensPedidoTable)
              ..where((t) => t.pedidoId.equals(p.id) & t.deletedAt.isNull().equals(true)))
            .get();

        for (final item in itens) {
          final est = await (_db.select(_db.estoqueProdutosTable)
                ..where((t) =>
                    t.tenantId.equals(tenantId) &
                    t.produtoId.equals(item.produtoId) &
                    t.deletedAt.isNull().equals(true)))
              .getSingleOrNull();

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
                motivo: Value('Expedição / Pedido entregue #${p.id.substring(0, 4)}'),
                operadorId: Value(_context.usuario.id),
                dataHora: now,
                syncVersion: const Value(1),
                syncStatus: SyncStatus.pending,
                createdAt: now,
                updatedAt: now,
                createdBy: _context.usuario.id,
                updatedBy: _context.usuario.id,
              ),
            );
          }
        }
      }
    }

    // 4. Para cada registro de estoque, ajusta a quantidadeReservada
    final todosEstoques = await (_db.select(_db.estoqueProdutosTable)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull().equals(true)))
        .get();

    for (final est in todosEstoques) {
      final reservadoAtualizado = reservasPorProduto[est.produtoId] ?? 0;

      // Se havia uma baixa física indevida (tipo 'saida' para um pedido pendente de Entrega), estorna a baixa física
      final movsSaidaPendentes = await (_db.select(_db.movimentacoesEstoqueTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.produtoId.equals(est.produtoId) &
                t.tipo.equals('saida') &
                t.deletedAt.isNull().equals(true)))
          .get();

      int estornoFisico = 0;
      for (final mov in movsSaidaPendentes) {
        if (mov.pedidoId != null) {
          final p = pedidosPendentes.cast<PedidoData?>().firstWhere((p) => p?.id == mov.pedidoId, orElse: () => null);
          if (p != null && p.tipoLogistica == 'Entrega') {
            estornoFisico += mov.quantidade;
            // Converte a movimentação no histórico para 'reserva'
            await (_db.update(_db.movimentacoesEstoqueTable)
                  ..where((t) => t.id.equals(mov.id)))
                .write(MovimentacoesEstoqueTableCompanion(
              tipo: const Value('reserva'),
              motivo: Value('Convertido de saída física para reserva (Pedido agendado #${p.id.substring(0, 4)})'),
              updatedAt: Value(now),
            ));
          }
        }
      }

      final novoFisico = est.quantidadeAtual + estornoFisico;

      await (_db.update(_db.estoqueProdutosTable)
            ..where((t) => t.id.equals(est.id)))
          .write(EstoqueProdutosTableCompanion(
        quantidadeAtual: Value(novoFisico),
        quantidadeReservada: Value(reservadoAtualizado),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ));
    }
  }
}
