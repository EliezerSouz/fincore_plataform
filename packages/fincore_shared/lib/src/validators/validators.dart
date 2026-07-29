import 'package:meta/meta.dart';
import '../value_objects/phone.dart';
import '../value_objects/cpf_cnpj.dart';
import '../value_objects/money.dart';
import '../value_objects/pix_key.dart';
import '../value_objects/misc_value_objects.dart';

// ─── Resultado de Validação ──────────────────────────────────────────────────

/// Resultado de uma validação. Pode ser válido ou inválido com mensagem de erro.
///
/// Uso em `FormField.validator`:
/// ```dart
/// validator: (v) => FincorePhoneValidator.validate(v).errorMessage,
/// ```
@immutable
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.valid()
      : isValid = true,
        errorMessage = null;

  const ValidationResult.invalid(this.errorMessage) : isValid = false;

  /// Retorna `null` se válido (compatível com `FormField.validator`).
  String? get formError => isValid ? null : errorMessage;

  @override
  String toString() =>
      isValid ? 'ValidationResult.valid' : 'ValidationResult.invalid($errorMessage)';
}

// ─── Validators ─────────────────────────────────────────────────────────────

/// Valida números de telefone brasileiro.
class FincorePhoneValidator {
  const FincorePhoneValidator._();

  static ValidationResult validate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const ValidationResult.invalid('Telefone obrigatório');
    }
    final phone = FincorePhone.parse(raw);
    if (!phone.isValid) {
      return const ValidationResult.invalid('Telefone inválido — informe 10 ou 11 dígitos');
    }
    return const ValidationResult.valid();
  }

  /// Atalho para uso em `FormField.validator`.
  static String? formValidator(String? raw) => validate(raw).formError;
}

/// Valida endereços de e-mail.
class FincoreEmailValidator {
  const FincoreEmailValidator._();

  static final _regex = RegExp(r'^[\w\.\-\+]+@[\w\-]+\.\w{2,}$');

  static ValidationResult validate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const ValidationResult.invalid('E-mail obrigatório');
    }
    if (!_regex.hasMatch(raw.trim())) {
      return const ValidationResult.invalid('E-mail inválido');
    }
    return const ValidationResult.valid();
  }

  static String? formValidator(String? raw) => validate(raw).formError;
}

/// Valida CPF com dígito verificador.
class FinCoreCpfValidator {
  const FinCoreCpfValidator._();

  static ValidationResult validate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const ValidationResult.invalid('CPF obrigatório');
    }
    final doc = FinCoreCpfCnpj.parse(raw);
    if (doc.tipo != CpfCnpjTipo.cpf) {
      return const ValidationResult.invalid('CPF deve ter 11 dígitos');
    }
    if (!doc.isValid) {
      return const ValidationResult.invalid('CPF inválido');
    }
    return const ValidationResult.valid();
  }

  static String? formValidator(String? raw) => validate(raw).formError;
}

/// Valida CNPJ com dígito verificador.
class FinCoreCnpjValidator {
  const FinCoreCnpjValidator._();

  static ValidationResult validate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const ValidationResult.invalid('CNPJ obrigatório');
    }
    final doc = FinCoreCpfCnpj.parse(raw);
    if (doc.tipo != CpfCnpjTipo.cnpj) {
      return const ValidationResult.invalid('CNPJ deve ter 14 dígitos');
    }
    if (!doc.isValid) {
      return const ValidationResult.invalid('CNPJ inválido');
    }
    return const ValidationResult.valid();
  }

  static String? formValidator(String? raw) => validate(raw).formError;
}

/// Valida valores monetários em centavos.
class FincoreMoneyValidator {
  const FincoreMoneyValidator._();

  static ValidationResult validate(
    int? centavos, {
    int min = 1,
    int? max,
    bool allowZero = false,
  }) {
    if (centavos == null) {
      return const ValidationResult.invalid('Valor obrigatório');
    }
    if (!allowZero && centavos <= 0) {
      return const ValidationResult.invalid('Valor deve ser maior que zero');
    }
    if (centavos < min) {
      return ValidationResult.invalid(
        'Valor mínimo: ${FinCoreMoney.fromCentavos(min).formatted}',
      );
    }
    if (max != null && centavos > max) {
      return ValidationResult.invalid(
        'Valor máximo: ${FinCoreMoney.fromCentavos(max).formatted}',
      );
    }
    return const ValidationResult.valid();
  }
}

/// Valida chaves PIX.
class FincorePixValidator {
  const FincorePixValidator._();

  static ValidationResult validate(FincorePixKey? key) {
    if (key == null || key.isEmpty) {
      return const ValidationResult.invalid('Chave PIX obrigatória');
    }
    if (!key.isValid) {
      return ValidationResult.invalid('Chave PIX inválida (${key.tipoLabel})');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult validateString(String? raw, PixKeyTipo tipo) {
    if (raw == null || raw.isEmpty) {
      return const ValidationResult.invalid('Chave PIX obrigatória');
    }
    final key = FincorePixKey(value: raw, tipo: tipo);
    return validate(key);
  }
}

/// Valida CEP brasileiro.
class FincorePostalCodeValidator {
  const FincorePostalCodeValidator._();

  static ValidationResult validate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const ValidationResult.invalid('CEP obrigatório');
    }
    final cep = FincorePostalCode.parse(raw);
    if (!cep.isValid) {
      return const ValidationResult.invalid('CEP inválido — deve ter 8 dígitos');
    }
    return const ValidationResult.valid();
  }

  static String? formValidator(String? raw) => validate(raw).formError;
}

/// Valida percentuais (0–100).
class FincorePercentageValidator {
  const FincorePercentageValidator._();

  static ValidationResult validate(double? value, {bool required = true}) {
    if (value == null) {
      return required
          ? const ValidationResult.invalid('Percentual obrigatório')
          : const ValidationResult.valid();
    }
    if (value < 0 || value > 100) {
      return const ValidationResult.invalid('Percentual deve ser entre 0% e 100%');
    }
    return const ValidationResult.valid();
  }
}

/// Valida strings genéricas (campos de texto).
class FincoreStringValidator {
  const FincoreStringValidator._();

  static ValidationResult validateRequired(String? raw, {String fieldName = 'Campo'}) {
    if (raw == null || raw.trim().isEmpty) {
      return ValidationResult.invalid('$fieldName obrigatório');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult validateLength(
    String? raw, {
    required int min,
    int? max,
    String fieldName = 'Campo',
  }) {
    final result = validateRequired(raw, fieldName: fieldName);
    if (!result.isValid) return result;
    final length = raw!.trim().length;
    if (length < min) {
      return ValidationResult.invalid('$fieldName deve ter ao menos $min caracteres');
    }
    if (max != null && length > max) {
      return ValidationResult.invalid('$fieldName deve ter no máximo $max caracteres');
    }
    return const ValidationResult.valid();
  }

  static String? formValidatorRequired(String? raw, {String fieldName = 'Campo'}) =>
      validateRequired(raw, fieldName: fieldName).formError;
}
