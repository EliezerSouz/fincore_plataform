import 'package:flutter/material.dart';
import '../spacing.dart';
import '../typography.dart';
import 'app_button.dart';

class AppDialog extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? description;
  final Widget content;
  final VoidCallback? onCancel;
  final String cancelLabel;
  final VoidCallback? onSave;
  final String saveLabel;
  final bool isDestructive;

  const AppDialog({
    super.key,
    this.icon,
    required this.title,
    this.description,
    required this.content,
    this.onCancel,
    this.cancelLabel = 'Cancelar',
    this.onSave,
    this.saveLabel = 'Salvar',
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.s16),
          ],
          Text(title, style: AppTypography.h3),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(description!, style: AppTypography.text.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
      content: content,
      actions: [
        if (onCancel != null)
          AppButton(
            label: cancelLabel,
            onPressed: onCancel,
            type: AppButtonType.secondary,
          ),
        if (onSave != null)
          AppButton(
            label: saveLabel,
            onPressed: onSave,
            type: isDestructive ? AppButtonType.danger : AppButtonType.primary,
          ),
      ],
    );
  }
}
