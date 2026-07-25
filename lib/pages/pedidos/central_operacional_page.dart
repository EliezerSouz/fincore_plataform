import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../models/domain_models.dart';
import '../../database/app_database.dart';
import '../../modules/pedidos/widgets/pedido_detalhe_widget.dart';
import '../../providers/app_view_model.dart';

class CentralOperacionalPage extends StatefulWidget {
  const CentralOperacionalPage({super.key});

  @override
  State<CentralOperacionalPage> createState() => _CentralOperacionalPageState();
}

class _CentralOperacionalPageState extends State<CentralOperacionalPage> {
  DateTime _dataFiltro = DateTime.now();
  String _filtroOrigem = 'Todos'; // Todos, Balcão, WhatsApp, iFood

  final Map<int, GlobalKey> _cardKeys = {};
  Timer? _atualizadorTimer;
  int? _glowPedidoId;

  @override
  void initState() {
    super.initState();
    // Atualizar a tela a cada 30 segundos para manter os SLAs em tempo real
    _atualizadorTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _atualizadorTimer?.cancel();
    super.dispose();
  }

  // Métodos de SLA removidos para cálculo dinâmico inline por capacidade de lote no FutureBuilder.

  List<Pedido> _filtrarPedidos(List<Pedido> pedidos) {
    final now = DateTime.now();
    final hojeInicio = DateTime(now.year, now.month, now.day);
    final hojeFim = hojeInicio.add(const Duration(days: 1));
    final amanhaInicio = hojeFim;
    final amanhaFim = amanhaInicio.add(const Duration(days: 1));

    // Esta semana (segunda a domingo)
    final diaSemana = now.weekday;
    final estaSemanaInicio = hojeInicio.subtract(Duration(days: diaSemana - 1));
    final estaSemanaFim = estaSemanaInicio.add(const Duration(days: 7));

    return pedidos.where((p) {
      // Excluir cancelados da Central Operacional
      if (p.status == 'Cancelado') return false;

      // Filtro de Data
      final filtroInicio = DateTime(_dataFiltro.year, _dataFiltro.month, _dataFiltro.day);
      final filtroFim = filtroInicio.add(const Duration(days: 1));
      if (p.dataEntrega.isBefore(filtroInicio) || p.dataEntrega.isAfter(filtroFim)) return false;

      // Filtro de Origem
      if (_filtroOrigem != 'Todos') {
        // Deduzir origem caso origemId não esteja mapeado ainda
        String origemNome = 'Balcão';
        if (p.origemId == 2 || p.observacoes.toLowerCase().contains('whats')) {
          origemNome = 'WhatsApp';
        } else if (p.origemId == 3 || p.observacoes.toLowerCase().contains('ifood')) {
          origemNome = 'iFood';
        }
        if (origemNome != _filtroOrigem) return false;
      }

      return true;
    }).toList();
  }

  int _comparePedidos(Pedido a, Pedido b) {
    final now = DateTime.now();
    final aAtrasado = a.dataEntrega.isBefore(now);
    final bAtrasado = b.dataEntrega.isBefore(now);
    if (aAtrasado && !bAtrasado) return -1;
    if (!aAtrasado && bAtrasado) return 1;
    return a.dataEntrega.compareTo(b.dataEntrega);
  }

  String pedidoNumero(int num) => num.toString().padLeft(4, '0');
  String dinheiro(int centavos) => 'R\$ ${(centavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final db = vm.db;

    // Lógica antiga de destaque removida do topo, pois foi movida para dentro do StreamBuilder para capturar a data do pedido.

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Central Operacional',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Foco no preparo e expedição das encomendas ativas.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () => vm.navegar(1), // Ir para Novo Pedido
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Novo Pedido'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // StreamBuilder Principal de Produtos para Mapear Capacidade/Tempo de Fritura
          Expanded(
            child: StreamBuilder<List<ProdutoComEstoque>>(
              stream: vm.observarEstoque(),
              builder: (context, estSnapshot) {
                final estoqueItens = estSnapshot.data ?? [];
                final Map<int, ProdutoComEstoque> prodMap = {};
                for (final item in estoqueItens) {
                  prodMap[item.produto.id] = item;
                }

                return StreamBuilder<List<Pedido>>(
                  stream: db.select(db.pedidos).watch(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final todosPedidos = snapshot.data!;
                    final pedidosOperacionais = _filtrarPedidos(todosPedidos)..sort(_comparePedidos);

                // Processar trigger de destaque operacional da Dashboard
                if (vm.pedidoIdParaDestacar != null) {
                  final destId = vm.pedidoIdParaDestacar!;
                  final matching = todosPedidos.where((p) => p.id == destId).toList();
                  if (matching.isNotEmpty) {
                    final pedidoDestacado = matching.first;
                    final dataDest = pedidoDestacado.dataEntrega;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && (_dataFiltro.year != dataDest.year || _dataFiltro.month != dataDest.month || _dataFiltro.day != dataDest.day || _glowPedidoId != destId)) {
                        setState(() {
                          _dataFiltro = dataDest;
                          _filtroOrigem = 'Todos';
                          _glowPedidoId = destId;
                        });

                        // Aguardar renderização e rolar até o card do pedido
                        Future.delayed(const Duration(milliseconds: 150), () {
                          final key = _cardKeys[destId];
                          final ctx = key?.currentContext;
                          if (ctx != null) {
                            Scrollable.ensureVisible(
                              ctx,
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeInOut,
                            );
                          }
                        });

                        // Limpar o brilho após 3 segundos
                        Timer(const Duration(seconds: 3), () {
                          if (mounted) {
                            setState(() {
                              _glowPedidoId = null;
                            });
                            vm.limparDestaqueKanban();
                          }
                        });
                      }
                    });
                  }
                }

                // Cálculo BI Operacional da Data Selecionada
                final filtroDataInicio = DateTime(_dataFiltro.year, _dataFiltro.month, _dataFiltro.day);
                final filtroDataFim = filtroDataInicio.add(const Duration(days: 1));
                final pedidosDeHoje = todosPedidos.where((p) =>
                    (p.dataEntrega.isAfter(filtroDataInicio) || p.dataEntrega.isAtSameMomentAs(filtroDataInicio)) &&
                    p.dataEntrega.isBefore(filtroDataFim) &&
                    p.status != 'Cancelado').toList();

                final totalHojeCount = pedidosDeHoje.length;
                final faturamentoHojeCentavos = pedidosDeHoje.fold<int>(0, (sum, p) => sum + p.totalCentavos);
                final ticketMedioHoje = totalHojeCount == 0 ? 0 : (faturamentoHojeCentavos / totalHojeCount).round();
                final entregasHoje = pedidosDeHoje.where((p) => p.tipoEntrega.toLowerCase() == 'entrega').length;
                final retiradasHoje = pedidosDeHoje.where((p) => p.tipoEntrega.toLowerCase() != 'entrega').length;

                // Alertas operacionais
                final hasAtrasados = pedidosOperacionais.any((p) => p.dataEntrega.isBefore(DateTime.now()));
                final hasVips = pedidosOperacionais.any((p) => p.prioridade == 'VIP');
                final hasPixPendentes = pedidosOperacionais.any((p) => p.formaPagamento.toLowerCase().contains('pix') && !p.pixConfirmado);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seção Produção Necessária
                    _buildProducaoNecessaria(pedidosOperacionais, db),
                    const SizedBox(height: 16),

                    // Resumo BI (KPIs de Hoje)
                    _buildResumoBI(
                      pedidos: totalHojeCount,
                      entregas: entregasHoje,
                      retiradas: retiradasHoje,
                      faturamento: faturamentoHojeCentavos,
                      ticket: ticketMedioHoje,
                    ),
                    const SizedBox(height: 16),

                    // Painel de Alertas
                    if (hasAtrasados || hasVips || hasPixPendentes) ...[
                      _buildPainelAlertas(
                        atrasado: hasAtrasados,
                        vip: hasVips,
                        pix: hasPixPendentes,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Barra de Filtros
                    Row(
                      children: [
                        const Text('Data de Entrega: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () {
                            setState(() {
                              _dataFiltro = _dataFiltro.subtract(const Duration(days: 1));
                            });
                          },
                          icon: const Icon(Icons.chevron_left, size: 18),
                        ),
                        const SizedBox(width: 6),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dataFiltro,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                              builder: (context, child) {
                                return Center(
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 450, maxHeight: 550),
                                    child: child,
                                  ),
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _dataFiltro = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today_outlined, size: 14),
                          label: Text(
                            DateFormat('dd/MM/yyyy').format(_dataFiltro),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          onPressed: () {
                            setState(() {
                              _dataFiltro = _dataFiltro.add(const Duration(days: 1));
                            });
                          },
                          icon: const Icon(Icons.chevron_right, size: 18),
                        ),
                        const SizedBox(width: 32),
                        const Text('Origem: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        ...['Todos', 'Balcão', 'WhatsApp', 'iFood'].map((o) {
                          final active = _filtroOrigem == o;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(o),
                              selected: active,
                              onSelected: (val) {
                                if (val) setState(() => _filtroOrigem = o);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Kanban de 4 Colunas Ativas
                    Expanded(
                      child: _buildKanbanGrid(pedidosOperacionais, vm, prodMap),
                    ),
                  ],
                );
              }, // fecha builder de StreamBuilder<List<Pedido>>
            ); // fecha StreamBuilder<List<Pedido>>
          }, // fecha builder de StreamBuilder<List<ProdutoComEstoque>>
        ), // fecha StreamBuilder<List<ProdutoComEstoque>>
      ), // fecha Expanded
    ], // fecha children de Column
  ), // fecha Column
); // fecha Padding
} // fecha build

  Widget _buildProducaoNecessaria(List<Pedido> pedidosAtivos, AppDatabase db) {
    if (pedidosAtivos.isEmpty) return const SizedBox.shrink();

    final pedidoIds = pedidosAtivos.map((p) => p.id).toList();

    return FutureBuilder<List<ItensPedidoData>>(
      future: (db.select(db.itensPedido)..where((i) => i.pedidoId.isIn(pedidoIds))).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final itens = snapshot.data!;
        final totais = <String, int>{};
        for (final i in itens) {
          totais[i.produtoNome] = (totais[i.produtoNome] ?? 0) + i.quantidade;
        }

        if (totais.isEmpty) return const SizedBox.shrink();

        return Card(
          color: Colors.blue.shade50.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.blue.shade200, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.kitchen_outlined, color: Colors.blue.shade800, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'PRODUÇÃO NECESSÁRIA (PERÍODO FILTRADO)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blue.shade800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: totais.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${entry.value} un.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
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
        );
      },
    );
  }

  // 2. Resumo BI de Hoje
  Widget _buildResumoBI({
    required int pedidos,
    required int entregas,
    required int retiradas,
    required int faturamento,
    required int ticket,
  }) {
    return Row(
      children: [
        _kpiBI('PEDIDOS HOJE', '$pedidos', Icons.analytics_outlined, Colors.indigo),
        const SizedBox(width: 16),
        _kpiBI('ENTREGAS', '$entregas', Icons.local_shipping_outlined, Colors.teal),
        const SizedBox(width: 16),
        _kpiBI('RETIRADAS', '$retiradas', Icons.storefront_outlined, Colors.purple),
        const SizedBox(width: 16),
        _kpiBI('FATURAMENTO', dinheiro(faturamento), Icons.monetization_on_outlined, Colors.green),
        const SizedBox(width: 16),
        _kpiBI('TICKET MÉDIO', dinheiro(ticket), Icons.shopping_bag_outlined, Colors.orange),
      ],
    );
  }

  Widget _kpiBI(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Painel de Alertas Dinâmicos
  Widget _buildPainelAlertas({required bool atrasado, required bool vip, required bool pix}) {
    return Row(
      children: [
        if (atrasado)
          _alertChip('⚠️ PEDIDO ATRASADO NA FILA', Colors.red.shade100, Colors.red.shade900),
        if (vip) ...[
          const SizedBox(width: 10),
          _alertChip('⭐ CLIENTE VIP PENDENTE', Colors.amber.shade100, Colors.amber.shade900),
        ],
        if (pix) ...[
          const SizedBox(width: 10),
          _alertChip('💳 AGUARDANDO CONFIRMAÇÃO DE PIX', Colors.blue.shade100, Colors.blue.shade900),
        ],
      ],
    );
  }

  Widget _alertChip(String text, Color bg, Color textCor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textCor.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: textCor, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  // 4. Kanban de 4 Colunas Ativas
  Widget _buildKanbanGrid(List<Pedido> pedidos, AppViewModel vm, Map<int, ProdutoComEstoque> prodMap) {
    final pendentes = pedidos.where((p) => p.status == 'Pendente').toList();
    final emProducao = pedidos.where((p) => p.status == 'Em Preparo').toList();
    final prontos = pedidos.where((p) => p.status == 'Pronto').toList();
    final emRota = pedidos.where((p) => p.status == 'Em Rota' || p.status == 'Aguardando Cliente').toList();
    final finalizados = pedidos.where((p) => p.status == 'Finalizado' || p.status == 'Entregue').toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _kanbanColumn('PENDENTES', pendentes, Colors.blue.shade600, vm, prodMap)),
        const SizedBox(width: 12),
        Expanded(child: _kanbanColumn('EM PREPARO', emProducao, Colors.orange.shade600, vm, prodMap)),
        const SizedBox(width: 12),
        Expanded(child: _kanbanColumn('PRONTOS (SEPARADOS)', prontos, Colors.purple.shade600, vm, prodMap)),
        const SizedBox(width: 12),
        Expanded(child: _kanbanColumn('SAIU / EM EXPEDIÇÃO', emRota, Colors.teal.shade600, vm, prodMap)),
        const SizedBox(width: 12),
        Expanded(child: _kanbanColumn('CONCLUÍDOS / FINALIZADOS', finalizados, Colors.green.shade600, vm, prodMap)),
      ],
    );
  }

  Widget _kanbanColumn(String title, List<Pedido> lista, Color color, AppViewModel vm, Map<int, ProdutoComEstoque> prodMap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${lista.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: lista.length,
              itemBuilder: (context, idx) {
                final p = lista[idx];
                final cardKey = _cardKeys.putIfAbsent(p.id, () => GlobalKey());

                return FutureBuilder<PedidoCompleto>(
                  future: vm.pedidos.completo(p.id),
                  builder: (context, snapshot) {
                    final completo = snapshot.data;
                    final totalSalgados = completo?.itens.fold<int>(0, (sum, i) => sum + i.quantidade) ?? 0;
                    // 1. Calcular tempo de preparação (fritura/assamento) baseado em rodadas de capacidade
                    int tempoPreparoPedido = 0;
                    if (completo != null) {
                      for (final item in completo.itens) {
                        final estProd = prodMap[item.produtoId];
                        if (estProd != null) {
                          // Capacidade do lote de preparação (fritura/forno)
                          int capLote = estProd.loteMinimo;
                          if (capLote <= 1) capLote = 50; // valor padrão inteligente se não configurado
                          
                          final rodadas = (item.quantidade / capLote).ceil();
                          final tempoItem = rodadas * estProd.produto.tempoMedioMinutos;
                          if (tempoItem > tempoPreparoPedido) {
                            tempoPreparoPedido = tempoItem;
                          }
                        }
                      }
                      if (tempoPreparoPedido > 0) {
                        tempoPreparoPedido += 10; // 10 min de margem para embalar/despachar
                      }
                    }

                    // 2. Determinar SLA Dinâmico Inteligente
                    final now = DateTime.now();
                    final diffEntrega = p.dataEntrega.difference(now);
                    
                    bool isAtrasado = false;
                    String slaText = '';
                    Color slaColor = Colors.green.shade700;

                    if (p.status == 'Pendente') {
                      final limitePreparo = p.dataEntrega.subtract(Duration(minutes: tempoPreparoPedido));
                      final diffPreparo = limitePreparo.difference(now);
                      if (diffPreparo.isNegative) {
                        isAtrasado = true;
                        slaText = 'Início Atrasado!';
                        slaColor = Colors.red.shade700;
                      } else if (diffPreparo.inMinutes < 15) {
                        slaText = 'Preparar em ${diffPreparo.inMinutes} min';
                        slaColor = Colors.orange.shade700;
                      } else {
                        slaText = 'Preparar às ${DateFormat('HH:mm').format(limitePreparo)}';
                        slaColor = Colors.green.shade700;
                      }
                    } else if (p.status == 'Em Preparo') {
                      if (diffEntrega.isNegative) {
                        isAtrasado = true;
                        slaText = 'Atrasado ${diffEntrega.inMinutes.abs()} min';
                        slaColor = Colors.red.shade700;
                      } else {
                        slaText = 'Fritando (Faltam ${diffEntrega.inMinutes} min)';
                        slaColor = diffEntrega.inMinutes < 15 ? Colors.orange.shade700 : Colors.green.shade700;
                      }
                    } else {
                      // Pronto ou Em Rota
                      if (diffEntrega.isNegative) {
                        isAtrasado = true;
                        slaText = 'Atrasado ${diffEntrega.inMinutes.abs()} min';
                        slaColor = Colors.red.shade700;
                      } else if (diffEntrega.inMinutes < 30) {
                        slaText = 'Falta ${diffEntrega.inMinutes} min';
                        slaColor = Colors.orange.shade700;
                      } else {
                        if (diffEntrega.inHours < 24) {
                          slaText = 'Falta ${diffEntrega.inHours}h';
                        } else {
                          slaText = 'Falta ${diffEntrega.inDays} dias';
                        }
                        slaColor = Colors.green.shade700;
                      }
                    }

                    final delayColor = slaColor;

                    final isGlowing = _glowPedidoId == p.id;

                    final isHoje = p.dataEntrega.year == now.year && p.dataEntrega.month == now.month && p.dataEntrega.day == now.day;
                    final isAmanha = p.dataEntrega.year == now.year && p.dataEntrega.month == now.month && p.dataEntrega.day == (now.day + 1);
                    final dataEntregaStr = isHoje 
                        ? 'Hoje ${DateFormat('HH:mm').format(p.dataEntrega)}' 
                        : (isAmanha 
                            ? 'Amanhã ${DateFormat('HH:mm').format(p.dataEntrega)}' 
                            : DateFormat('dd/MM HH:mm').format(p.dataEntrega));

                    return Card(
                      key: cardKey,
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isGlowing ? 8 : 2,
                      color: isGlowing ? Colors.amber.shade50 : Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isGlowing
                              ? Colors.amber
                              : (isAtrasado ? Colors.red.shade300 : Colors.grey.shade200),
                          width: isGlowing ? 2.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Stripe de cor de delay lateral
                              Container(
                                width: 5,
                                color: delayColor,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Cabeçalho Principal: Data e Hora da Entrega
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            dataEntregaStr,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14.5,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: p.tipoEntrega.toLowerCase() == 'entrega' ? Colors.blue.shade50 : Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  p.tipoEntrega.toLowerCase() == 'entrega' ? Icons.local_shipping : Icons.storefront,
                                                  size: 10,
                                                  color: p.tipoEntrega.toLowerCase() == 'entrega' ? Colors.blue.shade700 : Colors.green.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  p.tipoEntrega.toLowerCase() == 'entrega' ? 'Entrega' : 'Retirada',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: p.tipoEntrega.toLowerCase() == 'entrega' ? Colors.blue.shade800 : Colors.green.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),

                                      // Subcabeçalho: Número do pedido e tempo de SLA
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Pedido #${pedidoNumero(p.numero)}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                          Text(
                                            slaText,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: slaColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Cliente Nome
                                      Text(
                                        p.clienteNome,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                      ),

                                      // Telefone
                                      if (p.clienteTelefone.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          p.clienteTelefone,
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                      ],
                                      const SizedBox(height: 6),

                                      // Pagamento
                                      Text(
                                        'Pagamento: ${p.formaPagamento}${p.formaPagamento.toLowerCase().contains('pix') ? (p.pixConfirmado ? ' (Pago)' : ' (Pend.)') : ''}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                                      ),
                                      
                                      const Divider(height: 16),

                                      // Qtd Salgados e Valor Total
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '$totalSalgados un. salgados',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                          ),
                                          Text(
                                            dinheiro(p.totalCentavos),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const Divider(height: 16),

                                      // Rodapé de Ações
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              IconButton(
                                                visualDensity: VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                icon: const Icon(Icons.print_outlined, size: 16),
                                                tooltip: 'Imprimir via',
                                                onPressed: () async {
                                                  try {
                                                    await vm.reimprimir(p.id);
                                                    if (context.mounted) {
                                                      AppSnackbar.sucesso(context, 'Cupom impresso com sucesso!');
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      AppSnackbar.erro(context, 'Erro ao imprimir: $e');
                                                    }
                                                  }
                                                },
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                visualDensity: VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                icon: const Icon(Icons.info_outline, size: 16),
                                                tooltip: 'Detalhes',
                                                onPressed: () async {
                                                  final comp = await vm.pedidos.completo(p.id);
                                                  if (context.mounted) {
                                                    PedidoDetalheWidget.exibirModal(
                                                      context,
                                                      pedidoCompleto: comp,
                                                      onAtualizado: () => setState(() {}),
                                                    );
                                                  }
                                                },
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                visualDensity: VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                icon: Icon(Icons.cancel_outlined, size: 16, color: Colors.red.shade700),
                                                tooltip: 'Cancelar Pedido',
                                                onPressed: () async {
                                                  final confirmar = await ConfirmDialog.exibir(
                                                    context,
                                                    titulo: 'Cancelar Pedido',
                                                    mensagem: 'Deseja realmente cancelar o pedido #${pedidoNumero(p.numero)}?',
                                                    textoConfirmar: 'Cancelar',
                                                  );
                                                  if (confirmar) {
                                                    try {
                                                      await vm.pedidos.cancelar(p.id);
                                                      if (context.mounted) {
                                                        AppSnackbar.sucesso(context, 'Pedido cancelado com sucesso!');
                                                      }
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        AppSnackbar.erro(context, 'Erro ao cancelar pedido: $e');
                                                      }
                                                    }
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          _workflowButton(p, vm),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicatorMiniChip(String label, Color bg, Color textCor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textCor,
        ),
      ),
    );
  }

  Widget _workflowButton(Pedido p, AppViewModel vm) {
    final status = p.status;
    final isEntrega = p.tipoEntrega.toLowerCase() == 'entrega';

    if (status == 'Pendente') {
      return TextButton.icon(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          foregroundColor: Colors.grey.shade800,
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          try {
            await vm.pedidos.alterarStatus(p.id, 'Em Preparo');
            setState(() {});
          } catch (e) {
            if (context.mounted) AppSnackbar.erro(context, 'Erro ao iniciar preparo: $e');
          }
        },
        icon: const Icon(Icons.play_arrow, size: 14),
        label: const Text('Preparar'),
      );
    } else if (status == 'Em Preparo') {
      return TextButton.icon(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          foregroundColor: Colors.grey.shade800,
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          try {
            await vm.pedidos.alterarStatus(p.id, 'Pronto');
            setState(() {});
          } catch (e) {
            if (context.mounted) AppSnackbar.erro(context, 'Erro ao finalizar preparo: $e');
          }
        },
        icon: const Icon(Icons.check, size: 14),
        label: const Text('Finalizar'),
      );
    } else if (status == 'Pronto') {
      final targetStatus = isEntrega ? 'Em Rota' : 'Aguardando Cliente';
      final label = isEntrega ? 'Despachar' : 'Retirar';
      return TextButton.icon(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          foregroundColor: Colors.grey.shade800,
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          try {
            await vm.pedidos.alterarStatus(p.id, targetStatus);
            setState(() {});
          } catch (e) {
            if (context.mounted) AppSnackbar.erro(context, 'Erro ao despachar: $e');
          }
        },
        icon: Icon(isEntrega ? Icons.local_shipping : Icons.storefront, size: 14),
        label: Text(label),
      );
    } else if (status == 'Em Rota' || status == 'Aguardando Cliente') {
      return TextButton.icon(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          foregroundColor: Colors.grey.shade800,
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          try {
            await vm.pedidos.alterarStatus(p.id, 'Finalizado');
            setState(() {});
          } catch (e) {
            if (context.mounted) AppSnackbar.erro(context, 'Erro ao concluir: $e');
          }
        },
        icon: const Icon(Icons.done_all, size: 14),
        label: const Text('Concluir'),
      );
    }
    return const SizedBox.shrink();
  }
}
