import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/repository/produto_repository.dart';
import 'package:fincore_core/repository/categoria_repository.dart';
import 'package:fincore_core/repository/cliente_repository.dart';
import 'package:fincore_core/repository/local_entrega_repository.dart';
import 'package:fincore_core/repository/forma_pagamento_repository.dart';
import 'package:fincore_core/repository/taxa_entrega_repository.dart';
import '../domain/pricing_engine.dart';
import '../../cap/printing/print_capability.dart';

import 'package:fincore_pricing/repository/tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/item_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/produto_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/common/pricing_models.dart';

import '../models/pdv_item.dart';
import '../models/pedido_draft.dart';

enum PdvState {
  idle,
  drafting,
  selectingCustomer,
  selectingPayment,
  awaitingPix,
  confirming,
  completed,
  error
}

class DadosCliente {
  final String? id;
  final String? nome;
  final String? telefone;
  final String? apelidoEndereco;

  const DadosCliente({
    this.id,
    this.nome,
    this.telefone,
    this.apelidoEndereco,
  });

  DadosCliente copyWith({
    String? id,
    String? nome,
    String? telefone,
    String? apelidoEndereco,
  }) {
    return DadosCliente(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      apelidoEndereco: apelidoEndereco ?? this.apelidoEndereco,
    );
  }

  bool get isEmpty => (nome == null || nome!.isEmpty) && (telefone == null || telefone!.isEmpty);
}

class DadosEntrega {
  final String tipo; // 'Entrega' ou 'Retirada'
  final String logradouro;
  final String numero;
  final String bairro;
  final String referencia;
  final String cidade;
  final String cep;
  final int taxaEntregaCentavos;
  final int? trocoParaCentavos;
  final String prioridade; // 'Normal', 'Entrega Programada', 'Urgente', 'VIP'
  final String observacoes;
  final DateTime dataHora;

  DadosEntrega({
    this.tipo = 'Entrega',
    this.logradouro = '',
    this.numero = '',
    this.bairro = '',
    this.referencia = '',
    this.cidade = 'Pouso Alegre - MG',
    this.cep = '',
    this.taxaEntregaCentavos = 0,
    this.trocoParaCentavos,
    this.prioridade = 'Normal',
    this.observacoes = '',
    DateTime? dataHora,
  }) : dataHora = dataHora ?? DateTime.now().add(const Duration(hours: 2));

  DadosEntrega copyWith({
    String? tipo,
    String? logradouro,
    String? numero,
    String? bairro,
    String? referencia,
    String? cidade,
    String? cep,
    int? taxaEntregaCentavos,
    int? Function()? trocoParaCentavos,
    String? prioridade,
    String? observacoes,
    DateTime? dataHora,
  }) {
    return DadosEntrega(
      tipo: tipo ?? this.tipo,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      bairro: bairro ?? this.bairro,
      referencia: referencia ?? this.referencia,
      cidade: cidade ?? this.cidade,
      cep: cep ?? this.cep,
      taxaEntregaCentavos: taxaEntregaCentavos ?? this.taxaEntregaCentavos,
      trocoParaCentavos: trocoParaCentavos != null ? trocoParaCentavos() : this.trocoParaCentavos,
      prioridade: prioridade ?? this.prioridade,
      observacoes: observacoes ?? this.observacoes,
      dataHora: dataHora ?? this.dataHora,
    );
  }
}

class PdvExpressController extends ChangeNotifier {
  // Repositórios do Core
  final ProdutoRepository produtoRepo;
  final CategoriaRepository categoriaRepo;
  final ClienteRepository clienteRepo;
  final LocalEntregaRepository localRepo;
  final FormaPagamentoRepository pagamentoRepo;
  final TaxaEntregaRepository taxaRepo;

  // Repositórios e Engine do Pricing
  final TabelaPrecificacaoRepository tabelaRepo;
  final ItemTabelaPrecificacaoRepository itemRepo;
  final ProdutoTabelaPrecificacaoRepository assocRepo;
  final PricingEngine pricingEngine;
  final PrintUseCase printUseCase;

  // Contexto de Sessão
  final TenantContext tenantContext;
  final FincoreDatabase db;

  // Catálogo Real
  List<Produto> _products = [];
  List<Produto> get products => _products;

  List<Categoria> _categories = [];
  List<Categoria> get categories => _categories;

  List<Cliente> _clientes = [];
  List<Cliente> get clientes => _clientes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Estados do Wizard
  int _passoAtual = 0;
  int get passoAtual => _passoAtual;

  DadosCliente _cliente = const DadosCliente();
  DadosCliente get cliente => _cliente;

  DadosEntrega _entrega = DadosEntrega();
  DadosEntrega get entrega => _entrega;

  PdvState _state = PdvState.idle;
  PdvState get state => _state;

  final List<PdvItem> _cart = [];
  List<PdvItem> get cart => List.unmodifiable(_cart);

  String _paymentMethod = 'Dinheiro';
  String get paymentMethod => _paymentMethod;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Timer? _pixTimer;
  int _pixCountdown = 120;
  int get pixCountdown => _pixCountdown;

  PricingResult _pricingResult = const PricingResult(unitPrices: {}, groupSummaries: []);
  PricingResult get pricingResult => _pricingResult;

  // Estado da última venda finalizada (para Undo e para abrir comprovante)
  PedidoDraft? _lastVenda;
  PedidoDraft? get lastVenda => _lastVenda;
  Timer? _resetTimer;


  PdvExpressController()
      : produtoRepo = DependencyInjection().get<ProdutoRepository>(),
        categoriaRepo = DependencyInjection().get<CategoriaRepository>(),
        clienteRepo = DependencyInjection().get<ClienteRepository>(),
        localRepo = DependencyInjection().get<LocalEntregaRepository>(),
        pagamentoRepo = DependencyInjection().get<FormaPagamentoRepository>(),
        taxaRepo = DependencyInjection().get<TaxaEntregaRepository>(),
        tabelaRepo = DependencyInjection().get<TabelaPrecificacaoRepository>(),
        itemRepo = DependencyInjection().get<ItemTabelaPrecificacaoRepository>(),
        assocRepo = DependencyInjection().get<ProdutoTabelaPrecificacaoRepository>(),
        pricingEngine = PricingEngine(
          assocRepo: DependencyInjection().get<ProdutoTabelaPrecificacaoRepository>(),
          itemRepo: DependencyInjection().get<ItemTabelaPrecificacaoRepository>(),
          tabelaRepo: DependencyInjection().get<TabelaPrecificacaoRepository>(),
        ),
        printUseCase = DependencyInjection().get<PrintUseCase>(),
        tenantContext = DependencyInjection().get<TenantContext>(),
        db = DependencyInjection().get<FincoreDatabase>() {
    loadCatalog();
  }

  /// Construtor de Testes/Injeção manual
  PdvExpressController.custom({
    required this.produtoRepo,
    required this.categoriaRepo,
    required this.clienteRepo,
    required this.localRepo,
    required this.pagamentoRepo,
    required this.taxaRepo,
    required this.tabelaRepo,
    required this.itemRepo,
    required this.assocRepo,
    required this.pricingEngine,
    required this.printUseCase,
    required this.tenantContext,
    required this.db,
  }) {
    loadCatalog();
  }

  Future<void> loadCatalog() async {
    _isLoading = true;
    notifyListeners();
    try {
      _products = await produtoRepo.findAll();
      _categories = await categoriaRepo.findAll();
      _clientes = await clienteRepo.findAll();
    } catch (e) {
      _errorMessage = 'Falha ao carregar catálogo: $e';
      _state = PdvState.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void changeState(PdvState newState) {
    _state = newState;
    notifyListeners();
  }

  int get totalInCents {
    final subtotal = _cart.fold(0, (sum, item) => sum + item.totalInCents);
    final frete = _entrega.tipo == 'Entrega' ? _entrega.taxaEntregaCentavos : 0;
    return subtotal + frete;
  }

  void setPassoAtual(int step) {
    _passoAtual = step;
    notifyListeners();
  }

  void updateCliente(DadosCliente novoCliente) {
    _cliente = novoCliente;
    notifyListeners();
  }

  void updateEntrega(DadosEntrega novaEntrega) {
    _entrega = novaEntrega;
    notifyListeners();
  }

  Future<void> addItem(String id, String name, int priceInCents, double quantity) async {
    final index = _cart.indexWhere((item) => item.productId == id);
    if (index != -1) {
      _cart[index].quantity += quantity;
    } else {
      _cart.add(PdvItem(
        productId: id,
        name: name,
        priceInCents: priceInCents,
        quantity: quantity,
      ));
    }
    await _recalculatePrices();
    _state = PdvState.drafting;
    notifyListeners();
  }

  Future<void> updateQuantity(String id, double newQty) async {
    final index = _cart.indexWhere((item) => item.productId == id);
    if (index != -1) {
      if (newQty <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].quantity = newQty;
      }
    }
    await _recalculatePrices();
    if (_cart.isEmpty) {
      _state = PdvState.idle;
    } else {
      _state = PdvState.drafting;
    }
    notifyListeners();
  }

  /// Seleciona (ou atualiza) o cliente do pedido.
  /// Para pedidos de Retirada, o cliente é obrigatório e nunca é limpo automaticamente.
  void selectCustomer(String name, String phone, {String? clienteId}) {
    _cliente = _cliente.copyWith(nome: name, telefone: phone, id: clienteId);
    _state = _cart.isEmpty ? PdvState.idle : PdvState.drafting;
    notifyListeners();
  }

  /// Remove os dados do cliente.
  void clearCustomer() {
    _cliente = const DadosCliente();
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  Future<void> _recalculatePrices() async {
    final unitPrices = <String, int>{};
    final groupSummaries = <GroupPricingSummary>[];

    // ── PASSO 1: Mapear cada produto para sua tabela de precificação ──────
    // Estrutura: tabelaId → lista de (item do carrinho)
    final Map<String, List<PdvItem>> itensPorTabela = {};
    // Mapa: productId → tabelaId (para lookup rápido depois)
    final Map<String, String> produtoParaTabela = {};

    for (final item in _cart) {
      try {
        final assocs = await assocRepo.findByProdutoId(item.productId);
        final activeAssoc = assocs.firstWhere(
          (a) => a.ativo,
          orElse: () => throw Exception('sem tabela'),
        );
        final tabelaId = activeAssoc.tabelaPrecificacaoId;
        itensPorTabela.putIfAbsent(tabelaId, () => []).add(item);
        produtoParaTabela[item.productId] = tabelaId;
      } catch (_) {
        // Produto sem tabela: mantém preço original
        unitPrices[item.productId] = item.priceInCents;
      }
    }

    // ── PASSO 2: Para cada tabela, calcular o preço baseado no TOTAL DO GRUPO ──
    for (final entry in itensPorTabela.entries) {
      final tabelaId = entry.key;
      final itensDoGrupo = entry.value;

      try {
        final tabela = await tabelaRepo.findById(tabelaId);
        if (tabela == null || !tabela.ativo) {
          // Tabela inativa: usa preço original de cada item
          for (final item in itensDoGrupo) {
            unitPrices[item.productId] = item.priceInCents;
          }
          continue;
        }

        // Soma TOTAL de unidades de todos os produtos deste grupo
        final totalQtyDoGrupo = itensDoGrupo.fold<double>(
          0, (sum, i) => sum + i.quantity,
        );

        // Busca as faixas da tabela
        final faixas = await itemRepo.findByTabelaId(tabelaId);
        faixas.sort((a, b) => a.quantidadeMinima.compareTo(b.quantidadeMinima));

        // Encontra a faixa aplicável ao TOTAL do grupo
        ItemTabelaPrecificacao? faixaAplicada;
        ItemTabelaPrecificacao? proximaFaixa;

        for (int i = 0; i < faixas.length; i++) {
          final f = faixas[i];
          if (totalQtyDoGrupo >= f.quantidadeMinima &&
              (f.quantidadeMaxima == null || totalQtyDoGrupo <= f.quantidadeMaxima!)) {
            faixaAplicada = f;
            if (i + 1 < faixas.length) proximaFaixa = faixas[i + 1];
            break;
          }
        }

        // Fallback: sem faixa aplicada, usa a mínima (abaixo do mínimo)
        // Isso indica que a quantidade ainda não atingiu o mínimo de venda
        if (faixaAplicada == null) {
          if (faixas.isNotEmpty) {
            proximaFaixa = faixas.first;
          }
        }

        final precoPorUnidade = faixaAplicada?.valorUnitarioCentavos ?? 0;

        // Aplica o mesmo preço unitário a TODOS os produtos do grupo
        for (final item in itensDoGrupo) {
          item.priceInCents = precoPorUnidade;
          unitPrices[item.productId] = precoPorUnidade;
        }

        // Monta o GroupPricingSummary para alerta de upsell
        if (proximaFaixa != null) {
          final qtyNeeded = (proximaFaixa.quantidadeMinima - totalQtyDoGrupo).clamp(0, double.infinity).toDouble();
          final priceDifference = precoPorUnidade - proximaFaixa.valorUnitarioCentavos;

          final potentialSavings = (priceDifference * totalQtyDoGrupo).round();

          groupSummaries.add(GroupPricingSummary(
            group: PricingGroup(id: tabelaId, name: tabela.nome),
            totalQty: totalQtyDoGrupo,
            appliedUnitPriceInCents: precoPorUnidade,
            appliedRange: faixaAplicada != null
                ? PricingRange(
                    id: faixaAplicada.id,
                    groupId: tabelaId,
                    minQty: faixaAplicada.quantidadeMinima,
                    maxQty: faixaAplicada.quantidadeMaxima,
                    unitPriceInCents: faixaAplicada.valorUnitarioCentavos,
                  )
                : null,
            nextRange: PricingRange(
              id: proximaFaixa.id,
              groupId: tabelaId,
              minQty: proximaFaixa.quantidadeMinima,
              maxQty: proximaFaixa.quantidadeMaxima,
              unitPriceInCents: proximaFaixa.valorUnitarioCentavos,
            ),
            qtyNeededForNextRange: qtyNeeded,
            potentialSavingsInCents: potentialSavings,
          ));
        }
      } catch (e) {
        debugPrint('[PricingEngine] Erro ao calcular grupo $tabelaId: $e');
        for (final item in itensDoGrupo) {
          unitPrices[item.productId] = item.priceInCents;
        }
      }
    }

    _pricingResult = PricingResult(unitPrices: unitPrices, groupSummaries: groupSummaries);
    notifyListeners();
  }



  bool podeAvancar() {
    if (_passoAtual == 0) {
      if (_entrega.tipo == 'Entrega') {
        if (_cliente.isEmpty) return false;
        return _entrega.logradouro.isNotEmpty &&
            _entrega.numero.isNotEmpty &&
            _entrega.bairro.isNotEmpty;
      }
      return true; // Retirada: cliente é opcional
    }
    if (_passoAtual == 1) {
      return _cart.isNotEmpty;
    }
    return true;
  }

  void reset() {
    _cart.clear();
    _cliente = const DadosCliente();
    _entrega = DadosEntrega();
    _paymentMethod = 'Dinheiro';
    _errorMessage = null;
    _pixTimer?.cancel();
    _pixCountdown = 120;
    _passoAtual = 0;
    _state = PdvState.idle;
    _pricingResult = const PricingResult(unitPrices: {}, groupSummaries: []);
    _lastVenda = null;
    _resetTimer?.cancel();
    notifyListeners();
  }

  void startCheckout() {
    if (_cart.isEmpty) {
      _errorMessage = 'O carrinho está vazio.';
      _state = PdvState.error;
      notifyListeners();
      return;
    }
    _state = PdvState.selectingPayment;
    notifyListeners();
  }

  Future<void> confirmPayment() async {
    if (_paymentMethod == 'PIX') {
      _state = PdvState.awaitingPix;
      _pixCountdown = 120;
      notifyListeners();

      _pixTimer?.cancel();
      _pixTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (_pixCountdown > 115) {
          _pixCountdown--;
          notifyListeners();
        } else {
          timer.cancel();
          await _persistVenda();
        }
      });
    } else {
      await _persistVenda();
    }
  }

  /// Grava a venda transitória na OutboxSync e simula spooler térmico
  Future<void> _persistVenda() async {
    _state = PdvState.confirming;
    notifyListeners();

    try {
      final activeTenant = tenantContext.tenantId;
      final activeUser = tenantContext.usuario.id;

      final draftItens = _cart.map((item) {
        return ItemPedidoDraft(
          produtoId: item.productId,
          nome: item.name,
          quantidade: item.quantity,
          valorUnitarioCentavos: item.priceInCents,
          valorTotalCentavos: item.totalInCents,
        );
      }).toList();

      final subtotal = _cart.fold(0, (sum, i) => sum + i.totalInCents);
      final frete = _entrega.tipo == 'Entrega' ? _entrega.taxaEntregaCentavos : 0;

      final pedido = PedidoDraft(
        tenantId: activeTenant,
        clienteId: _cliente.id,
        tipoLogistica: _entrega.tipo,
        valorSubtotalCentavos: subtotal,
        valorTaxaEntregaCentavos: frete,
        valorTotalCentavos: subtotal + frete,
        formaPagamentoId: _paymentMethod,
        trocoParaCentavos: _entrega.trocoParaCentavos,
        itens: draftItens,
        operadorId: activeUser,
      );

      // Serializar e gravar na Outbox do Drift (SQLite Local)
      final payload = {
        'id': pedido.id,
        'tenantId': pedido.tenantId,
        'clienteId': pedido.clienteId,
        'tipoLogistica': pedido.tipoLogistica,
        'valorSubtotalCentavos': pedido.valorSubtotalCentavos,
        'valorTaxaEntregaCentavos': pedido.valorTaxaEntregaCentavos,
        'valorTotalCentavos': pedido.valorTotalCentavos,
        'formaPagamentoId': pedido.formaPagamentoId,
        'trocoParaCentavos': pedido.trocoParaCentavos,
        'itens': draftItens.map((i) => {
          'id': i.id,
          'produtoId': i.produtoId,
          'nome': i.nome,
          'quantidade': i.quantidade,
          'valorUnitarioCentavos': i.valorUnitarioCentavos,
          'valorTotalCentavos': i.valorTotalCentavos,
        }).toList(),
        'operadorId': pedido.operadorId,
        'createdAt': pedido.dataHoraCriacao.toIso8601String(),
      };

      await db.into(db.outboxSync).insert(OutboxSyncCompanion.insert(
        tenantId: activeTenant,
        entity: 'Pedido',
        entityId: pedido.id,
        action: 'create',
        payload: jsonEncode(payload),
        status: 'pending',
        version: 1,
        createdAt: DateTime.now(),
      ));

      // Simulação Spooler Térmico no Log
      debugPrint('====================================');
      debugPrint('SPOOLER TÉRMICO USB - CUPOM DE VENDA');
      debugPrint('PEDIDO ID: ${pedido.id}');
      debugPrint('CLIENTE: ${_cliente.nome ?? "Consumidor"}');
      debugPrint('TOTAL: R\$ ${(pedido.valorTotalCentavos / 100).toStringAsFixed(2)}');
      debugPrint('====================================');

      _lastVenda = pedido;
      _state = PdvState.completed;
      notifyListeners();

      // CAP.PRINTING: Impressão automática (sem diálogo)
      try {
        final printData = PrintData(
          pedidoId: pedido.id,
          clienteNome: _cliente.nome,
          clienteTelefone: _cliente.telefone,
          tipoLogistica: pedido.tipoLogistica,
          endereco: _entrega.tipo == 'Entrega'
              ? '${_entrega.logradouro}, ${_entrega.numero}'
              : null,
          bairro: _entrega.bairro,
          formaPagamento: _paymentMethod,
          totalCentavos: pedido.valorTotalCentavos,
          taxaEntregaCentavos: pedido.valorTaxaEntregaCentavos,
          itens: _cart.map((item) => PrintDataItem(
            nome: item.name,
            quantidade: item.quantity,
            precoUnitarioCentavos: item.priceInCents,
            totalCentavos: item.totalInCents,
          )).toList(),
          dataHora: pedido.dataHoraCriacao,
        );
        final result = await printUseCase.imprimirPedido(
          data: printData,
          usuario: activeUser,
        );
        if (!result.success) {
          debugPrint('[CAP.PRINTING] ⚠️ ${result.summary}');
        } else {
          debugPrint('[CAP.PRINTING] ✅ ${result.managerResult.results.length} vias impressas');
        }
      } catch (e) {
        debugPrint('[CAP.PRINTING] Erro na impressão automática: $e');
        // Não bloqueia o fluxo — a venda já foi persistida
      }

      // Configurar Timer de Auto-Reset de 4 segundos (tempo do toast de Undo)
      _resetTimer = Timer(const Duration(seconds: 4), () {
        reset();
      });

    } catch (e) {
      _errorMessage = 'Falha ao persistir transação de venda: $e';
      _state = PdvState.error;
      notifyListeners();
    }
  }

  /// Cancela o reset e anula a venda gravada na Outbox, restaurando o estado anterior
  Future<void> undoLastVenda() async {
    final venda = _lastVenda;
    if (venda == null) return;

    _resetTimer?.cancel();

    try {
      // Exclui fisicamente da outbox local
      await (db.delete(db.outboxSync)
            ..where((t) => t.entityId.equals(venda.id)))
          .go();

      // Restaurar o carrinho do estado anterior
      _cart.clear();
      for (final item in venda.itens) {
        _cart.add(PdvItem(
          productId: item.produtoId,
          name: item.nome,
          priceInCents: item.valorUnitarioCentavos,
          quantity: item.quantidade,
        ));
      }

      _paymentMethod = venda.formaPagamentoId ?? 'Dinheiro';
      _state = PdvState.selectingPayment;
      _passoAtual = 2; // Volta na aba de pagamento
      _lastVenda = null;
      notifyListeners();

    } catch (e) {
      _errorMessage = 'Falha ao desfazer transação: $e';
      _state = PdvState.error;
      notifyListeners();
    }
  }

  void retryPix() {
    _errorMessage = null;
    confirmPayment();
  }

  void forceContingente() {
    _pixTimer?.cancel();
    _paymentMethod = 'PIX Contingente';
    _persistVenda();
  }

  @override
  void dispose() {
    _pixTimer?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }
}
