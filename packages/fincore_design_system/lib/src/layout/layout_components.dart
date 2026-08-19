import 'package:flutter/material.dart';
import '../theme/fincore_colors.dart';

// ─── AppCard ─────────────────────────────────────────────────────────────────

/// Card padrão FINCORE com visual consistente em toda a plataforma.
///
/// Uso:
/// ```dart
/// AppCard(
///   child: Text('Conteúdo'),
///   onTap: () => print('clicado'),
/// )
/// ```
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? FincoreColors.surface,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? FincoreColors.border,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── AppSection ──────────────────────────────────────────────────────────────

/// Seção de conteúdo com cabeçalho padronizado e slot de ações.
///
/// Uso:
/// ```dart
/// AppSection(
///   title: 'Pedidos Recentes',
///   actions: [TextButton(...)],
///   children: [PedidoTile(...)],
/// )
/// ```
class AppSection extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const AppSection({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: FincoreColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
              ),
            ),
            if (actions != null) Row(children: actions!),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

// ─── AppToolbar ───────────────────────────────────────────────────────────────

/// Barra de título padrão para páginas com ações opcionais.
///
/// Uso:
/// ```dart
/// AppToolbar(
///   title: 'Pedidos',
///   subtitle: '32 pedidos hoje',
///   actions: [
///     AppToolbarAction(icon: Icons.add, label: 'Novo', onTap: () {}),
///   ],
/// )
/// ```
class AppToolbar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showDivider;

  const AppToolbar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: FincoreColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: FincoreColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (actions != null) Row(children: actions!),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 16),
          Divider(color: FincoreColors.border, height: 1),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

/// Botão de ação na AppToolbar (ícone + rótulo).
class AppToolbarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool primary;

  const AppToolbarAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? FincoreColors.primary;
    if (primary) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(backgroundColor: c),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: c),
      label: Text(label, style: TextStyle(color: c)),
      style: OutlinedButton.styleFrom(side: BorderSide(color: FincoreColors.border)),
    );
  }
}

// ─── AppPage ─────────────────────────────────────────────────────────────────

/// Wrapper padrão para conteúdo de páginas com scroll e padding consistentes.
///
/// Uso:
/// ```dart
/// AppPage(
///   toolbar: AppToolbar(title: 'Clientes'),
///   child: ClientesList(),
/// )
/// ```
class AppPage extends StatelessWidget {
  final Widget child;
  final AppToolbar? toolbar;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;

  const AppPage({
    super.key,
    required this.child,
    this.toolbar,
    this.scrollable = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (toolbar != null) toolbar!,
        Expanded(child: child),
      ],
    );

    final padded = Padding(
      padding: padding ?? const EdgeInsets.all(24),
      child: content,
    );

    if (scrollable) {
      return SingleChildScrollView(
        padding: padding ?? const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (toolbar != null) toolbar!,
            child,
          ],
        ),
      );
    }

    return padded;
  }
}
