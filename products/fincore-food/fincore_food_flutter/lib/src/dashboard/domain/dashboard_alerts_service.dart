import 'package:drift/drift.dart';
import 'package:fincore_core/database/fincore_database.dart';
import 'package:fincore_core/di/dependency_injection.dart';
import 'package:fincore_core/context/tenant_context.dart';
import 'package:intl/intl.dart';
import '../../estoque/controllers/estoque_controller.dart';
import '../../estoque/controllers/planejamento_controller.dart';

enum TipoAlertaOperacional {
  pedidoAtrasado,
  producaoAtrasada,
  pedidoProximoSemEstoque,
  estoqueCriticoSemProducao,
  estoqueCriticoComProducao,
  estoqueBaixoSemProducao,
  campanhaEmExecucao,
  producaoConcluidaRecente,
}

enum CategoriaAlerta {
  acaoNecessaria, // Vermelho
  acompanhamento, // Amarelo
  informativo,    // Verde / Azul
}

class AlertaOperacional {
  final TipoAlertaOperacional tipo;
  final CategoriaAlerta categoria;
  final String titulo;
  final String descricao;
  final int prioridade; // Menor valor = Maior prioridade (0 = Urgente, 6 = Baixa)
  final String? produtoId;
  final String? pedidoId;
  final String? planoId;
  final String? extra;
  final String? impacto;
  final String? acaoLabel;
  final DateTime? dataHora;
  final int atrasoMinutos;

  // Indicadores reais para popovers/tooltips explicativos
  final int disponivel;
  final int reservado;
  final int planejado;
  final int produzido;
  final int minimo;
  final int critico;
  final int fisico;

  const AlertaOperacional({
    required this.tipo,
    required this.categoria,
    required this.titulo,
    required this.descricao,
    required this.prioridade,
    this.produtoId,
    this.pedidoId,
    this.planoId,
    this.extra,
    this.impacto,
    this.acaoLabel,
    this.dataHora,
    this.atrasoMinutos = 0,
    this.disponivel = 0,
    this.reservado = 0,
    this.planejado = 0,
    this.produzido = 0,
    this.minimo = 0,
    this.critico = 0,
    this.fisico = 0,
  });
}

class DashboardAlertsService {
  final FincoreDatabase _db;
  final TenantContext _context;

  DashboardAlertsService()
      : _db = DependencyInjection().get<FincoreDatabase>(),
        _context = DependencyInjection().get<TenantContext>();

  /// Consolida e gera os alertas operacionais categorizados e ordenados por urgência
  Future<List<AlertaOperacional>> obterAlertasAtivos(
    EstoqueController estoqueCtrl,
    PlanoProducaoController planoCtrl,
  ) async {
    final List<AlertaOperacional> alertas = [];
    if (!_context.hasContext) return alertas;

    final tenantId = _context.tenantId;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));

    // ── 0. Pedidos Atrasados (Atendimento / Cozinha / Entrega) ──
    final pedidosAtivos = await (_db.select(_db.pedidosTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull() &
              t.status.isNotIn(['entregue', 'concluido', 'cancelado', 'rascunho'])))
        .get();

    for (final pedido in pedidosAtivos) {
      DateTime? dataEntrega;
      final ordens = await (_db.select(_db.ordensPreparoTable)
            ..where((t) => t.pedidoId.equals(pedido.id) & t.deletedAt.isNull()))
          .get();
      if (ordens.isNotEmpty && ordens.first.observacoes != null) {
        dataEntrega = _parseAgendadoFromObs(ordens.first.observacoes!);
      }
      dataEntrega ??= pedido.dataHoraEntregaPrevista?.toLocal();

      final dataCriacao = pedido.dataHoraCriacao.toLocal();

      bool isAtrasado = false;
      String motivoAtraso = '';
      int minAtraso = 0;

      final formatDataCriacao = DateFormat('dd/MM/yyyy HH:mm').format(dataCriacao);

      if (dataEntrega != null) {
        if (now.isAfter(dataEntrega)) {
          minAtraso = now.difference(dataEntrega).inMinutes;
          if (minAtraso >= 1) {
            isAtrasado = true;
            final formatPrazo = DateFormat('dd/MM/yyyy HH:mm').format(dataEntrega);
            motivoAtraso = 'Data/Hora do Pedido: $formatDataCriacao. Prazo de entrega/retirada ($formatPrazo) excedido há ${minAtraso}min.';
          }
        }
      } else {
        final minDecorridos = now.difference(dataCriacao).inMinutes;
        if (minDecorridos > 30) {
          isAtrasado = true;
          minAtraso = minDecorridos - 30;
          motivoAtraso = 'Data/Hora do Pedido: $formatDataCriacao. Pedido imediato ultrapassou o tempo padrão de atendimento (atrasado há ${minAtraso}min).';
        }
      }

      if (isAtrasado) {
        final numPed = pedido.numeroPedido != null && pedido.numeroPedido! > 0
            ? '#${pedido.numeroPedido}'
            : 'ID ${pedido.id.substring(0, 6)}';
        final cliente = (pedido.clienteNomeAvulso != null && pedido.clienteNomeAvulso!.trim().isNotEmpty)
            ? pedido.clienteNomeAvulso!
            : 'Cliente';

        alertas.add(AlertaOperacional(
          tipo: TipoAlertaOperacional.pedidoAtrasado,
          categoria: CategoriaAlerta.acaoNecessaria,
          titulo: 'Pedido Atrasado ($numPed)',
          descricao: 'Pedido de $cliente (${pedido.tipoLogistica.isNotEmpty ? pedido.tipoLogistica : "Entrega/Retirada"}). $motivoAtraso',
          impacto: 'Risco direto de insatisfação do cliente e descumprimento do prazo prometido de entrega.',
          acaoLabel: 'Ver Pedido',
          prioridade: 0,
          pedidoId: pedido.id,
          dataHora: dataEntrega ?? dataCriacao,
          atrasoMinutos: minAtraso,
        ));
      }
    }

    // ── 1. Produções Atrasadas ──
    final planosAtivos = planoCtrl.planosAtivos;

    final produtosComAtraso = planosAtivos
        .where((p) => p.status == 'planejada' && p.dataPlano.isBefore(now))
        .map((p) => p.produtoId)
        .toSet();

    final produtosEmAndamento = planosAtivos
        .where((p) => p.status == 'em_preparacao' || p.status == 'em_producao' || p.status == 'parcial')
        .map((p) => p.produtoId)
        .toSet();

    for (final plano in planosAtivos) {
      if (plano.status == 'planejada' && plano.dataPlano.isBefore(now)) {
        final prodItem = estoqueCtrl.itens.where((i) => i.estoque.produtoId == plano.produtoId).firstOrNull;
        if (prodItem == null) continue;

        final minAtraso = now.difference(plano.dataPlano).inMinutes;
        final formatHora = DateFormat('dd/MM/yyyy HH:mm').format(plano.dataPlano.toLocal());
        alertas.add(AlertaOperacional(
          tipo: TipoAlertaOperacional.producaoAtrasada,
          categoria: CategoriaAlerta.acaoNecessaria,
          titulo: 'Produção Atrasada',
          descricao: '${prodItem.nomeProduto} deveria ter sido executada em $formatHora.',
          impacto: 'Atraso na entrada física de estoque pode comprometer os pedidos agendados.',
          acaoLabel: 'Ver Planejamento',
          prioridade: 0,
          produtoId: plano.produtoId,
          planoId: plano.id,
          dataHora: plano.dataPlano,
          atrasoMinutos: minAtraso,
          disponivel: prodItem.quantidadeDisponivel,
          reservado: prodItem.quantidadeReservada,
          planejado: plano.quantidadePlanejada - plano.quantidadeProduzida,
          produzido: plano.quantidadeProduzida,
          minimo: prodItem.quantidadeMinima,
          critico: prodItem.quantidadeCritica,
          fisico: prodItem.quantidadeAtual,
        ));
      }
    }

    // ── 2. Pedidos Próximos Sem Estoque ──
    final hojePedidosAgendados = await (_db.select(_db.pedidosTable)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull() &
              t.status.isNotIn(['cancelado', 'rascunho', 'entregue', 'concluido']) &
              t.dataHoraEntregaPrevista.isBiggerOrEqualValue(startOfDay) &
              t.dataHoraEntregaPrevista.isSmallerOrEqualValue(endOfDay)))
        .get();

    if (hojePedidosAgendados.isNotEmpty) {
      final listItensHoje = await (_db.select(_db.itensPedidoTable)
            ..where((t) =>
                t.tenantId.equals(tenantId) &
                t.deletedAt.isNull()))
          .get();

      for (final pedido in hojePedidosAgendados) {
        if (pedido.dataHoraEntregaPrevista == null) continue;

        final orderItens = listItensHoje.where((it) => it.pedidoId == pedido.id).toList();
        for (final item in orderItens) {
          final prodId = item.produtoId;
          final estoqueItem = estoqueCtrl.itens.where((i) => i.estoque.produtoId == prodId).firstOrNull;
          if (estoqueItem == null) continue;

          if (estoqueItem.quantidadeAtual < estoqueItem.quantidadeReservada || estoqueItem.quantidadeDisponivel == 0) {
            final formatHora = DateFormat('HH:mm').format(pedido.dataHoraEntregaPrevista!.toLocal());
            final numPed = pedido.numeroPedido != null ? '#${pedido.numeroPedido}' : 'avulso';
            
            final temPlano = estoqueItem.producaoPlanejada > 0;
            alertas.add(AlertaOperacional(
              tipo: TipoAlertaOperacional.pedidoProximoSemEstoque,
              categoria: CategoriaAlerta.acaoNecessaria,
              titulo: 'Pedido Próximo Sem Estoque',
              descricao: 'O pedido $numPed será preparado às $formatHora e o estoque atual de ${estoqueItem.nomeProduto} é insuficiente.',
              impacto: 'Risco crítico de atraso ou impossibilidade de atendimento da entrega agendada.',
              acaoLabel: temPlano ? 'Acompanhar Produção' : 'Planejar Produção',
              prioridade: 1,
              produtoId: prodId,
              pedidoId: pedido.id,
              dataHora: pedido.dataHoraEntregaPrevista,
              disponivel: estoqueItem.quantidadeDisponivel,
              reservado: estoqueItem.quantidadeReservada,
              planejado: estoqueItem.producaoPlanejada,
              minimo: estoqueItem.quantidadeMinima,
              critico: estoqueItem.quantidadeCritica,
              fisico: estoqueItem.quantidadeAtual,
            ));
            break; // Apenas um alerta por pedido
          }
        }
      }
    }

    // ── 3. Estoque Crítico Sem Produção / Com Produção ──
    // ── 4. Estoque Baixo Sem Produção ──
    for (final item in estoqueCtrl.itens) {
      final prodId = item.estoque.produtoId;
      if (produtosComAtraso.contains(prodId)) continue;
      if (produtosEmAndamento.contains(prodId)) continue;

      if (item.status == EstoqueStatus.critico) {
        if (item.producaoPlanejada == 0) {
          alertas.add(AlertaOperacional(
            tipo: TipoAlertaOperacional.estoqueCriticoSemProducao,
            categoria: CategoriaAlerta.acaoNecessaria,
            titulo: 'Estoque Crítico',
            descricao: 'Estoque de ${item.nomeProduto} está em nível crítico e não há nenhuma produção planejada.',
            impacto: 'Novos pedidos deste produto correm risco iminente de não serem atendidos.',
            acaoLabel: 'Planejar Produção',
            prioridade: 2,
            produtoId: item.estoque.produtoId,
            disponivel: item.quantidadeDisponivel,
            reservado: item.quantidadeReservada,
            planejado: 0,
            minimo: item.quantidadeMinima,
            critico: item.quantidadeCritica,
            fisico: item.quantidadeAtual,
          ));
        } else {
          // Estoque crítico com produção planejada (ACOMPANHAMENTO)
          alertas.add(AlertaOperacional(
            tipo: TipoAlertaOperacional.estoqueCriticoComProducao,
            categoria: CategoriaAlerta.acompanhamento,
            titulo: 'Estoque Crítico — Produção Planejada',
            descricao: 'Há um déficit de ${item.deficitAtual} un. de ${item.nomeProduto}, mas já existe produção planejada.',
            impacto: 'Existe produção planejada, porém o estoque físico ainda não foi abastecido.',
            acaoLabel: 'Acompanhar Produção',
            prioridade: 3,
            produtoId: item.estoque.produtoId,
            disponivel: item.quantidadeDisponivel,
            reservado: item.quantidadeReservada,
            planejado: item.producaoPlanejada,
            minimo: item.quantidadeMinima,
            critico: item.quantidadeCritica,
            fisico: item.quantidadeAtual,
          ));
        }
      } else if (item.status == EstoqueStatus.baixo && item.producaoPlanejada == 0) {
        alertas.add(AlertaOperacional(
          tipo: TipoAlertaOperacional.estoqueBaixoSemProducao,
          categoria: CategoriaAlerta.acaoNecessaria,
          titulo: 'Estoque Baixo',
          descricao: '${item.nomeProduto} está abaixo do estoque mínimo (${item.quantidadeMinima} un) e sem produção programada.',
          impacto: 'O produto está na zona de risco de esgotamento caso ocorra um pico de demanda.',
          acaoLabel: 'Planejar Produção',
          prioridade: 4,
          produtoId: item.estoque.produtoId,
          disponivel: item.quantidadeDisponivel,
          reservado: item.quantidadeReservada,
          planejado: 0,
          minimo: item.quantidadeMinima,
          critico: item.quantidadeCritica,
          fisico: item.quantidadeAtual,
        ));
      }
    }

    // ── 5. Campanhas em Execução ou Produção Parcial ──
    for (final plano in planosAtivos) {
      if (plano.status == 'em_preparacao' || plano.status == 'em_producao' || plano.status == 'parcial') {
        final prodItem = estoqueCtrl.itens.where((i) => i.estoque.produtoId == plano.produtoId).firstOrNull;
        if (prodItem == null) continue;

        final isParcial = plano.status == 'parcial';
        alertas.add(AlertaOperacional(
          tipo: TipoAlertaOperacional.campanhaEmExecucao,
          categoria: CategoriaAlerta.acompanhamento,
          titulo: isParcial ? 'Produção Parcial' : 'Produção em Andamento',
          descricao: 'Campanha de ${prodItem.nomeProduto} (${plano.quantidadePlanejada} un) está em execução.',
          impacto: 'Ação tomada. Acompanhe a conclusão para o abastecimento automático do estoque físico.',
          acaoLabel: 'Acompanhar Produção',
          prioridade: 5,
          produtoId: plano.produtoId,
          planoId: plano.id,
          dataHora: plano.dataPlano,
          disponivel: prodItem.quantidadeDisponivel,
          reservado: prodItem.quantidadeReservada,
          planejado: plano.quantidadePlanejada - plano.quantidadeProduzida,
          produzido: plano.quantidadeProduzida,
          minimo: prodItem.quantidadeMinima,
          critico: prodItem.quantidadeCritica,
          fisico: prodItem.quantidadeAtual,
        ));
      }
    }

    // Ordena por prioridade e desempata por minutos de atraso (decrescente: maior atraso primeiro)
    alertas.sort((a, b) {
      final compPrioridade = a.prioridade.compareTo(b.prioridade);
      if (compPrioridade != 0) return compPrioridade;

      final compAtraso = b.atrasoMinutos.compareTo(a.atrasoMinutos);
      if (compAtraso != 0) return compAtraso;

      if (a.dataHora != null && b.dataHora != null) {
        return a.dataHora!.compareTo(b.dataHora!);
      }

      return 0;
    });

    return alertas;
  }

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
}
