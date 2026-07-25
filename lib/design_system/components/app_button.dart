import 'package:flutter/material.dart';

enum AppButtonType { primary, secondary, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonType type;
  final bool isExpanded;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.type = AppButtonType.primary,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Text(label);
    if (icon != null) {
      child = Row(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    } else if (isExpanded) {
      child = Center(child: child);
    }

    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton(
          onPressed: onPressed,
          child: child,
        );
      case AppButtonType.secondary:
        return OutlinedButton(
          onPressed: onPressed,
          child: child,
        );
      case AppButtonType.danger:
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: onPressed,
          child: child,
        );
    }
  }
}
