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

class DeadlineInfo {
  final DateTime horarioEntrega;
  final int tempoPreparacaoMinutos;
  final int tempoDeslocamentoMinutos;
  final int margemSegurancaMinutos;
  final DateTime horarioInicioRecomendado;
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
  Map<String, int> _precosProdutosMap = {};
  Map<String, int> _tempoPreparoProdutosMap = {};
  Map<String, PedidoData> _pedidosMap = {};
  int _margemSegurancaMinutos = 10;

  bool _isLoading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  String _selectedOrigem = 'Todos';

  Timer? _refreshTimer;

  CentralPedidosController({OrdemPreparoRepository? ordemRepo})
      : _ordemRepo =
            ordemRepo ?? DependencyInjection().get<OrdemPreparoRepository>() {
    carregarOrdens();
    // Atualização automática a cada 15s (igual ao sync monitor do shell)
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 15), (_) => carregarOrdens());
  }

  // ── Getters públicos ────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;
  String get selectedOrigem => _selectedOrigem;
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

  int get totalPedidos => _filteredOrdens.length;

  int get totalEntregas {
    int n = 0;
    for (final o in _filteredOrdens) {
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
        await _carregarDadosAuxiliares(list);
        _todasOrdens = list;
        _applyFilters();
        notifyListeners();
      } catch (e) {
        debugPrint('[CentralPedidosController] Erro no refresh: $e');
      }
      return;
    }

    // Primeiro carregamento
    try {
      final list = await _ordemRepo.findAll();
      await _carregarPrecos();
      await _carregarDadosAuxiliares(list);
      _todasOrdens = list;
      _applyFilters();
    } catch (e) {
      _error = 'Erro ao carregar pedidos: $e';
      debugPrint('[CentralPedidosController] $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
              ..where((t) => t.id.isIn(pedidoIds)))
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
          return (
            distanciaMetros: dist,
            tempoDeslocamentoMinutos: (durSeconds / 60).round(),
          );
        }
      } catch (_) {}
    }
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
    final isImmediate = parsed.dataAgendada == null;
    
    final tempoPrep = getTempoPreparacaoMinutos(o);
    
    int tempoDesloc = 0;
    
    final isDelivery = parsed.tipoLogistica.toLowerCase().contains('entrega') || 
                       parsed.tipoLogistica.toLowerCase().contains('delivery');
                       
    if (isDelivery) {
      final route = getRouteInfo(o);
      tempoDesloc = route.tempoDeslocamentoMinutos;
    }
    
    final margem = _margemSegurancaMinutos;
    
    DateTime targetEntrega;
    DateTime inicioRecomendado;
    
    if (isImmediate) {
      targetEntrega = o.criadaEm.add(Duration(minutes: tempoPrep + tempoDesloc + margem));
      inicioRecomendado = o.criadaEm;
    } else {
      targetEntrega = parsed.dataAgendada!;
      inicioRecomendado = targetEntrega.subtract(Duration(minutes: tempoPrep + tempoDesloc + margem));
    }
    
    final agora = DateTime.now();
    String statusLabel = '';
    Color statusColor = const Color(0xFF10B981);
    String tempoRestanteLabel = '';
    
    if (o.status == StatusOrdemPreparo.pronto || 
        o.status == StatusOrdemPreparo.entregue || 
        o.status == StatusOrdemPreparo.cancelado) {
      statusLabel = 'Concluído';
      statusColor = const Color(0xFF6B7280);
      tempoRestanteLabel = 'Preparo finalizado';
    } else {
      if (isImmediate) {
        if (o.status == StatusOrdemPreparo.pendente) {
          final minutosCriado = agora.difference(o.criadaEm).inMinutes;
          if (minutosCriado <= 2) {
            statusLabel = 'Iniciar agora';
            statusColor = const Color(0xFFEF4444);
            tempoRestanteLabel = 'Pedido imediato';
          } else {
            statusLabel = 'Produção atrasada';
            statusColor = const Color(0xFFDC2626);
            tempoRestanteLabel = 'Atrasado há ${_formatAtraso(minutosCriado)}';
          }
        } else {
          statusLabel = 'Dentro do prazo';
          statusColor = const Color(0xFF10B981);
          tempoRestanteLabel = 'Em preparação';
        }
      } else {
        final isEmPreparo = o.status == StatusOrdemPreparo.emPreparo;
        final targetTime = isEmPreparo ? targetEntrega : inicioRecomendado;
        final diferenca = targetTime.difference(agora).inMinutes;

        if (isEmPreparo) {
          if (diferenca > 0) {
            statusLabel = 'Em preparação';
            statusColor = const Color(0xFF10B981);
            tempoRestanteLabel = 'Faltam ${_formatAtraso(diferenca)}';
          } else {
            statusLabel = 'Entrega atrasada';
            statusColor = const Color(0xFFDC2626);
            tempoRestanteLabel = 'Atrasado há ${_formatAtraso(-diferenca)}';
          }
        } else {
          if (diferenca > 15) {
            statusLabel = 'Dentro do prazo';
            statusColor = const Color(0xFF10B981);
            tempoRestanteLabel = 'Faltam ${_formatAtraso(diferenca)}';
          } else if (diferenca > 0 && diferenca <= 15) {
            statusLabel = 'Iniciar em breve';
            statusColor = const Color(0xFFF59E0B);
            tempoRestanteLabel = 'Faltam ${_formatAtraso(diferenca)}';
          } else if (diferenca <= 0 && diferenca >= -2) {
            statusLabel = 'Iniciar agora';
            statusColor = const Color(0xFFEF4444);
            tempoRestanteLabel = 'Iniciar produção agora';
          } else {
            statusLabel = 'Produção atrasada';
            statusColor = const Color(0xFFDC2626);
            tempoRestanteLabel = 'Atrasado há ${_formatAtraso(-diferenca)}';
          }
        }
      }
    }
    
    return DeadlineInfo(
      horarioEntrega: targetEntrega,
      tempoPreparacaoMinutos: tempoPrep,
      tempoDeslocamentoMinutos: tempoDesloc,
      margemSegurancaMinutos: margem,
      horarioInicioRecomendado: inicioRecomendado,
      statusLabel: statusLabel,
      statusColor: statusColor,
      tempoRestanteLabel: tempoRestanteLabel,
      isImmediate: isImmediate,
    );
  }

  void _applyFilters() {
    _filteredOrdens = _todasOrdens.where((o) {
      final matchesDate = o.criadaEm.year == _selectedDate.year &&
          o.criadaEm.month == _selectedDate.month &&
          o.criadaEm.day == _selectedDate.day;

      final parsed = DadosOrdemKanban.fromOrdem(o);
      final matchesOrigem = _selectedOrigem == 'Todos' ||
          parsed.tipoLogistica.toLowerCase() ==
              _selectedOrigem.toLowerCase();

      return matchesDate && matchesOrigem;
    }).toList();
  }

  // ── Filtros públicos ─────────────────────────────────────────────────

  void mudarDia(int offset) {
    _selectedDate = _selectedDate.add(Duration(days: offset));
    _applyFilters();
    notifyListeners();
  }

  void setOrigem(String origem) {
    _selectedOrigem = origem;
    _applyFilters();
    notifyListeners();
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
          ? DateTime.now()
          : ordem.iniciadaEm,
      concluidaEm: novoStatus == StatusOrdemPreparo.pronto
          ? DateTime.now()
          : ordem.concluidaEm,
      canceladaEm: novoStatus == StatusOrdemPreparo.cancelado
          ? DateTime.now()
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
      final statusStr = novoStatus == StatusOrdemPreparo.entregue
          ? 'entregue'
          : novoStatus == StatusOrdemPreparo.cancelado
              ? 'cancelado'
              : novoStatus.name;

      await (db.update(db.pedidosTable)
            ..where((t) => t.id.equals(ordem.pedidoId)))
          .write(PedidosTableCompanion(
        status: Value(statusStr),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ));

      // Dispara recálculo de reservas e expedição física no EstoqueController
      final estoqueCtrl = DependencyInjection().get<EstoqueController>();
      await estoqueCtrl.recalcularReservasEEstoques();
    } catch (e) {
      debugPrint('[PEDIDOS] Erro ao sincronizar status com estoque: $e');
    }

    final isRev = isReversao(ordem, novoStatus);
    final titulo = isRev ? 'Status Revertido' : 'Status alterado';
    final descricao = isRev
        ? 'Passou de "${statusLabel(ordem.status)}" para "${statusLabel(novoStatus)}". Motivo: $motivo'
        : 'Passou de "${statusLabel(ordem.status)}" para "${statusLabel(novoStatus)}"';

    await _ordemRepo.registrarHistorico(ordem.id, titulo, descricao);

    // Atualiza localmente sem recarregar tudo
    final idx = _todasOrdens.indexWhere((o) => o.id == ordem.id);
    if (idx != -1) {
      _todasOrdens[idx] = updated;
    }
    _applyFilters();
    notifyListeners();
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

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
