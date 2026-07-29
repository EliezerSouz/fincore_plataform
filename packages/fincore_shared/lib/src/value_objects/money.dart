import 'package:meta/meta.dart';

/// Value Object imutável para valores monetários em centavos (BRL).
///
/// Armazenar valores como inteiros em centavos evita problemas de
/// precisão de ponto flutuante em operações financeiras.
///
/// Exemplo:
/// ```dart
/// final preco = FinCoreMoney.fromCentavos(1250);
/// print(preco.formatted);          // R$ 12,50
/// print(preco.reais);               // 12.5
/// final total = preco * 3;
/// print(total.formatted);           // R$ 37,50
/// ```
@immutable
class FinCoreMoney {
  /// Valor em centavos (inteiro, evita ponto flutuante).
  final int centavos;

  const FinCoreMoney(this.centavos);

  /// Cria a partir de centavos.
  const FinCoreMoney.fromCentavos(this.centavos);

  /// Cria a partir de reais (double).
  factory FinCoreMoney.fromReais(double reais) =>
      FinCoreMoney((reais * 100).round());

  /// Cria a partir de uma string como "12,50" ou "12.50".
  factory FinCoreMoney.parse(String raw) {
    final normalized = raw
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final value = double.tryParse(normalized) ?? 0.0;
    return FinCoreMoney.fromReais(value);
  }

  /// Zero moeda.
  static const FinCoreMoney zero = FinCoreMoney(0);

  /// Valor em reais (double).
  double get reais => centavos / 100.0;

  /// Retorna `true` se o valor for positivo.
  bool get isPositive => centavos > 0;

  /// Retorna `true` se o valor for zero.
  bool get isZero => centavos == 0;

  /// Retorna `true` se o valor for negativo.
  bool get isNegative => centavos < 0;

  /// Formata como moeda brasileira: `R$ 1.234,56`
  String get formatted {
    final abs = centavos.abs();
    final reaisPart = abs ~/ 100;
    final centavosPart = abs % 100;
    final reaisStr = _formatarMilhares(reaisPart);
    final centavosStr = centavosPart.toString().padLeft(2, '0');
    final sinal = centavos < 0 ? '-' : '';
    return '${sinal}R\$ $reaisStr,$centavosStr';
  }

  /// Formata sem símbolo: `1.234,56`
  String get formattedRaw {
    final abs = centavos.abs();
    final reaisPart = abs ~/ 100;
    final centavosPart = abs % 100;
    final reaisStr = _formatarMilhares(reaisPart);
    final centavosStr = centavosPart.toString().padLeft(2, '0');
    return '$reaisStr,$centavosStr';
  }

  static String _formatarMilhares(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  // ─── Operações ───────────────────────────────────────────────────────

  FinCoreMoney operator +(FinCoreMoney other) =>
      FinCoreMoney(centavos + other.centavos);

  FinCoreMoney operator -(FinCoreMoney other) =>
      FinCoreMoney(centavos - other.centavos);

  FinCoreMoney operator *(num factor) =>
      FinCoreMoney((centavos * factor).round());

  FinCoreMoney operator /(num divisor) =>
      FinCoreMoney((centavos / divisor).round());

  bool operator >(FinCoreMoney other) => centavos > other.centavos;
  bool operator <(FinCoreMoney other) => centavos < other.centavos;
  bool operator >=(FinCoreMoney other) => centavos >= other.centavos;
  bool operator <=(FinCoreMoney other) => centavos <= other.centavos;

  FinCoreMoney abs() => FinCoreMoney(centavos.abs());

  @override
  bool operator ==(Object other) =>
      other is FinCoreMoney && other.centavos == centavos;

  @override
  int get hashCode => centavos.hashCode;

  @override
  String toString() => formatted;
}
