import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fincore_core/fincore_core.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_pricing/repository/item_tabela_precificacao_repository.dart';
import 'package:fincore_pricing/repository/produto_tabela_precificacao_repository.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_food_flutter/src/shared/services/dados_ordem_parser.dart';
import '../../shared/services/permissao_service.dart';
import '../../estoque/controllers/estoque_controller.dart';
import '../../shared/data/sync/supabase_sync_service.dart';
import '../../shared/services/sound_service.dart';
import '../../cap/printing/print_capability.dart';
import '../../shared/services/whatsapp_service.dart';

class DeadlineInfo {
  final DateTime horarioEntrega;
  final int tempoPreparacaoMinutos;
  final int tempoDeslocamentoMinutos;
  final int margemSegurancaMinutos;
  final DateTime horarioInicioRecomendado;
  /// Horário limite para o pedido estar PRONTO (entrega - desloc - margem)
  final DateTime horarioProntoAte;
  /// Horário limite para SAIR para entrega (entrega - desloc)
  final DateTime horarioSairAte;
  final String statusLabel;
  final Color statusColor;
  final String tempoRestanteLabel;
  final bool isImmediate;

  const DeadlineInfo({
    required this.horarioEntrega,
    required this.tempoPreparacaoMinutos,
    required this.tempoDeslocamentoMinutos,
    required this.margemSegurancaMinutos,
    required this.horarioInicioRecomendado,
    required this.horarioProntoAte,
    required this.horarioSairAte,
    required this.statusLabel,
    required this.statusColor,
    required this.tempoRestanteLabel,
    required this.isImmediate,
  });
}

/// Representa o total de produção necessária para um produto específico.
class ItemProducaoNecessaria {
  final String produtoId;
  final String nomeProduto;
  final double quantidade;
  final String unidade;

  const ItemProducaoNecessaria({
    required this.produtoId,
    required this.nomeProduto,
    required this.quantidade,
    required this.unidade,
  });
}

/// Estatísticas de pedidos para exibição nos dias do calendário
class EstatisticasDiaCalendario {
  final int total;
  final int atrasados;
  final int finalizados;
  final int emAberto;

  const EstatisticasDiaCalendario({
    this.total = 0,
    this.atrasados = 0,
    this.finalizados = 0,
    this.emAberto = 0,
  });

  bool get temAtraso => atrasados > 0;
  bool get todosFinalizados => total > 0 && finalizados == total;
  bool get temEmAberto => emAberto > 0;
}

/// Controller do estado da Central de Pedidos.
///
/// Responsabilidades:
/// - Carregar e filtrar ordens por data e origem
/// - Mover status de ordens (com auditoria)
/// - Cancelar ordens com confirmação
/// - Calcular Produção Necessária (itens pendentes + em preparo + prontos)
/// - Manter mapa de preços dos produtos para exibição de totais
/// - Refresh periódico automático (15s)
class CentralPedidosController extends ChangeNotifier {
  final OrdemPreparoRepository _ordemRepo;

  List<OrdemPreparo> _todasOrdens = [];
  List<OrdemPreparo> _filteredOrdens = [];
  List<PedidoData> _historicoPedidos = [];
  Map<String, int> _precosProdutosMap = {};
  Map<String, int> _tempoPreparoProdutosMap = {};
  Map<String, PedidoData> _pedidosMap = {};
  int _margemSegurancaMinutos = 10;

  bool _isLoading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  String _selectedOrigem = 'Todos';

  Timer? _refreshTimer;
  StreamSubscription? _syncSub;

  Set<String> _knownOrderIds = {};
  bool _isFirstLoadCompleted = false;
  OrdemPreparo? _lastNewOrder;
  OrdemPreparo? get lastNewOrder => _lastNewOrder;

  CentralPedidosController({OrdemPreparoRepository? ordemRepo})
      : _ordemRepo =
            ordemRepo ?? DependencyInjection().get<OrdemPreparoRepository>() {
    carregarOrdens();
    // Refresh automático a cada 15s (fallback) + escuta instantânea de eventos Realtime
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 15), (_) => carregarOrdens());
    try {
      final syncService = DependencyInjection().get<SupabaseSyncService>();
      _syncSub = syncService.onDataSynced.listen((_) => carregarOrdens());
    } catch (_) {}
  }

  List<OrdemPreparo> get ordensWebAguardandoAprovacao {
    return _todasOrdens
        .where((o) => isPedidoAguardandoAprovacao(o))
        .toList();
  }

  void _checkNewOrders(List<OrdemPreparo> list) {
    final currentIds = list.map((o) => o.id).toSet();
    if (_isFirstLoadCompleted) {
      final newOrders = list.where((o) =>
        !_knownOrderIds.contains(o.id) &&
        o.status != StatusOrdemPreparo.cancelado
      ).toList();

      if (newOrders.isNotEmpty) {
        _lastNewOrder = newOrders.first;
        final temWeb = newOrders.any((o) => isPedidoAguardandoAprovacao(o));
        if (temWeb) {
          SoundService.playUrgentSound();
        } else {
          SoundService.playNewOrderSound();
        }
      }
    } else {
      _isFirstLoadCompleted = true;
    }
    _knownOrderIds = currentIds;
  }

  final Set<String> _alertedAttentionOrders = {};
  final Set<String> _alertedUrgentOrders = {};

  void checkProximityAudioAlerts() {
    if (!SoundService.enabled) return;
    final now = DateTime.now();

    final activeOrdens = _filteredOrdens.where((o) =>
        o.status == StatusOrdemPreparo.pendente ||
        o.status == StatusOrdemPreparo.emPreparo ||
        o.status == StatusOrdemPreparo.pronto).toList();

    for (final o in activeOrdens) {
      final deadline = calculateDeadline(o);
      final remainingMins = deadline.horarioEntrega.difference(now).inMinutes;

      if (remainingMins <= 15 && !_alertedUrgentOrders.contains(o.id)) {
        _alertedUrgentOrders.add(o.id);
        _alertedAttentionOrders.add(o.id);
        SoundService.playUrgentSound();
      } else if (remainingMins <= 30 && !_alertedAttentionOrders.contains(o.id)) {
        _alertedAttentionOrders.add(o.id);
        SoundService.playAttentionSound();
      }
    }
  }

  /// Imprime em lote todos os pedidos da data selecionada
  Future<int> imprimirPedidosDoDia({
    required PrintUseCase printUseCase,
  }) async {
    int count = 0;
    final ordensDoDia = _filteredOrdens.where((o) => o.status != StatusOrdemPreparo.cancelado).toList();

    for (final o in ordensDoDia) {
      final pRow = _pedidosMap[o.pedidoId];
      final parsed = DadosOrdemKanban.fromOrdem(o);
      final numeroPedido = getNumeroPedido(o.pedidoId) ?? pRow?.numeroPedido;

      if (pRow != null) {
        try {
          final printData = PrintData(
            pedidoId: pRow.id,
            numeroPedido: numeroPedido,
            clienteNome: parsed.cliente,
            clienteTelefone: parsed.telefone,
            tipoLogistica: pRow.tipoLogistica,
            endereco: parsed.endereco,
            bairro: parsed.bairro,
            formaPagamento: parsed.pagamento,
            totalCentavos: pRow.valorTotalCentavos,
            taxaEntregaCentavos: pRow.valorTaxaEntregaCentavos,
            trocoParaCentavos: pRow.trocoParaCentavos,
            itens: o.itens.map((item) {
              final unitPrice = _precosProdutosMap[item.produtoId] ?? 0;
              return PrintDataItem(
                nome: item.nomeProduto,
                quantidade: item.quantidade,
                precoUnitarioCentavos: unitPrice,
                totalCentavos: (unitPrice * item.quantidade).toInt(),
              );
            }).toList(),
            dataHora: pRow.dataHoraEntregaPrevista?.toLocal()
                ?? parsed.dataAgendada
                ?? pRow.dataHoraCriacao.toLocal(),
            observacao: parsed.observacoesLimpa,
            status: pRow.status,
          );

          await printUseCase.imprimirPedido(data: printData, usuario: 'lote_dia');
          count++;
        } catch (e) {
          debugPrint('[imprimirPedidosDoDia] Erro ao imprimir pedido ${pRow.id}: $e');
        }
      }
    }
    return count;
  }

  // ── Getters públicos ────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;
  String get selectedOrigem => _selectedOrigem;
  List<OrdemPreparo> get todasOrdens => _todasOrdens;
  List<PedidoData> get historicoPedidos => _historicoPedidos;
  List<OrdemPreparo> get filteredOrdens => _filteredOrdens;
  Map<String, PedidoData> get pedidosMap => _pedidosMap;

  String? get _userRole {
    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      return tenantCtx.hasContext ? tenantCtx.usuario.role : null;
    } catch (_) {
      return null;
    }
  }

  bool get _podeVerFinanceiro => PermissaoService.podeVerFinanceiro(_userRole);

  List<OrdemPreparo> get pendentes =>
      _filteredOrdens.where((o) => o.status == StatusOrdemPreparo.pendente).toList();

  List<OrdemPreparo> get emPreparo =>
      _filteredOrdens.where((o) => o.status == StatusOrdemPreparo.emPreparo).toList();

  List<OrdemPreparo> get prontos =>
      _filteredOrdens.where((o) => o.status == StatusOrdemPreparo.pronto).toList();

  List<OrdemPreparo> get saiuParaEntrega =>
      _filteredOrdens.where((o) => o.status == StatusOrdemPreparo.saiuParaEntrega).toList();

  List<OrdemPreparo> get entregues =>
      _filteredOrdens.where((o) => o.status == StatusOrdemPreparo.entregue).toList();

  List<OrdemPreparo> get cancelados =>
      _filteredOrdens.where((o) => o.status == StatusOrdemPreparo.cancelado).toList();

  /// Calcula os itens que precisam ser produzidos para os pedidos ativos.
  /// Considera apenas ordens: pendente + emPreparo + pronto (excluindo entregue e cancelado).
  List<ItemProducaoNecessaria> get producaoNecessaria {
    final statusAtivos = {
      StatusOrdemPreparo.pendente,
      StatusOrdemPreparo.emPreparo,
      StatusOrdemPreparo.pronto,
    };
    final totais = <String, ItemProducaoNecessaria>{};
    for (final ordem in _filteredOrdens) {
      if (!statusAtivos.contains(ordem.status)) continue;
      for (final item in ordem.itens) {
        if (totais.containsKey(item.produtoId)) {
          final existing = totais[item.produtoId]!;
          totais[item.produtoId] = ItemProducaoNecessaria(
            produtoId: item.produtoId,
            nomeProduto: item.nomeProduto,
            quantidade: existing.quantidade + item.quantidade,
            unidade: item.unidade,
          );
        } else {
          totais[item.produtoId] = ItemProducaoNecessaria(
            produtoId: item.produtoId,
            nomeProduto: item.nomeProduto,
            quantidade: item.quantidade,
            unidade: item.unidade,
          );
        }
      }
    }
    final lista = totais.values.toList();
    lista.sort((a, b) => b.quantidade.compareTo(a.quantidade));
    return lista;
  }

  // ── KPIs ────────────────────────────────────────────────────────────

  int get totalPedidos =>
      _filteredOrdens.where((o) => o.status != StatusOrdemPreparo.cancelado).toList().length;

  int get totalEntregas {
    int n = 0;
    for (final o in _filteredOrdens) {
      if (o.status == StatusOrdemPreparo.cancelado) continue;
      final p = DadosOrdemKanban.fromOrdem(o);
      if (p.tipoLogistica.toLowerCase().contains('entrega') ||
          p.tipoLogistica.toLowerCase().contains('delivery')) n++;
    }
    return n;
  }

  int get totalRetiradas => totalPedidos - totalEntregas;

  int get faturamentoCentavos {
    if (!_podeVerFinanceiro) return 0;
    int total = 0;
    for (final o in _filteredOrdens) {
      if (o.status == StatusOrdemPreparo.cancelado) continue;
      final p = DadosOrdemKanban.fromOrdem(o);
      int val = p.totalCentavos;
      if (val == 0) {
        for (final item in o.itens) {
          val += ((_precosProdutosMap[item.produtoId] ?? 0) * item.quantidade).round();
        }
      }
      total += val;
    }
    return total;
  }

  double get ticketMedioCentavos {
    if (!_podeVerFinanceiro) return 0.0;
    final ativos = _filteredOrdens
        .where((o) => o.status != StatusOrdemPreparo.cancelado)
        .length;
    return ativos > 0 ? faturamentoCentavos / ativos : 0.0;
  }

  // ── Acesso ao mapa de preços ─────────────────────────────────────────

  int precoUnitarioCentavos(String produtoId) {
    if (!_podeVerFinanceiro) return 0;
    return _precosProdutosMap[produtoId] ?? 0;
  }

  int totalOrdemCentavos(OrdemPreparo o) {
    if (!_podeVerFinanceiro) return 0;
    final p = DadosOrdemKanban.fromOrdem(o);
    int val = p.totalCentavos;
    if (val == 0) {
      for (final item in o.itens) {
        val += ((_precosProdutosMap[item.produtoId] ?? 0) * item.quantidade).round();
      }
    }
    return val;
  }

  // ── Carregamento ─────────────────────────────────────────────────────

  Future<void> carregarOrdens() async {
    _error = null;
    if (!_isLoading) {
      // Silent reload (já carregado antes)
      try {
        final list = await _ordemRepo.findAll();
        await _carregarPrecos(); // ← Mantém mapa de preparo atualizado
        await _carregarDadosAuxiliares(list);
        await carregarListaPedidos();
        if (_isDisposed) return;
        _todasOrdens = list;
        _checkNewOrders(list);
        _applyFilters();
        notifyListeners();
      } catch (e) {
        if (_isDisposed) return;
        debugPrint('[CentralPedidosController] Erro no refresh: $e');
      }
      return;
    }

    // Primeiro carregamento
    try {
      final list = await _ordemRepo.findAll();
      await _carregarPrecos();
      await _carregarDadosAuxiliares(list);
      await carregarListaPedidos();
      if (_isDisposed) return;
      _todasOrdens = list;
      _checkNewOrders(list);
      _applyFilters();
    } catch (e) {
      if (_isDisposed) return;
      _error = 'Erro ao carregar pedidos: $e';
      debugPrint('[CentralPedidosController] $e');
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> carregarListaPedidos() async {
    try {
      final db = DependencyInjection().get<FincoreDatabase>();
      final tenantId = _ordemRepo.activeTenantId;
      final rows = await (db.select(db.pedidosTable)
            ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull().equals(true))
            ..orderBy([(t) => OrderingTerm(expression: t.dataHoraCriacao, mode: OrderingMode.desc)]))
          .get();
      _historicoPedidos = rows;
    } catch (e) {
      debugPrint('[CentralPedidosController] Erro ao carregar histórico: $e');
    }
  }

  int? getNumeroPedido(String pedidoId) {
    for (final p in _historicoPedidos) {
      if (p.id == pedidoId) {
        return p.numeroPedido;
      }
    }
    return null;
  }

  Future<void> _carregarDadosAuxiliares(List<OrdemPreparo> ordens) async {
    try {
      final db = DependencyInjection().get<FincoreDatabase>();
      
      // 1. Carregar margem de segurança configurada
      final configRepo = DependencyInjection().get<EmpresaConfiguracaoRepository>();
      final configs = await configRepo.findAll();
      if (configs.isNotEmpty) {
        _margemSegurancaMinutos = configs.first.margemSegurancaMinutos;
      } else {
        _margemSegurancaMinutos = 10;
      }

      // 2. Carregar e mapear dados do Pedido (para extração do enderecoJson cacheado)
      final pedidoIds = ordens.map((o) => o.pedidoId).toSet().toList();
      if (pedidoIds.isNotEmpty) {
        final pedidosRows = await (db.select(db.pedidosTable)
              ..where((t) => t.id.isIn(pedidoIds) & t.deletedAt.isNull().equals(true)))
            .get();
        _pedidosMap = {for (final row in pedidosRows) row.id: row};
      } else {
        _pedidosMap = {};
      }
    } catch (e) {
      debugPrint('[CentralPedidosController] Erro ao carregar dados auxiliares: $e');
    }
  }

  Future<void> _carregarPrecos() async {
    try {
      final prodRepo = DependencyInjection().get<ProdutoRepository>();
      final assocRepo = DependencyInjection().get<ProdutoTabelaPrecificacaoRepository>();
      final itemTabRepo = DependencyInjection().get<ItemTabelaPrecificacaoRepository>();

      final prods = await prodRepo.findAll();
      final assocs = await assocRepo.findAll();
      final itensTabela = await itemTabRepo.findAll();

      final map = <String, int>{};
      final mapTempo = <String, int>{};
      for (final p in prods) {
        mapTempo[p.id] = p.tempoMedioMinutos;
        
        final assoc =
            assocs.where((a) => a.produtoId == p.id && a.ativo).firstOrNull;
        if (assoc != null) {
          final item = itensTabela
              .where((i) =>
                  i.tabelaPrecificacaoId == assoc.tabelaPrecificacaoId)
              .firstOrNull;
          if (item != null) {
            map[p.id] = item.valorUnitarioCentavos;
          }
        }
      }
      _precosProdutosMap = map;
      _tempoPreparoProdutosMap = mapTempo;
    } catch (e) {
      debugPrint('[CentralPedidosController] Erro ao carregar preços: $e');
    }
  }

  int getTempoPreparacaoMinutos(OrdemPreparo o) {
    if (o.itens.isEmpty) return 0;
    int maxTempo = 0;
    for (final item in o.itens) {
      final t = _tempoPreparoProdutosMap[item.produtoId] ?? 0;
      if (t > maxTempo) maxTempo = t;
    }
    return maxTempo > 0 ? maxTempo : 10;
  }

  ({int distanciaMetros, int tempoDeslocamentoMinutos}) getRouteInfo(OrdemPreparo o) {
    final pedido = _pedidosMap[o.pedidoId];
    if (pedido != null && pedido.enderecoJson != null) {
      try {
        final data = jsonDecode(pedido.enderecoJson!) as Map<String, dynamic>;
        final dist = data['distanciaMetros'] as int?;
        final durSeconds = data['tempoDeslocamentoSegundos'] as int?;
        if (dist != null && durSeconds != null) {
          // Respeita 0 seg = endereço próximo (mesmo CEP, mesma rua, etc.)
          return (
            distanciaMetros: dist,
            tempoDeslocamentoMinutos: (durSeconds / 60).round(),
          );
        }
        // enderecoJson existe mas sem dados de rota: endereço manual sem cálculo
        // → sem deslocamento (usuário entrou o endereço manualmente)
        return (distanciaMetros: 0, tempoDeslocamentoMinutos: 0);
      } catch (_) {}
    }
    // Sem enderecoJson: entrega sem endereço cadastrado → usa fallback conservador
    return (
      distanciaMetros: 5000,
      tempoDeslocamentoMinutos: 15,
    );
  }

  String _formatAtraso(int minutos) {
    if (minutos <= 0) return '0 min';
    
    if (minutos >= 1440) {
      final dias = minutos ~/ 1440;
      return '$dias dia(s)';
    }
    
    final horas = minutos ~/ 60;
    final mins = minutos % 60;
    if (horas > 0) {
      final minsStr = mins.toString().padLeft(2, '0');
      return '$horas:$minsStr hrs';
    }
    return '$minutos min';
  }

  DeadlineInfo calculateDeadline(OrdemPreparo o) {
    final parsed = DadosOrdemKanban.fromOrdem(o);

    // ── Resolução da data de entrega (prioridade decrescente) ────────────
    // 1. Campo direto no banco (pedidos novos, pós-fix)
    // 2. Parse textual das observações (tag `agendado:`)
    // 3. Fallback legado: código antigo gravava dataHoraCriacao = dataEntrega
    //    → se dataHoraCriacao do pedido for >30 min no futuro vs criadaEm da ordem,
    //      provavelmente é o horário de entrega armazenado com o bug
    final pedido = _pedidosMap[o.pedidoId];
    DateTime? dataAgendada = parsed.dataAgendada
        ?? pedido?.dataHoraEntregaPrevista?.toLocal();

    if (dataAgendada == null && pedido != null) {
      final pedidoCriadaLocal = pedido.dataHoraCriacao.toLocal();
      final ordemCriadaLocal  = o.criadaEm.toLocal();
      final diffMin = pedidoCriadaLocal.difference(ordemCriadaLocal).inMinutes;
      // Se dataHoraCriacao está >30 min no futuro vs criadaEm → bug legado detectado
      if (diffMin > 30) {
        dataAgendada = pedidoCriadaLocal;
        debugPrint('[Deadline] Fallback legado: usando dataHoraCriacao como entrega prevista '
            '(diff=${diffMin}min) para pedido ${o.pedidoId}');
      }
    }

    final isImmediate = dataAgendada == null;

    final tempoPrep = getTempoPreparacaoMinutos(o);

    int tempoDesloc = 0;
    final isDelivery = parsed.tipoLogistica.toLowerCase().contains('entrega') ||
                       parsed.tipoLogistica.toLowerCase().contains('delivery');
    if (isDelivery) {
      final route = getRouteInfo(o);
      // Respeita 0 min quando a rota calculada indica endereço próximo.
      // O fallback de 15 min só é aplicado internamente no getRouteInfo
      // quando não há nenhum enderecoJson cadastrado.
      tempoDesloc = route.tempoDeslocamentoMinutos;
    }

    final margem = _margemSegurancaMinutos;

    // ── Horários chave para cada etapa ──────────────────────────────────
    // targetEntrega:    quando o produto precisa chegar/estar disponível
    // prontoAte:        até quando precisa estar PRONTO (antes de sair)
    // sairAte:          até quando precisa SAIR (entrega - desloc)
    // inicioRecomendado: quando deve COMEÇAR o preparo
    final DateTime targetEntrega;
    final DateTime inicioRecomendado;

    final criadaEmLocal = o.criadaEm.toLocal();

    if (isImmediate) {
      // Pedido imediato: entrega estimada a partir de agora
      targetEntrega = criadaEmLocal.add(Duration(minutes: tempoPrep + tempoDesloc + margem));
      inicioRecomendado = criadaEmLocal;
    } else {
      targetEntrega = dataAgendada;
      inicioRecomendado = targetEntrega.subtract(Duration(minutes: tempoPrep + tempoDesloc + margem));
    }

    // Horário em que deve estar pronto (antes de sair ou ser retirado)
    final prontoAte = targetEntrega.subtract(Duration(minutes: tempoDesloc + margem));
    // Horário em que deve sair (só relevante para entregas)
    final sairAte = targetEntrega.subtract(Duration(minutes: tempoDesloc));

    final agora = DateTime.now();
    String statusLabel = '';
    Color statusColor = const Color(0xFF10B981);
    String tempoRestanteLabel = '';

    // ── Pedidos Concluídos / Cancelados ─────────────────────────────────
    final isFinalizado = o.status == StatusOrdemPreparo.entregue ||
        (pedido != null && {'entregue', 'concluido', 'concluído', 'finalizado'}.contains(pedido.status.toLowerCase().trim()));
    final isCancelado = o.status == StatusOrdemPreparo.cancelado ||
        (pedido != null && pedido.status.toLowerCase() == 'cancelado');

    if (isFinalizado || isCancelado) {
      statusLabel = isCancelado ? 'Cancelado' : 'Entregue';
      statusColor = const Color(0xFF6B7280);
      tempoRestanteLabel = isCancelado
          ? 'Pedido cancelado'
          : 'Pedido entregue';

    // ── Pedido Pronto: urgência em relação ao horário de SAÍDA ──────────
    } else if (o.status == StatusOrdemPreparo.pronto) {
      if (!isImmediate) {
        final refTime = isDelivery ? sairAte : targetEntrega;
        final diferenca = refTime.difference(agora).inMinutes;
        if (diferenca > 10) {
          statusLabel = 'Aguardando saída';
          statusColor = const Color(0xFF10B981);
          tempoRestanteLabel = isDelivery
              ? 'Sair em ${_formatAtraso(diferenca)}'
              : 'Retirada em ${_formatAtraso(diferenca)}';
        } else if (diferenca > 0) {
          statusLabel = isDelivery ? 'Sair em breve' : 'Retirada em breve';
          statusColor = const Color(0xFFF59E0B);
          tempoRestanteLabel = 'Faltam ${_formatAtraso(diferenca)}';
        } else if (diferenca >= -5) {
          statusLabel = isDelivery ? 'Sair agora!' : 'Retirada agora!';
          statusColor = const Color(0xFFEF4444);
          tempoRestanteLabel = isDelivery ? 'Saída imediata' : 'Cliente aguardando';
        } else {
          statusLabel = 'Entrega atrasada';
          statusColor = const Color(0xFFDC2626);
          tempoRestanteLabel = 'Atrasado há ${_formatAtraso(-diferenca)}';
        }
      } else {
        statusLabel = 'Pronto';
        statusColor = const Color(0xFF10B981);
        tempoRestanteLabel = 'Aguardando retirada/entrega';
      }

    // ── Em Preparo: urgência em relação ao horário de FICAR PRONTO ───────
    } else if (o.status == StatusOrdemPreparo.emPreparo) {
      if (!isImmediate) {
        final diferenca = prontoAte.difference(agora).inMinutes;
        if (diferenca > 10) {
          statusLabel = 'Em preparação';
          statusColor = const Color(0xFF10B981);
          tempoRestanteLabel = 'Pronto em ${_formatAtraso(diferenca)}';
        } else if (diferenca > 0) {
          statusLabel = 'Finalizar em breve';
          statusColor = const Color(0xFFF59E0B);
          tempoRestanteLabel = 'Faltam ${_formatAtraso(diferenca)}';
        } else if (diferenca >= -5) {
          statusLabel = 'Finalizar agora!';
          statusColor = const Color(0xFFEF4444);
          tempoRestanteLabel = 'Prazo de preparo atingido';
        } else {
          statusLabel = 'Preparo atrasado';
          statusColor = const Color(0xFFDC2626);
          tempoRestanteLabel = 'Atrasado há ${_formatAtraso(-diferenca)}';
        }
      } else {
        statusLabel = 'Em preparação';
        statusColor = const Color(0xFF10B981);
        tempoRestanteLabel = 'Em preparação';
      }

    // ── Pendente: urgência em relação ao horário de INÍCIO ───────────────
    } else {
      if (isImmediate) {
        final minutosCriado = agora.difference(criadaEmLocal).inMinutes;
        if (minutosCriado >= 0 && minutosCriado <= 2) {
          statusLabel = 'Iniciar agora';
          statusColor = const Color(0xFFEF4444);
          tempoRestanteLabel = 'Pedido imediato';
        } else if (minutosCriado > 2) {
          statusLabel = 'Produção atrasada';
          statusColor = const Color(0xFFDC2626);
          tempoRestanteLabel = 'Atrasado há ${_formatAtraso(minutosCriado)}';
        } else {
          statusLabel = 'Agendado';
          statusColor = const Color(0xFFF59E0B);
          tempoRestanteLabel = 'Entrega programada';
        }
      } else {
        // Urgência relativa ao horário de INÍCIO recomendado
        final diferenca = inicioRecomendado.difference(agora).inMinutes;
        if (diferenca > 15) {
          statusLabel = 'Dentro do prazo';
          statusColor = const Color(0xFF10B981);
          tempoRestanteLabel = 'Iniciar em ${_formatAtraso(diferenca)}';
        } else if (diferenca > 0 && diferenca <= 15) {
          statusLabel = 'Iniciar em breve';
          statusColor = const Color(0xFFF59E0B);
          tempoRestanteLabel = 'Iniciar em ${_formatAtraso(diferenca)}';
        } else if (diferenca <= 0 && diferenca >= -5) {
          statusLabel = 'Iniciar agora!';
          statusColor = const Color(0xFFEF4444);
          tempoRestanteLabel = 'Hora de iniciar o preparo';
        } else {
          statusLabel = 'Produção atrasada';
          statusColor = const Color(0xFFDC2626);
          tempoRestanteLabel = 'Atrasado há ${_formatAtraso(-diferenca)}';
        }
      }
    }

    return DeadlineInfo(
      horarioEntrega: targetEntrega,
      tempoPreparacaoMinutos: tempoPrep,
      tempoDeslocamentoMinutos: tempoDesloc,
      margemSegurancaMinutos: margem,
      horarioInicioRecomendado: inicioRecomendado,
      horarioProntoAte: prontoAte,
      horarioSairAte: sairAte,
      statusLabel: statusLabel,
      statusColor: statusColor,
      tempoRestanteLabel: tempoRestanteLabel,
      isImmediate: isImmediate,
    );
  }

  void _applyFilters() {
    final filtradas = _todasOrdens.where((o) {
      if (o.status == StatusOrdemPreparo.cancelado) return false;
      final pRow = _pedidosMap[o.pedidoId];
      if (pRow != null && pRow.status.toLowerCase() == 'cancelado') return false;

      final parsed = DadosOrdemKanban.fromOrdem(o);
      final dataOperacional = parsed.dataAgendada
          ?? pRow?.dataHoraEntregaPrevista?.toLocal()
          ?? o.criadaEm.toLocal();
      final matchesDate = dataOperacional.year == _selectedDate.year &&
          dataOperacional.month == _selectedDate.month &&
          dataOperacional.day == _selectedDate.day;

      final matchesOrigem = _selectedOrigem == 'Todos' ||
          parsed.tipoLogistica.toLowerCase() ==
              _selectedOrigem.toLowerCase();

      return matchesDate && matchesOrigem;
    }).toList();

    // Ordenação cronológica baseada no horário de início recomendado para produção
    filtradas.sort((a, b) {
      final dlA = calculateDeadline(a);
      final dlB = calculateDeadline(b);
      return dlA.horarioInicioRecomendado.compareTo(dlB.horarioInicioRecomendado);
    });

    _filteredOrdens = filtradas;
  }

  // ── Filtros públicos ─────────────────────────────────────────────────

  void mudarDia(int offset) {
    _selectedDate = _selectedDate.add(Duration(days: offset));
    _applyFilters();
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    _applyFilters();
    notifyListeners();
  }

  void setOrigem(String origem) {
    _selectedOrigem = origem;
    _applyFilters();
    notifyListeners();
  }

  /// Retorna um mapa com a contagem de pedidos operacionais/agendados por dia (DateTime sem hora -> quantidade)
  Map<DateTime, int> getContagemPedidosPorDia() {
    final Map<DateTime, int> counts = {};
    for (final o in _todasOrdens) {
      if (o.status == StatusOrdemPreparo.cancelado) continue;
      final pRow = _pedidosMap[o.pedidoId];
      if (pRow != null && pRow.status.toLowerCase() == 'cancelado') continue;

      final parsed = DadosOrdemKanban.fromOrdem(o);
      final dataOperacional = parsed.dataAgendada
          ?? pRow?.dataHoraEntregaPrevista?.toLocal()
          ?? o.criadaEm.toLocal();
      final key = DateTime(dataOperacional.year, dataOperacional.month, dataOperacional.day);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  /// Retorna estatísticas detalhadas de pedidos por dia (total, atrasados, finalizados, em aberto)
  Map<DateTime, EstatisticasDiaCalendario> getEstatisticasPedidosPorDia() {
    final Map<DateTime, List<OrdemPreparo>> ordensPorDia = {};
    for (final o in _todasOrdens) {
      if (o.status == StatusOrdemPreparo.cancelado) continue;
      final pRow = _pedidosMap[o.pedidoId];
      if (pRow != null && pRow.status.toLowerCase() == 'cancelado') continue;

      final parsed = DadosOrdemKanban.fromOrdem(o);
      final dataOperacional = parsed.dataAgendada
          ?? pRow?.dataHoraEntregaPrevista?.toLocal()
          ?? o.criadaEm.toLocal();
      final key = DateTime(dataOperacional.year, dataOperacional.month, dataOperacional.day);
      ordensPorDia.putIfAbsent(key, () => []).add(o);
    }

    final Map<DateTime, EstatisticasDiaCalendario> stats = {};
    for (final entry in ordensPorDia.entries) {
      final date = entry.key;
      final list = entry.value;

      int atrasados = 0;
      int finalizados = 0;
      int emAberto = 0;

      for (final o in list) {
        final pRow = _pedidosMap[o.pedidoId];
        final isFinalizado = o.status == StatusOrdemPreparo.entregue ||
            (pRow != null && {'entregue', 'concluido', 'concluído', 'finalizado'}.contains(pRow.status.toLowerCase().trim()));

        if (isFinalizado) {
          finalizados++;
        } else {
          final dl = calculateDeadline(o);
          final isAtrasado = dl.statusColor == const Color(0xFFDC2626) ||
              dl.statusColor == const Color(0xFFEF4444) ||
              dl.statusLabel.toLowerCase().contains('atrasad');
          if (isAtrasado) {
            atrasados++;
          } else {
            emAberto++;
          }
        }
      }

      stats[date] = EstatisticasDiaCalendario(
        total: list.length,
        atrasados: atrasados,
        finalizados: finalizados,
        emAberto: emAberto,
      );
    }

    return stats;
  }

  // ── Transição de status ───────────────────────────────────────────────

  String statusLabel(StatusOrdemPreparo s) {
    switch (s) {
      case StatusOrdemPreparo.pendente:
        return 'Pendente';
      case StatusOrdemPreparo.emPreparo:
        return 'Em Preparo';
      case StatusOrdemPreparo.pronto:
        return 'Pronto';
      case StatusOrdemPreparo.saiuParaEntrega:
        return 'Saiu p/ Entrega';
      case StatusOrdemPreparo.entregue:
        return 'Entregue';
      case StatusOrdemPreparo.cancelado:
        return 'Cancelado';
    }
  }

  bool isReversao(OrdemPreparo ordem, StatusOrdemPreparo novoStatus) {
    return (novoStatus.index < ordem.status.index) ||
        (ordem.status == StatusOrdemPreparo.cancelado &&
            novoStatus != StatusOrdemPreparo.cancelado);
  }

  /// Atualiza o status de um pedido diretamente na [pedidosTable], sem
  /// necessitar de uma [OrdemPreparo] correspondente no Kanban do dia.
  /// Ideal para pedidos antigos visíveis no histórico.
  Future<void> atualizarStatusPedidoDireto(
    String pedidoId,
    String novoStatus,
  ) async {
    final db = DependencyInjection().get<FincoreDatabase>();
    final now = DateTime.now().toUtc();

    final sanitizedPedidoStatus = novoStatus;

    await (db.update(db.pedidosTable)
          ..where((t) => t.id.equals(pedidoId)))
        .write(PedidosTableCompanion(
      status: Value(sanitizedPedidoStatus),
      updatedAt: Value(now),
      syncStatus: const Value(SyncStatus.pending),
    ));

    // Atualiza também a OrdemPreparo correspondente, se existir
    final matchingOrdem = _todasOrdens
        .cast<OrdemPreparo?>()
        .firstWhere((o) => o?.pedidoId == pedidoId, orElse: () => null);

    if (matchingOrdem != null) {
      final statusEnum = switch (novoStatus.toLowerCase()) {
        'confirmado' || 'pendente' || 'recebido' || 'rascunho' => StatusOrdemPreparo.pendente,
        'em_preparo' || 'empreparo' || 'preparando' => StatusOrdemPreparo.emPreparo,
        'pronto' => StatusOrdemPreparo.pronto,
        'saiu_para_entrega' || 'saiuparaentrega' || 'em_transito' || 'emtransito' => StatusOrdemPreparo.saiuParaEntrega,
        'entregue' || 'concluido' || 'finalizado' => StatusOrdemPreparo.entregue,
        'cancelado' => StatusOrdemPreparo.cancelado,
        _ => StatusOrdemPreparo.values.firstWhere(
            (s) => s.name.toLowerCase() == novoStatus.toLowerCase(),
            orElse: () => StatusOrdemPreparo.pendente,
          ),
      };
      try {
        await moverStatus(matchingOrdem, statusEnum);
        return; // moverStatus já chama recalcular + notifyListeners
      } catch (_) {}
    }

    // Enfileira alteração no Outbox para sincronização com o Supabase
    try {
      final outboxService = DependencyInjection().get<OutboxService>();
      final tenantId = _ordemRepo.activeTenantId;
      final pedRow = await (db.select(db.pedidosTable)..where((t) => t.id.equals(pedidoId))).getSingleOrNull();

      await outboxService.enqueue(
        entity: 'Pedido',
        entityId: pedidoId,
        action: 'update',
        payload: {
          'id': pedidoId,
          'tenantId': tenantId,
          'status': sanitizedPedidoStatus,
          if (pedRow != null) ...{
            'valorSubtotalCentavos': pedRow.valorSubtotalCentavos,
            'valorTaxaEntregaCentavos': pedRow.valorTaxaEntregaCentavos,
            'valorTaxaServicoCentavos': pedRow.valorTaxaServicoCentavos,
            'valorTotalCentavos': pedRow.valorTotalCentavos,
          },
          'updatedAt': now.toIso8601String(),
        },
        version: (pedRow?.syncVersion ?? 1) + 1,
      );
    } catch (e) {
      debugPrint('[PEDIDOS] Erro ao enfileirar outbox em atualizarStatusPedidoDireto: $e');
    }

    // Recalcula reservas e atualiza o histórico
    try {
      final estoqueCtrl = DependencyInjection().get<EstoqueController>();
      await estoqueCtrl.recalcularReservasEEstoques();
    } catch (e) {
      debugPrint('[PEDIDOS] Erro ao recalcular reservas: $e');
    }
    await carregarOrdens();
  }

  Future<void> moverStatus(
    OrdemPreparo ordem,
    StatusOrdemPreparo novoStatus, {
    String? motivo,
  }) async {
    final updated = OrdemPreparo(
      id: ordem.id,
      tenantId: ordem.tenantId,
      pedidoId: ordem.pedidoId,
      itens: ordem.itens,
      status: novoStatus,
      prioridade: ordem.prioridade,
      operadorId: ordem.operadorId,
      criadaEm: ordem.criadaEm,
      iniciadaEm: novoStatus == StatusOrdemPreparo.emPreparo
          ? (ordem.iniciadaEm ?? DateTime.now())
          : ordem.iniciadaEm,
      concluidaEm: (novoStatus == StatusOrdemPreparo.pronto || novoStatus == StatusOrdemPreparo.entregue)
          ? (ordem.concluidaEm ?? DateTime.now())
          : ordem.concluidaEm,
      canceladaEm: novoStatus == StatusOrdemPreparo.cancelado
          ? (ordem.canceladaEm ?? DateTime.now())
          : ordem.canceladaEm,
      tempoEstimadoSegundos: ordem.tempoEstimadoSegundos,
      observacoes: ordem.observacoes,
      metadata: ordem.metadata.copyWith(
        updatedAt: DateTime.now().toUtc(),
        syncStatus: SyncStatus.pending,
      ),
    );

    await _ordemRepo.save(updated);

    // Sincroniza o status na tabela principal de pedidos e atualiza o estoque (reservas e expedição)
    try {
      final db = DependencyInjection().get<FincoreDatabase>();
      final now = DateTime.now().toUtc();
      final statusStr = switch (novoStatus) {
        StatusOrdemPreparo.pendente        => isPedidoAguardandoAprovacao(ordem) ? 'pendente' : 'confirmado',
        StatusOrdemPreparo.emPreparo       => 'em_preparo',
        StatusOrdemPreparo.pronto          => 'pronto',
        StatusOrdemPreparo.saiuParaEntrega => 'saiu_para_entrega',
        StatusOrdemPreparo.entregue        => 'entregue',
        StatusOrdemPreparo.cancelado       => 'cancelado',
      };

      final statusOrdemStr = switch (novoStatus) {
        StatusOrdemPreparo.pendente        => 'pendente',
        StatusOrdemPreparo.emPreparo       => 'em_preparo',
        StatusOrdemPreparo.pronto          => 'pronto',
        StatusOrdemPreparo.saiuParaEntrega => 'saiu_para_entrega',
        StatusOrdemPreparo.entregue        => 'entregue',
        StatusOrdemPreparo.cancelado       => 'cancelado',
      };

      final obsCancelamento = (novoStatus == StatusOrdemPreparo.cancelado && motivo != null && motivo.trim().isNotEmpty)
          ? Value(motivo.trim())
          : const Value<String?>.absent();

      await (db.update(db.pedidosTable)
            ..where((t) => t.id.equals(ordem.pedidoId)))
          .write(PedidosTableCompanion(
        status: Value(statusStr),
        observacoes: obsCancelamento,
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ));

      // Se o pedido estava ENTREGUE e está sendo revertido/modificado, estorna as baixas físicas de expedição anteriores
      if (ordem.status == StatusOrdemPreparo.entregue && novoStatus != StatusOrdemPreparo.entregue) {
        final movsExp = await (db.select(db.movimentacoesEstoqueTable)
              ..where((t) =>
                  t.tenantId.equals(ordem.tenantId) &
                  t.pedidoId.equals(ordem.pedidoId) &
                  t.tipo.equals('expedicao') &
                  t.deletedAt.isNull()))
            .get();

        for (final m in movsExp) {
          await (db.update(db.movimentacoesEstoqueTable)
                ..where((t) => t.id.equals(m.id)))
              .write(MovimentacoesEstoqueTableCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            syncStatus: const Value(SyncStatus.pending),
          ));

          try {
            final outboxService = DependencyInjection().get<OutboxService>();
            await outboxService.enqueue(
              entity: 'movimentacao_estoque',
              entityId: m.id,
              action: 'DELETE',
              payload: {
                'id': m.id,
                'tenantId': ordem.tenantId,
                'deletedAt': now.toIso8601String(),
              },
              version: 1,
            );
          } catch (_) {}
        }
      }

      // Registrar no outbox a alteração do status do pedido e da ordem de preparo para sincronização com o Supabase
      try {
        final outboxService = DependencyInjection().get<OutboxService>();

        // Busca syncVersion atual do pedido local para incrementar corretamente
        final pedidoRow = await (db.select(db.pedidosTable)
              ..where((t) => t.id.equals(ordem.pedidoId)))
            .getSingleOrNull();
        final pedidoSyncVersion = (pedidoRow?.syncVersion ?? 0) + 1;

        // Atualiza syncVersion do pedido localmente
        await (db.update(db.pedidosTable)
              ..where((t) => t.id.equals(ordem.pedidoId)))
            .write(PedidosTableCompanion(
          syncVersion: Value(pedidoSyncVersion),
        ));

        // Atualiza também os caches em memória do controller para refletir o status imediatamente na UI
        if (_pedidosMap.containsKey(ordem.pedidoId)) {
          final current = _pedidosMap[ordem.pedidoId]!;
          _pedidosMap[ordem.pedidoId] = current.copyWith(
            status: statusStr,
            syncVersion: pedidoSyncVersion,
            updatedAt: now,
          );
        }
        final hIdx = _historicoPedidos.indexWhere((p) => p.id == ordem.pedidoId);
        if (hIdx != -1) {
          _historicoPedidos[hIdx] = _historicoPedidos[hIdx].copyWith(
            status: statusStr,
            syncVersion: pedidoSyncVersion,
            updatedAt: now,
          );
        }

        await outboxService.enqueue(
          entity: 'Pedido',
          entityId: ordem.pedidoId,
          action: 'update',
          payload: {
            'id': ordem.pedidoId,
            'tenantId': ordem.tenantId,
            'status': statusStr,
            if (novoStatus == StatusOrdemPreparo.cancelado && motivo != null && motivo.trim().isNotEmpty) ...{
              'observacoes': motivo.trim(),
              'motivoCancelamento': motivo.trim(),
              'motivo_cancelamento': motivo.trim(),
            },
            'syncVersion': pedidoSyncVersion,
            'updatedAt': now.toIso8601String(),
          },
          version: pedidoSyncVersion,
        );

        // Busca syncVersion atual da ordem de preparo local para incrementar
        final ordemRow = await (db.select(db.ordensPreparoTable)
              ..where((t) => t.id.equals(updated.id)))
            .getSingleOrNull();
        final ordemSyncVersion = (ordemRow?.syncVersion ?? 0) + 1;

        // Atualiza syncVersion da ordem localmente
        if (ordemRow != null) {
          await (db.update(db.ordensPreparoTable)
                ..where((t) => t.id.equals(updated.id)))
              .write(OrdensPreparoTableCompanion(
            syncVersion: Value(ordemSyncVersion),
            updatedAt: Value(now),
          ));
        }

        final kdsItensJson = jsonEncode(updated.itens.map((i) => i.toJson()).toList());
        await outboxService.enqueue(
          entity: 'OrdemPreparo',
          entityId: updated.id,
          action: 'update',
          payload: {
            'id': updated.id,
            'tenantId': updated.tenantId,
            'pedidoId': updated.pedidoId,
            'itensJson': kdsItensJson,
            'status': statusOrdemStr,
            'prioridade': updated.prioridade.name,
            'operadorId': updated.operadorId,
            'criadaEm': updated.criadaEm.toUtc().toIso8601String(),
            if (updated.iniciadaEm != null) 'iniciadaEm': updated.iniciadaEm!.toUtc().toIso8601String(),
            if (updated.concluidaEm != null) 'concluidaEm': updated.concluidaEm!.toUtc().toIso8601String(),
            if (updated.canceladaEm != null) 'canceladaEm': updated.canceladaEm!.toUtc().toIso8601String(),
            'tempoEstimadoSegundos': updated.tempoEstimadoSegundos,
            'observacoes': updated.observacoes,
            'syncVersion': ordemSyncVersion,
            'updatedAt': now.toIso8601String(),
          },
          version: ordemSyncVersion,
        );

        // Dispara push imediato para o Supabase sem aguardar o timer de 30s
        try {
          final syncEngine = DependencyInjection().get<SyncEngine>();
          unawaited(syncEngine.processPendingQueue().catchError((_) => const SyncResult(
                successCount: 0,
                failureCount: 0,
                hasPendingAfter: true,
              )));
        } catch (_) {}
      } catch (e) {
        debugPrint('[PEDIDOS] Erro ao registrar status no outbox: $e');
      }

      // Estorno ou reativação do lançamento financeiro do pedido
      try {
        final activeUser = ordem.operadorId ?? '';
        final outboxService = DependencyInjection().get<OutboxService>();
        if (novoStatus == StatusOrdemPreparo.cancelado) {
          // Cancelamento: deleta logicamente os lançamentos ativos vinculados a este pedido
          final lancamentos = await (db.select(db.lancamentosFinanceirosTable)
                ..where((t) =>
                    t.tenantId.equals(ordem.tenantId) &
                    t.pedidoId.equals(ordem.pedidoId) &
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

            try {
              await outboxService.enqueue(
                entity: 'lancamento_financeiro',
                entityId: lanc.id,
                action: 'DELETE',
                payload: {
                  'id': lanc.id,
                  'tenantId': ordem.tenantId,
                  'deletedAt': now.toIso8601String(),
                },
                version: 1,
              );
            } catch (err) {
              debugPrint('[PEDIDOS] Erro ao colocar estorno financeiro no outbox: $err');
            }
          }
        } else if (ordem.status == StatusOrdemPreparo.cancelado && novoStatus != StatusOrdemPreparo.cancelado) {
          // Reversão do cancelamento: reativa os lançamentos que estavam cancelados para este pedido
          final lancamentos = await (db.select(db.lancamentosFinanceirosTable)
                ..where((t) =>
                    t.tenantId.equals(ordem.tenantId) &
                    t.pedidoId.equals(ordem.pedidoId) &
                    t.deletedAt.isNotNull()))
              .get();

          for (final lanc in lancamentos) {
            await (db.update(db.lancamentosFinanceirosTable)
                  ..where((t) => t.id.equals(lanc.id)))
                .write(LancamentosFinanceirosTableCompanion(
              deletedAt: const Value(null),
              updatedAt: Value(now),
              updatedBy: Value(activeUser),
              syncStatus: const Value(SyncStatus.pending),
            ));

            try {
              await outboxService.enqueue(
                entity: 'lancamento_financeiro',
                entityId: lanc.id,
                action: 'update',
                payload: {
                  'id': lanc.id,
                  'tenantId': ordem.tenantId,
                  'deletedAt': null,
                  'updatedAt': now.toIso8601String(),
                },
                version: 1,
              );
            } catch (err) {
              debugPrint('[PEDIDOS] Erro ao colocar reativação financeira no outbox: $err');
            }
          }
        }
      } catch (e) {
        debugPrint('[PEDIDOS] Erro ao processar estorno/reativação financeira: $e');
      }

      // Dispara recálculo de reservas e expedição física no EstoqueController
      final estoqueCtrl = DependencyInjection().get<EstoqueController>();
      await estoqueCtrl.recalcularReservasEEstoques();
    } catch (e) {
      debugPrint('[PEDIDOS] Erro ao sincronizar status com estoque: $e');
    }

    // Resolve o nome do operador primeiro (usado em titulo, descricao e audit)
    String? operadorNome;
    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      if (tenantCtx.hasContext) {
        operadorNome = tenantCtx.usuario.nome;
      }
    } catch (_) {}

    final isRev = isReversao(ordem, novoStatus);
    final isCancelamento = novoStatus == StatusOrdemPreparo.cancelado;
    final isAprovacao = ordem.status == StatusOrdemPreparo.pendente && !isCancelamento;
    final titulo = isCancelamento
        ? 'Pedido Cancelado'
        : (isAprovacao
            ? 'Pedido Aprovado'
            : (isRev ? 'Status Revertido' : 'Status Atualizado'));
    final descricao = isCancelamento
        ? 'Cancelado por "${operadorNome ?? 'Operador'}". Motivo: ${motivo ?? 'Não informado'}'
        : (isAprovacao
            ? 'Pedido online aprovado por "${operadorNome ?? 'Operador'}" e encaminhado para preparação.'
            : (isRev
                ? 'Passou de "${statusLabel(ordem.status)}" para "${statusLabel(novoStatus)}". Motivo: $motivo'
                : 'Passou de "${statusLabel(ordem.status)}" para "${statusLabel(novoStatus)}"'));

    await _ordemRepo.registrarHistorico(
      ordem.id,
      titulo,
      descricao,
      operadorNome: operadorNome,
    );

    // Grava no audit log quando há motivo (cancelamentos e reversões)
    if (motivo != null && motivo.isNotEmpty) {
      try {
        final db = DependencyInjection().get<FincoreDatabase>();
        final auditNow = DateTime.now().toUtc();
        final auditId = '${ordem.id}-${auditNow.millisecondsSinceEpoch}';
        await db.into(db.auditLogsTable).insertOnConflictUpdate(
          AuditLogsTableCompanion.insert(
            id: auditId,
            targetEntity: 'OrdemPreparo',
            entityId: ordem.id,
            tenantId: ordem.tenantId,
            userId: operadorNome ?? 'sistema',
            action: isCancelamento ? 'cancelamento' : 'reversao',
            timestamp: auditNow,
            reason: Value(motivo),
            userName: Value(operadorNome),
            entityDisplayName: Value('Pedido ${ordem.pedidoId}'),
            entityModule: const Value('KDS'),
          ),
        );
      } catch (e) {
        debugPrint('[PEDIDOS] Erro ao gravar audit log: $e');
      }
    }

    // Atualiza localmente sem recarregar tudo
    final idx = _todasOrdens.indexWhere((o) => o.id == ordem.id);
    if (idx != -1) {
      _todasOrdens[idx] = updated;
    } else {
      // Ordem não estava na lista (ex: vinha de outra data): adiciona
      _todasOrdens = [..._todasOrdens, updated];
    }

    // Se reverteu para status ativo e a ordem é de outra data, navega para essa data
    final statusAtivos = {
      StatusOrdemPreparo.pendente,
      StatusOrdemPreparo.emPreparo,
      StatusOrdemPreparo.pronto,
    };
    if (statusAtivos.contains(novoStatus)) {
      final parsed = DadosOrdemKanban.fromOrdem(ordem);
      final dataOperacional = parsed.dataAgendada ?? ordem.criadaEm.toLocal();
      final isOutraData = dataOperacional.year != _selectedDate.year ||
          dataOperacional.month != _selectedDate.month ||
          dataOperacional.day != _selectedDate.day;
      if (isOutraData) {
        _selectedDate = DateTime(dataOperacional.year, dataOperacional.month, dataOperacional.day);
      }
    }

    // Disparo Simulado da Mensageria (Fase C: Modo Simulação / Mock - sem envio real)
    final eventoSimulado = switch (novoStatus) {
      StatusOrdemPreparo.pronto          => WhatsAppService.kEventoPedidoPronto,
      StatusOrdemPreparo.saiuParaEntrega => WhatsAppService.kEventoPedidoSaiuEntrega,
      StatusOrdemPreparo.cancelado       => WhatsAppService.kEventoPedidoCancelado,
      _                                  => null,
    };

    if (eventoSimulado != null) {
      _dispararSimulacaoWhatsApp(
        ordem: updated,
        eventoId: eventoSimulado,
        motivo: motivo,
      );
    } else if (isAprovacao && isPedidoAguardandoAprovacao(ordem)) {
      _dispararSimulacaoWhatsApp(
        ordem: updated,
        eventoId: WhatsAppService.kEventoPedidoAprovadoWeb,
      );
    }

    _applyFilters();
    notifyListeners();
  }

  bool isPedidoAguardandoAprovacao(OrdemPreparo o) {
    if (o.status != StatusOrdemPreparo.pendente) return false;
    final pedido = _pedidosMap[o.pedidoId];
    if (pedido != null) {
      final isOrigemWeb = pedido.canalOrigem == 'cardapio_web' || o.observacoes?.contains('cardapio_web') == true;
      final isStatusPendente = pedido.status == 'aguardando_aprovacao' || pedido.status == 'pendente';
      return isOrigemWeb && isStatusPendente;
    }
    final obs = o.observacoes ?? '';
    final isObsWeb = obs.contains('cardapio_web') || obs.contains('🌐');
    return isObsWeb;
  }

  Future<void> aprovarPedidoWeb(OrdemPreparo ordem) async {
    final now = DateTime.now().toUtc();
    final db = DependencyInjection().get<FincoreDatabase>();
    final outboxService = DependencyInjection().get<OutboxService>();

    String? operadorNome;
    try {
      final tenantCtx = DependencyInjection().get<TenantContext>();
      if (tenantCtx.hasContext) {
        operadorNome = tenantCtx.usuario.nome;
      }
    } catch (_) {}

    // 1. Atualiza a tabela 'pedido' localmente para status 'confirmado'
    final pedidoRow = await (db.select(db.pedidosTable)
          ..where((t) => t.id.equals(ordem.pedidoId)))
        .getSingleOrNull();

    final pedidoSyncVersion = (pedidoRow?.syncVersion ?? 0) + 1;

    if (pedidoRow != null) {
      await (db.update(db.pedidosTable)
            ..where((t) => t.id.equals(ordem.pedidoId)))
          .write(PedidosTableCompanion(
        status: const Value('confirmado'),
        syncVersion: Value(pedidoSyncVersion),
        updatedAt: Value(now),
      ));
    }

    // 2. Envia para o Outbox do Supabase
    try {
      await outboxService.enqueue(
        entity: 'Pedido',
        entityId: ordem.pedidoId,
        action: 'update',
        payload: {
          'id': ordem.pedidoId,
          'tenantId': ordem.tenantId,
          'status': 'confirmado',
          'syncVersion': pedidoSyncVersion,
          'updatedAt': now.toIso8601String(),
        },
        version: pedidoSyncVersion,
      );

      final syncEngine = DependencyInjection().get<SyncEngine>();
      unawaited(syncEngine.processPendingQueue().catchError((_) => const SyncResult(
            successCount: 0,
            failureCount: 0,
            hasPendingAfter: true,
          )));
    } catch (e) {
      debugPrint('[PEDIDOS] Erro ao colocar aprovação de pedido no outbox: $e');
    }

    // 3. Registra no histórico de auditoria
    const titulo = 'Pedido Web Aprovado';
    final descricao = 'Pedido online aprovado e aceito por "${operadorNome ?? 'Operador'}". Pedido liberado na fila de produção.';

    await _ordemRepo.registrarHistorico(
      ordem.id,
      titulo,
      descricao,
      operadorNome: operadorNome,
    );

    // 4. Atualiza o cache local de pedidosMap
    if (pedidoRow != null) {
      final updatedPedido = pedidoRow.copyWith(
        status: 'confirmado',
        syncVersion: pedidoSyncVersion,
        updatedAt: now,
      );
      _pedidosMap[ordem.pedidoId] = updatedPedido;
      
      final hIdx = _historicoPedidos.indexWhere((p) => p.id == ordem.pedidoId);
      if (hIdx != -1) {
        _historicoPedidos[hIdx] = updatedPedido;
      }
    }

    // 5. Disparo Simulado da Mensageria (Fase C: Modo Simulação / Mock)
    _dispararSimulacaoWhatsApp(
      ordem: ordem,
      eventoId: WhatsAppService.kEventoPedidoAprovadoWeb,
    );

    notifyListeners();
  }

  /// Processa mensageria do WhatsApp para a Central de Pedidos (Fase D2: Integrado e Seguro)
  void _dispararSimulacaoWhatsApp({
    required OrdemPreparo ordem,
    required String eventoId,
    String? motivo,
  }) {
    scheduleMicrotask(() async {
      try {
        final db = DependencyInjection().get<FincoreDatabase>();
        final pedidoRow = _pedidosMap[ordem.pedidoId] ??
            await (db.select(db.pedidosTable)..where((t) => t.id.equals(ordem.pedidoId))).getSingleOrNull();

        if (pedidoRow == null) return;

        final configRepo = DependencyInjection().get<EmpresaConfiguracaoRepository>();
        final configs = await configRepo.findAll();
        final empresaUsarWa = configs.isNotEmpty ? configs.first.usarWhatsApp : true;
        if (!empresaUsarWa) return;

        bool clienteAceita = false;
        String? telefone = pedidoRow.clienteTelefoneAvulso;
        String nome = pedidoRow.clienteNomeAvulso ?? 'Cliente';

        if (pedidoRow.clienteId != null && pedidoRow.clienteId!.isNotEmpty) {
          final clienteRow = await (db.select(db.clientesTable)..where((t) => t.id.equals(pedidoRow.clienteId!))).getSingleOrNull();
          if (clienteRow != null) {
            clienteAceita = clienteRow.aceitaWhatsapp;
            if (clienteRow.telefone.trim().isNotEmpty) {
              telefone = clienteRow.telefone;
            }
            nome = clienteRow.nome;
          }
        }

        final numeroExibicao = pedidoRow.numeroPedido?.toString() ??
            (pedidoRow.id.length >= 8 ? pedidoRow.id.substring(0, 8) : pedidoRow.id);

        // Verifica status oficial de pagamento no financeiro (sem fontes paralelas)
        final lancamento = await (db.select(db.lancamentosFinanceirosTable)
              ..where((l) =>
                  l.pedidoId.equals(ordem.pedidoId) &
                  l.tipo.equals('receita') &
                  l.deletedAt.isNull())
              ..limit(1))
            .getSingleOrNull();
        final statusPagamento = lancamento != null ? 'PAGO' : 'PENDENTE';

        final itensWhats = ordem.itens.map((it) {
          return {
            'nome': it.nomeProduto,
            'qtd': it.quantidade,
            'obs': null,
          };
        }).toList();

        final calcDescontoCentavos = (pedidoRow.valorSubtotalCentavos +
                pedidoRow.valorTaxaEntregaCentavos +
                pedidoRow.valorTaxaServicoCentavos) -
            pedidoRow.valorTotalCentavos;

        final obsFinal = (eventoId == WhatsAppService.kEventoPedidoCancelado && motivo != null && motivo.trim().isNotEmpty)
            ? motivo.trim()
            : pedidoRow.observacoes;

        await WhatsAppService.processarEventoPedidoAutomatico(
          tenantId: ordem.tenantId,
          pedidoId: ordem.pedidoId,
          numeroPedido: numeroExibicao,
          eventoId: eventoId,
          tipoLogistica: pedidoRow.tipoLogistica,
          formaPagamento: pedidoRow.formaPagamentoNome ?? 'Outro',
          statusPagamento: statusPagamento,
          rawPhone: telefone,
          clienteNome: nome,
          clienteAceitaWhatsapp: clienteAceita,
          valorTotalCentavos: pedidoRow.valorTotalCentavos,
          valorSubtotalCentavos: pedidoRow.valorSubtotalCentavos,
          valorDescontoCentavos: calcDescontoCentavos > 0 ? calcDescontoCentavos : 0,
          valorTaxaEntregaCentavos: pedidoRow.valorTaxaEntregaCentavos,
          valorTaxaServicoCentavos: pedidoRow.valorTaxaServicoCentavos,
          trocoParaCentavos: pedidoRow.trocoParaCentavos,
          itens: itensWhats,
          observacoes: obsFinal,
          enderecoCliente: pedidoRow.enderecoJson,
          eventInstanceId: 'ordem_${ordem.id}_v${ordem.metadata.version}_${ordem.status.name}',
          versaoPedido: ordem.metadata.version,
          dataAlteracao: ordem.metadata.updatedAt,
        );
      } catch (e) {
        debugPrint('[CentralPedidos] Mensageria WhatsApp isolada por segurança (fluxo principal 100% preservado): $e');
      }
    });
  }

  Future<OrdemPreparo?> recarregarOrdem(String ordemId) async {
    final reloaded = await _ordemRepo.findById(ordemId);
    if (reloaded != null) {
      final idx = _todasOrdens.indexWhere((o) => o.id == ordemId);
      if (idx != -1) _todasOrdens[idx] = reloaded;
      _applyFilters();
      notifyListeners();
    }
    return reloaded;
  }

  Future<List<HistoricoOrdemPreparo>> carregarHistorico(String ordemId) =>
      _ordemRepo.findHistoricoByOrdemId(ordemId);

  String formattedDate() =>
      DateFormat('dd/MM/yyyy').format(_selectedDate);

  // ── Controle de Produção por Janelas Operacionais ────────────────────────
  
  // Mapa em memória de quantidades produzidas: chave="${janela.millisecondsSinceEpoch}_${produtoId}"
  final Map<String, double> _produzidoJanelas = {};

  double getQuantidadeProduzida(DateTime janela, String produtoId) {
    final chave = "${janela.millisecondsSinceEpoch}_$produtoId";
    return _produzidoJanelas[chave] ?? 0;
  }

  void registrarProduzido(DateTime janela, String produtoId, double quantidade, double totalPlanejado) {
    final chave = "${janela.millisecondsSinceEpoch}_$produtoId";
    final atual = _produzidoJanelas[chave] ?? 0;
    _produzidoJanelas[chave] = (atual + quantidade).clamp(0.0, totalPlanejado);
    notifyListeners();
  }

  void marcarProdutoConcluido(DateTime janela, String produtoId, double totalPlanejado) {
    final chave = "${janela.millisecondsSinceEpoch}_$produtoId";
    _produzidoJanelas[chave] = totalPlanejado;
    notifyListeners();
  }

  void reiniciarProdutoProduzido(DateTime janela, String produtoId) {
    final chave = "${janela.millisecondsSinceEpoch}_$produtoId";
    _produzidoJanelas.remove(chave);
    notifyListeners();
  }

  DateTime _arredondarJanela(DateTime dt) {
    final minutos = dt.minute;
    int janelaMinuto;
    int janelaHora = dt.hour;
    if (minutos < 15) {
      janelaMinuto = 0;
    } else if (minutos < 45) {
      janelaMinuto = 30;
    } else {
      janelaMinuto = 0;
      janelaHora = (janelaHora + 1) % 24;
    }
    return DateTime(dt.year, dt.month, dt.day, janelaHora, janelaMinuto);
  }

  List<JanelaProducao> get janelasProducao {
    // Apenas pedidos que estão pendentes ou em preparo geram demanda operacional de produção física.
    final ordensAtivas = _filteredOrdens.where((o) => 
      o.status == StatusOrdemPreparo.pendente || 
      o.status == StatusOrdemPreparo.emPreparo
    ).toList();

    if (ordensAtivas.isEmpty) return [];

    // Agrupar ordens por janela de entrega arredondada
    final agrupado = <DateTime, List<OrdemPreparo>>{};
    for (final o in ordensAtivas) {
      final deadline = calculateDeadline(o);
      final janela = _arredondarJanela(deadline.horarioEntrega.toLocal());
      agrupado.putIfAbsent(janela, () => []).add(o);
    }

    // Ordenar as janelas cronologicamente
    final janelasOrdenadas = agrupado.keys.toList()..sort();

    final resultado = <JanelaProducao>[];
    // Pegar no máximo as duas primeiras janelas (Agora e Próxima)
    final limite = janelasOrdenadas.length > 2 ? 2 : janelasOrdenadas.length;

    for (int i = 0; i < limite; i++) {
      final janelaTime = janelasOrdenadas[i];
      final ordensDaJanela = agrupado[janelaTime]!;

      // Consolidar produtos
      final produtosConsolidados = <String, _Consolidado>{};
      for (final o in ordensDaJanela) {
        for (final item in o.itens) {
          produtosConsolidados.update(
            item.produtoId,
            (existente) => existente.copyWith(
              quantidadePlanejada: existente.quantidadePlanejada + item.quantidade,
            ),
            ifAbsent: () => _Consolidado(
              produtoId: item.produtoId,
              nomeProduto: item.nomeProduto,
              quantidadePlanejada: item.quantidade,
              unidade: item.unidade,
            ),
          );
        }
      }

      final itensJanela = produtosConsolidados.values.map((c) {
        final prodQty = getQuantidadeProduzida(janelaTime, c.produtoId);
        return ItemJanelaProducao(
          produtoId: c.produtoId,
          nomeProduto: c.nomeProduto,
          quantidadePlanejada: c.quantidadePlanejada,
          quantidadeProduzida: prodQty,
          unidade: c.unidade,
        );
      }).toList();

      // Ordenar itens da janela por quantidade planejada decrescente
      itensJanela.sort((a, b) => b.quantidadePlanejada.compareTo(a.quantidadePlanejada));

      resultado.add(
        JanelaProducao(
          horarioEntrega: janelaTime,
          itens: itensJanela,
          totalPedidos: ordensDaJanela.length,
        ),
      );
    }

    return resultado;
  }

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _refreshTimer?.cancel();
    _syncSub?.cancel();
    super.dispose();
  }
}

// ── Classes Auxiliares de Fila Dinâmica de Produção ──────────────────────────

class ItemJanelaProducao {
  final String produtoId;
  final String nomeProduto;
  final double quantidadePlanejada;
  final double quantidadeProduzida;
  final String unidade;

  double get quantidadeRestante => (quantidadePlanejada - quantidadeProduzida).clamp(0.0, quantidadePlanejada);
  bool get concluida => quantidadeRestante <= 0;

  const ItemJanelaProducao({
    required this.produtoId,
    required this.nomeProduto,
    required this.quantidadePlanejada,
    required this.quantidadeProduzida,
    required this.unidade,
  });
}

class JanelaProducao {
  final DateTime horarioEntrega;
  final List<ItemJanelaProducao> itens;
  final int totalPedidos;

  bool get concluida => itens.every((i) => i.concluida);

  const JanelaProducao({
    required this.horarioEntrega,
    required this.itens,
    required this.totalPedidos,
  });
}

class _Consolidado {
  final String produtoId;
  final String nomeProduto;
  final double quantidadePlanejada;
  final String unidade;

  const _Consolidado({
    required this.produtoId,
    required this.nomeProduto,
    required this.quantidadePlanejada,
    required this.unidade,
  });

  _Consolidado copyWith({double? quantidadePlanejada}) {
    return _Consolidado(
      produtoId: produtoId,
      nomeProduto: nomeProduto,
      quantidadePlanejada: quantidadePlanejada ?? this.quantidadePlanejada,
      unidade: unidade,
    );
  }
}
