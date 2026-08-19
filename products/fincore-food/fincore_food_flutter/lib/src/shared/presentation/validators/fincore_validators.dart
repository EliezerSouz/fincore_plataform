/// Biblioteca centralizada de validadores para formulários do FINCORE Platform.
///
/// Todos os validadores são compatíveis com o parâmetro [validator] do
/// [TextFormField] — retornam `null` se válido ou uma [String] de erro se inválido.
///
/// Uso:
/// ```dart
/// FincoreTextField(
///   validator: FincoreValidators.required,
/// )
/// FincoreTextField(
///   validator: FincoreValidators.compose([
///     FincoreValidators.required,
///     FincoreValidators.email,
///   ]),
/// )
/// ```
class FincoreValidators {
  FincoreValidators._();

  // ─── BÁSICOS ──────────────────────────────────────────────────────────────

  /// Campo obrigatório — não pode ser vazio ou apenas espaços.
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }
    return null;
  }

  /// Campo obrigatório com mensagem customizada.
  static String? Function(String?) requiredMsg(String msg) {
    return (value) {
      if (value == null || value.trim().isEmpty) return msg;
      return null;
    };
  }

  // ─── COMPRIMENTO ──────────────────────────────────────────────────────────

  /// Comprimento mínimo de caracteres (após trim).
  static String? Function(String?) minLength(int min) {
    return (value) {
      if (value == null || value.trim().isEmpty) return null; // deixa required tratar
      if (value.trim().length < min) {
        return 'Mínimo de $min caracteres';
      }
      return null;
    };
  }

  /// Comprimento máximo de caracteres.
  static String? Function(String?) maxLength(int max) {
    return (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (value.trim().length > max) {
        return 'Máximo de $max caracteres';
      }
      return null;
    };
  }

  // ─── FORMATO ──────────────────────────────────────────────────────────────

  /// Valida formato de e-mail (RFC 5322 simplificado).
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null; // deixa required tratar
    final regex = RegExp(r'^[\w\.\+\-]+@[\w\-]+(\.[\w\-]+)*\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'E-mail inválido';
    }
    return null;
  }

  /// Valida telefone brasileiro (aceita com ou sem formatação).
  /// Formatos aceitos: (11) 99999-9999 / 11999999999 / etc.
  static String? telefone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 11) {
      return 'Telefone inválido (mín. 10 dígitos)';
    }
    return null;
  }

  /// Valida CPF ou CNPJ (aceita com ou sem formatação).
  static String? cpfCnpj(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11 && digits.length != 14) {
      return 'CPF (11 dígitos) ou CNPJ (14 dígitos) inválido';
    }
    return null;
  }

  /// Valida CPF apenas.
  static String? cpf(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return 'CPF inválido (11 dígitos)';
    return null;
  }

  /// Valida CNPJ apenas.
  static String? cnpj(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 14) return 'CNPJ inválido (14 dígitos)';
    return null;
  }

  // ─── NUMÉRICOS ────────────────────────────────────────────────────────────

  /// Valida que o valor é um número inteiro válido.
  static String? integer(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (int.tryParse(value.trim()) == null) {
      return 'Deve ser um número inteiro';
    }
    return null;
  }

  /// Valida que o valor é um número decimal válido.
  static String? decimal(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().replaceAll(',', '.');
    if (double.tryParse(normalized) == null) {
      return 'Deve ser um número válido';
    }
    return null;
  }

  /// Valida que o valor é um decimal positivo (> 0).
  static String? positiveDecimal(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) return 'Deve ser um número válido';
    if (parsed <= 0) return 'Deve ser maior que zero';
    return null;
  }

  /// Valida que o valor é um inteiro ≥ 0.
  static String? nonNegativeInteger(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Deve ser um número inteiro';
    if (parsed < 0) return 'Deve ser zero ou maior';
    return null;
  }

  // ─── IDENTIDADE ───────────────────────────────────────────────────────────

  /// Valida username: sem espaços, apenas letras, números, ponto e sublinhado.
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.contains(' ')) return 'Username não pode conter espaços';
    final regex = RegExp(r'^[a-zA-Z0-9._]+$');
    if (!regex.hasMatch(value)) {
      return 'Use apenas letras, números, ponto (.) ou sublinhado (_)';
    }
    return null;
  }

  // ─── COMPOSIÇÃO ───────────────────────────────────────────────────────────

  /// Combina múltiplos validators em sequência.
  /// Retorna o erro do primeiro validator que falhar, ou null se todos passarem.
  ///
  /// Exemplo:
  /// ```dart
  /// validator: FincoreValidators.compose([
  ///   FincoreValidators.required,
  ///   FincoreValidators.email,
  /// ])
  /// ```
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
