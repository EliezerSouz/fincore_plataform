import 'package:flutter/material.dart';
import '../colors.dart';
import '../radius.dart';
import '../shadows.dart';

class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool hasHoverEffect;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.hasHoverEffect = false,
    this.onTap,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cards),
        border: Border.all(color: AppColors.border),
        boxShadow: widget.hasHoverEffect && _isHovered ? AppShadows.small : null,
      ),
      padding: widget.padding,
      child: widget.child,
    );

    if (widget.hasHoverEffect || widget.onTap != null) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.onTap,
          child: card,
        ),
      );
    }

    return card;
  }
}
