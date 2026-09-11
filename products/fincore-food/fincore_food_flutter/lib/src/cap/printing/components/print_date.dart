import 'package:fincore_shared/fincore_shared.dart';

/// Componente de impressão reutilizável para formatar datas e horários no cupom.
class PrintDate {
  const PrintDate._();

  /// Formata data e hora no formato padrão de cupom incluindo o dia da semana (ex: "domingo 27/07/2025 - 14:35").
  static String format(DateTime dateTime) {
    return FinCoreDateFormatter.formatDateTimeWithWeekday(dateTime);
  }

  /// Retorna apenas a hora formatada (ex: "14:35").
  static String formatTimeOnly(DateTime dateTime) {
    return FinCoreDateFormatter.formatTime(dateTime);
  }
}
