import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../database/app_database.dart';
import '../../providers/app_view_model.dart';

class FinanceiroPage extends StatefulWidget {
  const FinanceiroPage({super.key});

  @override
  State<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends State<FinanceiroPage> {
  String _periodoFiltro = 'Este Mês';

  DateTime _obterDataInicioFiltro() {
    final now = DateTime.now();
    switch (_periodoFiltro) {
      case 'Hoje':
        return DateTime(now.year, now.month, now.day);
      case 'Esta Semana':
        return DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      case 'Este Mês':
        return DateTime(now.year, now.month, 1);
      case 'Últimos 30 Dias':
        return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
      default:
        return DateTime(2020);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();
    final db = vm.db;
    final dataInicio = _obterDataInicioFiltro();

    final stream = db.select(db.pedidos).watch();

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financeiro',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitore o faturamento, ticket médio e meios de pagamento das vendas realizadas.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              // Filtro de Período
              DropdownButton<String>(
                value: _periodoFiltro,
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                items: const ['Hoje', 'Esta Semana', 'Este Mês', 'Últimos 30 Dias', 'Todos']
                    .map((opt) => DropdownMenuItem<String>(
                          value: opt,
                          child: Text(opt),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _periodoFiltro = val;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: StreamBuilder<List<Pedido>>(
              stream: stream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filtrar e ordenar em memória
                final pedidos = snapshot.data!
                    .where((p) =>
                        (p.criadoEm.isAfter(dataInicio) || p.criadoEm.isAtSameMomentAs(dataInicio)) &&
                        p.status != 'Cancelado')
                    .toList()
                  ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

                // 1. Cálculos de Faturamento e Ticket Médio
                final faturamentoTotal = pedidos.fold<int>(0, (sum, p) => sum + p.totalCentavos);
                final totalItensPedidos = pedidos.length;
                final ticketMedio = totalItensPedidos == 0 ? 0 : (faturamentoTotal / totalItensPedidos).round();

                // 2. Faturamento por Meio de Pagamento
                int faturamentoPix = 0;
                int faturamentoDinheiro = 0;
                int faturamentoCartao = 0;

                for (final p in pedidos) {
                  final pag = p.formaPagamento.toLowerCase();
                  if (pag.contains('pix')) {
                    faturamentoPix += p.totalCentavos;
                  } else if (pag.contains('dinheiro')) {
                    faturamentoDinheiro += p.totalCentavos;
                  } else {
                    faturamentoCartao += p.totalCentavos;
                  }
                }

                // 3. Faturamento por Status de Recebimento (PIX Confirmado ou Não)
                int faturamentoConfirmado = 0;
                int faturamentoPendente = 0;

                for (final p in pedidos) {
                  final pag = p.formaPagamento.toLowerCase();
                  if (pag.contains('pix')) {
                    if (p.pixConfirmado) {
                      faturamentoConfirmado += p.totalCentavos;
                    } else {
                      faturamentoPendente += p.totalCentavos;
                    }
                  } else {
                    // Dinheiro e Cartão consideramos recebidos ao finalizar ou criar
                    if (p.status == 'Finalizado') {
                      faturamentoConfirmado += p.totalCentavos;
                    } else {
                      faturamentoPendente += p.totalCentavos;
                    }
                  }
                }

                // 4. Agrupamento por Dia para gráfico simples
                final faturamentoPorDia = <String, int>{};
                for (final p in pedidos) {
                  final diaStr = DateFormat('dd/MM').format(p.criadoEm);
                  faturamentoPorDia[diaStr] = (faturamentoPorDia[diaStr] ?? 0) + p.totalCentavos;
                }
                final listaDias = faturamentoPorDia.entries.toList()
                  ..sort((a, b) => b.key.compareTo(a.key)); // Dias recentes primeiro

                if (pedidos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.monetization_on_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhuma venda registrada no período.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  children: [
                    // Grid de KPI Cards
                    Row(
                      children: [
                        Expanded(
                          child: _kpiCard(
                            title: 'Faturamento Total',
                            value: dinheiro(faturamentoTotal),
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _kpiCard(
                            title: 'Ticket Médio',
                            value: dinheiro(ticketMedio),
                            icon: Icons.analytics_outlined,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _kpiCard(
                            title: 'Total de Vendas',
                            value: '$totalItensPedidos pedidos',
                            icon: Icons.shopping_bag_outlined,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Painéis de Distribuição e Recebíveis
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Distribuição de Meios de Pagamento
                        Expanded(
                          flex: 3,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'MEIOS DE PAGAMENTO',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted, fontSize: 13),
                                  ),
                                  const Divider(height: 20),
                                  _barraPercentual('Pix', faturamentoPix, faturamentoTotal, Colors.teal),
                                  const SizedBox(height: 16),
                                  _barraPercentual('Dinheiro', faturamentoDinheiro, faturamentoTotal, Colors.amber),
                                  const SizedBox(height: 16),
                                  _barraPercentual('Cartão', faturamentoCartao, faturamentoTotal, Colors.indigo),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Fluxo de Caixa / Recebíveis
                        Expanded(
                          flex: 2,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'STATUS DE RECEBIMENTO',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted, fontSize: 13),
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                                          SizedBox(width: 8),
                                          Text('Recebido/Confirmado', style: TextStyle(fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                      Text(dinheiro(faturamentoConfirmado), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.hourglass_empty_outlined, color: Colors.orange, size: 18),
                                          SizedBox(width: 8),
                                          Text('A Receber/Pendente', style: TextStyle(fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                      Text(dinheiro(faturamentoPendente), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Faturamento Diário (Gráfico de barras vertical simples)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FATURAMENTO DIÁRIO',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted, fontSize: 13),
                            ),
                            const Divider(height: 20),
                            SizedBox(
                              height: 180,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: listaDias.take(15).toList().reversed.map((e) {
                                  final double percent = faturamentoTotal == 0
                                      ? 0
                                      : (e.value / faturamentoTotal).clamp(0.05, 1.0);
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(dinheiro(e.value), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 32,
                                        height: 120 * percent,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.85),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(e.key, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard({required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _barraPercentual(String label, int valor, int total, Color cor) {
    final double percent = total == 0 ? 0 : (valor / total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            Text('${dinheiro(valor)} (${(percent * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            color: cor,
            backgroundColor: Colors.grey.shade100,
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}
