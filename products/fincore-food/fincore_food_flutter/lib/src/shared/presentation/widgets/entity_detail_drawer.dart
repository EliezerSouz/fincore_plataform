import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';

/// Base compartilhada para drawers laterais do FINCORE.
///
/// Padrão: clicou em qualquer entidade → drawer desliza da direita →
/// visualiza contexto → executa ação → fecha.
///
/// Especializações:
/// - [PedidoDetailDrawer]
/// - (futuro) ClienteDetailDrawer
/// - (futuro) ProdutoDetailDrawer
class EntityDetailDrawer extends StatelessWidget {
  /// Título principal (ex: "Pedido #AB1234")
  final String title;

  /// Subtítulo (ex: "há 15 minutos")
  final String? subtitle;

  /// Área de badges de status/prioridade
  final Widget? badges;

  /// Lifecycle visual horizontal (stepper de etapas)
  final Widget? lifecycle;

  /// Corpo principal (dados da entidade)
  final Widget body;

  /// Linha do tempo / auditoria — exibida após o corpo
  final Widget? timeline;

  /// Ações operacionais na base do drawer
  final Widget? actions;

  /// Callback ao fechar
  final VoidCallback? onClose;

  /// Largura do drawer (padrão: 440)
  final double width;

  const EntityDetailDrawer({
    super.key,
    required this.title,
    this.subtitle,
    this.badges,
    this.lifecycle,
    required this.body,
    this.timeline,
    this.actions,
    this.onClose,
    this.width = 440,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: FincoreColors.surface,
          border: Border(
            left: BorderSide(color: FincoreColors.border),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ─────────────────────────────────────────────────
            _DrawerHeader(
              title: title,
              subtitle: subtitle,
              badges: badges,
              onClose: onClose ?? () => Navigator.of(context).pop(),
            ),
  
            // ── Lifecycle ───────────────────────────────────────────────
            if (lifecycle != null) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: lifecycle!,
              ),
              Container(height: 1, color: FincoreColors.border),
            ],
  
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      body,
                      if (timeline != null) ...[
                        const SizedBox(height: 24),
                        _SectionLabel(label: 'Linha do Tempo'),
                        const SizedBox(height: 12),
                        timeline!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
  
            // ── Ações ─────────────────────────────────────────────────
            if (actions != null) ...[
              Container(height: 1, color: FincoreColors.border),
              Padding(
                padding: const EdgeInsets.all(16),
                child: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets internos ─────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? badges;
  final VoidCallback onClose;

  const _DrawerHeader({
    required this.title,
    this.subtitle,
    this.badges,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: FincoreColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: FincoreColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: FincoreColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
                if (badges != null) ...[
                  const SizedBox(height: 8),
                  badges!,
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: FincoreColors.textMuted,
            onPressed: onClose,
            splashRadius: 18,
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }
}

/// Label de seção dentro do drawer
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: FincoreColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// Rótulo de seção exportável para uso em especializações.
class DrawerSectionLabel extends StatelessWidget {
  final String label;
  const DrawerSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: FincoreColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Linha de informação com ícone (ex: cliente, telefone, endereço).
class DrawerInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const DrawerInfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: iconColor ?? FincoreColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: FincoreColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
