import 'package:flutter/material.dart';
import '../theme/fincore_colors.dart';

// ─── AppEmptyState ────────────────────────────────────────────────────────────

/// Estado vazio padrão para listas e tabelas sem dados.
///
/// Uso:
/// ```dart
/// if (pedidos.isEmpty) AppEmptyState(
///   icon: Icons.receipt_long_outlined,
///   title: 'Nenhum pedido encontrado',
///   subtitle: 'Crie um novo pedido pelo PDV Express.',
///   action: ElevatedButton(onPressed: () {}, child: Text('Novo Pedido')),
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: (iconColor ?? FincoreColors.textMuted).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: (iconColor ?? FincoreColors.textMuted).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: FincoreColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: FincoreColors.textMuted,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─── AppLoading ───────────────────────────────────────────────────────────────

/// Indicador de carregamento centralizado e padronizado.
///
/// Uso:
/// ```dart
/// if (isLoading) const AppLoading()
/// if (isLoading) const AppLoading(message: 'Carregando pedidos...')
/// ```
class AppLoading extends StatelessWidget {
  final String? message;
  final double size;

  const AppLoading({super.key, this.message, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: FincoreColors.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: FincoreColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── AppErrorState ────────────────────────────────────────────────────────────

/// Estado de erro com mensagem e botão de retry opcional.
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: FincoreColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 36,
                color: FincoreColors.danger,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: FincoreColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Tentar novamente'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FincoreColors.primary,
                  side: const BorderSide(color: FincoreColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── AppStatusBadge ───────────────────────────────────────────────────────────

/// Badge de status colorido e padronizado.
///
/// Uso:
/// ```dart
/// AppStatusBadge(label: 'Pendente', color: FincoreColors.warning)
/// AppStatusBadge.success(label: 'Pago')
/// AppStatusBadge.danger(label: 'Cancelado')
/// ```
class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  const AppStatusBadge.success({super.key, required this.label, this.icon})
      : color = FincoreColors.success;

  const AppStatusBadge.danger({super.key, required this.label, this.icon})
      : color = FincoreColors.danger;

  const AppStatusBadge.warning({super.key, required this.label, this.icon})
      : color = FincoreColors.warning;

  const AppStatusBadge.muted({super.key, required this.label, this.icon})
      : color = FincoreColors.textMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AppInfoTile ──────────────────────────────────────────────────────────────

/// Linha de informação label + valor para formulários somente-leitura.
///
/// Uso:
/// ```dart
/// AppInfoTile(label: 'CPF', value: '123.456.789-00')
/// AppInfoTile(label: 'Total', value: 'R$ 45,00', valueColor: FincoreColors.success)
/// ```
class AppInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool compact;

  const AppInfoTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: FincoreColors.textMuted, fontSize: 12)),
          Text(value,
              style: TextStyle(
                color: valueColor ?? FincoreColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: FincoreColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? FincoreColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
