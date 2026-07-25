import 'package:flutter/material.dart';
import '../colors.dart';
import '../radius.dart';
import '../typography.dart';

enum AppStatusType { success, warning, danger, info, normal }

class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppStatusType type;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case AppStatusType.success:
        bg = AppColors.success.withAlpha(30);
        fg = AppColors.success;
        break;
      case AppStatusType.warning:
        bg = AppColors.warning.withAlpha(30);
        fg = AppColors.warning;
        break;
      case AppStatusType.danger:
        bg = AppColors.danger.withAlpha(30);
        fg = AppColors.danger;
        break;
      case AppStatusType.info:
        bg = AppColors.info.withAlpha(30);
        fg = AppColors.info;
        break;
      case AppStatusType.normal:
        bg = AppColors.border;
        fg = AppColors.textPrimary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.buttons),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
