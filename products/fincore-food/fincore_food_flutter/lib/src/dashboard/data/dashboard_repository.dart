import 'package:drift/drift.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:fincore_core/repository/ordem_preparo_repository.dart';
import 'package:intl/intl.dart';

/// Item do ranking de produtos
class RankingProdutoItem {
  final String produtoId;
  final String nomeProduto;
  final double quantidade;
  final bool isCrescimento;
  final double variacaoPercentual;

  const RankingProdutoItem({
    required this.produtoId,
    required this.nomeProduto,
    required this.quantidade,
    required this.isCrescimento,
    required this.variacaoPercentual,
  });
}

/// Grupo de entrega agendada
class EntregaAgendadaGrupo {
  final DateTime dataHora;
  final String clienteNome;
  final List<String> itensResumo;
  final bool isAmanha;

  const EntregaAgendadaGrupo({
    required this.dataHora,
    required this.clienteNome,
    required this.itensResumo,
    required this.isAmanha,
  });
}

/// Evento da linha do tempo
class EventoTimeline {
  final String hora;
  final String cliente;
  final String tipo; // 'Entrega' | 'Retirada' | 'Preparação' | 'Produção'
  final String status;
  final String orderId;

  const EventoTimeline({
    required this.hora,
    required this.cliente,
    required this.tipo,
    required this.status,
    required this.orderId,
  });
}

/// Item de detalhe de risco na previsão diária
class ProjecaoDiaItem {
  final String produtoId;
  final String nomeProduto;
  final double quantidadeDisponivel;
  final double quantidadeReservadaDia;
  final double producaoPlanejadaAteDia;
  final double projetado;
  final bool hasRisco;

  const ProjecaoDiaItem({
    required this.produtoId,
    required this.nomeProduto,
    required this.quantidadeDisponivel,
    required this.quantidadeReservadaDia,
    required this.producaoPlanejadaAteDia,
    required this.projetado,
    required this.hasRisco,
  });
}

/// Projeção diária de atendimento
class ProjecaoDia {
  final DateTime data;
  final String diaSemana;
  final int totalPedidos;
  final int totalProducoesPlanejadas;
  final int totalProducoesEmAndamento;
  final List<ProjecaoDiaItem> itensComRisco;
  final List<String> pedidosIds;
  final String estoqueStatus; // 'NORMAL' | 'ATENCAO' | 'CRITICO'

  const ProjecaoDia({
    required this.data,
    required this.diaSemana,
    required this.totalPedidos,
    required this.totalProducoesPlanejadas,
    required this.totalProducoesEmAndamento,
    required this.itensComRisco,
    required this.pedidosIds,
    required this.estoqueStatus,
  });
}

/// Modelo de dados contendo as métricas reais consolidadas para o dashboard.
class DashboardMetrics {
  final int totalPedidosHoje;
  final int faturamentoCentavosHoje;
  final int totalEntregasHoje;
  final int totalRetiradasHoje;
  final int producoesAtivasCount;
  final int ticketMedioCentavosHoje;
  final int pedidosCanceladosHoje;
  final int producoesConcluidasHoje;
  final int planejamentosCriadosHoje;
  final int producoesParciaisHoje;

  // Estatísticas comparativas
  final int faturamentoCentavosSemana;
  final int faturamentoCentavosMes;
  final int ticketMedioCentavosSemana;
  final int ticketMedioCentavosMes;
  final int totalPedidosSemana;
  final int totalPedidosMes;
  final int canceladosSemana;
  final int canceladosMes;

  final List<int> faturamento7DiasCentavos;
  final List<int> faturamento30DiasCentavos;
  final List<String> faturamento7DiasDatas;
  final List<String> faturamento30DiasDatas;

  final List<RankingProdutoItem> topProdutos;
  final List<EntregaAgendadaGrupo> proximasEntregas;
  final List<EventoTimeline> timelineHoje;
  final List<ProjecaoDia> projecaoDias;

  const DashboardMetrics({
    required this.totalPedidosHoje,
    required this.faturamentoCentavosHoje,
    required this.totalEntregasHoje,
    required this.totalRetiradasHoje,
    required this.producoesAtivasCount,
    required this.ticketMedioCentavosHoje,
    required this.pedidosCanceladosHoje,
    required this.faturamentoCentavosSemana,
    required this.faturamentoCentavosMes,
    required this.ticketMedioCentavosSemana,
    required this.ticketMedioCentavosMes,
    required this.totalPedidosSemana,
    required this.totalPedidosMes,
    required this.canceladosSemana,
    required this.canceladosMes,
    required this.faturamento7DiasCentavos,
    required this.faturamento30DiasCentavos,
    required this.faturamento7DiasDatas,
    required this.faturamento30DiasDatas,
    required this.topProdutos,
    required this.proximasEntregas,
    required this.timelineHoje,
    required this.projecaoDias,
    required this.producoesConcluidasHoje,
    required this.planejamentosCriadosHoje,
    required this.producoesParciaisHoje,
  });

  factory DashboardMetrics.zero() {
    return const DashboardMetrics(
      totalPedidosHoje: 0,
      faturamentoCentavosHoje: 0,
      totalEntregasHoje: 0,
      totalRetiradasHoje: 0,
      producoesAtivasCount: 0,
      ticketMedioCentavosHoje: 0,
      pedidosCanceladosHoje: 0,
      faturamentoCentavosSemana: 0,
      faturamentoCentavosMes: 0,
      ticketMedioCentavosSemana: 0,
      ticketMedioCentavosMes: 0,
      totalPedidosSemana: 0,
      totalPedidosMes: 0,
      canceladosSemana: 0,
      canceladosMes: 0,
      faturamento7DiasCentavos: [0, 0, 0, 0, 0, 0, 0],
      faturamento30DiasCentavos: [],
      faturamento7DiasDatas: [],
      faturamento30DiasDatas: [],
      topProdutos: [],
      proximasEntregas: [],
      timelineHoje: [],
      projecaoDias: [],
      producoesConcluidasHoje: 0,
      planejamentosCriadosHoje: 0,
      producoesParciaisHoje: 0,
    );
  }
}

/// Repositório responsável por buscar métricas operacionais e financeiras
/// em tempo real da [pedidos_table] do banco local.
class DashboardRepository {
  final FincoreDatabase db;
  final TenantContext tenantContext;
  final OrdemPreparoRepository kdsRepo;

  const DashboardRepository({
    required this.db,
    required this.tenantContext,
    required this.kdsRepo,
  });

  /// Calcula as métricas operacionais consolidadas de hoje e dos últimos 7 dias.
  Future<DashboardMetrics> getMetrics() async {
    final activeTenant = tenantContext.tenantId;
    if (activeTenant.isEmpty) {
      return DashboardMetrics.zero();
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));

    // ── 1. Pedidos do último mês + agendados dos próximos 7 dias ──
    final startOf30DaysAgo = startOfDay.subtract(const Duration(days: 30));
    final endOf7Days = startOfDay.add(const Duration(days: 7));
    final pedidos30Dias = await (db.select(db.pedidosTable)
          ..where((t) =>
              t.tenantId.equals(activeTenant) &
              t.deletedAt.isNull() &
              (t.dataHoraCriacao.isBiggerOrEqualValue(startOf30DaysAgo) |
               t.dataHoraEntregaPrevista.isBetweenValues(startOfDay, endOf7Days))))
        .get();

    // Filtros de tempo em memória
    final hojePedidosValidos = pedidos30Dias.where((p) =>
        p.dataHoraCriacao.isAfter(startOfDay) &&
        p.dataHoraCriacao.isBefore(endOfDay) &&
        p.status != 'cancelado' &&
        p.status != 'rascunho').toList();

    final hojePedidosCancelados = pedidos30Dias.where((p) =>
        p.dataHoraCriacao.isAfter(startOfDay) &&
        p.dataHoraCriacao.isBefore(endOfDay) &&
        p.status == 'cancelado').length;

    final totalPedidosHoje = hojePedidosValidos.length;
    final faturamentoHoje = hojePedidosValidos.fold<int>(0, (sum, p) => sum + p.valorTotalCentavos);
    final ticketMedioHoje = totalPedidosHoje > 0 ? faturamentoHoje ~/ totalPedidosHoje : 0;

    final totalEntregasHoje = hojePedidosValidos.where((p) => p.tipoLogistica == 'Entrega').length;
    final totalRetiradasHoje = hojePedidosValidos.where((p) => p.tipoLogistica == 'Retirada').length;

    // ── 2. Campanhas de Produção Ativas ──
    final producoesAtivasList = await (db.select(db.planejamentoProducaoTable)
          ..where((t) =>
              t.tenantId.equals(activeTenant) &
              t.deletedAt.isNull() &
              t.status.isIn(['planejada', 'em_preparacao', 'em_producao', 'parcial'])))
        .get();
    final producoesAtivasCount = producoesAtivasList.length;

    // ── 3. Métricas Comparativas (Semana / Mês) ──
    final startOf7DaysAgo = startOfDay.subtract(const Duration(days: 7));

    // Semana
    final semanaPedidosValidos = pedidos30Dias.where((p) =>
        p.dataHoraCriacao.isAfter(startOf7DaysAgo) &&
        p.status != 'cancelado' &&
        p.status != 'rascunho').toList();
    final semanaCancelados = pedidos30Dias.where((p) =>
        p.dataHoraCriacao.isAfter(startOf7DaysAgo) &&
        p.status == 'cancelado').length;
    final faturamentoSemana = semanaPedidosValidos.fold<int>(0, (sum, p) => sum + p.valorTotalCentavos);
    final totalPedidosSemana = semanaPedidosValidos.length;
    final ticketMedioSemana = totalPedidosSemana > 0 ? faturamentoSemana ~/ totalPedidosSemana : 0;

    // Mês
    final mesPedidosValidos = pedidos30Dias.where((p) =>
        p.status != 'cancelado' &&
        p.status != 'rascunho').toList();
    final mesCancelados = pedidos30Dias.where((p) =>
        p.status == 'cancelado').length;
    final faturamentoMes = mesPedidosValidos.fold<int>(0, (sum, p) => sum + p.valorTotalCentavos);
    final totalPedidosMes = mesPedidosValidos.length;
    final ticketMedioMes = totalPedidosMes > 0 ? faturamentoMes ~/ totalPedidosMes : 0;

    // ── 4. Gráficos de Faturamento (7 dias e 30 dias) ──
    final faturamento7Dias = <int>[0, 0, 0, 0, 0, 0, 0];
    final faturamento7DiasDatas = <String>[];
    for (int i = 0; i < 7; i++) {
      final dia = now.subtract(Duration(days: 6 - i));
      final inicioDia = DateTime(dia.year, dia.month, dia.day);
      final fimDia = inicioDia.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));

      faturamento7DiasDatas.add(DateFormat('dd/MM').format(inicioDia));
      final pedidosDia = pedidos30Dias.where((p) =>
          !p.dataHoraCriacao.isBefore(inicioDia) &&
          !p.dataHoraCriacao.isAfter(fimDia) &&
          p.status != 'cancelado' &&
          p.status != 'rascunho');
      faturamento7Dias[i] = pedidosDia.fold<int>(0, (sum, p) => sum + p.valorTotalCentavos);
    }

    final faturamento30Dias = <int>[];
    final faturamento30DiasDatas = <String>[];
    for (int i = 0; i < 30; i++) {
      final dia = now.subtract(Duration(days: 29 - i));
      final inicioDia = DateTime(dia.year, dia.month, dia.day);
      final fimDia = inicioDia.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));

      if (i % 5 == 0 || i == 29) {
        faturamento30DiasDatas.add(DateFormat('dd/MM').format(inicioDia));
      } else {
        faturamento30DiasDatas.add('');
      }

      final pedidosDia = pedidos30Dias.where((p) =>
          !p.dataHoraCriacao.isBefore(inicioDia) &&
          !p.dataHoraCriacao.isAfter(fimDia) &&
          p.status != 'cancelado' &&
          p.status != 'rascunho');
      faturamento30Dias.add(pedidosDia.fold<int>(0, (sum, p) => sum + p.valorTotalCentavos));
    }

    // ── 5. TOP 5 Produtos mais vendidos (últimos 30 dias) ──
    final itens30Dias = await (db.select(db.itensPedidoTable)
          ..where((t) =>
              t.tenantId.equals(activeTenant) &
              t.createdAt.isBiggerOrEqualValue(startOf30DaysAgo) &
              t.deletedAt.isNull()))
        .get();

    final productSales = <String, double>{};
    final productNames = <String, String>{};
    for (final item in itens30Dias) {
      // Filtra apenas itens de pedidos válidos
      final isValido = pedidos30Dias.any((p) => p.id == item.pedidoId && p.status != 'cancelado' && p.status != 'rascunho');
      if (isValido) {
        productSales[item.produtoId] = (productSales[item.produtoId] ?? 0.0) + item.quantidade;
        productNames[item.produtoId] = item.nomeProduto;
      }
    }
    final sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final halfLimit = startOfDay.subtract(const Duration(days: 15));
    final topProdutos = sortedProducts.take(5).map((e) {
      double salesRecent = 0.0;
      double salesOlder = 0.0;
      for (final item in itens30Dias.where((item) => item.produtoId == e.key)) {
        if (item.createdAt.isAfter(halfLimit)) {
          salesRecent += item.quantidade;
        } else {
          salesOlder += item.quantidade;
        }
      }
      final double pct = salesOlder > 0 ? ((salesRecent - salesOlder) / salesOlder) * 100 : (salesRecent > 0 ? 100.0 : 0.0);
      return RankingProdutoItem(
        produtoId: e.key,
        nomeProduto: productNames[e.key] ?? 'Produto',
        quantidade: e.value,
        isCrescimento: salesRecent >= salesOlder,
        variacaoPercentual: pct,
      );
    }).toList();

    // ── 6. Próximas Entregas (Hoje + Amanhã) ──
    final startOfDayUtc = startOfDay.toUtc();
    final endOfTomorrowUtc = startOfDay.add(const Duration(days: 2)).subtract(const Duration(microseconds: 1)).toUtc();

    // Busca ordens de preparo para extrair dataAgendada de pedidos sem dataHoraEntregaPrevista
    final ordensRecentes = await (db.select(db.ordensPreparoTable)
          ..where((t) =>
              t.tenantId.equals(activeTenant) &
              t.deletedAt.isNull() &
              t.criadaEm.isBiggerOrEqualValue(startOf30DaysAgo)))
        .get();
    final ordemByPedidoId = <String, String?>{
      for (final o in ordensRecentes) o.pedidoId: o.observacoes,
    };

    // Parser inline para extrair "agendado: dd/MM/yyyy HH:mm" das observações
    DateTime? _parseAgendadoFromObs(String? obs) {
      if (obs == null || obs.isEmpty) return null;
      final regex = RegExp(r'agendado\s*:\s*(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2})', caseSensitive: false);
      final match = regex.firstMatch(obs);
      if (match == null) return null;
      try {
        return DateFormat('dd/MM/yyyy HH:mm').parse(match.group(1)!.trim());
      } catch (_) {
        return null;
      }
    }

    // Monta lista de agendados com fallback de data via parse das observações
    final List<({PedidoData pedido, DateTime dataEntrega})> agendadosCandidatos = [];
    for (final p in pedidos30Dias) {
      // Pedidos cancelados, entregues ou em rascunho não aparecem nas próximas entregas
      if (p.status == 'cancelado' || p.status == 'entregue' || p.status == 'rascunho') continue;

      DateTime? dataEntrega = p.dataHoraEntregaPrevista;

      // Fallback 1: tenta parsear dataAgendada das observações da ordem de preparo
      if (dataEntrega == null) {
        final obsText = ordemByPedidoId[p.id];
        if (obsText != null) {
          dataEntrega = _parseAgendadoFromObs(obsText);
        }
      }

      // Fallback 2 (bug legado): código antigo gravava dataHoraCriacao = dataEntrega.
      // Se dataHoraCriacao do pedido for >30 min no futuro em relação a now → é o horário de entrega
      if (dataEntrega == null) {
        final pedidoCriada = p.dataHoraCriacao.toLocal();
        if (pedidoCriada.difference(now).inMinutes > 30) {
          dataEntrega = pedidoCriada;
        }
      }

      if (dataEntrega == null) continue;

      final dataEntregaUtc = dataEntrega.isUtc ? dataEntrega : dataEntrega.toUtc();
      if (dataEntregaUtc.isAfter(startOfDayUtc) && dataEntregaUtc.isBefore(endOfTomorrowUtc)) {
        agendadosCandidatos.add((pedido: p, dataEntrega: dataEntrega));
      }
    }
    agendadosCandidatos.sort((a, b) => a.dataEntrega.compareTo(b.dataEntrega));

    final List<EntregaAgendadaGrupo> proximasEntregas = [];
    for (final entry in agendadosCandidatos) {
      final p = entry.pedido;
      final entregaLocal = entry.dataEntrega.toLocal();
      final inicioAmanha = DateTime(now.year, now.month, now.day + 1);
      final isAmanha = entregaLocal.year == inicioAmanha.year &&
                       entregaLocal.month == inicioAmanha.month &&
                       entregaLocal.day == inicioAmanha.day;
      final orderItens = itens30Dias.where((item) => item.pedidoId == p.id).toList();
      final List<String> itemsResumo = [];
      for (final it in orderItens) {
        itemsResumo.add('${it.quantidade.round()} ${it.nomeProduto}');
      }
      proximasEntregas.add(EntregaAgendadaGrupo(
        dataHora: entregaLocal,
        clienteNome: p.clienteNomeAvulso ?? 'Balcão',
        itensResumo: itemsResumo,
        isAmanha: isAmanha,
      ));
    }

    // ── 7. Linha de Tempo Operacional de Hoje ──
    final List<EventoTimeline> timelineHoje = [];
    final hojePedidos = pedidos30Dias.where((p) =>
        p.dataHoraCriacao.isAfter(startOfDay) &&
        p.dataHoraCriacao.isBefore(endOfDay)
    ).toList();

    for (final p in hojePedidos) {
      final time = p.dataHoraEntregaPrevista ?? p.dataHoraCriacao;
      final formatTime = DateFormat('HH:mm').format(time.toLocal());
      final String cliente = p.clienteNomeAvulso ?? 'Balcão';
      final String tipo = p.tipoLogistica;
      final String statusLabel = p.status;

      if (p.dataHoraEntregaPrevista != null) {
        final prepTime = p.dataHoraEntregaPrevista!.subtract(const Duration(minutes: 40));
        if (prepTime.isAfter(startOfDay)) {
          timelineHoje.add(EventoTimeline(
            hora: DateFormat('HH:mm').format(prepTime.toLocal()),
            cliente: 'Preparo Pedido #${p.numeroPedido ?? p.id.substring(0, 4)}',
            tipo: 'Preparação',
            status: 'Pendente',
            orderId: p.id,
          ));
        }
      }

      timelineHoje.add(EventoTimeline(
        hora: formatTime,
        cliente: cliente,
        tipo: tipo,
        status: statusLabel,
        orderId: p.id,
      ));
    }

    final todayProductions = await (db.select(db.planejamentoProducaoTable)
          ..where((t) =>
              t.tenantId.equals(activeTenant) &
              t.deletedAt.isNull() &
              t.dataPlano.isBiggerOrEqualValue(startOfDay) &
              t.dataPlano.isSmallerOrEqualValue(endOfDay)))
        .get();

    for (final prod in todayProductions) {
      final prodItem = await (db.select(db.produtosTable)
            ..where((t) => t.id.equals(prod.produtoId)))
          .getSingleOrNull();
      final nome = prodItem?.nome ?? 'Produto';
      timelineHoje.add(EventoTimeline(
        hora: DateFormat('HH:mm').format(prod.dataPlano.toLocal()),
        cliente: 'Produção: $nome (${prod.quantidadePlanejada} un)',
        tipo: 'Produção',
        status: prod.status,
        orderId: prod.id,
      ));
    }
    timelineHoje.sort((a, b) => a.hora.compareTo(b.hora));

    // ── 8. Previsão dos Próximos 7 Dias ──
    final List<ProjecaoDia> projecaoDias = [];
    final diasSemanaNomes = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    for (int i = 0; i < 7; i++) {
      final date = startOfDay.add(Duration(days: i));
      final nextDay = date.add(const Duration(days: 1));

      final String label;
      if (i == 0) {
        label = 'Hoje';
      } else if (i == 1) {
        label = 'Amanhã';
      } else {
        final weekday = date.weekday;
        label = diasSemanaNomes[weekday - 1];
      }

      final pedidosDia = pedidos30Dias.where((p) =>
          p.dataHoraEntregaPrevista != null &&
          !p.dataHoraEntregaPrevista!.isBefore(date) &&
          p.dataHoraEntregaPrevista!.isBefore(nextDay) &&
          p.status != 'cancelado' &&
          p.status != 'rascunho'
      ).toList();

      final pCount = pedidosDia.length;
      final pedidosIds = pedidosDia.map((p) => p.id).toList();

      final prodDia = await (db.select(db.planejamentoProducaoTable)
            ..where((t) =>
                t.tenantId.equals(activeTenant) &
                t.deletedAt.isNull() &
                t.dataPlano.isBiggerOrEqualValue(date) &
                t.dataPlano.isSmallerThanValue(nextDay)))
          .get();

      final totalProducoesPlanejadas = prodDia.where((p) => p.status == 'planejada').length;
      final totalProducoesEmAndamento = prodDia.where((p) => p.status == 'em_preparacao' || p.status == 'em_producao' || p.status == 'parcial').length;

      final List<ProjecaoDiaItem> itensComRisco = [];
      if (pedidosIds.isNotEmpty) {
        final orderItens = await (db.select(db.itensPedidoTable)
              ..where((t) => t.pedidoId.isIn(pedidosIds) & t.deletedAt.isNull()))
            .get();

        final Map<String, double> qtdePorProduto = {};
        final Map<String, String> nomePorProduto = {};
        for (final item in orderItens) {
          qtdePorProduto[item.produtoId] = (qtdePorProduto[item.produtoId] ?? 0.0) + item.quantidade;
          nomePorProduto[item.produtoId] = item.nomeProduto;
        }

        for (final entry in qtdePorProduto.entries) {
          final prodId = entry.key;
          final qtdReservadaDia = entry.value;

          final estoqueRecord = await (db.select(db.estoqueProdutosTable)
                ..where((t) => t.tenantId.equals(activeTenant) & t.produtoId.equals(prodId) & t.deletedAt.isNull()))
              .getSingleOrNull();

          if (estoqueRecord == null) continue;

          final double fisico = estoqueRecord.quantidadeAtual.toDouble();
          final double reservadoTotal = estoqueRecord.quantidadeReservada.toDouble();
          final double disponivel = (fisico - reservadoTotal).clamp(0.0, 999999.0);

          final prodPlanejadaAteDiaList = await (db.select(db.planejamentoProducaoTable)
                ..where((t) =>
                    t.tenantId.equals(activeTenant) &
                    t.produtoId.equals(prodId) &
                    t.deletedAt.isNull() &
                    t.status.isIn(['planejada', 'em_preparacao', 'em_producao', 'parcial']) &
                    t.dataPlano.isSmallerThanValue(nextDay)))
              .get();

          double producaoPlanejadaAteDia = 0.0;
          for (final p in prodPlanejadaAteDiaList) {
            producaoPlanejadaAteDia += (p.quantidadePlanejada - p.quantidadeProduzida).clamp(0, 999999).toDouble();
          }

          final double projetado = fisico + producaoPlanejadaAteDia - reservadoTotal;
          final bool hasRisco = projetado < 0;

          if (hasRisco) {
            itensComRisco.add(ProjecaoDiaItem(
              produtoId: prodId,
              nomeProduto: nomePorProduto[prodId] ?? 'Produto',
              quantidadeDisponivel: disponivel,
              quantidadeReservadaDia: qtdReservadaDia,
              producaoPlanejadaAteDia: producaoPlanejadaAteDia,
              projetado: projetado,
              hasRisco: hasRisco,
            ));
          }
        }
      }

      String estStatus = 'NORMAL';
      if (itensComRisco.isNotEmpty) {
        final hasCritico = itensComRisco.any((item) => item.producaoPlanejadaAteDia == 0);
        if (hasCritico) {
          estStatus = 'CRITICO';
        } else {
          estStatus = 'ATENCAO';
        }
      }

      projecaoDias.add(ProjecaoDia(
        data: date,
        diaSemana: label,
        totalPedidos: pCount,
        totalProducoesPlanejadas: totalProducoesPlanejadas,
        totalProducoesEmAndamento: totalProducoesEmAndamento,
        itensComRisco: itensComRisco,
        pedidosIds: pedidosIds,
        estoqueStatus: estStatus,
      ));
    }

    // Consultas de Atividades Recentes
    final concluidasHoje = await (db.select(db.planejamentoProducaoTable)
          ..where((t) =>
              t.tenantId.equals(activeTenant) &
              t.deletedAt.isNull() &
              t.status.equals('concluida') &
              t.dataPlano.isBiggerOrEqualValue(startOfDay)))
        .get();
    final int countConcluidas = concluidasHoje.length;

    final criadosHoje = await (db.select(db.planejamentoProducaoTable)
          ..where((t) =>
              t.tenantId.equals(activeTenant) &
              t.deletedAt.isNull() &
              t.createdAt.isBiggerOrEqualValue(startOfDay)))
        .get();
    final int countCriados = criadosHoje.length;

    final parciaisHoje = await (db.select(db.planejamentoProducaoTable)
          ..where((t) =>
              t.tenantId.equals(activeTenant) &
              t.deletedAt.isNull() &
              t.status.equals('parcial')))
        .get();
    final int countParciais = parciaisHoje.length;

    return DashboardMetrics(
      totalPedidosHoje: totalPedidosHoje,
      faturamentoCentavosHoje: faturamentoHoje,
      totalEntregasHoje: totalEntregasHoje,
      totalRetiradasHoje: totalRetiradasHoje,
      producoesAtivasCount: producoesAtivasCount,
      ticketMedioCentavosHoje: ticketMedioHoje,
      pedidosCanceladosHoje: hojePedidosCancelados,
      faturamentoCentavosSemana: faturamentoSemana,
      faturamentoCentavosMes: faturamentoMes,
      ticketMedioCentavosSemana: ticketMedioSemana,
      ticketMedioCentavosMes: ticketMedioMes,
      totalPedidosSemana: totalPedidosSemana,
      totalPedidosMes: totalPedidosMes,
      canceladosSemana: semanaCancelados,
      canceladosMes: mesCancelados,
      faturamento7DiasCentavos: faturamento7Dias,
      faturamento30DiasCentavos: faturamento30Dias,
      faturamento7DiasDatas: faturamento7DiasDatas,
      faturamento30DiasDatas: faturamento30DiasDatas,
      topProdutos: topProdutos,
      proximasEntregas: proximasEntregas,
      timelineHoje: timelineHoje,
      projecaoDias: projecaoDias,
      producoesConcluidasHoje: countConcluidas,
      planejamentosCriadosHoje: countCriados,
      producoesParciaisHoje: countParciais,
    );
  }
}

