import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/domain_primitives.dart';

/// Componente Padrão de Cabeçalho Global do FINCORE ERP (Zero Redundância).
/// Suporta Breadcrumb (11px UPPERCASE), Título (30px Bold), Descrição (14px) e Ações alinhadas à direita.
class FincorePageHeader extends StatelessWidget {
  final List<String> breadcrumb;
  final String title;
  final String description;
  final SyncStatus? syncStatus;
  final String? syncMessage;
  final Widget? statusWidget;
  final Widget? primaryAction;
  final List<Widget>? extraActions;

  const FincorePageHeader({
    super.key,
    required this.breadcrumb,
    required this.title,
    required this.description,
    this.syncStatus,
    this.syncMessage,
    this.statusWidget,
    this.primaryAction,
    this.extraActions,
  });

  Color _syncColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
      case SyncStatus.resolved:
        return const Color(0xFF22C55E);
      case SyncStatus.pending:
      case SyncStatus.processing:
      case SyncStatus.retrying:
        return const Color(0xFFF59E0B);
      case SyncStatus.failed:
      case SyncStatus.conflict:
        return const Color(0xFFEF4444);
    }
  }

  IconData _syncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
      case SyncStatus.resolved:
        return Icons.cloud_done_outlined;
      case SyncStatus.pending:
      case SyncStatus.retrying:
        return Icons.cloud_upload_outlined;
      case SyncStatus.processing:
        return Icons.sync;
      case SyncStatus.failed:
      case SyncStatus.conflict:
        return Icons.cloud_off_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final breadcrumbText = breadcrumb.join('  /  ');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha 1: Breadcrumb + Status + Ações alinhadas à direita
          Row(
            children: [
              Text(
                breadcrumbText.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: FincoreColors.textMuted,
                ),
              ),
              const Spacer(),
              if (syncStatus != null) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _syncColor(syncStatus!).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _syncColor(syncStatus!).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      syncStatus == SyncStatus.processing
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _syncColor(syncStatus!),
                              ),
                            )
                          : Icon(_syncIcon(syncStatus!), size: 14, color: _syncColor(syncStatus!)),
                      const SizedBox(width: 6),
                      Text(
                        (syncMessage != null && syncMessage!.isNotEmpty) ? syncMessage! : 'Sincronizado',
                        style: TextStyle(
                          fontSize: 11,
                          color: _syncColor(syncStatus!),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (statusWidget != null) ...[
                statusWidget!,
                const SizedBox(width: 12),
              ],
              if (primaryAction != null) primaryAction!,
              if (extraActions != null) ...extraActions!,
            ],
          ),
          const SizedBox(height: 6),

          // Linha 2: Título (30px Bold)
          Text(
            title,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: FincoreColors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),

          // Linha 3: Descrição da Tela (14px)
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: FincoreColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
