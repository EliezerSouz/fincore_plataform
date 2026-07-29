import 'package:fincore_shared/fincore_shared.dart';

/// Componente de impressão reutilizável para formatar datas e horários no cupom.
class PrintDate {
  const PrintDate._();

  /// Formata data e hora no formato padrão de cupom (ex: "27/07/2025 - 14:35").
  static String format(DateTime dateTime) {
    final dateStr = FinCoreDateFormatter.formatDate(dateTime);
    final timeStr = FinCoreDateFormatter.formatTime(dateTime);
    return '$dateStr - $timeStr';
  }

  /// Retorna apenas a hora formatada (ex: "14:35").
  static String formatTimeOnly(DateTime dateTime) {
    return FinCoreDateFormatter.formatTime(dateTime);
  }
}
