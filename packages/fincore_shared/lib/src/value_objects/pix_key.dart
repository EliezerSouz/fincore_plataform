import 'package:meta/meta.dart';

/// Tipo de chave PIX suportada pelo Banco Central.
enum PixKeyTipo { cpf, cnpj, email, telefone, aleatoria }

/// Value Object imutável para chave PIX.
///
/// Encapsula o tipo da chave e o valor bruto, fornecendo
/// validação básica e formatação para exibição no cupom.
///
/// Exemplo:
/// ```dart
/// final pix = FincorePixKey.parse('15999999999', PixKeyTipo.telefone);
/// print(pix.isValid);   // true
/// print(pix.formatted); // +55 15 99999-9999
/// ```
@immutable
class FincorePixKey {
  final String value;
  final PixKeyTipo tipo;

  const FincorePixKey({required this.value, required this.tipo});

  const FincorePixKey.empty()
      : value = '',
        tipo = PixKeyTipo.aleatoria;

  /// Detecta automaticamente o tipo a partir do valor.
  factory FincorePixKey.autoDetect(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) {
      return const FincorePixKey.empty();
    }
    // Telefone: somente dígitos, 10-11 dígitos
    final digits = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10 && digits.length <= 11 &&
        RegExp(r'^\d+$').hasMatch(digits)) {
      return FincorePixKey(value: cleaned, tipo: PixKeyTipo.telefone);
    }
    // E-mail
    if (cleaned.contains('@')) {
      return FincorePixKey(value: cleaned, tipo: PixKeyTipo.email);
    }
    // CPF (11 dígitos) ou CNPJ (14 dígitos)
    if (digits.length == 11) {
      return FincorePixKey(value: cleaned, tipo: PixKeyTipo.cpf);
    }
    if (digits.length == 14) {
      return FincorePixKey(value: cleaned, tipo: PixKeyTipo.cnpj);
    }
    // Chave aleatória (UUID)
    return FincorePixKey(value: cleaned, tipo: PixKeyTipo.aleatoria);
  }

  bool get isEmpty => value.isEmpty;

  /// Valida a chave de acordo com o tipo.
  bool get isValid {
    if (isEmpty) return false;
    switch (tipo) {
      case PixKeyTipo.email:
        return RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$').hasMatch(value);
      case PixKeyTipo.telefone:
        final d = value.replaceAll(RegExp(r'\D'), '');
        return d.length == 10 || d.length == 11;
      case PixKeyTipo.cpf:
        return value.replaceAll(RegExp(r'\D'), '').length == 11;
      case PixKeyTipo.cnpj:
        return value.replaceAll(RegExp(r'\D'), '').length == 14;
      case PixKeyTipo.aleatoria:
        // Formato UUID
        return RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false,
        ).hasMatch(value);
    }
  }

  /// Rótulo legível do tipo da chave.
  String get tipoLabel {
    switch (tipo) {
      case PixKeyTipo.cpf:        return 'CPF';
      case PixKeyTipo.cnpj:       return 'CNPJ';
      case PixKeyTipo.email:      return 'E-mail';
      case PixKeyTipo.telefone:   return 'Telefone';
      case PixKeyTipo.aleatoria:  return 'Chave Aleatória';
    }
  }

  /// Versão "limpa" da chave para uso em payloads EMV/PIX.
  String get clean {
    switch (tipo) {
      case PixKeyTipo.cpf:
      case PixKeyTipo.cnpj:
      case PixKeyTipo.telefone:
        return value.replaceAll(RegExp(r'\D'), '');
      case PixKeyTipo.email:
      case PixKeyTipo.aleatoria:
        return value.trim();
    }
  }

  /// Versão formatada para exibição no cupom/tela.
  String get formatted => value;

  @override
  bool operator ==(Object other) =>
      other is FincorePixKey && other.value == value && other.tipo == tipo;

  @override
  int get hashCode => Object.hash(value, tipo);

  @override
  String toString() => '[$tipoLabel] $value';
}
