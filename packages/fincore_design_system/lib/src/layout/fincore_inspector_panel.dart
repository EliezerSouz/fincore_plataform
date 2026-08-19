import 'package:flutter/material.dart';
import '../theme/fincore_colors.dart';

class FincoreInspectorPanel extends StatelessWidget {
  final bool isOpen;
  final String title;
  final String? subtitle;
  final bool isEditing;
  final VoidCallback? onClose;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final Widget? actionsRow;
  final Widget child;
  final double width;

  const FincoreInspectorPanel({
    super.key,
    required this.isOpen,
    required this.title,
    this.subtitle,
    required this.isEditing,
    this.onClose,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
    this.actionsRow,
    required this.child,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: FincoreColors.surface,
        border: Border(
          left: BorderSide(color: FincoreColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do Painel
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isEditing)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'EDITANDO',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: FincoreColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 12,
                                color: FincoreColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onClose != null)
                      IconButton(
                        onPressed: onClose,
                        icon: Icon(Icons.close, size: 20, color: FincoreColors.textMuted),
                        splashRadius: 20,
                      ),
                  ],
                ),
                if (onEdit != null || onDuplicate != null || onDelete != null || actionsRow != null) ...[
                  const SizedBox(height: 12),
                  actionsRow ??
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (onEdit != null)
                            ElevatedButton.icon(
                              onPressed: onEdit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FincoreColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 13, color: Colors.white),
                              label: const Text('Editar', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          if (onDuplicate != null)
                            OutlinedButton.icon(
                              onPressed: onDuplicate,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                side: BorderSide(color: FincoreColors.border),
                              ),
                              icon: Icon(Icons.copy_outlined, size: 13, color: FincoreColors.textSecondary),
                              label: Text('Duplicar', style: TextStyle(fontSize: 11.5, color: FincoreColors.textSecondary)),
                            ),
                          if (onDelete != null)
                            OutlinedButton.icon(
                              onPressed: onDelete,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                              ),
                              icon: const Icon(Icons.delete_outline, size: 13, color: Colors.redAccent),
                              label: const Text('Excluir', style: TextStyle(fontSize: 11.5, color: Colors.redAccent)),
                            ),
                        ],
                      ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: FincoreColors.border),
          // Corpo do Painel
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
