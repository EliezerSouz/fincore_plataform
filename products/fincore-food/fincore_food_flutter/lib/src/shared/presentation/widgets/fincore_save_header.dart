import 'package:flutter/material.dart';
import 'package:fincore_design_system/fincore_design_system.dart';
import 'package:fincore_core/common/domain_primitives.dart';

/// Cabeçalho padronizado High-Density ERP com ação primária de salvamento e indicador de sincronização.
class FincoreSaveHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final SyncStatus syncStatus;
  final String syncMessage;
  final bool hasUnsavedChanges;
  final bool isSaving;
  final VoidCallback? onSave;
  final List<Widget>? extraActions;

  const FincoreSaveHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.syncStatus,
    required this.syncMessage,
    required this.hasUnsavedChanges,
    required this.isSaving,
    this.onSave,
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
    final statusColor = _syncColor(syncStatus);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: FincoreColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: FincoreColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // Chip Status de Sync
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                syncStatus == SyncStatus.processing
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: statusColor,
                        ),
                      )
                    : Icon(_syncIcon(syncStatus), size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  syncMessage.isEmpty ? 'Sincronizado' : syncMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Botão Ação Primária
          ElevatedButton.icon(
            onPressed: (hasUnsavedChanges && !isSaving) ? onSave : null,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(
              isSaving ? 'Salvando...' : 'Salvar Alterações',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: FincoreColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(140, 40),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: FincoreColors.border,
              disabledForegroundColor: FincoreColors.textMuted,
              elevation: 0,
            ),
          ),

          if (extraActions != null) ...extraActions!,
        ],
      ),
    );
  }
}
