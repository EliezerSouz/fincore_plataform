import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_shared/fincore_shared.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/dashboard_controller.dart';

/// Bloco de KPIs com variação % vs. ontem + Velocímetro de Meta Diária
class BlocoVelocimetroVendas extends StatefulWidget {
  final DashboardController controller;
  const BlocoVelocimetroVendas({super.key, required this.controller});

  @override
  State<BlocoVelocimetroVendas> createState() => _BlocoVelocimetroVendasState();
}

class _BlocoVelocimetroVendasState extends State<BlocoVelocimetroVendas>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _ringAnimation = CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic);
    _ringController.forward();
  }

  @override
  void didUpdateWidget(covariant BlocoVelocimetroVendas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ringController.forward(from: 0);
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  void _definirMetaModal(BuildContext context) {
    final controller = TextEditingController();
    final metaAtual = widget.controller.metrics.metaDiariaCentavos / 100.0;
    if (metaAtual > 0) {
      controller.text = metaAtual.toStringAsFixed(2);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FincoreColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.flag_rounded, color: FincoreColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text('Meta Diária de Vendas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informe o valor alvo de faturamento diário para a sua operação (ex: 1500.00):',
                style: TextStyle(fontSize: 12, color: FincoreColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                prefixStyle: TextStyle(color: FincoreColors.primary, fontWeight: FontWeight.bold),
                hintText: '0,00',
                filled: true,
                fillColor: FincoreColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: FincoreColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('meta_diaria_faturamento', val);
              if (ctx.mounted) Navigator.pop(ctx);
              widget.controller.loadMetrics();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FincoreColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salvar Meta'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.controller.metrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Performance do Dia',
              style: TextStyle(color: FincoreColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;

            final velocimetro = Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FincoreColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FincoreColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('META DIÁRIA',
                      style: TextStyle(color: FincoreColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _ringAnimation,
                    builder: (context, _) {
                      final progresso = m.metaDiariaCentavos > 0
                          ? (m.progressoMeta * _ringAnimation.value).clamp(0.0, 1.5)
                          : _ringAnimation.value * 0.68;
                      return SizedBox(
                        width: 140,
                        height: 140,
                        child: CustomPaint(
                          painter: _GaugePainter(
                              progresso: progresso, temMeta: m.metaDiariaCentavos > 0, faturamento: m.faturamentoCentavosHoje),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(FincoreMoneyFormatter.format(m.faturamentoCentavosHoje),
                                    style: const TextStyle(color: FincoreColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 2),
                                _VariacaoChip(pct: m.variacaoFaturamentoPct),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (m.metaDiariaCentavos > 0) ...[
                    const SizedBox(height: 8),
                    Text('Meta: ${FincoreMoneyFormatter.format(m.metaDiariaCentavos)}',
                        style: const TextStyle(color: FincoreColors.textMuted, fontSize: 11)),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: m.progressoMeta.clamp(0.0, 1.0),
                      backgroundColor: FincoreColors.border,
                      color: m.progressoMeta >= 1.0 ? FincoreColors.success : FincoreColors.primary,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Text('${(m.progressoMeta * 100).toStringAsFixed(0)}% da meta',
                        style: TextStyle(
                            color: m.progressoMeta >= 1.0 ? FincoreColors.success : FincoreColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ] else ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () => _definirMetaModal(context),
                      icon: Icon(Icons.edit_outlined, size: 12, color: FincoreColors.primary),
                      label: Text('Definir Meta Diária',
                          style: TextStyle(color: FincoreColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            );

            final kpiGrid = Column(
              children: [
                Row(children: [
                  Expanded(
                      child: _KpiDeltaCard(
                          label: 'Pedidos Hoje',
                          value: m.totalPedidosHoje.toString(),
                          variacaoPct: m.variacaoPedidosPct,
                          icon: Icons.receipt_long_rounded,
                          color: FincoreColors.accent,
                          onTap: () => FincoreShell.selectTab(context, 'pedidos'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _KpiDeltaCard(
                          label: 'Entregas Hoje',
                          value: m.totalEntregasHoje.toString(),
                          variacaoPct: m.variacaoEntregasPct,
                          icon: Icons.delivery_dining_rounded,
                          color: const Color(0xFF3B82F6),
                          onTap: () => FincoreShell.selectTab(context, 'pedidos'))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _KpiDeltaCard(
                          label: 'Retiradas',
                          value: m.totalRetiradasHoje.toString(),
                          variacaoPct: null,
                          icon: Icons.storefront_rounded,
                          color: const Color(0xFF8B5CF6),
                          onTap: () => FincoreShell.selectTab(context, 'pedidos'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _KpiDeltaCard(
                          label: 'Produções Ativas',
                          value: m.producoesAtivasCount.toString(),
                          variacaoPct: null,
                          icon: Icons.precision_manufacturing_rounded,
                          color: FincoreColors.warning,
                          onTap: () => FincoreShell.selectTab(context, 'producao'))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _KpiDeltaCard(
                          label: 'Ticket Médio',
                          value: FincoreMoneyFormatter.format(m.ticketMedioCentavosHoje),
                          variacaoPct: null,
                          icon: Icons.price_check_rounded,
                          color: FincoreColors.success,
                          onTap: () => FincoreShell.selectTab(context, 'financeiro'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _KpiDeltaCard(
                          label: 'Cancelamentos',
                          value: m.pedidosCanceladosHoje.toString(),
                          variacaoPct: (m.pedidosCanceladosHoje > 0 && m.pedidosCanceladosOntem > 0)
                              ? ((m.pedidosCanceladosHoje - m.pedidosCanceladosOntem) / m.pedidosCanceladosOntem) * 100.0
                              : null,
                          icon: Icons.cancel_outlined,
                          color: m.pedidosCanceladosHoje > 0 ? const Color(0xFFE05C5C) : FincoreColors.textSecondary,
                          invertColor: true,
                          onTap: () => FincoreShell.selectTab(context, 'pedidos'))),
                ]),
              ],
            );

            if (isMobile) return Column(children: [velocimetro, const SizedBox(height: 16), kpiGrid]);
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 220, child: velocimetro),
              const SizedBox(width: 16),
              Expanded(child: kpiGrid),
            ]);
          },
        ),
      ],
    );
  }
}

class _VariacaoChip extends StatelessWidget {
  final double pct;
  const _VariacaoChip({required this.pct});
  @override
  Widget build(BuildContext context) {
    if (pct == 0) return const SizedBox.shrink();
    final isPos = pct >= 0;
    final cor = isPos ? FincoreColors.success : const Color(0xFFE05C5C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isPos ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: cor, size: 10),
        const SizedBox(width: 2),
        Text('${pct.abs().toStringAsFixed(1)}%', style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _KpiDeltaCard extends StatefulWidget {
  final String label;
  final String value;
  final double? variacaoPct;
  final IconData icon;
  final Color color;
  final bool invertColor;
  final VoidCallback onTap;
  const _KpiDeltaCard({
    required this.label, required this.value, required this.variacaoPct,
    required this.icon, required this.color, required this.onTap, this.invertColor = false,
  });
  @override
  State<_KpiDeltaCard> createState() => _KpiDeltaCardState();
}

class _KpiDeltaCardState extends State<_KpiDeltaCard> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? widget.color.withValues(alpha: 0.5) : widget.color.withValues(alpha: 0.15),
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered ? [BoxShadow(color: widget.color.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(widget.icon, color: widget.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.label, style: const TextStyle(color: FincoreColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(widget.value, style: TextStyle(color: widget.color, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                if (widget.variacaoPct != null) ...[
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _DeltaBadge(pct: widget.variacaoPct!, invertColor: widget.invertColor),
                  ),
                ],
              ]),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  final double pct;
  final bool invertColor;
  const _DeltaBadge({required this.pct, this.invertColor = false});
  @override
  Widget build(BuildContext context) {
    final isPos = pct >= 0;
    final corPos = invertColor ? const Color(0xFFE05C5C) : FincoreColors.success;
    final corNeg = invertColor ? FincoreColors.success : const Color(0xFFE05C5C);
    final cor = isPos ? corPos : corNeg;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(isPos ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: cor, size: 10),
      Text('${pct.abs().toStringAsFixed(0)}%', style: TextStyle(color: cor, fontSize: 9, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _GaugePainter extends CustomPainter {
  final double progresso;
  final bool temMeta;
  final int faturamento;
  _GaugePainter({required this.progresso, required this.temMeta, required this.faturamento});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    final paintBg = Paint()
      ..color = const Color(0xFF1E2D3D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi * 1.1, math.pi * 1.35, false, paintBg);

    if (progresso > 0) {
      final cor = temMeta
          ? (progresso >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF3B82F6))
          : const Color(0xFF6366F1);

      final sweep = math.pi * 1.35 * progresso.clamp(0.0, 1.0);
      final paintProgress = Paint()
        ..shader = SweepGradient(
          colors: [cor.withValues(alpha: 0.4), cor],
          startAngle: -math.pi * 1.1,
          endAngle: -math.pi * 1.1 + sweep,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi * 1.1, sweep, false, paintProgress);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.progresso != progresso;
}
