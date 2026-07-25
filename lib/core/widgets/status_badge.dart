import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status.toLowerCase()) {
      case 'entregue':
      case 'concluído':
      case 'concluido':
        bg = AppColors.successBg;
        fg = AppColors.success;
        break;
      case 'saiu para entrega':
      case 'em transporte':
        bg = AppColors.infoBg;
        fg = AppColors.info;
        break;
      case 'cancelado':
        bg = AppColors.errorBg;
        fg = AppColors.error;
        break;
      case 'pendente':
      case 'em preparo':
      default:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
