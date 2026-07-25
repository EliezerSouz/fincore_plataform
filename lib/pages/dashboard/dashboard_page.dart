import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/status_badge.dart';
import '../../database/app_database.dart';
import '../../models/domain_models.dart';
import '../../providers/app_view_model.dart';
import '../../modules/pedidos/widgets/pedido_detalhe_widget.dart';
import '../../services/assistente_operacional_service.dart';
import '../../modules/dashboard/widgets/central_notificacoes_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _periodoFiltro = 'Amanhã';
  final Set<int> _expandedProjections = {};
  
  String _obterDataPorExtenso() {
    final now = DateTime.now();
    final format = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');
    return format.format(now);
  }

  void _abrirDetalhePedido(BuildContext context, AppViewModel vm, int id) async {
    final completo = await vm.pedidos.completo(id);
    if (context.mounted) {
      PedidoDetalheWidget.exibirModal(
        context,
        pedidoCompleto: completo,
        onAtualizado: () {},
      );
    }
  }

  void _exibirSimuladorProducao(BuildContext context, AppViewModel vm, List<ProdutoComEstoque> estoque, List<Pedido> todosPedidos, List<ItensPedidoData> todosItens) {
    Produto? prodSelecionado;
    final qtdCtrl = TextEditingController(text: '100');
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    showDialog(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget simulationResult = const SizedBox();

          if (prodSelecionado != null) {
            final simQtd = int.tryParse(qtdCtrl.text) ?? 0;
            final item = estoque.firstWhere((e) => e.produto.id == prodSelecionado!.id);

            // Simular a projeção de 7 dias
            final dailyDemands = <int, int>{};
            for (final p in todosPedidos) {
              if (p.status == 'Cancelado' || p.status == 'Entregue' || p.status == 'Retirado') continue;
              final diff = p.dataEntrega.difference(today).inDays;
              if (diff >= 0 && diff <= 10) {
                final items = todosItens.where((i) => i.pedidoId == p.id && i.produtoId == prodSelecionado!.id);
                for (final item in items) {
                  dailyDemands[diff] = (dailyDemands[diff] ?? 0) + item.quantidade;
                }
              }
            }

            int runningSimStock = item.saldoAtual + simQtd;
            final timelinePoints = <String>[];
            String rupturaMsg = 'Sem rupturas previstas nos próximos 7 dias. Cobertura completa!';
            Color ruptureCor = Colors.green;

            for (int offset = 0; offset <= 7; offset++) {
              final dailyDemand = dailyDemands[offset] ?? 0;
              runningSimStock -= dailyDemand;
              final date = today.add(Duration(days: offset));
              final dayStr = DateFormat('E', 'pt_BR').format(date).toUpperCase().replaceAll('.', '');

              if (runningSimStock < 0) {
                timelinePoints.add('$dayStr: ❌ $runningSimStock');
                if (rupturaMsg.startsWith('Sem')) {
                  rupturaMsg = '⚠️ Ruptura projetada para: ${DateFormat('dd/MM (EEEE)').format(date)}';
                  ruptureCor = Colors.red;
                }
              } else {
                timelinePoints.add('$dayStr: $runningSimStock');
              }
            }

            simulationResult = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text('Projeção de Estoque Simulado (Próximos 7 Dias):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: timelinePoints.map((pt) {
                    final isNeg = pt.contains('❌');
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isNeg ? Colors.red.shade50 : Colors.green.shade50,
                        border: Border.all(color: isNeg ? Colors.red.shade200 : Colors.green.shade200),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(pt, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isNeg ? Colors.red.shade900 : Colors.green.shade900)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ruptureCor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ruptureCor.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      Icon(ruptureCor == Colors.green ? Icons.check_circle_outline : Icons.warning_amber_rounded, color: ruptureCor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(rupturaMsg, style: TextStyle(color: ruptureCor == Colors.green ? Colors.green.shade900 : Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.science_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Simulador de Planejamento'),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selecione o produto e simule o impacto de uma produção no estoque projetado:'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Produto>(
                      value: prodSelecionado,
                      decoration: const InputDecoration(labelText: 'Produto'),
                      items: estoque.map((e) => DropdownMenuItem(
                        value: e.produto,
                        child: Text(e.produto.nome),
                      )).toList(),
                      onChanged: (v) {
                        setDialogState(() {
                          prodSelecionado = v;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: qtdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantidade a produzir', hintText: 'Ex.: 300'),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    if (prodSelecionado != null) simulationResult,
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(d),
                child: const Text('Fechar'),
              ),
              if (prodSelecionado != null)
                FilledButton.icon(
                  onPressed: () {
                    final qtd = int.tryParse(qtdCtrl.text) ?? 0;
                    Navigator.pop(d);
                    vm.navegarProducao(produto: prodSelecionado!, quantidade: qtd);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar Produção'),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final db = vm.db;

    final hojeAgora = DateTime.now();
    final inicioHoje = DateTime(hojeAgora.year, hojeAgora.month, hojeAgora.day);
    final fimHoje = inicioHoje.add(const Duration(days: 1));
    final fimAmanha = fimHoje.add(const Duration(days: 1));

    // Buscar todos os pedidos
    final qTodosPedidos = db.select(db.pedidos)
      ..orderBy([(p) => OrderingTerm.desc(p.criadoEm)]);

    return StreamBuilder<List<Pedido>>(
      stream: qTodosPedidos.watch(),
      builder: (context, sTodosPedidos) {
        final todosPedidos = sTodosPedidos.data ?? [];
        
        // Pedidos de hoje e amanhã
        final pedidosHoje = todosPedidos.where((p) => (p.dataEntrega.isAfter(inicioHoje) || p.dataEntrega.isAtSameMomentAs(inicioHoje)) && p.dataEntrega.isBefore(fimHoje) && p.status != 'Cancelado').toList();
        final pedidosAgendaHoje = todosPedidos.where((p) => p.dataEntrega.isAfter(inicioHoje) && p.dataEntrega.isBefore(fimHoje) && p.status != 'Cancelado').toList()
          ..sort((a, b) => a.dataEntrega.compareTo(b.dataEntrega));
        // KPIs de Desempenho

        return StreamBuilder<List<ProdutoComEstoque>>(
          stream: vm.observarEstoque(),
          builder: (context, sEstoque) {
            final estoque = sEstoque.data ?? [];

            return StreamBuilder<List<MovimentacoesEstoqueData>>(
              stream: (db.select(db.movimentacoesEstoque)
                    ..where((m) => m.criadoEm.isBiggerOrEqualValue(inicioHoje))
                    ..where((m) => m.tipoMovimentacao.equals('ENTRADA_PRODUCAO')))
                  .watch(),
              builder: (context, sMovs) {
                final movsHoje = sMovs.data ?? [];

                // Fabricação de hoje agrupada
                final producaoAcumulada = <String, int>{};
                for (final m in movsHoje) {
                  final prod = estoque.firstWhere(
                    (e) => e.produto.id == m.produtoId,
                    orElse: () => ProdutoComEstoque(
                      produto: const Produto(
                        id: 0,
                        nome: 'Desconhecido',
                        categoria: '',
                        ativo: false,
                        tempoMedioMinutos: 0,
                        controlaEstoque: false,
                        ordemProducao: 0,
                      ),
                      saldoAtual: 0,
                      reservado: 0,
                      estoqueMinimo: 0,
                      estoqueIdeal: 0,
                      loteMinimo: 1,
                    ),
                  );
                  if (prod.produto.id != 0) {
                    producaoAcumulada[prod.produto.nome] =
                        (producaoAcumulada[prod.produto.nome] ?? 0) + m.quantidade;
                  }
                }

                return FutureBuilder<List<ItensPedidoData>>(
                  future: db.select(db.itensPedido).get(),
                  builder: (context, sItens) {
                    final todosItens = sItens.data ?? [];

                    // 1. Calculate boundaries for Reserva Operacional (from settings)
                    final horizon = vm.settings.horizonteOperacional;
                    DateTime filtroHorizonInicio = inicioHoje;
                    DateTime filtroHorizonFim = fimAmanha;
                    if (horizon == 'Hoje') {
                      filtroHorizonFim = fimHoje;
                    } else if (horizon == 'Hoje + Amanhã') {
                      filtroHorizonFim = fimAmanha;
                    } else if (horizon == 'Próximos 3 dias') {
                      filtroHorizonFim = inicioHoje.add(const Duration(days: 3));
                    } else if (horizon == 'Próximos 7 dias') {
                      filtroHorizonFim = inicioHoje.add(const Duration(days: 7));
                    } else if (horizon == 'Todos') {
                      filtroHorizonFim = inicioHoje.add(const Duration(days: 3650));
                    }

                    // 2. Calculate Reserva Operacional quantities
                    final ordersInHorizon = todosPedidos
                        .where((p) =>
                            p.dataEntrega.isAfter(filtroHorizonInicio) &&
                            p.dataEntrega.isBefore(filtroHorizonFim) &&
                            p.status != 'Cancelado')
                        .toList();
                    final Map<int, int> MapResOperacional = {};
                    for (final p in ordersInHorizon) {
                      final items = todosItens.where((i) => i.pedidoId == p.id);
                      for (final item in items) {
                        MapResOperacional[item.produtoId] =
                            (MapResOperacional[item.produtoId] ?? 0) + item.quantidade;
                      }
                    }

                    // 3. Calculate Demanda por Período de Sugestão
                    DateTime filtroInicio = inicioHoje;
                    DateTime filtroFim = fimAmanha;
                    if (_periodoFiltro == 'Hoje') {
                      filtroInicio = inicioHoje;
                      filtroFim = fimHoje;
                    } else if (_periodoFiltro == 'Amanhã') {
                      filtroInicio = fimHoje;
                      filtroFim = fimAmanha;
                    } else if (_periodoFiltro == '7 dias') {
                      filtroInicio = inicioHoje;
                      filtroFim = inicioHoje.add(const Duration(days: 7));
                    } else if (_periodoFiltro == 'Todos') {
                      filtroInicio = inicioHoje;
                      filtroFim = inicioHoje.add(const Duration(days: 3650));
                    }

                    final pedidosNoPeriodo = todosPedidos
                        .where((p) =>
                            p.dataEntrega.isAfter(filtroInicio) &&
                            p.dataEntrega.isBefore(filtroFim) &&
                            p.status != 'Cancelado')
                        .toList();
                    final Map<int, int> MapDemandaPeriodo = {};
                    for (final p in pedidosNoPeriodo) {
                      final items = todosItens.where((i) => i.pedidoId == p.id);
                      for (final item in items) {
                        MapDemandaPeriodo[item.produtoId] =
                            (MapDemandaPeriodo[item.produtoId] ?? 0) + item.quantidade;
                      }
                    }

                    // 4. Pedidos por Categoria (Hoje, Amanhã, Semana, Mês)
                    int countPedidosHoje = todosPedidos
                        .where((p) =>
                            p.dataEntrega.isAfter(inicioHoje) &&
                            p.dataEntrega.isBefore(fimHoje) &&
                            p.status != 'Cancelado')
                        .length;
                    int countPedidosAmanha = todosPedidos
                        .where((p) =>
                            p.dataEntrega.isAfter(fimHoje) &&
                            p.dataEntrega.isBefore(fimAmanha) &&
                            p.status != 'Cancelado')
                        .length;
                    int countPedidosSemana = todosPedidos
                        .where((p) =>
                            p.dataEntrega.isAfter(inicioHoje) &&
                            p.dataEntrega.isBefore(inicioHoje.add(const Duration(days: 7))) &&
                            p.status != 'Cancelado')
                        .length;
                    int countPedidosMes = todosPedidos
                        .where((p) =>
                            p.dataEntrega.isAfter(inicioHoje) &&
                            p.dataEntrega.isBefore(inicioHoje.add(const Duration(days: 30))) &&
                            p.status != 'Cancelado')
                        .length;

                    // 5. Projeções, Rupturas, Cobertura
                    final Map<int, Map<int, int>> MapDemandByDay = {}; // prodId -> {dayOffset -> quantity}
                    final Map<int, int> MapTotalActiveDemand = {};
                    for (final p in todosPedidos) {
                      if (p.status == 'Cancelado' ||
                          p.status == 'Entregue' ||
                          p.status == 'Retirado') continue;
                      final diff = p.dataEntrega.difference(inicioHoje).inDays;
                      final offset = diff.clamp(0, 15);
                      final items = todosItens.where((i) => i.pedidoId == p.id);
                      for (final item in items) {
                        if (!MapDemandByDay.containsKey(item.produtoId)) {
                          MapDemandByDay[item.produtoId] = {};
                        }
                        MapDemandByDay[item.produtoId]![offset] =
                            (MapDemandByDay[item.produtoId]![offset] ?? 0) + item.quantidade;
                        MapTotalActiveDemand[item.produtoId] =
                            (MapTotalActiveDemand[item.produtoId] ?? 0) + item.quantidade;
                      }
                    }

                    final sugestoes = <Map<String, dynamic>>[];
                    final listProjecoes = <Map<String, dynamic>>[];
                    final listAlertasCriticos = <String>[];
                    final listAlertasAtencao = <String>[];

                    // Analisar cada produto
                    for (final item in estoque) {
                      final p = item.produto;
                      if (!p.controlaEstoque) continue;

                      final fisico = item.saldoAtual;
                      final min = item.estoqueMinimo;
                      final ideal = item.estoqueIdeal;
                      final lote = item.loteMinimo;
                      final resOperacional = MapResOperacional[p.id] ?? 0;
                      final resComercial = item.reservado;
                      final dispOperacional = (fisico - resOperacional);

                      // Cobertura de Estoque (Demanda média)
                      double demandaMedia = 15.0; // default average daily demand
                      if (MapTotalActiveDemand[p.id] != null) {
                        demandaMedia = (MapTotalActiveDemand[p.id]! / 7.0).clamp(1.0, 99999.0);
                      }
                      double coberturaDias = fisico / demandaMedia;

                      // Projeção 7 dias e Ruptura
                      int runningStock = fisico;
                      final projTimeline = <String>[];
                      DateTime? dataRuptura;

                      for (int dOffset = 0; dOffset <= 7; dOffset++) {
                        final dailyDemand = MapDemandByDay[p.id]?[dOffset] ?? 0;
                        runningStock -= dailyDemand;
                        final date = inicioHoje.add(Duration(days: dOffset));
                        final dayStr = DateFormat('E', 'pt_BR')
                            .format(date)
                            .toUpperCase()
                            .replaceAll('.', '');

                        if (runningStock < 0) {
                          projTimeline.add('$dayStr: ❌ $runningStock');
                          if (dataRuptura == null) {
                            dataRuptura = date;
                          }
                        } else {
                          projTimeline.add('$dayStr: $runningStock');
                        }
                      }

                      // Sugestão de Produção
                      final demandPeriodo = MapDemandaPeriodo[p.id] ?? 0;
                      final necessidade = (demandPeriodo + min) - fisico;
                      if (necessidade > 0) {
                        int sugerido = necessidade;
                        if (lote > 1) {
                          sugerido = (necessidade / lote).ceil() * lote;
                        }

                        final isUrgente = (fisico < min) || (fisico - resComercial < 0);
                        sugestoes.add({
                          'produto': p,
                          'necessidade': necessidade,
                          'sugerido': sugerido,
                          'disp': dispOperacional,
                          'demand': demandPeriodo,
                          'min': min,
                          'lote': lote,
                          'prioridade': isUrgente ? 'URGENTE' : 'IMPORTANTE',
                          'cor': isUrgente ? Colors.red : Colors.orange,
                        });
                      }

                      listProjecoes.add({
                        'produto': p,
                        'fisico': fisico,
                        'resComercial': resComercial,
                        'resOperacional': resOperacional,
                        'cobertura': coberturaDias,
                        'timeline': projTimeline,
                        'ruptura': dataRuptura,
                      });

                      // Alertas
                      if (fisico < min) {
                        listAlertasAtencao.add(
                            '${p.nome} está abaixo do mínimo (Físico: $fisico un., Mínimo: $min un.)');
                      }
                      if (fisico < resComercial) {
                        listAlertasCriticos.add(
                            '${p.nome} possui déficit comercial (Físico: $fisico un., Reservado Comercial: $resComercial un.)');
                      }
                    }

                    // 6. Alertas Futuros e Cobertura Inteligente
                    final listAlertasFuturos = <Map<String, dynamic>>[];
                    final attentionProducts = <Map<String, dynamic>>[];

                    for (final proj in listProjecoes) {
                      final prod = proj['produto'] as Produto;
                      final min = estoque.firstWhere((e) => e.produto.id == prod.id).estoqueMinimo;
                      final dataRuptura = proj['ruptura'] as DateTime?;
                      final cob = proj['cobertura'] as double;
                      final fisico = proj['fisico'] as int;

                      // Find suggestion
                      final sug = sugestoes.firstWhere((s) => (s['produto'] as Produto).id == prod.id, orElse: () => {});
                      final sugerido = sug.isNotEmpty ? sug['sugerido'] as int : 0;

                      // Classificação de atenção
                      Color cor;
                      String iconStr;
                      String desc;

                      if (dataRuptura != null && dataRuptura.difference(inicioHoje).inDays <= 3) {
                        cor = Colors.red;
                        iconStr = '🔴';
                        final diaSemana = DateFormat('EEEE', 'pt_BR').format(dataRuptura);
                        final diaSemanaCapitalized = diaSemana[0].toUpperCase() + diaSemana.substring(1);
                        desc = 'Cobertura: até $diaSemanaCapitalized • Produzir: $sugerido un.';
                      } else if (fisico < min) {
                        cor = Colors.orange;
                        iconStr = '🟠';
                        final diaSemana = dataRuptura != null ? DateFormat('EEEE', 'pt_BR').format(dataRuptura) : 'Domingo';
                        final diaSemanaCapitalized = diaSemana[0].toUpperCase() + diaSemana.substring(1);
                        desc = 'Cobertura: até $diaSemanaCapitalized • Produzir: $sugerido un.';
                      } else if (cob < 5) {
                        cor = Colors.yellow.shade800;
                        iconStr = '🟡';
                        desc = 'Estoque mínimo será atingido em ${(cob).toStringAsFixed(0)} dias.';
                      } else {
                        continue;
                      }

                      attentionProducts.add({
                        'produto': prod,
                        'cor': cor,
                        'icon': iconStr,
                        'desc': desc,
                        'timeline': proj['timeline'] as List<String>,
                      });

                      // Projeção futura dia a dia para alertas
                      int runningStock = proj['fisico'] as int;
                      bool minAtingido = false;
                      bool rupturaAtingida = false;

                      for (int dOffset = 0; dOffset <= 7; dOffset++) {
                        final dailyDemand = MapDemandByDay[prod.id]?[dOffset] ?? 0;
                        runningStock -= dailyDemand;
                        final date = inicioHoje.add(Duration(days: dOffset));
                        final diaSemanaStr = DateFormat('EEEE', 'pt_BR').format(date);
                        final diaSemanaCapitalized = diaSemanaStr[0].toUpperCase() + diaSemanaStr.substring(1);

                        if (runningStock < 0 && !rupturaAtingida) {
                          rupturaAtingida = true;
                          listAlertasFuturos.add({
                            'dia': diaSemanaCapitalized,
                            'tipo': 'ruptura',
                            'msg': '${prod.nome} ficará em ruptura.',
                          });
                        } else if (runningStock < min && !minAtingido && runningStock >= 0) {
                          minAtingido = true;
                          listAlertasFuturos.add({
                            'dia': diaSemanaCapitalized,
                            'tipo': 'minimo',
                            'msg': '${prod.nome} ficará abaixo do mínimo.',
                          });
                        }
                      }
                    }

                    // Rupturas iminentes de projeção
                    for (final proj in listProjecoes) {
                      if (proj['ruptura'] != null) {
                        final diffDays =
                            (proj['ruptura'] as DateTime).difference(inicioHoje).inDays;
                        final diaSemanaStr = DateFormat('EEEE', 'pt_BR').format(proj['ruptura']);
                        final prodNome = (proj['produto'] as Produto).nome;
                        final msg =
                            'Ruptura de estoque prevista de $prodNome no $diaSemanaStr ($diffDays dias)';
                        if (diffDays <= 2) {
                          listAlertasCriticos.add(msg);
                        } else {
                          listAlertasAtencao.add(msg);
                        }
                      }
                    }

                    // Alertas de Pedidos em Atraso ou em Risco (12 horas)
                    final proximoLimite = DateTime.now().add(const Duration(hours: 12));
                    for (final p in todosPedidos) {
                      if (p.status != 'Cancelado' && p.status != 'Finalizado' && p.status != 'Entregue') {
                        if (p.dataEntrega.isBefore(DateTime.now())) {
                          listAlertasCriticos.add(
                            '🚨 Pedido #${pedidoNumero(p.numero)} (${p.clienteNome}) está EM ATRASO! Entrega era para ${DateFormat("dd/MM 'às' HH:mm").format(p.dataEntrega)}'
                          );
                        } else if (p.dataEntrega.isBefore(proximoLimite)) {
                          final items = todosItens.where((i) => i.pedidoId == p.id);
                          for (final item in items) {
                            final est = estoque.firstWhere(
                              (e) => e.produto.id == item.produtoId,
                              orElse: () => ProdutoComEstoque(
                                produto: const Produto(
                                  id: 0,
                                  nome: 'Desconhecido',
                                  categoria: '',
                                  ativo: false,
                                  tempoMedioMinutos: 0,
                                  controlaEstoque: false,
                                  ordemProducao: 0,
                                ),
                                saldoAtual: 0,
                                reservado: 0,
                                estoqueMinimo: 0,
                                estoqueIdeal: 0,
                                loteMinimo: 1,
                              ),
                            );
                            if (est.produto.controlaEstoque && est.saldoAtual < item.quantidade) {
                              listAlertasCriticos.add(
                                  'Pedido #${pedidoNumero(p.numero)} (${p.clienteNome}) em risco - Falta ${item.produtoNome}');
                            }
                          }
                        }
                      }
                    }

                    // --- DETERMINAÇÃO DO ESTADO DO ASSISTENTE OPERACIONAL ---
                    Widget assistenteBanner;
                    if (listAlertasCriticos.isNotEmpty) {
                      assistenteBanner = Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200, width: 1.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 30),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🔴 OPERAÇÃO EM RISCO',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.red),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Atenção imediata requerida! Os seguintes problemas críticos foram identificados:\n• ${listAlertasCriticos.join('\n• ')}',
                                    style: TextStyle(
                                        color: Colors.red.shade900, fontSize: 13, height: 1.4),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Ação recomendada: Executar simulação de produção e fabricar as quantidades recomendadas.',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (listAlertasAtencao.isNotEmpty) {
                      assistenteBanner = Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300, width: 1.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.amber, size: 30),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🟠 ATENÇÃO REQUERIDA',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.amber),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Itens e prazos abaixo das metas estabelecidas:\n• ${listAlertasAtencao.join('\n• ')}',
                                    style: TextStyle(
                                        color: Colors.amber.shade900, fontSize: 13, height: 1.4),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Ação recomendada: Programar produção de segurança.',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.amber),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      assistenteBanner = Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200, width: 1.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.green, size: 30),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🟢 OPERAÇÃO SOB CONTROLE',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '✔ Estoque atende toda a demanda dos próximos 7 dias.',
                                    style: TextStyle(
                                        color: Colors.green.shade900, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Calcular conjuntos de pedidos para o "O Que Fazer Agora" (incluindo ativos de datas anteriores em atraso)
                    final pedidosAgendaHoje = todosPedidos
                        .where((p) =>
                            p.status != 'Cancelado' &&
                            p.status != 'Finalizado' &&
                            p.status != 'Entregue' &&
                            p.dataEntrega.isBefore(fimHoje))
                        .toList()
                      ..sort((a, b) => a.dataEntrega.compareTo(b.dataEntrega));

                    final pedidosAtrasados = todosPedidos
                        .where((p) =>
                            p.status != 'Cancelado' &&
                            p.status != 'Finalizado' &&
                            p.status != 'Entregue' &&
                            p.dataEntrega.isBefore(DateTime.now()))
                        .toList()
                      ..sort((a, b) => a.dataEntrega.compareTo(b.dataEntrega));

                    final pendentesSeparacao = pedidosAgendaHoje
                        .where((p) => p.status == 'Pendente' || p.status == 'Em Preparo')
                        .toList();

                    final prontosDespacho =
                        pedidosAgendaHoje.where((p) => p.status == 'Pronto').toList();

                    // --- FILA INTELIGENTE DE TAREFAS (O QUE FAZER AGORA) ---
                    final allTasks = <_CockpitTaskData>[];

                    // 1. Produção Urgente (necessidade imediata se disponível < 0)
                    for (final s in sugestoes) {
                      if (s['prioridade'] == 'URGENTE') {
                        final prod = s['produto'] as Produto;
                        final sugerido = s['sugerido'] as int;
                        allTasks.add(
                          _CockpitTaskData(
                            urgency: 1,
                            date: inicioHoje,
                            builder: (number) => _urgencyCard(
                              number: number,
                              title: 'Produzir $sugerido un. de ${prod.nome}',
                              subtitle: 'Estoque disponível operacional está negativo (${s['disp']} un.).',
                              buttonLabel: 'Produzir',
                              onPressed: () => vm.navegarProducao(produto: prod, quantidade: sugerido),
                              color: Colors.red,
                            ),
                          ),
                        );
                      }
                    }

                    // 2. Pedidos pendentes de separação/preparo (Exclui os que já estão na Prioridade 1!)
                    for (final p in pendentesSeparacao) {
                      final now = DateTime.now();
                      final diff = p.dataEntrega.difference(now);
                      if (diff.isNegative || p.dataEntrega.isBefore(now)) {
                        // Já está na PRIORIDADE 1 (Cliente Aguardando)! Excluir da P2 para evitar duplicidade.
                        continue;
                      }

                      final isHoje = p.dataEntrega.year == now.year && p.dataEntrega.month == now.month && p.dataEntrega.day == now.day;
                      final isAmanha = p.dataEntrega.year == now.year && p.dataEntrega.month == now.month && p.dataEntrega.day == (now.day + 1);
                      final dataEntregaStr = isHoje 
                          ? 'Hoje às ${DateFormat('HH:mm').format(p.dataEntrega)}' 
                          : (isAmanha 
                              ? 'Amanhã às ${DateFormat('HH:mm').format(p.dataEntrega)}' 
                              : DateFormat('dd/MM às HH:mm').format(p.dataEntrega));

                      String relativeTime = '';
                      if (diff.inMinutes < 60) {
                        relativeTime = 'Em ${diff.inMinutes} minutos';
                      } else if (diff.inHours < 24) {
                        relativeTime = 'Em ${diff.inHours}h';
                      } else {
                        relativeTime = 'Em ${diff.inDays} dias';
                      }

                      final isPendente = p.status == 'Pendente';

                      allTasks.add(
                        _CockpitTaskData(
                          urgency: 2,
                          date: p.dataEntrega,
                          builder: (number) => _urgencyCard(
                            number: number,
                            title: isPendente 
                                ? 'Iniciar Fritura/Preparo - Pedido #${pedidoNumero(p.numero)}' 
                                : 'Concluir Preparação - Pedido #${pedidoNumero(p.numero)}',
                            subtitle: isPendente
                                ? 'Cliente: ${p.clienteNome} • Entrega: $dataEntregaStr ($relativeTime).'
                                : 'Cliente: ${p.clienteNome} • Entrega: $dataEntregaStr ($relativeTime). Já está no óleo/forno.',
                            buttonLabel: isPendente ? 'Fritar' : 'Finalizar',
                            onPressed: () async {
                              try {
                                final novoStatus = isPendente ? 'Em Preparo' : 'Pronto';
                                await vm.pedidos.alterarStatus(p.id, novoStatus);
                                if (context.mounted) {
                                  AppSnackbar.sucesso(context, 'Pedido #${pedidoNumero(p.numero)} atualizado para $novoStatus!');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  AppSnackbar.erro(context, 'Erro ao atualizar pedido: $e');
                                }
                              }
                            },
                            color: isPendente ? Colors.blue : Colors.orange,
                          ),
                        ),
                      );
                    }

                    // 3. Confirmar pagamento PIX de pedidos ativos pendentes que selecionaram PIX
                    final pendentesPix = pedidosAgendaHoje
                        .where((p) => p.formaPagamento.toLowerCase() == 'pix' && 
                                      !p.pixConfirmado &&
                                      p.status != 'Cancelado' && 
                                      p.status != 'Entregue' && 
                                      p.status != 'Retirado')
                        .toList();
                    for (final p in pendentesPix) {
                      final now = DateTime.now();
                      final isHoje = p.dataEntrega.year == now.year && p.dataEntrega.month == now.month && p.dataEntrega.day == now.day;
                      final isAmanha = p.dataEntrega.year == now.year && p.dataEntrega.month == now.month && p.dataEntrega.day == (now.day + 1);
                      final dataEntregaStr = isHoje 
                          ? 'Hoje às ${DateFormat('HH:mm').format(p.dataEntrega)}' 
                          : (isAmanha 
                              ? 'Amanhã às ${DateFormat('HH:mm').format(p.dataEntrega)}' 
                              : DateFormat('dd/MM às HH:mm').format(p.dataEntrega));

                      allTasks.add(
                        _CockpitTaskData(
                          urgency: 3,
                          date: p.dataEntrega,
                          builder: (number) => _urgencyCard(
                            number: number,
                            title: 'Confirmar pagamento PIX',
                            subtitle: 'Pedido #${pedidoNumero(p.numero)} (${p.clienteNome}) - ${dinheiro(p.totalCentavos)} • Entrega: $dataEntregaStr.',
                            buttonLabel: 'Confirmar',
                            onPressed: () async {
                              final ref = await showDialog<String>(
                                context: context,
                                builder: (context) {
                                  final refCtrl = TextEditingController();
                                  return AlertDialog(
                                    title: const Text('Confirmar Recebimento PIX'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Certifique-se de que o valor já consta em sua conta bancária antes de confirmar.',
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: refCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'Código / Comprovante PIX',
                                            hintText: 'Ex: E123456789... ou Nome do pagador',
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.pop(context, refCtrl.text.trim());
                                        },
                                        child: const Text('Confirmar Recebimento'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (ref != null && ref.isNotEmpty) {
                                try {
                                  await vm.pedidos.confirmarPix(
                                    pedidoId: p.id,
                                    comprovantePix: ref,
                                  );
                                  if (context.mounted) {
                                    AppSnackbar.sucesso(
                                      context, 
                                      'Pagamento PIX do Pedido #${pedidoNumero(p.numero)} confirmado com sucesso!',
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppSnackbar.erro(context, 'Erro ao confirmar PIX: $e');
                                  }
                                }
                              }
                            },
                            color: Colors.teal,
                          ),
                        ),
                      );
                    }

                    // 4. Pedidos prontos aguardando despacho/retirada
                    for (final p in prontosDespacho) {
                      final isRetirada = p.tipoEntrega.toLowerCase() == 'retirada';
                      final now = DateTime.now();
                      final isHoje = p.dataEntrega.year == now.year && p.dataEntrega.month == now.month && p.dataEntrega.day == now.day;
                      final isAmanha = p.dataEntrega.year == now.year && p.dataEntrega.month == now.month && p.dataEntrega.day == (now.day + 1);
                      final dataEntregaStr = isHoje 
                          ? 'Hoje às ${DateFormat('HH:mm').format(p.dataEntrega)}' 
                          : (isAmanha 
                              ? 'Amanhã às ${DateFormat('HH:mm').format(p.dataEntrega)}' 
                              : DateFormat('dd/MM às HH:mm').format(p.dataEntrega));

                      allTasks.add(
                        _CockpitTaskData(
                          urgency: 4,
                          date: p.dataEntrega,
                          builder: (number) => _urgencyCard(
                            number: number,
                            title: isRetirada ? 'Cliente aguardando retirada' : 'Despachar Pedido #${pedidoNumero(p.numero)}',
                            subtitle: 'Pedido #${pedidoNumero(p.numero)} (${p.clienteNome}) pronto para liberação • Entrega: $dataEntregaStr.',
                            buttonLabel: isRetirada ? 'Retirar' : 'Despachar',
                            onPressed: () async {
                              try {
                                final novoStatus = isRetirada ? 'Aguardando Cliente' : 'Em Rota';
                                await vm.pedidos.alterarStatus(p.id, novoStatus);
                                if (context.mounted) {
                                  final msg = isRetirada 
                                      ? 'Pedido #${pedidoNumero(p.numero)} marcado como aguardando retirada!' 
                                      : 'Pedido #${pedidoNumero(p.numero)} despachado em rota!';
                                  AppSnackbar.sucesso(context, msg);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  AppSnackbar.erro(context, 'Erro ao despachar pedido: $e');
                                }
                              }
                            },
                            color: isRetirada ? Colors.green : Colors.deepPurple,
                          ),
                        ),
                      );
                    }

                    // Ordenar as tarefas por data/horário de entrega, e depois por urgência (critério de desempate)
                    allTasks.sort((a, b) {
                      final compDate = a.date.compareTo(b.date);
                      if (compDate != 0) return compDate;
                      return a.urgency.compareTo(b.urgency);
                    });

                    final List<Widget> urgenciasWidgets = [];
                    final maxTasksToShow = allTasks.length > 5 ? 5 : allTasks.length;
                    for (int i = 0; i < maxTasksToShow; i++) {
                      urgenciasWidgets.add(allTasks[i].builder(i + 1));
                    }



                    final faturamentoHoje = todosPedidos
                        .where((p) =>
                            p.criadoEm.isAfter(inicioHoje) && p.status != 'Cancelado')
                        .fold<int>(0, (v, p) => v + p.totalCentavos);
                    final quantidadeValidaHoje = todosPedidos
                        .where((p) =>
                            p.criadoEm.isAfter(inicioHoje) && p.status != 'Cancelado')
                        .length;
                    final ticketMedioHoje = quantidadeValidaHoje == 0
                        ? 0
                        : (faturamentoHoje / quantidadeValidaHoje).round();

                    // Métricas adicionais da salgaderia
                    int totalSalgadosVendidosHoje = 0;
                    for (final p in pedidosHoje) {
                      if (p.status == 'Cancelado') continue;
                      final items = todosItens.where((i) => i.pedidoId == p.id);
                      for (final item in items) {
                        totalSalgadosVendidosHoje += item.quantidade;
                      }
                    }

                    final vendasPorProduto = <String, int>{};
                    for (final p in pedidosHoje) {
                      if (p.status == 'Cancelado') continue;
                      final items = todosItens.where((i) => i.pedidoId == p.id);
                      for (final item in items) {
                        vendasPorProduto[item.produtoNome] = (vendasPorProduto[item.produtoNome] ?? 0) + item.quantidade;
                      }
                    }
                    final campeoes = vendasPorProduto.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    // Próximo Gargalo (Estoque crítico ou demanda reservada maior que o saldo)
                    Map<String, dynamic>? proximoGargalo;
                    for (final item in estoque) {
                      if (item.produto.controlaEstoque) {
                        final faltara = item.reservado - item.saldoAtual;
                        if (faltara > 0) {
                          if (proximoGargalo == null || faltara > (proximoGargalo['faltara'] as int)) {
                            proximoGargalo = {
                              'produto': item.produto,
                              'dias': 1,
                              'faltara': faltara,
                            };
                          }
                        }
                      }
                    }

                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. MISSÃO DO DIA (Header & Progress Indicators)
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade900, Colors.blue.shade800],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '🎯 MISSÃO DO DIA (COCKPIT OPERACIONAL)',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_obterDataPorExtenso()} • Previsão Faturamento: ${dinheiro(faturamentoHoje)} • Previsão Término: 18:40',
                                              style: TextStyle(color: Colors.blue.shade100, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.blue.shade900,
                                        ),
                                        onPressed: () => vm.navegar(1),
                                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                                        label: const Text('Novo Pedido', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // 4 Barras de Progresso Visual Operacional
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildProgressCard(
                                          title: 'Pedidos Hoje',
                                          valueStr: '${pedidosHoje.where((p) => p.status == "Entregue" || p.status == "Retirado").length} / ${pedidosHoje.length}',
                                          progress: pedidosHoje.isEmpty ? 0 : pedidosHoje.where((p) => p.status == "Entregue" || p.status == "Retirado").length / pedidosHoje.length,
                                          color: Colors.cyanAccent,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildProgressCard(
                                          title: 'Produção',
                                          valueStr: '$totalSalgadosVendidosHoje un',
                                          progress: 0.65,
                                          color: Colors.amberAccent,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildProgressCard(
                                          title: 'Entregas',
                                          valueStr: '${pedidosAgendaHoje.where((p) => p.status == "Entregue").length} / ${pedidosAgendaHoje.length}',
                                          progress: pedidosAgendaHoje.isEmpty ? 0 : pedidosAgendaHoje.where((p) => p.status == "Entregue").length / pedidosAgendaHoje.length,
                                          color: Colors.lightGreenAccent,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildProgressCard(
                                          title: 'PIX Confirmado',
                                          valueStr: '${pedidosHoje.where((p) => p.formaPagamento.toLowerCase().contains("pix") && p.pixConfirmado).length} / ${pedidosHoje.where((p) => p.formaPagamento.toLowerCase().contains("pix")).length}',
                                          progress: pedidosHoje.where((p) => p.formaPagamento.toLowerCase().contains("pix")).isEmpty
                                              ? 1
                                              : pedidosHoje.where((p) => p.formaPagamento.toLowerCase().contains("pix") && p.pixConfirmado).length /
                                                  pedidosHoje.where((p) => p.formaPagamento.toLowerCase().contains("pix")).length,
                                          color: Colors.tealAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                           const SizedBox(height: 20),
                           // 🚨 PRIORIDADE 1 — CLIENTE AGUARDANDO (Banner Dinâmico Dominante de Largura Total)
                           if (pedidosAtrasados.isNotEmpty) ...[
                             Container(
                               margin: const EdgeInsets.only(bottom: 20),
                               padding: const EdgeInsets.all(24),
                               decoration: BoxDecoration(
                                 color: Colors.red.shade600,
                                 borderRadius: BorderRadius.circular(16),
                                 boxShadow: [
                                   BoxShadow(
                                     color: Colors.red.withValues(alpha: 0.4),
                                     blurRadius: 16,
                                     offset: const Offset(0, 6),
                                   ),
                                 ],
                               ),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Row(
                                         children: [
                                           Container(
                                             padding: const EdgeInsets.all(10),
                                             decoration: const BoxDecoration(
                                               color: Colors.white,
                                               shape: BoxShape.circle,
                                             ),
                                             child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                                           ),
                                           const SizedBox(width: 14),
                                           Column(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                                               Text(
                                                 '🚨 PRIORIDADE 1 — CLIENTE AGUARDANDO (${pedidosAtrasados.length} ${pedidosAtrasados.length == 1 ? "PEDIDO ATRASADO" : "PEDIDOS ATRASADOS"})',
                                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white, letterSpacing: 0.5),
                                               ),
                                               const SizedBox(height: 2),
                                               const Text(
                                                 'Existe cliente aguardando atendimento imediato. Atenda estes pedidos antes de prosseguir!',
                                                 style: TextStyle(color: Colors.white70, fontSize: 13),
                                               ),
                                             ],
                                           ),
                                         ],
                                       ),
                                     ],
                                   ),
                                   const Divider(color: Colors.white24, height: 28),
                                   ...pedidosAtrasados.map((p) {
                                     final diff = DateTime.now().difference(p.dataEntrega);
                                     final minsAtraso = diff.inMinutes;
                                     final horasAtraso = diff.inHours;
                                     final tempoAtrasoStr = horasAtraso > 0 ? '$horasAtraso h e ${minsAtraso % 60} min' : '$minsAtraso min';

                                     return Container(
                                       margin: const EdgeInsets.only(bottom: 10),
                                       padding: const EdgeInsets.all(16),
                                       decoration: BoxDecoration(
                                         color: Colors.white,
                                         borderRadius: BorderRadius.circular(12),
                                       ),
                                       child: Row(
                                         children: [
                                           Expanded(
                                             child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               children: [
                                                 Text(
                                                   'Pedido #${pedidoNumero(p.numero)} — ${p.clienteNome}',
                                                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                                 ),
                                                 const SizedBox(height: 4),
                                                 Text(
                                                   'Agendado: ${DateFormat("HH:mm").format(p.dataEntrega)} • Atrasado há $tempoAtrasoStr • Status: ${p.status}',
                                                   style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                                 ),
                                               ],
                                             ),
                                           ),
                                           FilledButton.icon(
                                             style: FilledButton.styleFrom(
                                               backgroundColor: Colors.red.shade700,
                                               foregroundColor: Colors.white,
                                               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                             ),
                                             onPressed: () {
                                               vm.navegarKanbanComDestaque(pedidoId: p.id, status: p.status);
                                             },
                                             icon: const Icon(Icons.flash_on, size: 18),
                                             label: const Text('ATENDER AGORA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                           ),
                                         ],
                                       ),
                                     );
                                   }),
                                 ],
                               ),
                             ),
                           ],

                           // ⚡ PRIORIDADE 2 — PRÓXIMAS AÇÕES (Fila Inteligente CTA Banner - Exclui itens da Prioridade 1)
                           Card(
                             elevation: 4,
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(16),
                               side: BorderSide(
                                 color: urgenciasWidgets.isNotEmpty ? Colors.amber.shade700 : Colors.grey.shade300,
                                 width: urgenciasWidgets.isNotEmpty ? 2 : 1,
                               ),
                             ),
                             child: Container(
                               decoration: BoxDecoration(
                                 borderRadius: BorderRadius.circular(16),
                                 gradient: urgenciasWidgets.isNotEmpty
                                     ? LinearGradient(
                                         colors: [Colors.amber.shade50, Colors.orange.shade50],
                                         begin: Alignment.topLeft,
                                         end: Alignment.bottomRight,
                                       )
                                     : null,
                               ),
                               padding: const EdgeInsets.all(20),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Row(
                                         children: [
                                           Container(
                                             padding: const EdgeInsets.all(8),
                                             decoration: BoxDecoration(
                                               color: Colors.amber.shade700,
                                               shape: BoxShape.circle,
                                             ),
                                             child: const Icon(Icons.bolt, color: Colors.white, size: 20),
                                           ),
                                           const SizedBox(width: 12),
                                           const Text(
                                             '⚡ PRIORIDADE 2 — PRÓXIMAS AÇÕES (O QUE FAZER AGORA)',
                                             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                                           ),
                                         ],
                                       ),
                                       if (urgenciasWidgets.isNotEmpty)
                                         Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                           decoration: BoxDecoration(
                                             color: Colors.amber.shade800,
                                             borderRadius: BorderRadius.circular(12),
                                           ),
                                           child: const Text(
                                             'TRABALHO ATIVO',
                                             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                           ),
                                         ),
                                     ],
                                   ),
                                   const Divider(height: 24),
                                   if (urgenciasWidgets.isEmpty)
                                     const Padding(
                                       padding: EdgeInsets.symmetric(vertical: 16),
                                       child: Row(
                                         children: [
                                           Icon(Icons.check_circle_outline, color: Colors.green),
                                           SizedBox(width: 10),
                                           Text(
                                             'Nenhuma ação pendente no momento. Operação rodando perfeitamente!',
                                             style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                           ),
                                         ],
                                       ),
                                     )
                                   else
                                     Column(children: urgenciasWidgets),
                                 ],
                               ),
                             ),
                           ),
                           const SizedBox(height: 20),

                           // 🤖 PRIORIDADE 3 — ASSISTENTE OPERACIONAL IA
                           FutureBuilder<BriefingOperacionalDiario>(
                             future: AssistenteOperacionalService(db).gerarBriefingDiario(),
                             builder: (context, snapshot) {
                               if (!snapshot.hasData) return const SizedBox();
                               final briefing = snapshot.data!;

                               return Card(
                                 margin: const EdgeInsets.only(bottom: 20),
                                 elevation: 2,
                                 shape: RoundedRectangleBorder(
                                   borderRadius: BorderRadius.circular(14),
                                   side: BorderSide(color: AppColors.primary.withAlpha(40)),
                                 ),
                                 child: Padding(
                                   padding: const EdgeInsets.all(18),
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Row(
                                         children: [
                                           Container(
                                             padding: const EdgeInsets.all(8),
                                             decoration: BoxDecoration(
                                               color: AppColors.primary.withAlpha(20),
                                               borderRadius: BorderRadius.circular(10),
                                             ),
                                             child: const Icon(Icons.psychology, color: AppColors.primary, size: 22),
                                           ),
                                           const SizedBox(width: 12),
                                           const Expanded(
                                             child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               children: [
                                                 Text(
                                                   '🤖 PRIORIDADE 3 — Assistente Operacional IA (Briefing Diário)',
                                                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                 ),
                                                 Text(
                                                   'Análise inteligente e diagnósticos do dia em linguagem natural',
                                                   style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                                 ),
                                               ],
                                             ),
                                           ),
                                         ],
                                       ),
                                       const SizedBox(height: 14),
                                       Container(
                                         padding: const EdgeInsets.all(16),
                                         decoration: BoxDecoration(
                                           color: Colors.blue.shade50.withValues(alpha: 0.5),
                                           borderRadius: BorderRadius.circular(12),
                                           border: Border.all(color: Colors.blue.shade200),
                                         ),
                                         child: Text(
                                           briefing.textoConversacional,
                                           style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.textPrimary),
                                         ),
                                       ),
                                       const SizedBox(height: 12),
                                       Row(
                                         children: [
                                           if (briefing.producaoSugerida.isNotEmpty)
                                             ElevatedButton.icon(
                                               style: ElevatedButton.styleFrom(
                                                 backgroundColor: AppColors.primary,
                                                 foregroundColor: Colors.white,
                                               ),
                                               onPressed: () {
                                                 final item = briefing.producaoSugerida.first;
                                                 vm.navegarProducao(
                                                   produto: item['produto'] as Produto,
                                                   quantidade: item['quantidade'] as int,
                                                 );
                                               },
                                               icon: const Icon(Icons.bolt, size: 16),
                                               label: const Text('⚡ Iniciar Lote Recomendado'),
                                             ),
                                           if (briefing.bairrosAgrupados.isNotEmpty) ...[
                                             const SizedBox(width: 12),
                                             OutlinedButton.icon(
                                               onPressed: () => vm.navegar(2), // Expedição & Agenda
                                               icon: const Icon(Icons.route, size: 16),
                                               label: Text('📍 Rotas (${briefing.bairrosAgrupados.join(", ")})'),
                                             ),
                                           ],
                                         ],
                                       ),
                                     ],
                                   ),
                                 ),
                               );
                             },
                           ),

                           // 📊 PRIORIDADE 4 — SITUAÇÃO DA OPERAÇÃO (CENTRO DE ALERTAS TIMELINE)
                           CentralNotificacoesWidget(
                             alertas: [
                               ...listAlertasCriticos.map((msg) => AlertaNotificacao(
                                     id: 'critico_${msg.hashCode}',
                                     titulo: 'Alerta Crítico Operacional',
                                     mensagem: msg,
                                     tipo: 'Estoque',
                                     urgencia: 'Alta', // 🔴 Crítico
                                     data: DateTime.now(),
                                     actionText: 'Resolver no Estoque',
                                     onAction: () => vm.navegar(7),
                                   )),
                               ...listAlertasAtencao.map((msg) => AlertaNotificacao(
                                     id: 'atencao_${msg.hashCode}',
                                     titulo: 'Atenção Necessária',
                                     mensagem: msg,
                                     tipo: 'Producao',
                                     urgencia: 'Media', // 🟠 Atenção
                                     data: DateTime.now(),
                                     actionText: 'Ir para Produção',
                                     onAction: () => vm.navegar(3),
                                   )),
                             ],
                           ),
                           const SizedBox(height: 20),

                          // Grid Central
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // COLUNA DA ESQUERDA (Trabalho Ativo, URGÊNCIAS e Timeline)
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      // Card: 🚚 PRÓXIMAS ENTREGAS
                                      Card(
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(Icons.local_shipping_outlined, color: Colors.blue),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    '🚚 PRÓXIMAS ENTREGAS',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                                                  ),
                                                ],
                                              ),
                                              const Divider(height: 24),
                                              if (pedidosAgendaHoje.isEmpty)
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 24),
                                                  child: Center(child: Text('Nenhuma entrega ou retirada agendada para hoje.')),
                                                )
                                              else
                                                Column(
                                                  children: pedidosAgendaHoje.map((p) {
                                                    final formatTime = DateFormat('HH:mm').format(p.dataEntrega);
                                                    final isEntrega = p.tipoEntrega.toLowerCase() == 'entrega';
                                                    
                                                    // Calculo de tempo relativo
                                                    final diff = p.dataEntrega.difference(DateTime.now());
                                                    String tempoRelativo = '';
                                                    if (p.status == 'Entregue' || p.status == 'Retirado') {
                                                      tempoRelativo = 'Concluído';
                                                    } else if (diff.isNegative) {
                                                      tempoRelativo = 'Atrasado';
                                                    } else if (diff.inMinutes < 60) {
                                                      tempoRelativo = 'Em ${diff.inMinutes} min';
                                                    } else if (diff.inHours < 24) {
                                                      tempoRelativo = 'Em ${diff.inHours}h';
                                                    } else {
                                                      tempoRelativo = 'Em ${diff.inDays} dias';
                                                    }

                                                    return Container(
                                                      margin: const EdgeInsets.only(bottom: 12),
                                                      padding: const EdgeInsets.all(12),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade50,
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: Colors.grey.shade200),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.all(10),
                                                            decoration: BoxDecoration(
                                                              color: isEntrega ? Colors.blue.shade100 : Colors.green.shade100,
                                                              shape: BoxShape.circle,
                                                            ),
                                                            child: Icon(
                                                              isEntrega ? Icons.local_shipping_outlined : Icons.storefront_outlined,
                                                              color: isEntrega ? Colors.blue.shade800 : Colors.green.shade800,
                                                              size: 20,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 16),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  'Pedido #${pedidoNumero(p.numero)} - ${p.clienteNome}',
                                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                                ),
                                                                const SizedBox(height: 4),
                                                                Text(
                                                                  '$formatTime ($tempoRelativo) • ${p.tipoEntrega.toUpperCase()} • ${p.formaPagamento}${p.formaPagamento.toLowerCase().contains('pix') ? (p.pixConfirmado ? ' (Pago)' : ' (Pend.)') : ''}',
                                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Column(
                                                            crossAxisAlignment: CrossAxisAlignment.end,
                                                            children: [
                                                              StatusBadge(status: p.status),
                                                              const SizedBox(height: 4),
                                                              Text(
                                                                dinheiro(p.totalCentavos),
                                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                              ),
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // COLUNA DA DIREITA (Status e Métricas)
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Card: 🏭 FILA DE PRODUÇÃO DE HOJE (CHECKLIST COM 1 CLIQUE)
                                      if (sugestoes.isNotEmpty) ...[
                                        Card(
                                          elevation: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(Icons.checklist_rtl_rounded, color: Colors.purple, size: 20),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'FILA DE PRODUÇÃO (CHECKLIST)',
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                const Text(
                                                  'Marque ao concluir o lote para dar entrada no estoque instantaneamente:',
                                                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                                ),
                                                const Divider(height: 20),
                                                Column(
                                                  children: sugestoes.map((s) {
                                                    final prod = s['produto'] as Produto;
                                                    final sugerido = s['sugerido'] as int;

                                                    return Container(
                                                      margin: const EdgeInsets.only(bottom: 8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.purple.shade50.withOpacity(0.5),
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: Colors.purple.shade200),
                                                      ),
                                                      child: CheckboxListTile(
                                                        value: false,
                                                        dense: true,
                                                        activeColor: Colors.purple,
                                                        title: Text(
                                                          prod.nome,
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                        ),
                                                        subtitle: Text('Sugerido: $sugerido un.'),
                                                        secondary: Text(
                                                          '$sugerido un.',
                                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 13),
                                                        ),
                                                        onChanged: (val) async {
                                                          if (val == true) {
                                                            await db.into(db.movimentacoesEstoque).insert(
                                                              MovimentacoesEstoqueCompanion(
                                                                produtoId: Value(prod.id),
                                                                quantidade: Value(sugerido),
                                                                tipoMovimentacao: const Value('ENTRADA_PRODUCAO'),
                                                                motivo: const Value('Produção via Fila do Cockpit'),
                                                                criadoEm: Value(DateTime.now()),
                                                              ),
                                                            );

                                                            final est = await (db.select(db.estoqueAtual)..where((e) => e.produtoId.equals(prod.id))).getSingleOrNull();
                                                            if (est != null) {
                                                              await (db.update(db.estoqueAtual)..where((e) => e.produtoId.equals(prod.id))).write(
                                                                EstoqueAtualCompanion(
                                                                  saldoAtual: Value(est.saldoAtual + sugerido),
                                                                  atualizadoEm: Value(DateTime.now()),
                                                                ),
                                                              );
                                                            }
                                                            await vm.reconciliarReservasEstoque();
                                                            if (context.mounted) {
                                                              AppSnackbar.sucesso(context, 'Produção de $sugerido un de ${prod.nome} registrada com sucesso!');
                                                            }
                                                            setState(() {});
                                                          }
                                                        },
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // Card: ⚠ ALERTAS FUTUROS (Hide if empty!)
                                      if (listAlertasFuturos.isNotEmpty) ...[
                                        Card(
                                          elevation: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(Icons.notification_important_outlined, color: Colors.orange, size: 18),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'ALERTAS FUTUROS',
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(height: 20),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: listAlertasFuturos.map((alerta) {
                                                    return Padding(
                                                      padding: const EdgeInsets.only(bottom: 12),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            '⚠ ${alerta['dia']}:',
                                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.blueGrey),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            alerta['msg'],
                                                            style: TextStyle(
                                                              fontSize: 12.5,
                                                              fontWeight: FontWeight.w500,
                                                              color: alerta['tipo'] == 'ruptura' ? Colors.red.shade800 : Colors.orange.shade800,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // Card: 📦 SAÚDE DO ESTOQUE
                                      Builder(
                                        builder: (context) {
                                          final totalProdutos = estoque.where((e) => e.produto.controlaEstoque).length;
                                          final criticos = estoque.where((e) => e.produto.controlaEstoque && e.saldoAtual < e.estoqueMinimo).length;
                                          final ok = totalProdutos - criticos;
                                          final attentionCount = attentionProducts.length;

                                          return Card(
                                            elevation: 2,
                                            child: Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text(
                                                        '📦 SAÚDE DO ESTOQUE',
                                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => vm.navegar(7), // Navegar para Estoque
                                                        child: const Text('Ver Estoque', style: TextStyle(fontSize: 12)),
                                                      ),
                                                    ],
                                                  ),
                                                  const Divider(height: 12),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '✔ $ok produtos OK',
                                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Text(
                                                        criticos > 0 ? '⚠ $criticos críticos' : '✔ Sem críticos',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: criticos > 0 ? Colors.red : Colors.green,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    attentionCount == 0
                                                        ? '✔ Estoque atende toda a demanda dos próximos 7 dias.'
                                                        : '⚠ $attentionCount produtos precisam de atenção em cobertura.',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: attentionCount == 0 ? Colors.green.shade800 : Colors.orange.shade800,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }
                                      ),
                                      const SizedBox(height: 16),

                                      // Card: 💰 RESULTADO DO DIA
                                      Card(
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                '💰 RESULTADO DO DIA',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted),
                                              ),
                                              const Divider(height: 20),
                                              _resumoRow('Pedidos Hoje', '$quantidadeValidaHoje', Colors.blue),
                                              _resumoRow('Faturamento', dinheiro(faturamentoHoje), Colors.green),
                                              _resumoRow('Salgados Vendidos', '$totalSalgadosVendidosHoje un.', Colors.orange),
                                              _resumoRow('Ticket Médio', dinheiro(ticketMedioHoje), Colors.teal),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Card: 🏭 PRODUÇÃO DE HOJE
                                      Card(
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(Icons.done_all, color: Colors.green, size: 18),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'PRODUZIDO HOJE',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted),
                                                  ),
                                                ],
                                              ),
                                              const Divider(height: 20),
                                              if (producaoAcumulada.isEmpty)
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 8),
                                                  child: Text(
                                                    'Nenhuma produção registrada hoje.',
                                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                                  ),
                                                )
                                              else
                                                Column(
                                                  children: producaoAcumulada.entries.map((e) {
                                                    return Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text('• ${e.key}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                          Text('${e.value} un.', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Card: 🥇 PRODUTOS CAMPEÕES
                                      Card(
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 18),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'MAIS VENDIDOS HOJE',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted),
                                                  ),
                                                ],
                                              ),
                                              const Divider(height: 20),
                                              if (campeoes.isEmpty)
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 8),
                                                  child: Text(
                                                    'Nenhuma venda registrada hoje.',
                                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                                  ),
                                                )
                                              else
                                                Column(
                                                  children: List.generate(campeoes.length > 3 ? 3 : campeoes.length, (idx) {
                                                    final e = campeoes[idx];
                                                    final medals = ['🥇', '🥈', '🥉'];
                                                    final medal = idx < medals.length ? medals[idx] : '•';
                                                    return Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text('$medal ${e.key}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                          Text('${e.value} un.', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                                        ],
                                                      ),
                                                    );
                                                  }),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Card: 🏭 PRÓXIMO GARGALO (Impedimentos futuros de estoque)
                                      if (proximoGargalo != null) ...[
                                        Card(
                                          elevation: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(Icons.warning_amber_outlined, color: Colors.red, size: 18),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'PRÓXIMO GARGALO',
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(height: 20),
                                                Text(
                                                  'Daqui ${proximoGargalo['dias']} dias',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.blueGrey),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      (proximoGargalo['produto'] as Produto).nome,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                    ),
                                                    Text(
                                                      'Faltará ${proximoGargalo['faltara']} un.',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: OutlinedButton(
                                                    onPressed: () => vm.navegar(6), // Ir para Produção
                                                    child: const Text('Planejar Produção'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                },
              );
            },
          );
        },
      );
        },
      );
    }

  Widget _buildProgressCard({
    required String title,
    required String valueStr,
    required double progress,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            valueStr,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskRow({
    required String label,
    required bool checked,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_box_outlined : Icons.check_box_outline_blank,
            color: checked ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                decoration: checked ? TextDecoration.lineThrough : null,
                color: checked ? Colors.grey : AppColors.textPrimary,
                fontSize: 13.5,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
            ),
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _urgencyCard({
    required int number,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color,
            child: Text(
              '$number',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
            onPressed: onPressed,
            child: Text(buttonLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _statusCounter(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _resumoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _CockpitTaskData {
  final int urgency;
  final DateTime date;
  final Widget Function(int number) builder;

  _CockpitTaskData({
    required this.urgency,
    required this.date,
    required this.builder,
  });
}
