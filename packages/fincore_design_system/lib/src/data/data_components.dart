import 'package:flutter/material.dart';
import '../theme/fincore_colors.dart';

// ─── AppMetricCard ────────────────────────────────────────────────────────────

/// Card de métrica com ícone, valor principal e indicador de tendência.
///
/// Uso:
/// ```dart
/// AppMetricCard(
///   icon: Icons.receipt_long_outlined,
///   title: 'Pedidos Hoje',
///   value: '32',
///   subtitle: '+8 vs ontem',
///   trend: MetricTrend.up,
///   color: FincoreColors.accent,
/// )
/// ```
enum MetricTrend { up, down, neutral }

class AppMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final MetricTrend trend;
  final Color color;
  final VoidCallback? onTap;

  const AppMetricCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.trend = MetricTrend.neutral,
    this.color = FincoreColors.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FincoreColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FincoreColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (trend != MetricTrend.neutral)
                    _TrendIndicator(trend: trend),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: FincoreColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: FincoreColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendIndicator extends StatelessWidget {
  final MetricTrend trend;
  const _TrendIndicator({required this.trend});

  @override
  Widget build(BuildContext context) {
    final isUp = trend == MetricTrend.up;
    final color = isUp ? FincoreColors.success : FincoreColors.danger;
    final icon = isUp ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: color, size: 14),
    );
  }
}

// ─── AppDashboardCard ─────────────────────────────────────────────────────────

/// Card flexível para dashboards com header, body e footer slots.
class AppDashboardCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final Widget child;
  final Widget? footer;
  final List<Widget>? actions;

  const AppDashboardCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.footer,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? FincoreColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accent, size: 18),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: FincoreColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: FincoreColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                if (actions != null) Row(children: actions!),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
          // Footer
          if (footer != null) ...[
            Divider(color: FincoreColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }
}
