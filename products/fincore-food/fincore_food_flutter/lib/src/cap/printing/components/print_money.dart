import 'package:fincore_shared/fincore_shared.dart';

/// Componente de impressão reutilizável para formatar valores monetários.
class PrintMoney {
  const PrintMoney._();

  /// Formata centavos em String monetária amigável para cupom (ex: "R$ 45,90").
  static String format(int centavos) {
    return FincoreMoneyFormatter.format(centavos);
  }

  /// Formata centavos sem o símbolo de moeda (ex: "45,90").
  static String formatRaw(int centavos) {
    return FincoreMoneyFormatter.formatRaw(centavos);
  }
}
