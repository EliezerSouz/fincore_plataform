import 'package:meta/meta.dart';

/// Value Object para percentual (0 a 100%).
@immutable
class FincorePercentage {
  /// Valor percentual (ex: 10.5 representa 10,5%).
  final double value;

  const FincorePercentage(this.value);

  const FincorePercentage.zero() : value = 0.0;

  factory FincorePercentage.parse(String raw) {
    final cleaned = raw.replaceAll('%', '').replaceAll(',', '.').trim();
    return FincorePercentage(double.tryParse(cleaned) ?? 0.0);
  }

  bool get isValid => value >= 0 && value <= 100;

  /// Converte para decimal (ex: 10.5% → 0.105).
  double get toDecimal => value / 100.0;

  /// Aplica o percentual a um valor em centavos.
  int applyToCentavos(int centavos) => (centavos * toDecimal).round();

  /// Exibe como "10,50%".
  String get formatted {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')}%';
  }

  @override
  bool operator ==(Object other) =>
      other is FincorePercentage && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => formatted;
}

/// Value Object para CEP.
@immutable
class FincorePostalCode {
  final String digits;

  const FincorePostalCode._(this.digits);

  factory FincorePostalCode.parse(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return FincorePostalCode._(digits);
  }

  const FincorePostalCode.empty() : digits = '';

  bool get isEmpty => digits.isEmpty;

  bool get isValid => digits.length == 8;

  /// Retorna `#####-###`.
  String get formatted {
    if (digits.length == 8) {
      return '${digits.substring(0, 5)}-${digits.substring(5)}';
    }
    return digits;
  }

  @override
  bool operator ==(Object other) =>
      other is FincorePostalCode && other.digits == digits;

  @override
  int get hashCode => digits.hashCode;

  @override
  String toString() => formatted;
}

/// Value Object para intervalo de datas.
@immutable
class FinCoreDateRange {
  final DateTime start;
  final DateTime end;

  const FinCoreDateRange({required this.start, required this.end});

  /// Cria o intervalo do dia atual.
  factory FinCoreDateRange.today() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
    return FinCoreDateRange(start: start, end: end);
  }

  /// Cria o intervalo da semana atual (segunda-feira a domingo).
  factory FinCoreDateRange.thisWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 7)).subtract(const Duration(microseconds: 1));
    return FinCoreDateRange(start: start, end: end);
  }

  /// Cria o intervalo do mês atual.
  factory FinCoreDateRange.thisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1));
    return FinCoreDateRange(start: start, end: end);
  }

  bool get isValid => !end.isBefore(start);

  Duration get duration => end.difference(start);

  bool contains(DateTime date) =>
      !date.isBefore(start) && !date.isAfter(end);

  @override
  bool operator ==(Object other) =>
      other is FinCoreDateRange &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '${start.toIso8601String()} → ${end.toIso8601String()}';
}
