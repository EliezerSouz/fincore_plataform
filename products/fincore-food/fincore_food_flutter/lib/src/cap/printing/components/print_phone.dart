import 'package:fincore_shared/fincore_shared.dart';

/// Componente de impressão reutilizável para formatar telefones.
class PrintPhone {
  const PrintPhone._();

  /// Formata e retorna a linha de telefone formatada (ex: "(15) 99999-9999").
  static String format(String raw) {
    if (raw.trim().isEmpty) return '';
    return FincorePhoneFormatter.format(raw);
  }
}
