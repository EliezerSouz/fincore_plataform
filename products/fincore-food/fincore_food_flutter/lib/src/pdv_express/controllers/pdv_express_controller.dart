import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/common/domain_primitives.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/common/master_data_models.dart';
import 'package:fincore_core/common/kds_models.dart';
import 'package:fincore_food_client/fincore_food_client.dart' as client;
import 'package:fincore_core/fincore_core.dart';
import 'package:intl/intl.dart';
import 'package:fincore_core/repository/produto_repository.dart';
import 'package:fincore_core/repository/categoria_repository.dart';
import 'package:fincore_core/repository/cliente_repository.dart';
import 'package:fincore_core/repository/local_entrega_repository.dart';
import 'package:fincore_core/repository/forma_pagamento_repository.dart';
import 'package:fincore_core/repository/taxa_entrega_repository.dart';
import 'package:fincore_core/repository/empresa_configuracao_repository.dart';
import 'package:fincore_core/repository/audit_log_repository.dart';
import 'package:fincore_core/common/core_models.dart';
import 'package:fincore_pricing/pricing_engine.dart';
import '../models/pricing_result.dart';
import '../../cap/printing/print_capability.dart';

import 'package:fincore_pricing/repository/tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/item_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/produto_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/categoria_tabela_precificacao_repository.dart';
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
  final String mesa;
  final String garcom;
  final DateTime dataHora;
  final int? distanciaMetros;
  final int? tempoDeslocamentoSegundos;

  DadosEntrega({
    this.tipo = 'Entrega',
    this.logradouro = '',
    this.numero = '',
    this.bairro = '',
    this.referencia = '',
    this.cidade = '', // HC-001: Carregado da EmpresaConfiguracao no loadCatalog()
    this.cep = '',
    this.taxaEntregaCentavos = 0,
    this.trocoParaCentavos,
    this.prioridade = 'Normal',
    this.observacoes = '',
    this.mesa = '',
    this.garcom = '',
    DateTime? dataHora,
    this.distanciaMetros,
    this.tempoDeslocamentoSegundos,
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
    String? mesa,
    String? garcom,
    DateTime? dataHora,
    int? distanciaMetros,
    int? tempoDeslocamentoSegundos,
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
      mesa: mesa ?? this.mesa,
      garcom: garcom ?? this.garcom,
      dataHora: dataHora ?? this.dataHora,
      distanciaMetros: distanciaMetros ?? this.distanciaMetros,
      tempoDeslocamentoSegundos: tempoDeslocamentoSegundos ?? this.tempoDeslocamentoSegundos,
    );
  }
}

class PdvExpressController extends ChangeNotifier {
  // RepositÃ³rios do Core
  final ProdutoRepository produtoRepo;
  final CategoriaRepository categoriaRepo;
  final ClienteRepository clienteRepo;
  final LocalEntregaRepository localRepo;
  final FormaPagamentoRepository pagamentoRepo;
  final TaxaEntregaRepository taxaRepo;
  final EmpresaConfiguracaoRepository configRepo;

  // RepositÃ³rios e Engine do Pricing
  final TabelaPrecificacaoRepository tabelaRepo;
  final ItemTabelaPrecificacaoRepository itemRepo;
  final ProdutoTabelaPrecificacaoRepository assocRepo;
  final PricingEngine pricingEngine;
  final PrintUseCase printUseCase;

  // Contexto de SessÃ£o
  final TenantContext tenantContext;
  final FincoreDatabase db;

  CoreEmpresaConfiguracao? _empresaConfig;
  CoreEmpresaConfiguracao? get empresaConfig => _empresaConfig;
  bool get modoDeliveryAtivo => _empresaConfig?.modoDeliveryAtivo ?? true;
  bool get modoComandasAtivo => _empresaConfig?.modoComandasAtivo ?? false;
  bool get clienteObrigatorioVenda => _empresaConfig?.clienteObrigatorioVenda ?? false;
  String get atendimentoPadrao => _empresaConfig?.atendimentoPadrao ?? 'Delivery';

  // CatÃ¡logo Real
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

  // Estado da Ãºltima venda finalizada (para Undo e para abrir comprovante)
  PedidoDraft? _lastVenda;
  PedidoDraft? get lastVenda => _lastVenda;
  Timer? _resetTimer;

  final OrdemPreparo? ordemParaEditar;
  final String? repetirPedidoId;

  PdvExpressController({this.ordemParaEditar, this.repetirPedidoId})
      : produtoRepo = DependencyInjection().get<ProdutoRepository>(),
        categoriaRepo = DependencyInjection().get<CategoriaRepository>(),
        clienteRepo = DependencyInjection().get<ClienteRepository>(),
        localRepo = DependencyInjection().get<LocalEntregaRepository>(),
        pagamentoRepo = DependencyInjection().get<FormaPagamentoRepository>(),
        taxaRepo = DependencyInjection().get<TaxaEntregaRepository>(),
        configRepo = DependencyInjection().get<EmpresaConfiguracaoRepository>(),
        tabelaRepo = DependencyInjection().get<TabelaPrecificacaoRepository>(),
        itemRepo = DependencyInjection().get<ItemTabelaPrecificacaoRepository>(),
        assocRepo = DependencyInjection().get<ProdutoTabelaPrecificacaoRepository>(),
        pricingEngine = DependencyInjection().get<PricingEngine>(),
        printUseCase = DependencyInjection().get<PrintUseCase>(),
        tenantContext = DependencyInjection().get<TenantContext>(),
        db = DependencyInjection().get<FincoreDatabase>() {
    loadCatalog();
  }

  /// Construtor de Testes/InjeÃ§Ã£o manual
  PdvExpressController.custom({
    this.ordemParaEditar,
    this.repetirPedidoId,
    required this.produtoRepo,
    required this.categoriaRepo,
    required this.clienteRepo,
    required this.localRepo,
    required this.pagamentoRepo,
    required this.taxaRepo,
    required this.configRepo,
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

      // Garantir formas de pagamento padrÃ£o se a tabela estiver vazia
      final formas = await pagamentoRepo.findAll();
      if (formas.isEmpty && tenantContext.hasContext) {
        final activeTenant = tenantContext.tenantId;
        final activeUser = tenantContext.usuario.id;
        final now = DateTime.now().toUtc();
        
        final dineroId = const Uuid().v4();
        final pixId = const Uuid().v4();
        
        final dineroPayload = {
          'id': dineroId,
          'tenantId': activeTenant,
          'nome': 'Dinheiro',
          'tipo': 'DINHEIRO',
          'ordem': 1,
          'ativo': true,
          'permiteTroco': true,
          'syncVersion': 1,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'createdBy': activeUser,
          'updatedBy': activeUser,
        };
        final pixPayload = {
          'id': pixId,
          'tenantId': activeTenant,
          'nome': 'Pix',
          'tipo': 'PIX',
          'ordem': 2,
          'ativo': true,
          'permiteTroco': false,
          'syncVersion': 1,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'createdBy': activeUser,
          'updatedBy': activeUser,
        };

        await db.transaction(() async {
          await db.into(db.formasPagamentoTable).insert(
            FormasPagamentoTableCompanion.insert(
              id: dineroId,
              tenantId: activeTenant,
              nome: 'Dinheiro',
              tipo: 'DINHEIRO',
              ordem: 1,
              ativo: true,
              permiteTroco: true,
              createdAt: now,
              updatedAt: now,
              createdBy: activeUser,
              updatedBy: activeUser,
              syncStatus: SyncStatus.pending,
            ),
          );
          await db.into(db.formasPagamentoTable).insert(
            FormasPagamentoTableCompanion.insert(
              id: pixId,
              tenantId: activeTenant,
              nome: 'Pix',
              tipo: 'PIX',
              ordem: 2,
              ativo: true,
              permiteTroco: false,
              createdAt: now,
              updatedAt: now,
              createdBy: activeUser,
              updatedBy: activeUser,
              syncStatus: SyncStatus.pending,
            ),
          );
          
          await db.into(db.outboxSync).insert(OutboxSyncCompanion.insert(
            tenantId: activeTenant,
            entity: 'formas_pagamento',
            entityId: dineroId,
            action: 'create',
            payload: jsonEncode(dineroPayload),
            status: 'pending',
            version: 1,
            createdAt: DateTime.now(),
          ));
          await db.into(db.outboxSync).insert(OutboxSyncCompanion.insert(
            tenantId: activeTenant,
            entity: 'formas_pagamento',
            entityId: pixId,
            action: 'create',
            payload: jsonEncode(pixPayload),
            status: 'pending',
            version: 1,
            createdAt: DateTime.now(),
          ));
        });
      }

      final configs = await configRepo.findAll();
      if (configs.isNotEmpty) {
        _empresaConfig = configs.first;

        // HC-001: Cidade lida do endereÃ§o estruturado da empresa (empresa.cidade)
        final cidadeEmpresa = tenantContext.hasContext ? (tenantContext.empresa.cidade ?? '') : '';

        if (_empresaConfig!.atendimentoPadrao == 'Mesa/BalcÃ£o') {
          _entrega = _entrega.copyWith(tipo: 'Retirada', taxaEntregaCentavos: 0, cidade: cidadeEmpresa);
        } else if (_empresaConfig!.atendimentoPadrao == 'Delivery') {
          _entrega = _entrega.copyWith(tipo: 'Entrega', cidade: cidadeEmpresa);
        } else {
          _entrega = _entrega.copyWith(cidade: cidadeEmpresa);
        }
      }

      if (ordemParaEditar != null) {
        final o = ordemParaEditar!;
        final pedidoRow = await (db.select(db.pedidosTable)
              ..where((t) => t.id.equals(o.pedidoId)))
            .getSingleOrNull();

        if (pedidoRow != null) {
          _cliente = DadosCliente(
            id: pedidoRow.clienteId,
            nome: pedidoRow.clienteNomeAvulso,
            telefone: pedidoRow.clienteTelefoneAvulso,
          );

          if (pedidoRow.enderecoJson != null) {
            try {
              final Map<String, dynamic> end = jsonDecode(pedidoRow.enderecoJson!) as Map<String, dynamic>;
              _entrega = DadosEntrega(
                tipo: pedidoRow.tipoLogistica,
                logradouro: end['logradouro'] as String? ?? '',
                numero: end['numero'] as String? ?? '',
                bairro: end['bairro'] as String? ?? '',
                cidade: end['cidade'] as String? ?? '',
                cep: end['cep'] as String? ?? '',
                referencia: end['referencia'] as String? ?? '',
                taxaEntregaCentavos: end['taxaEntregaCentavos'] as int? ?? 0,
                prioridade: o.prioridade == PrioridadeOrdem.urgente
                    ? 'Urgente'
                    : (o.prioridade == PrioridadeOrdem.vip ? 'VIP' : 'Normal'),
                dataHora: pedidoRow.dataHoraCriacao.toLocal(),
              );
            } catch (_) {
              _entrega = _entrega.copyWith(
                tipo: pedidoRow.tipoLogistica,
                prioridade: o.prioridade == PrioridadeOrdem.urgente
                    ? 'Urgente'
                    : (o.prioridade == PrioridadeOrdem.vip ? 'VIP' : 'Normal'),
              );
            }
          } else {
            _entrega = _entrega.copyWith(
              tipo: pedidoRow.tipoLogistica,
              prioridade: o.prioridade == PrioridadeOrdem.urgente
                  ? 'Urgente'
                  : (o.prioridade == PrioridadeOrdem.vip ? 'VIP' : 'Normal'),
            );
          }

          if (pedidoRow.formaPagamentoNome != null) {
            _paymentMethod = pedidoRow.formaPagamentoNome!;
          }

          final itemRows = await (db.select(db.itensPedidoTable)
                ..where((t) => t.pedidoId.equals(o.pedidoId) & t.deletedAt.isNull()))
              .get();

          _cart.clear();
          for (final row in itemRows) {
            _cart.add(PdvItem(
              productId: row.produtoId,
              name: row.nomeProduto,
              priceInCents: row.valorUnitarioCentavos,
              quantity: row.quantidade,
            ));
          }

          await _recalculatePrices();
          _state = PdvState.drafting;
          _passoAtual = 1;
        }
      } else if (repetirPedidoId != null) {
        final pedidoRow = await (db.select(db.pedidosTable)
              ..where((t) => t.id.equals(repetirPedidoId!)))
            .getSingleOrNull();

        if (pedidoRow != null) {
          _cliente = DadosCliente(
            id: pedidoRow.clienteId,
            nome: pedidoRow.clienteNomeAvulso,
            telefone: pedidoRow.clienteTelefoneAvulso,
          );

          if (pedidoRow.enderecoJson != null) {
            try {
              final Map<String, dynamic> end = jsonDecode(pedidoRow.enderecoJson!) as Map<String, dynamic>;
              _entrega = DadosEntrega(
                tipo: pedidoRow.tipoLogistica,
                logradouro: end['logradouro'] as String? ?? '',
                numero: end['numero'] as String? ?? '',
                bairro: end['bairro'] as String? ?? '',
                cidade: end['cidade'] as String? ?? '',
                cep: end['cep'] as String? ?? '',
                referencia: end['referencia'] as String? ?? '',
                taxaEntregaCentavos: end['taxaEntregaCentavos'] as int? ?? 0,
                prioridade: 'Normal',
                dataHora: DateTime.now().add(const Duration(hours: 2)),
              );
            } catch (_) {
              _entrega = _entrega.copyWith(
                tipo: pedidoRow.tipoLogistica,
                prioridade: 'Normal',
                dataHora: DateTime.now().add(const Duration(hours: 2)),
              );
            }
          } else {
            _entrega = _entrega.copyWith(
              tipo: pedidoRow.tipoLogistica,
              prioridade: 'Normal',
              dataHora: DateTime.now().add(const Duration(hours: 2)),
            );
          }

          if (pedidoRow.formaPagamentoNome != null) {
            _paymentMethod = pedidoRow.formaPagamentoNome!;
          }

          final itemRows = await (db.select(db.itensPedidoTable)
                ..where((t) => t.pedidoId.equals(repetirPedidoId!) & t.deletedAt.isNull()))
              .get();

          _cart.clear();
          for (final row in itemRows) {
            _cart.add(PdvItem(
              productId: row.produtoId,
              name: row.nomeProduto,
              priceInCents: row.valorUnitarioCentavos,
              quantity: row.quantidade,
            ));
          }

          await _recalculatePrices();
          _state = PdvState.drafting;
          _passoAtual = 1;
        }
      }
    } catch (e) {
      _errorMessage = 'Falha ao carregar catÃ¡logo: $e';
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
  /// Para pedidos de Retirada, o cliente Ã© obrigatÃ³rio e nunca Ã© limpo automaticamente.
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

    // â”€â”€ PASSO 1: Mapear cada produto para sua tabela de precificaÃ§Ã£o (Produto -> Tabela ou Categoria -> Tabela) â”€â”€â”€â”€â”€â”€
    final Map<String, List<PdvItem>> itensPorTabela = {};

    for (final item in _cart) {
      try {
        // 1.1 Tentar associaÃ§Ã£o direta de produto
        final assocs = await assocRepo.findByProdutoId(item.productId);
        final activeAssoc = assocs.firstWhere(
          (a) => a.ativo,
          orElse: () => throw Exception('sem tabela produto'),
        );
        final tabelaId = activeAssoc.tabelaPrecificacaoId;
        itensPorTabela.putIfAbsent(tabelaId, () => []).add(item);
      } catch (_) {
        try {
          // 1.2 Tentar fallback por categoria
          final productRow = await (db.select(db.produtosTable)
                ..where((t) => t.id.equals(item.productId)))
              .getSingleOrNull();
          final categoryId = productRow?.categoriaId;
          if (categoryId != null) {
            final catAssocs = await DependencyInjection()
                .get<CategoriaTabelaPrecificacaoRepository>()
                .findByCategoriaId(categoryId);
            final activeCatAssoc = catAssocs.firstWhere(
              (a) => a.ativo,
              orElse: () => throw Exception('sem tabela categoria'),
            );
            final tabelaId = activeCatAssoc.tabelaPrecificacaoId;
            itensPorTabela.putIfAbsent(tabelaId, () => []).add(item);
          } else {
            throw Exception('sem categoria');
          }
        } catch (_) {
          // Produto sem nenhuma tabela (nem direta nem por categoria)
          // Usa preÃ§o base do prÃ³prio produto ou o preÃ§o padrÃ£o
          int basePrice = item.priceInCents;
          try {
            basePrice = await pricingEngine.resolvePrice(
              produtoId: item.productId,
              quantidade: item.quantity.toInt(),
              canal: _entrega.tipo,
            );
          } catch (_) {}
          unitPrices[item.productId] = basePrice;
        }
      }
    }

    // â”€â”€ PASSO 2: Para cada tabela/grupo, calcular o preÃ§o por PRODUTO individual â”€â”€
    // P2-04: Cada produto recebe seu prÃ³prio resolvePrice() â€” elimina o bug em que
    // todos os produtos do grupo recebiam o preÃ§o do primeiro produto da lista.
    for (final entry in itensPorTabela.entries) {
      final tabelaId = entry.key;
      final itensDoGrupo = entry.value;

      try {
        final tabela = await tabelaRepo.findById(tabelaId);
        if (tabela == null || !tabela.ativo) {
          for (final item in itensDoGrupo) {
            unitPrices[item.productId] = item.priceInCents;
          }
          continue;
        }

        // Soma o total de unidades do grupo (usado para faixa de upsell do grupo)
        final totalQtyDoGrupo = itensDoGrupo.fold<double>(0, (sum, i) => sum + i.quantity);

        // Calcula preÃ§o individualmente por produto â€” resolve usando o produtoId correto
        for (final item in itensDoGrupo) {
          try {
            final preco = await pricingEngine.resolvePrice(
              produtoId: item.productId,       // â† cada produto usa seu prÃ³prio ID
              quantidade: item.quantity.toInt(),
              quantidadeGrupo: totalQtyDoGrupo.toInt(),
              canal: _entrega.tipo,
            );
            item.priceInCents = preco;
            unitPrices[item.productId] = preco;
          } catch (_) {
            // Produto sem preÃ§o na tabela: mantÃ©m o preÃ§o existente
            unitPrices[item.productId] = item.priceInCents;
          }
        }

        // Monta o GroupPricingSummary usando o primeiro produto do grupo como referÃªncia de faixa
        final faixas = await itemRepo.findByTabelaId(tabelaId);
        faixas.sort((a, b) => a.quantidadeMinima.compareTo(b.quantidadeMinima));

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
        if (faixaAplicada == null && faixas.isNotEmpty) {
          proximaFaixa = faixas.first;
        }

        // PreÃ§o de referÃªncia para o upsell = preÃ§o do primeiro item do grupo
        final precoReferencia = itensDoGrupo.isNotEmpty
            ? (unitPrices[itensDoGrupo.first.productId] ?? itensDoGrupo.first.priceInCents)
            : 0;

        if (proximaFaixa != null) {
          final qtyNeeded = (proximaFaixa.quantidadeMinima - totalQtyDoGrupo).clamp(0, double.infinity).toDouble();
          final priceDifference = precoReferencia - proximaFaixa.valorUnitarioCentavos;
          final potentialSavings = (priceDifference * totalQtyDoGrupo).round();

          groupSummaries.add(GroupPricingSummary(
            group: PricingGroup(id: tabelaId, name: tabela.nome),
            totalQty: totalQtyDoGrupo,
            appliedUnitPriceInCents: precoReferencia,
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
      if (clienteObrigatorioVenda && _cliente.isEmpty) {
        return false;
      }
      return true; // Retirada / BalcÃ£o
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
      _errorMessage = 'O carrinho estÃ¡ vazio.';
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
        if (_pixCountdown > 0) {
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

  /// Grava a venda na tabela local (pedidos_table + itens_pedido_table) e na OutboxSync.
  ///
  /// ## Fluxo Correto (P0-01)
  /// 1. Persiste pedido em `pedidos_table` (SQLite local) â€” dado seguro mesmo offline
  /// 2. Persiste itens em `itens_pedido_table` (SQLite local)
  /// 3. Enfileira no Outbox para envio ao Supabase
  /// 4. O SyncEngine processa o Outbox â†’ upsert na tabela `pedido` do Supabase
  Future<String?> _resolveFormaPagamentoId(String methodLabel) async {
    try {
      final formas = await pagamentoRepo.findAll();
      final cleanLabel = methodLabel.toLowerCase();
      
      final matched = formas.where((f) {
        final name = f.nome.toLowerCase();
        if (cleanLabel.contains('pix') && name.contains('pix')) return true;
        if (cleanLabel.contains('dinheiro') && name.contains('dinheiro')) return true;
        if (cleanLabel.contains('cart') && name.contains('cart')) return true;
        return name.contains(cleanLabel) || cleanLabel.contains(name);
      }).firstOrNull;
      
      if (matched != null) {
        return matched.id;
      }
      
      if (formas.isNotEmpty) {
        return formas.first.id;
      }
    } catch (_) {}
    return null;
  }

  /// Grava a venda na tabela local (pedidos_table + itens_pedido_table) e na OutboxSync.
  ///
  /// ## Fluxo Correto (P0-01)
  /// 1. Persiste pedido em `pedidos_table` (SQLite local) â€” dado seguro mesmo offline
  /// 2. Persiste itens em `itens_pedido_table` (SQLite local)
  /// 3. Enfileira no Outbox para envio ao Supabase
  /// 4. O SyncEngine processa o Outbox â†’ upsert na tabela `pedido` do Supabase
  Future<void> _persistVenda() async {
    _state = PdvState.confirming;
    notifyListeners();

    try {
      final activeTenant = tenantContext.tenantId;
      final activeUser = tenantContext.usuario.id;
      final now = DateTime.now().toUtc();

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

      // Calcular distÃ¢ncia e tempo de viagem via Serverpod MapRouteEndpoint (reutilizar se jÃ¡ calculado)
      int? distanciaMetros = _entrega.distanciaMetros;
      int? tempoDeslocamentoSegundos = _entrega.tempoDeslocamentoSegundos;

      if (_entrega.tipo == 'Entrega' && (distanciaMetros == null || tempoDeslocamentoSegundos == null)) {
        try {
          final serverpodClient = DependencyInjection().get<client.Client>();
          final empresa = tenantContext.empresa;
          final origin = [
            empresa.logradouro,
            empresa.numero,
            empresa.bairro,
            empresa.cidade,
            empresa.estado,
            empresa.cep
          ].where((s) => s != null && s.trim().isNotEmpty).join(', ');

          final destination = [
            _entrega.logradouro,
            _entrega.numero,
            _entrega.bairro,
            _entrega.cidade,
            _entrega.cep
          ].where((s) => s != null && s.trim().isNotEmpty).join(', ');

          if (origin.isNotEmpty && destination.isNotEmpty) {
            final routeResult = await serverpodClient.mapRoute.calculateRoute(origin, destination);
            if (routeResult.status != 'error') {
              distanciaMetros = routeResult.distanciaMetros;
              tempoDeslocamentoSegundos = routeResult.tempoDeslocamentoSegundos;
            }
          }
        } catch (e) {
          LogService.instance.warning(LogModule.sync, 'Falha ao calcular rota do pedido: $e');
        }
      }

      final enderecoStr = _entrega.tipo == 'Entrega' ? jsonEncode({
        'logradouro': _entrega.logradouro,
        'numero': _entrega.numero,
        'bairro': _entrega.bairro,
        'cidade': _entrega.cidade,
        'cep': _entrega.cep,
        'referencia': _entrega.referencia,
        'taxaEntregaCentavos': _entrega.taxaEntregaCentavos,
        'distanciaMetros': distanciaMetros,
        'tempoDeslocamentoSegundos': tempoDeslocamentoSegundos,
      }) : null;

      final formaPgtoId = await _resolveFormaPagamentoId(_paymentMethod);
      final ordemPreparoId = ordemParaEditar?.id ?? const Uuid().v4();
      final historicoId = const Uuid().v4();
      final kdsItensJson = jsonEncode(draftItens.map((i) => {
        'produtoId': i.produtoId,
        'nomeProduto': i.nome,
        'quantidade': i.quantidade,
        'unidade': 'un',
      }).toList());

      // Calcular o prÃ³ximo nÃºmero sequencial de pedido para este Tenant
      final totalPedidos = await (db.select(db.pedidosTable)
            ..where((t) => t.tenantId.equals(activeTenant)))
          .get();
      
      int proxNumero;
      if (ordemParaEditar != null) {
        final existingPedido = await (db.select(db.pedidosTable)
              ..where((t) => t.id.equals(ordemParaEditar!.pedidoId)))
            .getSingleOrNull();
        proxNumero = existingPedido?.numeroPedido ?? (totalPedidos.length + 1);
      } else {
        proxNumero = totalPedidos.length + 1;
      }

      final pedido = PedidoDraft(
        id: ordemParaEditar?.pedidoId,
        tenantId: activeTenant,
        clienteId: _cliente.id,
        tipoLogistica: _entrega.tipo,
        valorSubtotalCentavos: subtotal,
        valorTaxaEntregaCentavos: frete,
        valorTotalCentavos: subtotal + frete,
        formaPagamentoId: formaPgtoId,
        trocoParaCentavos: _entrega.trocoParaCentavos,
        itens: draftItens,
        operadorId: activeUser,
        dataHoraCriacao: _entrega.dataHora,
      );

      final isEdit = ordemParaEditar != null;
      final action = isEdit ? 'update' : 'create';
      final histTitle = isEdit ? 'Pedido editado' : 'Pedido criado';
      final histDesc = isEdit ? 'Itens/Valores atualizados no PDV' : 'Pedido enviado para a cozinha';

      final List<ItemPedidoData> oldItems = isEdit
          ? await (db.select(db.itensPedidoTable)..where((t) => t.pedidoId.equals(pedido.id) & t.deletedAt.isNull())).get()
          : [];

      // â”€â”€ PASSO 1: PersistÃªncia LOCAL na pedidos_table (SQLite) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      // Isso garante que a venda NÃƒO seja perdida mesmo se o Outbox ou Supabase
      // falharem. O dado fica seguro no banco local primeiro.
      await db.transaction(() async {
        // Se for ediÃ§Ã£o, limpa os itens antigos para evitar lixo
        if (isEdit) {
          await (db.delete(db.itensPedidoTable)
                ..where((t) => t.pedidoId.equals(pedido.id)))
              .go();
        }

        // 1a. Inserir pedido principal
        await db.into(db.pedidosTable).insertOnConflictUpdate(
          PedidosTableCompanion.insert(
            id: pedido.id,
            tenantId: activeTenant,
            status: const Value('confirmado'),
            tipoLogistica: pedido.tipoLogistica,
            clienteId: Value(pedido.clienteId),
            clienteNomeAvulso: Value(_cliente.nome),
            clienteTelefoneAvulso: Value(_cliente.telefone),
            valorSubtotalCentavos: pedido.valorSubtotalCentavos,
            valorTaxaEntregaCentavos: Value(pedido.valorTaxaEntregaCentavos),
            valorTotalCentavos: pedido.valorTotalCentavos,
            trocoParaCentavos: Value(pedido.trocoParaCentavos),
            formaPagamentoId: Value(pedido.formaPagamentoId),
            formaPagamentoNome: Value(_paymentMethod),
            numeroPedido: Value(proxNumero),
            enderecoJson: Value(enderecoStr),
            operadorId: Value(activeUser),
            dataHoraCriacao: pedido.dataHoraCriacao.toUtc(),
            canalOrigem: const Value('pdv_express'),
            syncVersion: const Value(1),
            syncStatus: SyncStatus.pending,
            createdAt: now,
            updatedAt: now,
            createdBy: activeUser,
            updatedBy: activeUser,
          ),
        );

        // 1b. Inserir itens do pedido
        for (final item in draftItens) {
          await db.into(db.itensPedidoTable).insertOnConflictUpdate(
            ItensPedidoTableCompanion.insert(
              id: item.id,
              tenantId: activeTenant,
              pedidoId: pedido.id,
              produtoId: item.produtoId,
              nomeProduto: item.nome,
              quantidade: item.quantidade,
              valorUnitarioCentavos: item.valorUnitarioCentavos,
              valorTotalCentavos: item.valorTotalCentavos,
              syncVersion: const Value(1),
              syncStatus: SyncStatus.pending,
              createdAt: now,
              updatedAt: now,
              createdBy: activeUser,
              updatedBy: activeUser,
            ),
          );
        }

        final String observacoesKDS = 
            '[DADOS_PEDIDO]\n'
            'cliente: ${_cliente.nome ?? 'Consumidor'}\n'
            'telefone: ${_cliente.telefone ?? ''}\n'
            'tipo: ${pedido.tipoLogistica}\n'
            'pagamento: $_paymentMethod\n'
            'total: ${pedido.valorTotalCentavos}\n'
            'unidades: ${draftItens.fold<double>(0.0, (sum, i) => sum + i.quantidade)}\n'
            '${(pedido.tipoLogistica == 'Entrega' || pedido.tipoLogistica == 'Retirada') ? 'agendado: ${DateFormat('dd/MM/yyyy HH:mm').format(_entrega.dataHora)}\n' : ''}'
            'obs: ${_entrega.observacoes}\n'
            '[/DADOS_PEDIDO]';

        // 1c. Inserir ordem de preparo correspondente para a cozinha (KDS)
        await db.into(db.ordensPreparoTable).insertOnConflictUpdate(
          OrdensPreparoTableCompanion.insert(
            id: ordemPreparoId,
            tenantId: activeTenant,
            pedidoId: pedido.id,
            itensJson: kdsItensJson,
            status: 'pendente',
            prioridade: 'normal',
            operadorId: Value(activeUser),
            criadaEm: now.toLocal(),
            observacoes: Value(observacoesKDS),
            syncVersion: const Value(1),
            syncStatus: SyncStatus.pending,
            createdAt: now,
            updatedAt: now,
            createdBy: activeUser,
            updatedBy: activeUser,
          ),
        );

        // 1d. Inserir histÃ³rico inicial do preparo
        await db.into(db.historicosOrdemPreparoTable).insert(
          HistoricosOrdemPreparoTableCompanion.insert(
            id: historicoId,
            tenantId: activeTenant,
            ordemPreparoId: ordemPreparoId,
            titulo: histTitle,
            descricao: histDesc,
            operadorNome: Value(tenantContext.usuario.nome),
            criadaEm: now.toLocal(),
            syncVersion: const Value(1),
            syncStatus: SyncStatus.pending,
            createdAt: now,
            updatedAt: now,
            createdBy: activeUser,
            updatedBy: activeUser,
          ),
        );
      });

      // â”€â”€ PASSO 1c: Baixa AutomÃ¡tica de Estoque â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      // Entrega com data futura â†’ RESERVA (incrementa quantidadeReservada, nÃ£o toca quantidadeAtual)
      // Retirada ou venda imediata â†’ SAÃDA FÃSICA (decrementa quantidadeAtual)
      try {
        await _baixarEstoque(
          itens: draftItens,
          pedidoId: pedido.id,
          pedidoNumero: proxNumero,
          operadorId: activeUser,
          activeTenant: activeTenant,
          db: db,
          now: now,
          isEdit: isEdit,
          oldItems: oldItems,
          tipoLogistica: pedido.tipoLogistica,
          dataEntregaPrevista: pedido.tipoLogistica == 'Entrega' ? _entrega.dataHora : null,
        );
      } catch (e) {
        debugPrint('[ESTOQUE] Erro ao movimentar estoque (nÃ£o bloqueia venda): $e');
      }

      // Gerar log de auditoria
      try {
        final auditLogRepo = DependencyInjection().get<AuditLogRepository>();
        await auditLogRepo.log(
          entityName: 'Pedido',
          entityId: pedido.id,
          userId: activeUser,
          action: isEdit ? 'UPDATE' : 'CREATE',
          entityDisplayName: 'Pedido #${proxNumero}',
          entityModule: 'PDV',
          diff: {
            'cliente': _cliente.nome ?? 'Consumidor',
            'valorTotalCentavos': pedido.valorTotalCentavos,
            'tipoLogistica': pedido.tipoLogistica,
            'pagamento': _paymentMethod,
          },
        );
      } catch (e) {
        debugPrint('Erro ao gerar log de auditoria do pedido: $e');
      }

      // â”€â”€ PASSO 2: Enfileirar no Outbox (SQLite â†’ Supabase) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      // O payload Ã© o snapshot completo do pedido para o Supabase.
      final payload = {
        'id': pedido.id,
        'tenantId': pedido.tenantId,
        'clienteId': pedido.clienteId,
        'clienteNomeAvulso': _cliente.nome,
        'clienteTelefoneAvulso': _cliente.telefone,
        'tipoLogistica': pedido.tipoLogistica,
        'valorSubtotalCentavos': pedido.valorSubtotalCentavos,
        'valorTaxaEntregaCentavos': pedido.valorTaxaEntregaCentavos,
        'valorTotalCentavos': pedido.valorTotalCentavos,
        'formaPagamentoId': pedido.formaPagamentoId,
        'formaPagamentoNome': _paymentMethod,
        'trocoParaCentavos': pedido.trocoParaCentavos,
        'status': 'confirmado',
        'canalOrigem': 'pdv_express',
        'operadorId': pedido.operadorId,
        'dataHoraCriacao': pedido.dataHoraCriacao.toIso8601String(),
        'numeroPedido': proxNumero,
        'enderecoJson': enderecoStr,
        'syncVersion': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'createdBy': activeUser,
        'updatedBy': activeUser,
      };

      await db.into(db.outboxSync).insert(OutboxSyncCompanion.insert(
        tenantId: activeTenant,
        entity: 'Pedido',
        entityId: pedido.id,
        action: action,
        payload: jsonEncode(payload),
        status: 'pending',
        version: 1,
        createdAt: DateTime.now(),
      ));

      // Enfileirar itens do pedido no outbox para sincronizar com Supabase
      for (final item in draftItens) {
        final itemPayload = {
          'id': item.id,
          'tenantId': activeTenant,
          'pedidoId': pedido.id,
          'produtoId': item.produtoId,
          'nomeProduto': item.nome,
          'quantidade': item.quantidade,
          'valorUnitarioCentavos': item.valorUnitarioCentavos,
          'valorTotalCentavos': item.valorTotalCentavos,
          'syncVersion': 1,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'createdBy': activeUser,
          'updatedBy': activeUser,
        };

        await db.into(db.outboxSync).insert(OutboxSyncCompanion.insert(
          tenantId: activeTenant,
          entity: 'itens_pedido',
          entityId: item.id,
          action: 'create',
          payload: jsonEncode(itemPayload),
          status: 'pending',
          version: 1,
          createdAt: DateTime.now(),
        ));
      }

      if (isEdit) {
        for (final oldItem in oldItems) {
          await db.into(db.outboxSync).insert(OutboxSyncCompanion.insert(
            tenantId: activeTenant,
            entity: 'itens_pedido',
            entityId: oldItem.id,
            action: 'DELETE',
            payload: jsonEncode({
              'id': oldItem.id,
              'tenantId': activeTenant,
            }),
            status: 'pending',
            version: 1,
            createdAt: DateTime.now(),
          ));
        }
      }

      // â”€â”€ PASSO 2b: Enfileirar OrdemPreparo no Outbox para sincronizar com a cozinha â”€â”€
      final kdsPayload = {
        'id': ordemPreparoId,
        'tenantId': activeTenant,
        'pedidoId': pedido.id,
        'itensJson': kdsItensJson,
        'status': 'pendente',
        'prioridade': 'normal',
        'operadorId': activeUser,
        'criadaEm': now.toIso8601String(),
        'tempoEstimadoSegundos': 0,
        'observacoes': null,
        'syncVersion': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'createdBy': activeUser,
        'updatedBy': activeUser,
      };

      await db.into(db.outboxSync).insert(OutboxSyncCompanion.insert(
        tenantId: activeTenant,
        entity: 'OrdemPreparo',
        entityId: ordemPreparoId,
        action: action,
        payload: jsonEncode(kdsPayload),
        status: 'pending',
        version: 1,
        createdAt: DateTime.now(),
      ));

      // Enfileirar HistoricoOrdemPreparo no Outbox
      final histPayload = {
        'id': historicoId,
        'tenantId': activeTenant,
        'ordemPreparoId': ordemPreparoId,
        'titulo': histTitle,
        'descricao': histDesc,
        'operadorNome': tenantContext.usuario.nome,
        'criadaEm': now.toIso8601String(),
        'syncVersion': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'createdBy': activeUser,
        'updatedBy': activeUser,
      };

      await db.into(db.outboxSync).insert(OutboxSyncCompanion.insert(
        tenantId: activeTenant,
        entity: 'HistoricoOrdemPreparo',
        entityId: historicoId,
        action: 'create',
        payload: jsonEncode(histPayload),
        status: 'pending',
        version: 1,
        createdAt: DateTime.now(),
      ));

      // â”€â”€ PASSO 3: ImpressÃ£o automÃ¡tica (CAP.PRINTING) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
          debugPrint('[CAP.PRINTING] âš ï¸ ${result.summary}');
        } else {
          debugPrint('[CAP.PRINTING] âœ… ${result.managerResult.results.length} vias impressas');
        }
      } catch (e) {
        debugPrint('[CAP.PRINTING] Erro na impressÃ£o automÃ¡tica: $e');
        // NÃ£o bloqueia o fluxo â€” a venda jÃ¡ foi persistida localmente
      }

      _lastVenda = pedido;
      _state = PdvState.completed;
      notifyListeners();

      // Timer de auto-reset de 4 segundos (janela do toast de Undo)
      _resetTimer = Timer(const Duration(seconds: 4), () {
        reset();
      });

    } catch (e) {
      _errorMessage = 'Falha ao persistir transaÃ§Ã£o de venda: $e';
      _state = PdvState.error;
      notifyListeners();
    }
  }

  /// Cancela o reset e anula a venda gravada na Outbox e nas tabelas locais.
  ///
  /// ## Comportamento (P1-06)
  /// - Remove o pedido do Outbox (somente se ainda nÃ£o foi sincronizado)
  /// - Remove o pedido e seus itens das tabelas locais (soft delete marcado como cancelado)
  /// - Restaura o carrinho ao estado anterior para que o operador possa corrigir
  Future<void> undoLastVenda() async {
    final venda = _lastVenda;
    if (venda == null) return;

    _resetTimer?.cancel();

    try {
      await db.transaction(() async {
        // 1. Remove do Outbox (se ainda nÃ£o sincronizado â€” idempotente)
        final outboxEntry = await (db.select(db.outboxSync)
              ..where((t) => t.entityId.equals(venda.id)))
            .getSingleOrNull();

        if (outboxEntry != null && outboxEntry.status != SyncStatus.synced.name) {
          await (db.delete(db.outboxSync)
                ..where((t) => t.entityId.equals(venda.id)))
              .go();
        } else if (outboxEntry?.status == SyncStatus.synced.name) {
          // Pedido jÃ¡ foi enviado ao Supabase â€” precisaria de cancelamento remoto.
          // Por enquanto, marca localmente como cancelado e loga o aviso.
          debugPrint('[PDV] AVISO: Pedido ${venda.id} jÃ¡ sincronizado com Supabase. Cancelamento remoto pendente.');
        }

        // 2. Marca pedido local como cancelado (soft delete reversÃ­vel)
        final now = DateTime.now().toUtc();
        await (db.update(db.pedidosTable)
              ..where((t) => t.id.equals(venda.id)))
            .write(PedidosTableCompanion(
          status: const Value('cancelado'),
          updatedAt: Value(now),
          deletedAt: Value(now),
        ));

        // 3. Marca itens como cancelados
        await (db.update(db.itensPedidoTable)
              ..where((t) => t.pedidoId.equals(venda.id)))
            .write(ItensPedidoTableCompanion(
          updatedAt: Value(now),
          deletedAt: Value(now),
        ));
      });

      // 4. Restaura o carrinho ao estado da venda anterior
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
      _errorMessage = 'Falha ao desfazer transaÃ§Ã£o: $e';
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ESTOQUE: Baixa AutomÃ¡tica de Produtos Acabados
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Deduz do estoque local os itens vendidos e enfileira a movimentaÃ§Ã£o
  /// no Outbox para sincronizar com o Supabase.
  ///
  /// Em modo de ediÃ§Ã£o ([isEdit]=true), estorna os itens antigos antes
  /// de debitar os novos â€” mantendo consistÃªncia sem duplicar baixas.
  ///
  /// Apenas produtos com [ProdutoData.controlaEstoque]=true sÃ£o afetados.
  Future<void> _baixarEstoque({
    required List<ItemPedidoDraft> itens,
    required String pedidoId,
    required int pedidoNumero,
    required String operadorId,
    required String activeTenant,
    required FincoreDatabase db,
    required DateTime now,
    required bool isEdit,
    required List<ItemPedidoData> oldItems,
    required String tipoLogistica,
    DateTime? dataEntregaPrevista,
  }) async {
    final uuid = const Uuid();
    final pedidoLabel = '#${pedidoNumero.toString().padLeft(4, '0')}';

    // Determina o tipo de movimentaÃ§Ã£o com base na logÃ­stica:
    // - Entrega (data futura) â†’ RESERVA: compromete estoque, nÃ£o baixa fÃ­sico
    // - Retirada / BalcÃ£o / Mesa â†’ SAÃDA FÃSICA: baixa imediata
    final bool isEntregaAgendada = tipoLogistica == 'Entrega';
    final String tipoMovimento = isEntregaAgendada ? 'reserva' : 'saida';

    // Se for ediÃ§Ã£o, estorna os itens antigos primeiro
    if (isEdit && oldItems.isNotEmpty) {
      for (final oldItem in oldItems) {
        // Estorno sempre volta para o tipo oposto do que foi gerado originalmente.
        // Para simplificar: sempre devolve ao fÃ­sico (cancelamento).
        await _movimentarEstoque(
          db: db,
          uuid: uuid,
          activeTenant: activeTenant,
          produtoId: oldItem.produtoId,
          pedidoId: pedidoId,
          quantidade: oldItem.quantidade.toInt(),
          tipo: 'cancelamento',
          motivo: 'Estorno de ediÃ§Ã£o â€” Pedido $pedidoLabel',
          operadorId: operadorId,
          now: now,
          isEntradaFisica: true,
          isSaidaReserva: false,
        );
      }
    }

    // Registra movimento para cada item novo
    for (final item in itens) {
      final produtoResult = await (db.select(db.produtosTable)
            ..where((t) => t.id.equals(item.produtoId)))
          .getSingleOrNull();

      if (produtoResult == null || !produtoResult.controlaEstoque) continue;

      if (isEntregaAgendada) {
        // Entrega futura: incrementa quantidadeReservada
        await _movimentarEstoque(
          db: db,
          uuid: uuid,
          activeTenant: activeTenant,
          produtoId: item.produtoId,
          pedidoId: pedidoId,
          quantidade: item.quantidade.toInt(),
          tipo: 'reserva',
          motivo: 'Reserva para entrega â€” Pedido $pedidoLabel',
          operadorId: operadorId,
          now: now,
          isEntradaFisica: false,
          isEntradaReserva: true,
          dataEntregaPrevista: dataEntregaPrevista,
        );
      } else {
        // Venda imediata: decrementa quantidadeAtual
        await _movimentarEstoque(
          db: db,
          uuid: uuid,
          activeTenant: activeTenant,
          produtoId: item.produtoId,
          pedidoId: pedidoId,
          quantidade: item.quantidade.toInt(),
          tipo: 'saida',
          motivo: 'Venda PDV â€” Pedido $pedidoLabel',
          operadorId: operadorId,
          now: now,
          isEntradaFisica: false,
          isEntradaReserva: false,
        );
      }
    }
  }

  /// Move uma quantidade no estoque: cria o registro de estoque se nÃ£o existir,
  /// atualiza o saldo e insere a movimentaÃ§Ã£o + outbox.
  ///
  /// - [isEntradaFisica]: true = incrementa quantidadeAtual (produÃ§Ã£o, cancelamento)
  /// - [isEntradaReserva]: true = incrementa quantidadeReservada (entrega agendada)
  /// - [isSaidaReserva]: true = decrementa quantidadeReservada (libera reserva)
  /// - Quando nenhum flag estÃ¡ ativo: decrementa quantidadeAtual (venda imediata)
  Future<void> _movimentarEstoque({
    required FincoreDatabase db,
    required Uuid uuid,
    required String activeTenant,
    required String produtoId,
    required String pedidoId,
    required int quantidade,
    required String tipo,
    required String motivo,
    required String operadorId,
    required DateTime now,
    bool isEntradaFisica = false,
    bool isEntradaReserva = false,
    bool isSaidaFisica = false,
    bool isSaidaReserva = false,
    DateTime? dataEntregaPrevista,
  }) async {
    // 1. Busca ou cria o registro de estoque
    var estoque = await (db.select(db.estoqueProdutosTable)
          ..where((t) =>
              t.tenantId.equals(activeTenant) &
              t.produtoId.equals(produtoId) &
              t.deletedAt.isNull()))
        .getSingleOrNull();

    final estoqueId = estoque?.id ?? uuid.v4();

    if (estoque == null) {
      await db.into(db.estoqueProdutosTable).insertOnConflictUpdate(
        EstoqueProdutosTableCompanion.insert(
          id: estoqueId,
          tenantId: activeTenant,
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
      estoque = await (db.select(db.estoqueProdutosTable)
            ..where((t) => t.id.equals(estoqueId)))
          .getSingleOrNull();
    }

    final qFisicoAntes = estoque?.quantidadeAtual ?? 0;
    final qReservadaAntes = estoque?.quantidadeReservada ?? 0;

    // 2. Calcula novos saldos com base nos flags
    int qFisicoDepois = qFisicoAntes;
    int qReservadaDepois = qReservadaAntes;

    if (isEntradaFisica) {
      // ProduÃ§Ã£o, cancelamento, ajuste positivo
      qFisicoDepois += quantidade;
    } else if (isEntradaReserva) {
      // Reserva para entrega futura â€” nÃ£o toca fÃ­sico
      qReservadaDepois += quantidade;
    } else if (isSaidaFisica && isSaidaReserva) {
      // ExpediÃ§Ã£o: baixa fÃ­sico E reserva
      qFisicoDepois = (qFisicoDepois - quantidade).clamp(-999999, 999999);
      qReservadaDepois = (qReservadaDepois - quantidade).clamp(0, 999999);
    } else if (isSaidaReserva) {
      // LiberaÃ§Ã£o de reserva (cancelamento de pedido agendado)
      qReservadaDepois = (qReservadaDepois - quantidade).clamp(0, 999999);
    } else {
      // PadrÃ£o: venda imediata â€” baixa fÃ­sico
      qFisicoDepois = (qFisicoDepois - quantidade).clamp(-999999, 999999);
    }

    // 3. Atualiza os saldos
    await (db.update(db.estoqueProdutosTable)
          ..where((t) => t.id.equals(estoqueId)))
        .write(EstoqueProdutosTableCompanion(
      quantidadeAtual: Value(qFisicoDepois),
      quantidadeReservada: Value(qReservadaDepois),
      updatedAt: Value(now),
      updatedBy: Value(operadorId),
      syncVersion: const Value(1),
      syncStatus: const Value(SyncStatus.pending),
    ));

    // 4. Registra a movimentaÃ§Ã£o com snapshots completos
    final movId = uuid.v4();
    await db.into(db.movimentacoesEstoqueTable).insert(
      MovimentacoesEstoqueTableCompanion.insert(
        id: movId,
        tenantId: activeTenant,
        produtoId: produtoId,
        pedidoId: Value(pedidoId),
        tipo: tipo,
        quantidade: quantidade,
        quantidadeAntes: qFisicoAntes,
        quantidadeDepois: qFisicoDepois,
        quantidadeReservadaAntes: Value(qReservadaAntes),
        quantidadeReservadaDepois: Value(qReservadaDepois),
        motivo: Value(motivo),
        operadorId: Value(operadorId),
        dataHora: now,
        dataEntregaPrevista: Value(dataEntregaPrevista),
        syncVersion: const Value(1),
        syncStatus: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
        createdBy: operadorId,
        updatedBy: operadorId,
      ),
    );

    // 5. Outbox: movimentaÃ§Ã£o
    await db.into(db.outboxSync).insert(OutboxSyncCompanion.insert(
      tenantId: activeTenant,
      entity: 'movimentacao_estoque',
      entityId: movId,
      action: 'create',
      payload: jsonEncode({
        'id': movId,
        'tenantId': activeTenant,
        'produtoId': produtoId,
        'pedidoId': pedidoId,
        'tipo': tipo,
        'quantidade': quantidade,
        'quantidadeAntes': qFisicoAntes,
        'quantidadeDepois': qFisicoDepois,
        'quantidadeReservadaAntes': qReservadaAntes,
        'quantidadeReservadaDepois': qReservadaDepois,
        'motivo': motivo,
        'operadorId': operadorId,
        'dataHora': now.toIso8601String(),
        if (dataEntregaPrevista != null)
          'dataEntregaPrevista': dataEntregaPrevista.toIso8601String(),
        'syncVersion': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'createdBy': operadorId,
        'updatedBy': operadorId,
      }),
      status: 'pending',
      version: 1,
      createdAt: DateTime.now(),
    ));

    // 6. Outbox: saldo atualizado
    await db.into(db.outboxSync).insert(OutboxSyncCompanion.insert(
      tenantId: activeTenant,
      entity: 'estoque_produto',
      entityId: estoqueId,
      action: 'upsert',
      payload: jsonEncode({
        'id': estoqueId,
        'tenantId': activeTenant,
        'produtoId': produtoId,
        'quantidadeAtual': qFisicoDepois,
        'quantidadeReservada': qReservadaDepois,
        'quantidadeMinima': estoque?.quantidadeMinima ?? 0,
        'quantidadeMaxima': estoque?.quantidadeMaxima ?? 9999,
        'quantidadeProducaoLote': estoque?.quantidadeProducaoLote ?? 100,
        'diasCoberturaAlvo': estoque?.diasCoberturaAlvo ?? 3,
        'unidade': estoque?.unidade ?? 'un',
        'syncVersion': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'createdBy': operadorId,
        'updatedBy': operadorId,
      }),
      status: 'pending',
      version: 1,
      createdAt: DateTime.now(),
    ));
  }
}
