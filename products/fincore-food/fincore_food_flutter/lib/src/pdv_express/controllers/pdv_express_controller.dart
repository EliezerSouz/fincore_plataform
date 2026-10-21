import 'dart:async';
import 'dart:io';
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
import '../../shared/services/whatsapp_service.dart';
import '../../shared/services/whatsapp_order_ai_parser.dart';

import 'package:fincore_pricing/repository/tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/item_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/produto_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/categoria_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/common/pricing_models.dart';

import '../models/pdv_item.dart';
import '../models/pedido_draft.dart';
import '../domain/confirmar_venda_use_case.dart';

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

/// Resultado da justificativa de pedido retroativo
class JustificativaRetroativoResult {
  final String motivo;
  final bool movimentarEstoque;
  const JustificativaRetroativoResult({
    required this.motivo,
    required this.movimentarEstoque,
  });
}

/// Estrutura completa de saldos de estoque (Físico, Reservado, Produção Planejada, Saldo Projetado)
class StockInfo {
  final double fisico;
  final double reservado;
  final double producaoPlanejada;

  const StockInfo({
    this.fisico = 0,
    this.reservado = 0,
    this.producaoPlanejada = 0,
  });

  double get disponivel => fisico - reservado;
  double get projetado => disponivel + producaoPlanejada;
}

class DadosCliente {
  final String? id;
  final String? nome;
  final String? apelido;
  final String? telefone;
  final String? apelidoEndereco;

  const DadosCliente({
    this.id,
    this.nome,
    this.apelido,
    this.telefone,
    this.apelidoEndereco,
  });

  DadosCliente copyWith({
    String? id,
    String? nome,
    String? apelido,
    String? telefone,
    String? apelidoEndereco,
  }) {
    return DadosCliente(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      apelido: apelido ?? this.apelido,
      telefone: telefone ?? this.telefone,
      apelidoEndereco: apelidoEndereco ?? this.apelidoEndereco,
    );
  }

  /// Retorna o nome formatado com o apelido, ex: "João Paulo (Memac)"
  String? get nomeExibicao {
    if (nome == null) return null;
    if (apelido != null && apelido!.trim().isNotEmpty) {
      return '$nome (${apelido!.trim()})';
    }
    return nome;
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
  final int taxaServicoCentavos;
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
    this.taxaServicoCentavos = 0,
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
    int? taxaServicoCentavos,
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
      taxaServicoCentavos: taxaServicoCentavos ?? this.taxaServicoCentavos,
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
  // Repositórios do Core
  final ProdutoRepository produtoRepo;
  final CategoriaRepository categoriaRepo;
  final ClienteRepository clienteRepo;
  final LocalEntregaRepository localRepo;
  final FormaPagamentoRepository pagamentoRepo;
  final TaxaEntregaRepository taxaRepo;
  final EmpresaConfiguracaoRepository configRepo;

  // Repositórios e Engine do Pricing
  final TabelaPrecificacaoRepository tabelaRepo;
  final ItemTabelaPrecificacaoRepository itemRepo;
  final ProdutoTabelaPrecificacaoRepository assocRepo;
  final PricingEngine pricingEngine;
  final PrintUseCase printUseCase;

  // Contexto de Sessão
  final TenantContext tenantContext;
  final FincoreDatabase db;

  CoreEmpresaConfiguracao? _empresaConfig;
  CoreEmpresaConfiguracao? get empresaConfig => _empresaConfig;
  bool get modoDeliveryAtivo => _empresaConfig?.modoDeliveryAtivo ?? true;
  bool get modoComandasAtivo => _empresaConfig?.modoComandasAtivo ?? false;
  bool get clienteObrigatorioVenda => _empresaConfig?.clienteObrigatorioVenda ?? false;
  String get atendimentoPadrao => _empresaConfig?.atendimentoPadrao ?? 'Delivery';

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

  List<FormaPagamento> _formasPagamento = [];
  List<FormaPagamento> get formasPagamento => _formasPagamento;

  FormaPagamento? _selectedFormaPagamento;
  FormaPagamento? get selectedFormaPagamento => _selectedFormaPagamento;

  String _paymentMethod = 'Dinheiro';
  String get paymentMethod => _selectedFormaPagamento?.nome ?? _paymentMethod;

  String _canalOrigem = 'pdv_express';
  String get canalOrigem => _canalOrigem;
  void setCanalOrigem(String canal) {
    _canalOrigem = canal;
    notifyListeners();
  }

  // Split Payment (AUD-006): fatias de pagamento compostas
  final List<PagamentoItemDraft> _splitPayments = [];
  List<PagamentoItemDraft> get splitPayments => List.unmodifiable(_splitPayments);
  bool get isSplitPayment => _splitPayments.isNotEmpty;

  void addSplitPayment(PagamentoItemDraft payment) {
    _splitPayments.add(payment);
    notifyListeners();
  }

  void setSplitPayments(List<PagamentoItemDraft> list) {
    _splitPayments.clear();
    _splitPayments.addAll(list);
    notifyListeners();
  }

  void removeSplitPayment(String id) {
    _splitPayments.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void clearSplitPayments() {
    _splitPayments.clear();
    notifyListeners();
  }

  int get totalSplitCentavos => _splitPayments.fold(0, (acc, p) => acc + p.valorCentavos);
  int get restanteSplitCentavos => totalInCents - totalSplitCentavos;

  Map<String, double> _estoqueMap = {};
  Map<String, double> get estoqueMap => _estoqueMap;

  Map<String, StockInfo> _stockDetailsMap = {};
  Map<String, StockInfo> get stockDetailsMap => _stockDetailsMap;

  bool _autoPrintOnFinalize = false;
  bool get autoPrintOnFinalize => _autoPrintOnFinalize;

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
  int? _lastNumeroPedido;
  int? get lastNumeroPedido => _lastNumeroPedido;
  String? _lastPedidoId;
  String? get lastPedidoId => _lastPedidoId;
  Timer? _resetTimer;
  bool _isPersistingVenda = false;

  final OrdemPreparo? ordemParaEditar;
  final String? repetirPedidoId;
  final Cliente? clienteInicial;

  PdvExpressController({
    this.ordemParaEditar,
    this.repetirPedidoId,
    this.clienteInicial,
  })  : produtoRepo = DependencyInjection().get<ProdutoRepository>(),
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

  /// Construtor de Testes/Injeção manual
  PdvExpressController.custom({
    this.ordemParaEditar,
    this.repetirPedidoId,
    this.clienteInicial,
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
      _products = await produtoRepo.findAtivos();
      _categories = await categoriaRepo.findAll();
      _clientes = await clienteRepo.findAll();

      try {
        final estoques = await db.select(db.estoqueProdutosTable).get();
        final planejamentos = await (db.select(db.planejamentoProducaoTable)
              ..where((t) => t.status.isNotIn(['concluida', 'cancelada'])))
            .get();

        final Map<String, double> producaoMap = {};
        for (var p in planejamentos) {
          final pid = p.produtoId;
          final qtd = p.quantidadePlanejada.toDouble();
          producaoMap[pid] = (producaoMap[pid] ?? 0) + qtd;
        }

        final Map<String, StockInfo> stockDetails = {};
        final Map<String, double> estMap = {};

        for (var e in estoques) {
          final pid = e.produtoId;
          final fis = e.quantidadeAtual.toDouble();
          final res = e.quantidadeReservada.toDouble();
          final prod = producaoMap[pid] ?? 0.0;

          final info = StockInfo(
            fisico: fis,
            reservado: res,
            producaoPlanejada: prod,
          );
          stockDetails[pid] = info;
          estMap[pid] = info.projetado;
        }

        _stockDetailsMap = stockDetails;
        _estoqueMap = estMap;
      } catch (e) {
        debugPrint('[loadCatalog] Erro ao carregar estoques: $e');
      }

      // Garantir formas de pagamento padrão se a tabela estiver vazia
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
          'tipo': TipoFormaPagamento.dinheiro.name,
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
          'nome': 'PIX',
          'tipo': TipoFormaPagamento.pix.name,
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
              tipo: TipoFormaPagamento.dinheiro.name,
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
              nome: 'PIX',
              tipo: TipoFormaPagamento.pix.name,
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

      final todasFormas = await pagamentoRepo.findAll();
      _formasPagamento = todasFormas.where((f) => f.ativo).toList();
      _formasPagamento.sort((a, b) => a.ordem.compareTo(b.ordem));

      if (_selectedFormaPagamento == null && _formasPagamento.isNotEmpty) {
        final defaultDinheiro = _formasPagamento.where((f) => f.tipo == TipoFormaPagamento.dinheiro).firstOrNull;
        _selectedFormaPagamento = defaultDinheiro ?? _formasPagamento.first;
        _paymentMethod = _selectedFormaPagamento!.nome;
      }

      final configs = await configRepo.findAll();
      if (configs.isNotEmpty) {
        _empresaConfig = configs.first;

        if (_empresaConfig!.atendimentoPadrao == 'Mesa/Balcão') {
          _entrega = _entrega.copyWith(tipo: 'Retirada', taxaEntregaCentavos: 0);
        } else if (_empresaConfig!.atendimentoPadrao == 'Delivery') {
          _entrega = _entrega.copyWith(tipo: 'Entrega');
        }
      }

      if (ordemParaEditar != null) {
        final o = ordemParaEditar!;
        var pedidoRow = await (db.select(db.pedidosTable)
              ..where((t) => t.id.equals(o.pedidoId)))
            .getSingleOrNull();

        if (pedidoRow == null) {
          pedidoRow = await (db.select(db.pedidosTable)
                ..where((t) => t.id.equals(o.id)))
              .getSingleOrNull();
        }

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
                    : (o.prioridade == PrioridadeOrdem.vip
                        ? 'VIP'
                        : (o.prioridade == PrioridadeOrdem.programado
                            ? 'Entrega Programada'
                            : 'Normal')),
                dataHora: (pedidoRow.dataHoraEntregaPrevista ?? pedidoRow.dataHoraCriacao).toLocal(),
              );
            } catch (_) {
              _entrega = _entrega.copyWith(
                tipo: pedidoRow.tipoLogistica,
                prioridade: o.prioridade == PrioridadeOrdem.urgente
                    ? 'Urgente'
                    : (o.prioridade == PrioridadeOrdem.vip
                        ? 'VIP'
                        : (o.prioridade == PrioridadeOrdem.programado
                            ? 'Entrega Programada'
                            : 'Normal')),
                dataHora: (pedidoRow.dataHoraEntregaPrevista ?? pedidoRow.dataHoraCriacao).toLocal(),
              );
            }
          } else {
            _entrega = _entrega.copyWith(
              tipo: pedidoRow.tipoLogistica,
              prioridade: o.prioridade == PrioridadeOrdem.urgente
                  ? 'Urgente'
                  : (o.prioridade == PrioridadeOrdem.vip
                      ? 'VIP'
                      : (o.prioridade == PrioridadeOrdem.programado
                          ? 'Entrega Programada'
                          : 'Normal')),
              dataHora: (pedidoRow.dataHoraEntregaPrevista ?? pedidoRow.dataHoraCriacao).toLocal(),
            );
          }

          final pRow = pedidoRow;
          if (pRow != null) {
            if (pRow.formaPagamentoId != null) {
              _selectedFormaPagamento = _formasPagamento.where((f) => f.id == pRow.formaPagamentoId).firstOrNull;
            }
            if (_selectedFormaPagamento == null && pRow.formaPagamentoNome != null) {
              _paymentMethod = pRow.formaPagamentoNome!;
              _selectedFormaPagamento = _formasPagamento.where((f) => f.nome.toLowerCase() == pRow.formaPagamentoNome!.toLowerCase()).firstOrNull;
            } else if (_selectedFormaPagamento != null) {
              _paymentMethod = _selectedFormaPagamento!.nome;
            }
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
        }

        // Resiliência adicional: Se o carrinho estiver vazio mas a ordem tiver itens (ex: KDS / Cloud)
        if (_cart.isEmpty && o.itens.isNotEmpty) {
          _cart.clear();
          for (final it in o.itens) {
            _cart.add(PdvItem(
              productId: it.produtoId,
              name: it.nomeProduto,
              priceInCents: 0,
              quantity: it.quantidade,
            ));
          }
        }

        if (_cart.isNotEmpty || pedidoRow != null) {
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
                dataHora: (pedidoRow.dataHoraEntregaPrevista ?? DateTime.now()).toLocal(),
              );
            } catch (_) {
              _entrega = _entrega.copyWith(
                tipo: pedidoRow.tipoLogistica,
                prioridade: 'Normal',
                dataHora: (pedidoRow.dataHoraEntregaPrevista ?? DateTime.now()).toLocal(),
              );
            }
          } else {
            _entrega = _entrega.copyWith(
              tipo: pedidoRow.tipoLogistica,
              prioridade: 'Normal',
              dataHora: (pedidoRow.dataHoraEntregaPrevista ?? DateTime.now()).toLocal(),
            );
          }

          if (pedidoRow.formaPagamentoId != null) {
            _selectedFormaPagamento = _formasPagamento.where((f) => f.id == pedidoRow.formaPagamentoId).firstOrNull;
          }
          if (_selectedFormaPagamento == null && pedidoRow.formaPagamentoNome != null) {
            _paymentMethod = pedidoRow.formaPagamentoNome!;
            _selectedFormaPagamento = _formasPagamento.where((f) => f.nome.toLowerCase() == pedidoRow.formaPagamentoNome!.toLowerCase()).firstOrNull;
          } else if (_selectedFormaPagamento != null) {
            _paymentMethod = _selectedFormaPagamento!.nome;
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
      if (clienteInicial != null && ordemParaEditar == null && repetirPedidoId == null) {
        final c = clienteInicial!;
        _cliente = DadosCliente(
          id: c.id,
          nome: c.nome,
          apelido: c.apelido,
          telefone: c.telefone,
        );
        try {
          final locals = await localRepo.findByClienteId(c.id);
          if (locals.isNotEmpty) {
            final address = locals.firstWhere((l) => l.ativo, orElse: () => locals.first);
            final taxaCadastrada = await taxaRepo.findByBairro(address.bairro);
            final valorCentavos = taxaCadastrada?.valorCentavos ?? 0;
            _entrega = _entrega.copyWith(
              logradouro: address.logradouro,
              numero: address.numero,
              bairro: address.bairro,
              referencia: address.referencia,
              cep: address.cep,
              cidade: address.cidade.isNotEmpty ? address.cidade : _entrega.cidade,
              taxaEntregaCentavos: valorCentavos,
            );
          }
        } catch (_) {}
      }
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
    final servico = _entrega.taxaServicoCentavos;
    return subtotal + frete + servico;
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

  void selectFormaPagamento(FormaPagamento forma) {
    _selectedFormaPagamento = forma;
    _paymentMethod = forma.nome;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    final clean = method.toLowerCase().trim();
    final match = _formasPagamento.where((f) {
      if (f.nome.toLowerCase() == clean) return true;
      if (clean == 'pix' && (f.tipo == TipoFormaPagamento.pix || f.nome.toLowerCase().contains('pix'))) return true;
      if (clean == 'dinheiro' && (f.tipo == TipoFormaPagamento.dinheiro || f.nome.toLowerCase().contains('dinheiro'))) return true;
      if ((clean.contains('cartão') || clean.contains('cartao') || clean.contains('cart')) &&
          (f.tipo == TipoFormaPagamento.cartaoCredito || f.tipo == TipoFormaPagamento.cartaoDebito || f.nome.toLowerCase().contains('cart'))) {
        return true;
      }
      if ((clean.contains('consumo') || clean.contains('cortesia') || clean.contains('bonifica') || clean.contains('interno')) &&
          (f.tipo == TipoFormaPagamento.consumoInterno || f.isUsoInterno || !f.movimentaFinanceiro || f.nome.toLowerCase().contains('consumo'))) {
        return true;
      }
      return false;
    }).firstOrNull;
    if (match != null) {
      _selectedFormaPagamento = match;
    }
    notifyListeners();
  }

  /// Aplica no PDV os dados de um pedido interpretado por IA a partir do WhatsApp
  Future<void> aplicarPedidoIa(PedidoIaParsedResult pedidoIa, {bool substituirCarrinho = false}) async {
    if (substituirCarrinho) {
      _cart.clear();
    }

    _canalOrigem = 'whatsapp_ia';

    // 1. Cliente
    if (pedidoIa.clienteNome != null || pedidoIa.clienteTelefone != null) {
      String? clienteIdCadastrado;
      // Procura cliente existente pelo telefone se houver
      if (pedidoIa.clienteTelefone != null && pedidoIa.clienteTelefone!.isNotEmpty) {
        final telLimpo = pedidoIa.clienteTelefone!.replaceAll(RegExp(r'\D'), '');
        final achado = _clientes.where((c) {
          final cTel = c.telefone.replaceAll(RegExp(r'\D'), '');
          return cTel.isNotEmpty && (cTel == telLimpo || telLimpo.endsWith(cTel) || cTel.endsWith(telLimpo));
        }).firstOrNull;
        if (achado != null) {
          clienteIdCadastrado = achado.id;
        }
      }

      selectCustomer(
        pedidoIa.clienteNome ?? 'Cliente WhatsApp',
        pedidoIa.clienteTelefone ?? '',
        clienteId: clienteIdCadastrado,
      );
    }

    // 2. Destino / Entrega
    final tipoDestino = pedidoIa.tipoLogistica == 'Retirada' ? 'Retirada' : 'Entrega';
    int taxaCalculadaCentavos = 0;

    if (tipoDestino == 'Entrega' && pedidoIa.bairro != null && pedidoIa.bairro!.isNotEmpty) {
      try {
        final taxaRow = await taxaRepo.findByBairro(pedidoIa.bairro!);
        if (taxaRow != null) {
          taxaCalculadaCentavos = taxaRow.valorCentavos;
        }
      } catch (_) {}
    }

    final obsOriginal = _entrega.observacoes;
    final obsIa = '[Origem: WhatsApp / IA]${pedidoIa.observacoesGerais != null ? ' - ${pedidoIa.observacoesGerais}' : ''}';
    final obsFinal = obsOriginal.isNotEmpty ? '$obsOriginal | $obsIa' : obsIa;

    _entrega = _entrega.copyWith(
      tipo: tipoDestino,
      logradouro: pedidoIa.logradouro ?? _entrega.logradouro,
      numero: pedidoIa.numero ?? _entrega.numero,
      bairro: pedidoIa.bairro ?? _entrega.bairro,
      referencia: pedidoIa.referencia ?? _entrega.referencia,
      taxaEntregaCentavos: taxaCalculadaCentavos > 0 ? taxaCalculadaCentavos : _entrega.taxaEntregaCentavos,
      trocoParaCentavos: () => pedidoIa.trocoParaCentavos ?? _entrega.trocoParaCentavos,
      observacoes: obsFinal,
    );

    // 3. Forma de Pagamento
    if (pedidoIa.formaPagamento != null && pedidoIa.formaPagamento!.isNotEmpty) {
      setPaymentMethod(pedidoIa.formaPagamento!);
    }

    // 4. Adicionar Itens ao Carrinho
    for (final itemIa in pedidoIa.itens) {
      final prod = itemIa.produtoMatched;
      if (prod != null) {
        int unitPrice = 0;
        try {
          unitPrice = await pricingEngine.resolvePrice(
            produtoId: prod.id,
            quantidade: itemIa.quantidade.round(),
          );
        } catch (_) {
          unitPrice = itemIa.precoSugeridoCentavos > 0 ? itemIa.precoSugeridoCentavos : 150;
        }

        await addItem(prod.id, prod.nome, unitPrice, itemIa.quantidade);
      }
    }

    await _recalculatePrices();
    _state = _cart.isNotEmpty ? PdvState.drafting : PdvState.idle;
    notifyListeners();
  }

  Future<void> _recalculatePrices() async {
    final unitPrices = <String, int>{};
    final groupSummaries = <GroupPricingSummary>[];

    // ── PASSO 1: Mapear cada produto para sua tabela de precificação (Produto -> Tabela ou Categoria -> Tabela) ────────
    final Map<String, List<PdvItem>> itensPorTabela = {};
    final Map<String, String> nomesPorTabela = {};

    for (final item in _cart) {
      try {
        // 1.1 Tentar associação direta de produto
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

            try {
              final cat = await categoriaRepo.findById(categoryId);
              if (cat != null && cat.nome.isNotEmpty) {
                nomesPorTabela[tabelaId] = cat.nome;
              }
            } catch (_) {}
          } else {
            throw Exception('sem categoria');
          }
        } catch (_) {
          // Produto sem nenhuma tabela (nem direta nem por categoria)
          // Usa preço base do próprio produto ou o preço padrão
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

    // ── PASSO 2: Para cada tabela/grupo, calcular o preço por PRODUTO individual ──
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

        final totalQtyDoGrupo = itensDoGrupo.fold<double>(0, (sum, i) => sum + i.quantity);

        for (final item in itensDoGrupo) {
          try {
            final preco = await pricingEngine.resolvePrice(
              produtoId: item.productId,
              quantidade: item.quantity.toInt(),
              quantidadeGrupo: totalQtyDoGrupo.toInt(),
              canal: _entrega.tipo,
            );
            item.priceInCents = preco;
            unitPrices[item.productId] = preco;
          } catch (_) {
            unitPrices[item.productId] = item.priceInCents;
          }
        }

        final faixas = await itemRepo.findByTabelaId(tabelaId);
        faixas.sort((a, b) => a.quantidadeMinima.compareTo(b.quantidadeMinima));
        final minRequiredQty = faixas.isNotEmpty ? faixas.first.quantidadeMinima : 0;

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

        final precoReferencia = itensDoGrupo.isNotEmpty
            ? (unitPrices[itensDoGrupo.first.productId] ?? itensDoGrupo.first.priceInCents)
            : 0;

        final grupoNome = nomesPorTabela[tabelaId] ?? tabela.nome;

        double? qtyNeeded;
        int? potentialSavings;

        if (proximaFaixa != null) {
          qtyNeeded = (proximaFaixa.quantidadeMinima - totalQtyDoGrupo).clamp(0, double.infinity).toDouble();
          final priceDifference = precoReferencia - proximaFaixa.valorUnitarioCentavos;
          potentialSavings = (priceDifference * totalQtyDoGrupo).round();
        }

        groupSummaries.add(GroupPricingSummary(
          group: PricingGroup(id: tabelaId, name: grupoNome),
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
          nextRange: proximaFaixa != null
              ? PricingRange(
                  id: proximaFaixa.id,
                  groupId: tabelaId,
                  minQty: proximaFaixa.quantidadeMinima,
                  maxQty: proximaFaixa.quantidadeMaxima,
                  unitPriceInCents: proximaFaixa.valorUnitarioCentavos,
                )
              : null,
          qtyNeededForNextRange: qtyNeeded,
          potentialSavingsInCents: potentialSavings,
          minRequiredQty: minRequiredQty,
        ));
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

  /// Valida se todas as categorias/grupos com precificação por quantidade
  /// atingiram a quantidade mínima exigida para finalização do pedido.
  /// Retorna a mensagem descritiva de erro ou `null` caso válido.
  Future<String?> validarQuantidadesMinimasGrupos() async {
    await _recalculatePrices();

    final pendencias = <String>[];
    for (final summary in _pricingResult.groupSummaries) {
      if (summary.minRequiredQty > 1 && summary.totalQty < summary.minRequiredQty) {
        final totalAtual = summary.totalQty % 1 == 0
            ? summary.totalQty.toInt().toString()
            : summary.totalQty.toString();
        final faltam = (summary.minRequiredQty - summary.totalQty).toInt();
        pendencias.add(
          'A categoria "${summary.group.name}" exige no mínimo ${summary.minRequiredQty} un no pedido (atual: $totalAtual un. Faltam $faltam un).',
        );
      }
    }

    if (pendencias.isNotEmpty) {
      return pendencias.join('\n');
    }
    return null;
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
      return true; // Retirada / Balcão
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
    if (_formasPagamento.isNotEmpty) {
      final defaultDinheiro = _formasPagamento.where((f) => f.tipo == TipoFormaPagamento.dinheiro).firstOrNull;
      _selectedFormaPagamento = defaultDinheiro ?? _formasPagamento.first;
      _paymentMethod = _selectedFormaPagamento!.nome;
    } else {
      _selectedFormaPagamento = null;
      _paymentMethod = 'Dinheiro';
    }
    _errorMessage = null;
    _splitPayments.clear();
    _pixTimer?.cancel();
    _pixCountdown = 120;
    _passoAtual = 0;
    _state = PdvState.idle;
    _pricingResult = const PricingResult(unitPrices: {}, groupSummaries: []);
    _canalOrigem = 'pdv_express';
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

  /// Callback injetado pela View para solicitar justificativa de pedido retroativo.
  /// Recebe a data retroativa e deve retornar o resultado (JustificativaRetroativoResult) ou null para cancelar.
  Future<JustificativaRetroativoResult?> Function(DateTime dataRetroativa)? onPedidoRetroativo;

  Future<void> confirmPayment({bool autoPrint = false}) async {
    _autoPrintOnFinalize = autoPrint;
    if (_isPersistingVenda || _state == PdvState.confirming || _state == PdvState.completed) {
      return;
    }

    // ── Validação de data retroativa ────────────────────────────────────────
    final agora = DateTime.now();
    final dataEntrega = _entrega.dataHora;
    final minutosAtraso = agora.difference(dataEntrega).inMinutes;

    // Se a data de entrega está no passado (mais de 10 min de atraso real)
    if (minutosAtraso > 10 && onPedidoRetroativo != null) {
      final res = await onPedidoRetroativo!(dataEntrega);
      if (res == null || res.motivo.trim().isEmpty) {
        // Usuário cancelou ou não informou motivo → bloqueia
        return;
      }
      // Salva justificativa e opção de estoque para o pedido
      _motivoRetroativo = res.motivo.trim();
      _movimentarEstoqueRetroativo = res.movimentarEstoque;
    }

    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
    if (_paymentMethod == 'PIX' && !isDesktop) {
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

  String? _motivoRetroativo;
  bool? _movimentarEstoqueRetroativo;

  Future<String?> _resolveFormaPagamentoId(String methodLabel) async {
    try {
      final formas = await pagamentoRepo.findAll();
      final cleanLabel = methodLabel.toLowerCase().trim();
      
      final matched = formas.where((f) {
        final name = f.nome.toLowerCase().trim();
        if (cleanLabel.contains('pix') && (name.contains('pix') || f.tipo == TipoFormaPagamento.pix)) return true;
        if (cleanLabel.contains('dinheiro') && (name.contains('dinheiro') || f.tipo == TipoFormaPagamento.dinheiro)) return true;
        if (cleanLabel.contains('cart') && (name.contains('cart') || f.tipo == TipoFormaPagamento.cartaoCredito || f.tipo == TipoFormaPagamento.cartaoDebito)) return true;
        if ((cleanLabel.contains('consumo') || cleanLabel.contains('cortesia') || cleanLabel.contains('bonifica') || cleanLabel.contains('interno')) &&
            (name.contains('consumo') || name.contains('cortesia') || f.tipo == TipoFormaPagamento.consumoInterno || f.isUsoInterno || !f.movimentaFinanceiro)) {
          return true;
        }
        return name == cleanLabel || cleanLabel.contains(name) || name.contains(cleanLabel);
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

  Future<void> _persistVenda() async {
    if (_isPersistingVenda) return;
    _isPersistingVenda = true;
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
      final servico = _entrega.taxaServicoCentavos;
      final totalVenda = subtotal + frete + servico;

      int? distanciaMetros = _entrega.distanciaMetros;
      int? tempoDeslocamentoSegundos = _entrega.tempoDeslocamentoSegundos;

      if (_entrega.tipo == 'Entrega' && (distanciaMetros == null || tempoDeslocamentoSegundos == null)) {
        // NOTA: Cálculo de rota via Serverpod foi removido (arquitetura local-first).
        // A taxa de entrega é inserida manualmente pelo operador.
        // TODO: Reimplementar via Google Maps HTTP API diretamente.
        LogService.instance.info(LogModule.app, '[PDV] Distância não calculada — operador deve inserir taxa manualmente.');
      }

      final enderecoStr = _entrega.tipo == 'Entrega' ? jsonEncode({
        'logradouro': _entrega.logradouro,
        'numero': _entrega.numero,
        'bairro': _entrega.bairro,
        'cidade': _entrega.cidade,
        'cep': _entrega.cep,
        'referencia': _entrega.referencia,
        'taxaEntregaCentavos': _entrega.taxaEntregaCentavos,
        'taxaServicoCentavos': _entrega.taxaServicoCentavos,
        'distanciaMetros': distanciaMetros,
        'tempoDeslocamentoSegundos': tempoDeslocamentoSegundos,
      }) : null;

      final formaPgtoId = _selectedFormaPagamento?.id ?? (await _resolveFormaPagamentoId(_paymentMethod));
      final formaPgtoNome = _selectedFormaPagamento?.nome ?? _paymentMethod;
      final isUsoInterno = (_selectedFormaPagamento?.isUsoInterno ?? false) ||
          (_selectedFormaPagamento?.tipo == TipoFormaPagamento.consumoInterno) ||
          (_selectedFormaPagamento?.movimentaFinanceiro == false) ||
          formaPgtoNome.toLowerCase().contains('consumo') ||
          formaPgtoNome.toLowerCase().contains('cortesia') ||
          formaPgtoNome.toLowerCase().contains('bonifica');
      final isEdit = ordemParaEditar != null;

      final List<ItemPedidoData> oldItems = isEdit
          ? await (db.select(db.itensPedidoTable)
                ..where((t) => t.pedidoId.equals(ordemParaEditar!.pedidoId) & t.deletedAt.isNull()))
              .get()
          : [];

      final agora = DateTime.now();
      final dataPrevistaLocal = _entrega.dataHora;
      final minutosDiferenca = dataPrevistaLocal.difference(agora).inMinutes;

      // Um pedido é retroativo se a data/hora estiver no passado (mais de 10 min de atraso real)
      final isRetroativo = minutosDiferenca < -10;

      // Um pedido é agendado APENAS se for no futuro (mais de 10 min no futuro OU data futura) e não for retroativo
      final isFuturo = minutosDiferenca > 10;
      final isOutroDiaFuturo = (dataPrevistaLocal.year > agora.year) ||
          (dataPrevistaLocal.year == agora.year && dataPrevistaLocal.month > agora.month) ||
          (dataPrevistaLocal.year == agora.year && dataPrevistaLocal.month == agora.month && dataPrevistaLocal.day > agora.day);
      final isAgendado = !isRetroativo && (isFuturo || isOutroDiaFuturo || _entrega.prioridade == 'Entrega Programada');

      // Se há justificativa de retroativo, acrescenta às observações
      final obsBase = _entrega.observacoes ?? '';
      final infoEstoqueRetroativo = isRetroativo
          ? ((_movimentarEstoqueRetroativo ?? false) ? 'Estoque: Baixado' : 'Estoque: Não movimentado')
          : '';
      final obsComRetroativo = _motivoRetroativo != null && _motivoRetroativo!.isNotEmpty
          ? '${obsBase.isNotEmpty ? '$obsBase\n' : ''}[RETROATIVO] Justificativa: $_motivoRetroativo ($infoEstoqueRetroativo)'
          : obsBase;

      final movimentaEstoqueForma = _selectedFormaPagamento?.movimentaEstoque ?? true;
      final movimentarEstoque = isRetroativo ? (_movimentarEstoqueRetroativo ?? false) : movimentaEstoqueForma;
      _motivoRetroativo = null; // Limpa após uso
      _movimentarEstoqueRetroativo = null;

      final pedido = PedidoDraft(
        id: ordemParaEditar?.pedidoId,
        tenantId: activeTenant,
        clienteId: _cliente.id,
        tipoLogistica: _entrega.tipo,
        valorSubtotalCentavos: subtotal,
        valorTaxaEntregaCentavos: frete,
        valorTaxaServicoCentavos: servico,
        valorTotalCentavos: totalVenda,
        formaPagamentoId: formaPgtoId,
        trocoParaCentavos: _entrega.trocoParaCentavos,
        itens: draftItens,
        operadorId: activeUser,
        // Se for retroativo, registra a data e hora selecionada pelo usuário; caso contrário, registra o momento atual
        dataHoraCriacao: isRetroativo ? dataPrevistaLocal : agora,
        observacoes: obsComRetroativo.isEmpty ? null : obsComRetroativo,
      );

      final useCase = ConfirmarVendaUseCase(db: db, context: tenantContext);
      final nomeClienteFinal = _cliente.nomeExibicao ?? _cliente.nome;
      final result = await useCase.execute(ConfirmarVendaInput(
        pedido: pedido,
        itens: draftItens,
        paymentMethod: formaPgtoNome,
        pagamentos: _splitPayments.isNotEmpty ? _splitPayments : null,
        clienteNome: nomeClienteFinal,
        clienteTelefone: _cliente.telefone,
        enderecoJson: enderecoStr,
        ordemPreparoIdExistente: ordemParaEditar?.id,
        isEdit: isEdit,
        oldItems: oldItems,
        isEntregaAgendada: isAgendado,
        dataEntregaPrevista: isAgendado ? _entrega.dataHora : null,
        operadorNome: tenantContext.usuario.nome,
        observacao: _entrega.observacoes,
        movimentarEstoque: movimentarEstoque,
        isUsoInterno: isUsoInterno,
        isRetroativo: isRetroativo,
        canalOrigem: _canalOrigem,
      ));

      try {
        final auditLogRepo = DependencyInjection().get<AuditLogRepository>();
        await auditLogRepo.log(
          entityName: 'Pedido',
          entityId: pedido.id,
          userId: activeUser,
          action: isEdit ? 'UPDATE' : 'CREATE',
          entityDisplayName: 'Pedido #${result.numeroPedido}',
          entityModule: 'PDV',
          diff: {
            'cliente': nomeClienteFinal ?? 'Consumidor',
            'valorTotalCentavos': pedido.valorTotalCentavos,
            'tipoLogistica': pedido.tipoLogistica,
            'pagamento': _paymentMethod,
          },
        );
      } catch (e) {
        debugPrint('Erro ao gerar log de auditoria do pedido: $e');
      }

      if (_autoPrintOnFinalize) {
        try {
          final printData = PrintData(
            pedidoId: pedido.id,
            numeroPedido: result.numeroPedido,
            clienteNome: nomeClienteFinal,
            clienteTelefone: _cliente.telefone,
            tipoLogistica: pedido.tipoLogistica,
            endereco: _entrega.tipo == 'Entrega'
                ? '${_entrega.logradouro}, ${_entrega.numero}'
                : null,
            bairro: _entrega.bairro,
            formaPagamento: _paymentMethod,
            totalCentavos: pedido.valorTotalCentavos,
            taxaEntregaCentavos: pedido.valorTaxaEntregaCentavos,
            taxaServicoCentavos: pedido.valorTaxaServicoCentavos,
            trocoParaCentavos: pedido.trocoParaCentavos,
            itens: _cart.map((item) => PrintDataItem(
              nome: item.name,
              quantidade: item.quantity,
              precoUnitarioCentavos: item.priceInCents,
              totalCentavos: item.totalInCents,
            )).toList(),
            dataHora: _entrega.dataHora.toLocal(),
            observacao: _entrega.observacoes,
            status: 'confirmado',
          );

          await printUseCase.imprimirPedido(
            data: printData,
          );
        } catch (e) {
          debugPrint('Erro ao disparar impressão automática: $e');
        }
      }

      _lastVenda = pedido;
      _lastNumeroPedido = result.numeroPedido;
      _lastPedidoId = result.pedidoId;
      _state = PdvState.completed;
      notifyListeners();

      _resetTimer = Timer(const Duration(seconds: 4), () {
        reset();
      });

      // Mensageria WhatsApp no PDV Express é orquestrada com exclusividade pela tela
      // (pdv_express_screen.dart), respeitando o switch do operador, itens e dados de PIX.

    } catch (e) {
      _errorMessage = 'Falha ao persistir transação de venda: $e';
      _state = PdvState.error;
      notifyListeners();
    } finally {
      _isPersistingVenda = false;
    }
  }

  /// Cancela o reset e anula a venda gravada na Outbox e nas tabelas locais.
  ///
  /// ## Comportamento (P0 — Fase 2)
  /// - Tudo ocorre dentro de db.transaction(): marca cancelado, estorna estoque
  ///   e enfileira Outbox de cancelamento remoto.
  /// - Se o pedido já foi sincronizado, um Outbox de UPDATE com status=cancelado
  ///   é enfileirado para propagar o cancelamento ao Supabase.
  Future<void> undoLastVenda() async {
    final venda = _lastVenda;
    if (venda == null) return;

    _resetTimer?.cancel();

    try {
      final activeTenant = tenantContext.tenantId;
      final activeUser = tenantContext.usuario.id;
      final now = DateTime.now().toUtc();

      await db.transaction(() async {
        // 1. Marca pedido local como cancelado (soft delete reversível)
        await (db.update(db.pedidosTable)
              ..where((t) => t.id.equals(venda.id)))
            .write(PedidosTableCompanion(
          status: const Value('cancelado'),
          updatedAt: Value(now),
          deletedAt: Value(now),
          syncStatus: const Value(SyncStatus.pending),
        ));

        // 2. Marca itens como cancelados
        await (db.update(db.itensPedidoTable)
              ..where((t) => t.pedidoId.equals(venda.id)))
            .write(ItensPedidoTableCompanion(
          updatedAt: Value(now),
          deletedAt: Value(now),
        ));

        // 3. Estorno de estoque: desfaz baixas / reservas dos itens
        for (final item in venda.itens) {
          final produto = await (db.select(db.produtosTable)
                ..where((t) => t.id.equals(item.produtoId)))
              .getSingleOrNull();
          if (produto == null || !produto.controlaEstoque) continue;

          // Determina se era reserva (Entrega) ou saída física
          final eraReserva = venda.tipoLogistica == 'Entrega';

          var estoque = await (db.select(db.estoqueProdutosTable)
                ..where((t) =>
                    t.tenantId.equals(activeTenant) &
                    t.produtoId.equals(item.produtoId) &
                    t.deletedAt.isNull()))
              .getSingleOrNull();

          if (estoque == null) continue;

          final qFisicoAntes = estoque.quantidadeAtual;
          final qReservadaAntes = estoque.quantidadeReservada;
          final qty = item.quantidade.toInt();

          final int qFisicoDepois;
          final int qReservadaDepois;
          if (eraReserva) {
            // Estorno de reserva
            qFisicoDepois = qFisicoAntes;
            qReservadaDepois = (qReservadaAntes - qty).clamp(0, 999999);
          } else {
            // Devolve ao estoque físico
            qFisicoDepois = qFisicoAntes + qty;
            qReservadaDepois = qReservadaAntes;
          }

          await (db.update(db.estoqueProdutosTable)
                ..where((t) => t.id.equals(estoque.id)))
              .write(EstoqueProdutosTableCompanion(
            quantidadeAtual: Value(qFisicoDepois),
            quantidadeReservada: Value(qReservadaDepois),
            updatedAt: Value(now),
            updatedBy: Value(activeUser),
            syncStatus: const Value(SyncStatus.pending),
          ));

          // Movimentação de estorno
          final movId = const Uuid().v4();
          await db.into(db.movimentacoesEstoqueTable).insert(
            MovimentacoesEstoqueTableCompanion.insert(
              id: movId,
              tenantId: activeTenant,
              produtoId: item.produtoId,
              pedidoId: Value(venda.id),
              tipo: 'cancelamento',
              quantidade: qty,
              quantidadeAntes: qFisicoAntes,
              quantidadeDepois: qFisicoDepois,
              quantidadeReservadaAntes: Value(qReservadaAntes),
              quantidadeReservadaDepois: Value(qReservadaDepois),
              motivo: Value('Estorno de undo — Pedido #${venda.id.substring(0, 8)}'),
              operadorId: Value(activeUser),
              dataHora: now,
              syncVersion: const Value(1),
              syncStatus: SyncStatus.pending,
              createdAt: now,
              updatedAt: now,
              createdBy: activeUser,
              updatedBy: activeUser,
            ),
          );

          // Outbox da movimentação de estorno
          await db.into(db.outboxSync).insert(OutboxSyncCompanion.insert(
            tenantId: activeTenant,
            entity: 'movimentacao_estoque',
            entityId: movId,
            action: 'create',
            payload: jsonEncode({
              'id': movId,
              'tenantId': activeTenant,
              'produtoId': item.produtoId,
              'pedidoId': venda.id,
              'tipo': 'cancelamento',
              'quantidade': qty,
              'quantidadeAntes': qFisicoAntes,
              'quantidadeDepois': qFisicoDepois,
              'quantidadeReservadaAntes': qReservadaAntes,
              'quantidadeReservadaDepois': qReservadaDepois,
              'motivo': 'Estorno undo PDV',
              'operadorId': activeUser,
              'dataHora': now.toIso8601String(),
              'syncVersion': 1,
              'createdAt': now.toIso8601String(),
              'updatedAt': now.toIso8601String(),
              'createdBy': activeUser,
              'updatedBy': activeUser,
            }),
            status: 'pending',
            version: 1,
            createdAt: now,
          ));

          // Outbox: saldo atualizado de estoque_produto
          await db.into(db.outboxSync).insert(OutboxSyncCompanion.insert(
            tenantId: activeTenant,
            entity: 'estoque_produto',
            entityId: estoque.id,
            action: 'upsert',
            payload: jsonEncode({
              'id': estoque.id,
              'tenantId': activeTenant,
              'produtoId': item.produtoId,
              'quantidadeAtual': qFisicoDepois,
              'quantidadeReservada': qReservadaDepois,
              'quantidadeMinima': estoque.quantidadeMinima,
              'quantidadeMaxima': estoque.quantidadeMaxima,
              'quantidadeProducaoLote': estoque.quantidadeProducaoLote,
              'diasCoberturaAlvo': estoque.diasCoberturaAlvo,
              'unidade': estoque.unidade,
              'syncVersion': 1,
              'createdAt': now.toIso8601String(),
              'updatedAt': now.toIso8601String(),
              'createdBy': activeUser,
              'updatedBy': activeUser,
            }),
            status: 'pending',
            version: 1,
            createdAt: now,
          ));
        }

        // 4. Cancelamento remoto do pedido no Outbox
        // Remove outboxes anteriores pendentes do mesmo pedido para evitar concorrência
        await (db.delete(db.outboxSync)
              ..where((t) =>
                  t.entityId.equals(venda.id) &
                  t.status.equals('pending')))
            .go();

        await db.into(db.outboxSync).insert(OutboxSyncCompanion.insert(
          tenantId: activeTenant,
          entity: 'Pedido',
          entityId: venda.id,
          action: 'update',
          payload: jsonEncode({
            'id': venda.id,
            'tenantId': activeTenant,
            'status': 'cancelado',
            'deletedAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
            'updatedBy': activeUser,
            'syncVersion': 2,
          }),
          status: 'pending',
          version: 2,
          createdAt: now,
        ));

        // 5. Estorno do lançamento financeiro (se existir)
        final lancamentos = await (db.select(db.lancamentosFinanceirosTable)
              ..where((t) =>
                  t.tenantId.equals(activeTenant) &
                  t.pedidoId.equals(venda.id) &
                  t.tipo.equals('receita') &
                  t.deletedAt.isNull()))
            .get();

        for (final lanc in lancamentos) {
          await (db.update(db.lancamentosFinanceirosTable)
                ..where((t) => t.id.equals(lanc.id)))
              .write(LancamentosFinanceirosTableCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            updatedBy: Value(activeUser),
            syncStatus: const Value(SyncStatus.pending),
          ));

          await db.into(db.outboxSync).insert(OutboxSyncCompanion.insert(
            tenantId: activeTenant,
            entity: 'lancamento_financeiro',
            entityId: lanc.id,
            action: 'DELETE',
            payload: jsonEncode({
              'id': lanc.id,
              'tenantId': activeTenant,
              'deletedAt': now.toIso8601String(),
            }),
            status: 'pending',
            version: 2,
            createdAt: now,
          ));
        }
        try { DependencyInjection().get<SyncEngine>().processPendingQueue(); } catch (_) {}
      });

      // 6. Restaura o carrinho ao estado da venda anterior
      _cart.clear();
      for (final item in venda.itens) {
        _cart.add(PdvItem(
          productId: item.produtoId,
          name: item.nome,
          priceInCents: item.valorUnitarioCentavos,
          quantity: item.quantidade,
        ));
      }

      if (venda.formaPagamentoId != null) {
        _selectedFormaPagamento = _formasPagamento.where((f) => f.id == venda.formaPagamentoId).firstOrNull;
      }
      _paymentMethod = _selectedFormaPagamento?.nome ?? 'Dinheiro';
      _state = PdvState.selectingPayment;
      _passoAtual = 2;
      // Processamento de Mensageria de Cancelamento (Fase D2: Integrado e Seguro)
      _processarWhatsAppCancelamentoPdv(
        pedidoId: venda.id,
        numeroPedido: venda.id.length >= 8 ? venda.id.substring(0, 8) : venda.id,
        tipoLogistica: venda.tipoLogistica,
        clienteNome: _cliente.nomeExibicao ?? _cliente.nome ?? 'Consumidor',
        clienteTelefone: _cliente.telefone,
        clienteId: _cliente.id,
        formaPagamento: _paymentMethod,
        valorTotalCentavos: venda.valorTotalCentavos,
      );

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


  /// Processa eventos de cancelamento de pedido no PDV (Fase D2: Seguro e Desacoplado)
  void _processarWhatsAppCancelamentoPdv({
    required String pedidoId,
    required String numeroPedido,
    required String tipoLogistica,
    required String clienteNome,
    required String? clienteTelefone,
    required String? clienteId,
    required String formaPagamento,
    required int valorTotalCentavos,
  }) {
    scheduleMicrotask(() async {
      try {
        final activeTenant = tenantContext.tenantId;
        final empresaUsarWa = _empresaConfig?.usarWhatsApp ?? true;
        if (!empresaUsarWa) return;

        bool clienteAceita = false;
        if (clienteId != null && clienteId.isNotEmpty) {
          final clienteData = await clienteRepo.findById(clienteId);
          clienteAceita = clienteData?.aceitaWhatsapp ?? false;
        }

        await WhatsAppService.processarEventoPedidoAutomatico(
          tenantId: activeTenant,
          pedidoId: pedidoId,
          numeroPedido: numeroPedido,
          eventoId: WhatsAppService.kEventoPedidoCancelado,
          tipoLogistica: tipoLogistica,
          formaPagamento: formaPagamento,
          statusPagamento: 'CANCELADO',
          rawPhone: clienteTelefone,
          clienteNome: clienteNome,
          clienteAceitaWhatsapp: clienteAceita,
          valorTotalCentavos: valorTotalCentavos,
          eventInstanceId: 'pdv_${pedidoId}_cancelado',
        );
      } catch (e) {
        debugPrint('[PDV Express] Mensageria de cancelamento isolada por segurança: $e');
      }
    });
  }

  @override
  void dispose() {
    _pixTimer?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }
}
