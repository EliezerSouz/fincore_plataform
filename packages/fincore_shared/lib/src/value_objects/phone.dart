import 'package:meta/meta.dart';

/// Value Object imutável que representa um número de telefone brasileiro.
///
/// Armazena internamente apenas os dígitos (sem máscara).
/// Fornece métodos para formatação, validação e comparação.
///
/// Exemplo:
/// ```dart
/// final phone = FincorePhone.parse('(15) 99999-9999');
/// print(phone.formatted); // (15) 99999-9999
/// print(phone.isValid);   // true
/// ```
@immutable
class FincorePhone {
  /// Dígitos brutos do telefone (apenas números, sem máscara).
  final String digits;

  const FincorePhone._(this.digits);

  /// Cria um [FincorePhone] a partir de uma string que pode conter máscara.
  factory FincorePhone.parse(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return FincorePhone._(digits);
  }

  /// Cria um [FincorePhone] vazio/inválido.
  const FincorePhone.empty() : digits = '';

  /// Retorna `true` se o telefone tem 10 dígitos (fixo) ou 11 (celular).
  bool get isValid =>
      digits.length == 10 || digits.length == 11;

  /// Retorna `true` se o telefone está vazio.
  bool get isEmpty => digits.isEmpty;

  /// Retorna o telefone formatado com máscara:
  /// - 11 dígitos: `(##) #####-####`
  /// - 10 dígitos: `(##) ####-####`
  /// - Inválido: retorna os dígitos sem formatação.
  String get formatted {
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return digits;
  }

  /// Retorna o número no formato internacional sem máscara: `+55XXXXXXXXXXX`.
  String get international => '+55$digits';

  /// Retorna o número para uso em links do WhatsApp: `55XXXXXXXXXXX`.
  String get whatsAppNumber => '55$digits';

  @override
  bool operator ==(Object other) =>
      other is FincorePhone && other.digits == digits;

  @override
  int get hashCode => digits.hashCode;

  @override
  String toString() => formatted;
}
