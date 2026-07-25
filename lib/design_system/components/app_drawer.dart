import 'package:flutter/material.dart';
import '../colors.dart';

class AppContextualDrawer extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? badge;
  final Widget child;
  final List<Widget>? actions;
  final VoidCallback onClose;
  final double width;

  const AppContextualDrawer({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.badge,
    required this.child,
    this.actions,
    required this.onClose,
    this.width = 460,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    IconData? icon,
    Widget? badge,
    required Widget child,
    List<Widget>? actions,
    double width = 460,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar Painel Lateral',
      barrierColor: Colors.black.withAlpha(90),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: AppContextualDrawer(
              title: title,
              subtitle: subtitle,
              icon: icon,
              badge: badge,
              actions: actions,
              onClose: () => Navigator.of(ctx).pop(),
              width: width,
              child: child,
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final effectiveWidth = screenWidth < width ? screenWidth * 0.95 : width;

    return Container(
      width: effectiveWidth,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            badge!,
                          ],
                        ],
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.grey),
                  tooltip: 'Fechar (Esc)',
                ),
              ],
            ),
          ),

          // Body Conteúdo
          Expanded(
            child: child,
          ),

          // Footer com botões de ação se existirem
          if (actions != null && actions!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!
                    .expand((w) => [w, const SizedBox(width: 10)])
                    .toList()
                  ..removeLast(),
              ),
            ),
        ],
      ),
    );
  }
}
