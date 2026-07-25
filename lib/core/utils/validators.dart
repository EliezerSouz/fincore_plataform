/// Validadores de formulários e campos do sistema.
class Validators {
  static String? obrigatorio(String? value, [String campo = 'Campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$campo é obrigatório.';
    }
    return null;
  }

  static String? telefone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefone é obrigatório.';
    }
    final limpo = value.replaceAll(RegExp(r'\D'), '');
    if (limpo.length < 8 || limpo.length > 11) {
      return 'Telefone deve conter de 8 a 11 dígitos.';
    }
    return null;
  }

  static String? valorPositivo(String? value, [String campo = 'Valor']) {
    if (value == null || value.trim().isEmpty) {
      return '$campo é obrigatório.';
    }
    final num = double.tryParse(value.replaceAll(',', '.'));
    if (num == null || num <= 0) {
      return '$campo deve ser maior que zero.';
    }
    return null;
  }
}
