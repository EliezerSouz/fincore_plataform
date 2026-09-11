import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_shared/fincore_shared.dart';
import '../controllers/dashboard_controller.dart';

class BlocoVendas extends StatefulWidget {
  final DashboardController controller;

  const BlocoVendas({super.key, required this.controller});

  @override
  State<BlocoVendas> createState() => _BlocoVendasState();
}

class _BlocoVendasState extends State<BlocoVendas> {
  String _filtroSelecionado = '7_DIAS'; // 'HOJE' | '7_DIAS' | '30_DIAS'

  @override
  Widget build(BuildContext context) {
    final m = widget.controller.metrics;

    // Métricas dinâmicas com base no filtro selecionado
    final int faturamento = switch (_filtroSelecionado) {
      'HOJE' => m.faturamentoCentavosHoje,
      '7_DIAS' => m.faturamentoCentavosSemana,
      _ => m.faturamentoCentavosMes,
    };

    final int ticketMedio = switch (_filtroSelecionado) {
      'HOJE' => m.ticketMedioCentavosHoje,
      '7_DIAS' => m.ticketMedioCentavosSemana,
      _ => m.ticketMedioCentavosMes,
    };

    final int totalPedidos = switch (_filtroSelecionado) {
      'HOJE' => m.totalPedidosHoje,
      '7_DIAS' => m.totalPedidosSemana,
      _ => m.totalPedidosMes,
    };

    final int totalCancelados = switch (_filtroSelecionado) {
      'HOJE' => m.pedidosCanceladosHoje,
      '7_DIAS' => m.canceladosSemana,
      _ => m.canceladosMes,
    };

    // Dados do gráfico
    final List<int> faturamentoList = _filtroSelecionado == '7_DIAS'
        ? m.faturamento7DiasCentavos
        : m.faturamento30DiasCentavos;

    final List<String> faturamentoDatas = _filtroSelecionado == '7_DIAS'
        ? m.faturamento7DiasDatas
        : m.faturamento30DiasDatas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Vendas & Faturamento',
              style: TextStyle(
                color: FincoreColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Chips de Filtro de Vendas
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFiltroChip('Hoje', 'HOJE'),
                const SizedBox(width: 6),
                _buildFiltroChip('7 dias', '7_DIAS'),
                const SizedBox(width: 6),
                _buildFiltroChip('30 dias', '30_DIAS'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;

            final painelKpis = Container(
              padding: const EdgeInsets.all(16),
              height: 220,
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildKpiItem('Faturamento', FincoreMoneyFormatter.format(faturamento), FincoreColors.success),
                  _buildKpiItem('Ticket Médio', FincoreMoneyFormatter.format(ticketMedio), const Color(0xFF3B82F6)),
                  Row(
                    children: [
                      Expanded(child: _buildKpiItemMini('Pedidos', totalPedidos.toString())),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiItemMini(
                          'Cancelamentos',
                          totalCancelados.toString(),
                          valueColor: totalCancelados > 0 ? const Color(0xFFE05C5C) : FincoreColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );

            final painelGrafico = Container(
              padding: const EdgeInsets.all(16),
              height: 220,
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Faturamento diário',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FincoreColors.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: faturamentoList.isEmpty || faturamentoList.every((v) => v == 0)
                        ? const Center(
                            child: Text(
                              'Nenhuma venda registrada no período.',
                              style: TextStyle(color: FincoreColors.textMuted, fontSize: 12),
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: CustomPaint(
                                  size: Size.infinite,
                                  painter: _LineChartPainter(
                                    values: faturamentoList,
                                    dates: faturamentoDatas,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Datas do eixo X
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: faturamentoDatas
                                    .where((d) => d.isNotEmpty)
                                    .map((d) => Text(
                                          d,
                                          style: const TextStyle(color: FincoreColors.textMuted, fontSize: 9),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            );

            if (isMobile) {
              return Column(
                children: [
                  painelKpis,
                  const SizedBox(height: 14),
                  painelGrafico,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: painelKpis,
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: painelGrafico,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFiltroChip(String label, String key) {
    final isSelected = _filtroSelecionado == key;
    return InkWell(
      onTap: () => setState(() => _filtroSelecionado = key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? FincoreColors.primary : FincoreColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? FincoreColors.primary : FincoreColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : FincoreColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildKpiItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: FincoreColors.textSecondary, fontSize: 12)),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildKpiItemMini(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: FincoreColors.surfaceOverlay,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: FincoreColors.textMuted, fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? FincoreColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<int> values;
  final List<String> dates;

  _LineChartPainter({required this.values, required this.dates});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final diff = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    final double widthBetweenPoints = size.width / (values.length - 1);

    final path = Path();
    final fillPath = Path();

    final paintLine = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF10B981).withValues(alpha: 0.25),
          const Color(0xFF10B981).withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (int i = 0; i < values.length; i++) {
      final val = values[i];
      final double x = i * widthBetweenPoints;
      final double y = size.height - ((val - minVal) / diff) * size.height * 0.8 - size.height * 0.1;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == values.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    // Desenha círculos para os pontos principais (no máximo e no fim)
    final paintCircle = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    final paintOuterCircle = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      if (i == values.length - 1 || values[i] == maxVal) {
        final double x = i * widthBetweenPoints;
        final double y = size.height - ((values[i] - minVal) / diff) * size.height * 0.8 - size.height * 0.1;

        canvas.drawCircle(Offset(x, y), 5.5, paintCircle);
        canvas.drawCircle(Offset(x, y), 3, paintOuterCircle);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
