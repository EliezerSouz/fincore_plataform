import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/kds_models.dart';

/// Coluna do Kanban com header colorido, contador de pedidos e lista de cards.
class KanbanColumn extends StatelessWidget {
  final String title;
  final Color accentColor;
  final List<OrdemPreparo> ordens;
  final Widget Function(OrdemPreparo ordem, int index) cardBuilder;

  /// Se verdadeiro, a coluna é exibida em modo compacto (lista de linhas).
  final bool modoCompacto;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.accentColor,
    required this.ordens,
    required this.cardBuilder,
    this.modoCompacto = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FincoreColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header com acento superior
          _KanbanColumnHeader(
            title: title,
            count: ordens.length,
            accentColor: accentColor,
          ),

          // Lista de cards (ou estado vazio)
          Expanded(
            child: ordens.isEmpty
                ? _EmptyState(accentColor: accentColor)
                : modoCompacto
                    ? _CompactList(ordens: ordens, cardBuilder: cardBuilder)
                    : _CardList(ordens: ordens, cardBuilder: cardBuilder),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _KanbanColumnHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color accentColor;

  const _KanbanColumnHeader({
    required this.title,
    required this.count,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.05),
          border: Border(
            top: BorderSide(color: accentColor, width: 3),
            bottom: BorderSide(color: FincoreColors.border),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: FincoreColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: count == 0
                  ? Container(
                      key: const ValueKey('zero'),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: FincoreColors.border,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '0',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: FincoreColors.textMuted,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      key: ValueKey(count),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color accentColor;
  const _EmptyState({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 28,
            color: FincoreColors.textMuted.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nenhum pedido',
            style: TextStyle(
              color: FincoreColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardList extends StatelessWidget {
  final List<OrdemPreparo> ordens;
  final Widget Function(OrdemPreparo, int) cardBuilder;

  const _CardList({required this.ordens, required this.cardBuilder});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: ordens.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) => cardBuilder(ordens[idx], idx),
    );
  }
}

class _CompactList extends StatelessWidget {
  final List<OrdemPreparo> ordens;
  final Widget Function(OrdemPreparo, int) cardBuilder;

  const _CompactList({required this.ordens, required this.cardBuilder});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: ordens.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: FincoreColors.border),
      itemBuilder: (ctx, idx) => cardBuilder(ordens[idx], idx),
    );
  }
}
