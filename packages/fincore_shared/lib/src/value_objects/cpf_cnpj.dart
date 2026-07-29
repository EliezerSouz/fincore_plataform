import 'package:meta/meta.dart';

/// Tipo de documento fiscal.
enum CpfCnpjTipo { cpf, cnpj, desconhecido }

/// Value Object imutável para CPF ou CNPJ brasileiro.
///
/// Armazena internamente apenas os dígitos.
/// Detecta automaticamente se é CPF (11 dígitos) ou CNPJ (14 dígitos).
/// Valida o dígito verificador algoritmicamente.
///
/// Exemplo:
/// ```dart
/// final doc = FinCoreCpfCnpj.parse('12.345.678/0001-90');
/// print(doc.tipo);      // CpfCnpjTipo.cnpj
/// print(doc.isValid);   // true
/// print(doc.formatted); // 12.345.678/0001-90
/// ```
@immutable
class FinCoreCpfCnpj {
  final String digits;

  const FinCoreCpfCnpj._(this.digits);

  factory FinCoreCpfCnpj.parse(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return FinCoreCpfCnpj._(digits);
  }

  const FinCoreCpfCnpj.empty() : digits = '';

  bool get isEmpty => digits.isEmpty;

  /// Detecta o tipo com base no tamanho dos dígitos.
  CpfCnpjTipo get tipo {
    if (digits.length == 11) return CpfCnpjTipo.cpf;
    if (digits.length == 14) return CpfCnpjTipo.cnpj;
    return CpfCnpjTipo.desconhecido;
  }

  /// Valida o dígito verificador para CPF ou CNPJ.
  bool get isValid {
    switch (tipo) {
      case CpfCnpjTipo.cpf:
        return _validarCpf(digits);
      case CpfCnpjTipo.cnpj:
        return _validarCnpj(digits);
      case CpfCnpjTipo.desconhecido:
        return false;
    }
  }

  /// Retorna o documento formatado com máscara:
  /// - CPF: `###.###.###-##`
  /// - CNPJ: `##.###.###/####-##`
  String get formatted {
    if (tipo == CpfCnpjTipo.cpf && digits.length == 11) {
      return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
    }
    if (tipo == CpfCnpjTipo.cnpj && digits.length == 14) {
      return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12)}';
    }
    return digits;
  }

  // ─── Algoritmo CPF ──────────────────────────────────────────────────
  static bool _validarCpf(String cpf) {
    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1+$').hasMatch(cpf)) return false;

    int _calcDigito(String str, int pesoInicial) {
      int soma = 0;
      for (int i = 0; i < str.length; i++) {
        soma += int.parse(str[i]) * (pesoInicial - i);
      }
      final resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    final d1 = _calcDigito(cpf.substring(0, 9), 10);
    final d2 = _calcDigito(cpf.substring(0, 10), 11);
    return d1 == int.parse(cpf[9]) && d2 == int.parse(cpf[10]);
  }

  // ─── Algoritmo CNPJ ─────────────────────────────────────────────────
  static bool _validarCnpj(String cnpj) {
    if (cnpj.length != 14) return false;
    if (RegExp(r'^(\d)\1+$').hasMatch(cnpj)) return false;

    int _calcDigito(String str, List<int> pesos) {
      int soma = 0;
      for (int i = 0; i < str.length; i++) {
        soma += int.parse(str[i]) * pesos[i];
      }
      final resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    const p1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const p2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

    final d1 = _calcDigito(cnpj.substring(0, 12), p1);
    final d2 = _calcDigito(cnpj.substring(0, 13), p2);
    return d1 == int.parse(cnpj[12]) && d2 == int.parse(cnpj[13]);
  }

  @override
  bool operator ==(Object other) =>
      other is FinCoreCpfCnpj && other.digits == digits;

  @override
  int get hashCode => digits.hashCode;

  @override
  String toString() => formatted;
}
