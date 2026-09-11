import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_shared/fincore_shared.dart';
import 'package:fincore_food_flutter/src/shared/presentation/shell/fincore_shell.dart';
import '../controllers/dashboard_controller.dart';

class BlocoOperacaoAgora extends StatelessWidget {
  final DashboardController controller;

  const BlocoOperacaoAgora({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final m = controller.metrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Operação Agora',
            style: TextStyle(
              color: FincoreColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _KpiCard(
                label: 'Pedidos Hoje',
                value: m.totalPedidosHoje.toString(),
                icon: Icons.receipt_long_rounded,
                color: FincoreColors.accent,
                onTap: () => FincoreShell.selectTab(context, 'pedidos'),
              ),
              _KpiCard(
                label: 'Entregas Hoje',
                value: m.totalEntregasHoje.toString(),
                icon: Icons.delivery_dining_rounded,
                color: const Color(0xFF3B82F6),
                onTap: () => FincoreShell.selectTab(context, 'pedidos'),
              ),
              _KpiCard(
                label: 'Retiradas Hoje',
                value: m.totalRetiradasHoje.toString(),
                icon: Icons.storefront_rounded,
                color: const Color(0xFF8B5CF6),
                onTap: () => FincoreShell.selectTab(context, 'pedidos'),
              ),
              _KpiCard(
                label: 'Produções Ativas',
                value: m.producoesAtivasCount.toString(),
                icon: Icons.precision_manufacturing_rounded,
                color: FincoreColors.warning,
                onTap: () => FincoreShell.selectTab(context, 'producao'),
              ),
              _KpiCard(
                label: 'Faturamento Hoje',
                value: FincoreMoneyFormatter.format(m.faturamentoCentavosHoje),
                icon: Icons.attach_money_rounded,
                color: FincoreColors.success,
                onTap: () => FincoreShell.selectTab(context, 'financeiro'),
              ),
            ];

            int crossAxisCount = 5;
            if (constraints.maxWidth < 480) {
              crossAxisCount = 1;
            } else if (constraints.maxWidth < 768) {
              crossAxisCount = 2;
            } else if (constraints.maxWidth < 1024) {
              crossAxisCount = 3;
            }

            if (crossAxisCount == 5) {
              return Row(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            } else {
              final spacing = 12.0;
              final cardWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: cards.map((card) {
                  return SizedBox(
                    width: cardWidth,
                    child: card,
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }
}

class _KpiCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
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
          height: 110,
          decoration: BoxDecoration(
            color: FincoreColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.5)
                  : widget.color.withValues(alpha: 0.15),
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              widget.label,
                              style: const TextStyle(
                                color: FincoreColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.color,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        widget.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.color,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.55,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
