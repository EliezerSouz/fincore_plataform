import '../value_objects/money.dart';
import '../value_objects/phone.dart';
import '../value_objects/misc_value_objects.dart';
import '../formatters/formatters.dart';

// ─── DateTime Extensions ─────────────────────────────────────────────────────

extension DateTimeExtensions on DateTime {
  /// Formata como `27/07/2025`.
  String get formatted => FinCoreDateFormatter.formatDate(this);

  /// Formata como `14:35`.
  String get formattedTime => FinCoreDateFormatter.formatTime(this);

  /// Formata como `27/07/2025 14:35`.
  String get formattedDateTime => FinCoreDateFormatter.formatDateTime(this);

  /// Formata como `27/07` (dashboard compacto).
  String get formattedShort => FinCoreDateFormatter.formatShortDate(this);

  /// Formata relativo: "há 3 min", "há 2h", "ontem".
  String get fromNow => FinCoreDateFormatter.formatRelative(this);

  /// Retorna o início do dia (00:00:00).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Retorna o fim do dia (23:59:59.999999).
  DateTime get endOfDay =>
      DateTime(year, month, day + 1).subtract(const Duration(microseconds: 1));

  /// Retorna `true` se a data é hoje.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Retorna `true` se a data é ontem.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Retorna o início da semana (segunda-feira).
  DateTime get startOfWeek {
    final mondayOffset = weekday - 1;
    return subtract(Duration(days: mondayOffset)).startOfDay;
  }

  /// Retorna o início do mês.
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Retorna o fim do mês.
  DateTime get endOfMonth =>
      DateTime(year, month + 1, 1).subtract(const Duration(microseconds: 1));
}

// ─── String Extensions ───────────────────────────────────────────────────────

extension StringExtensions on String {
  /// Remove todos os caracteres não numéricos.
  String get onlyDigits => replaceAll(RegExp(r'\D'), '');

  /// Remove espaços e caracteres especiais de máscara.
  String get unmasked => replaceAll(RegExp(r'[\s\.\-\(\)/]'), '');

  /// Retorna `true` se a string contém somente dígitos.
  bool get isNumeric => RegExp(r'^\d+$').hasMatch(this);

  /// Converte para `FincorePhone`.
  FincorePhone get asPhone => FincorePhone.parse(this);

  /// Converte para `FincorePostalCode`.
  FincorePostalCode get asPostalCode => FincorePostalCode.parse(this);

  /// Capitaliza a primeira letra de cada palavra.
  String get toTitleCase {
    if (isEmpty) return this;
    return split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Abrevia o nome para as iniciais (máximo [maxLength] chars).
  String initials({int max = 2}) {
    final parts = trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    return parts.take(max).map((s) => s[0].toUpperCase()).join();
  }

  /// Verifica se é um e-mail válido (simples).
  bool get isValidEmail =>
      RegExp(r'^[\w\.\-\+]+@[\w\-]+\.\w{2,}$').hasMatch(trim());

  /// Verifica se é um telefone válido (10 ou 11 dígitos).
  bool get isValidPhone {
    final d = onlyDigits;
    return d.length == 10 || d.length == 11;
  }

  /// Converte para `int` sem lançar exceção.
  int? tryParseInt() => int.tryParse(this);

  /// Converte para `double` sem lançar exceção (suporta vírgula).
  double? tryParseDouble() =>
      double.tryParse(replaceAll(',', '.'));

  /// Trunca a string ao tamanho máximo, adicionando `...` se necessário.
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }
}

// ─── Int Extensions ──────────────────────────────────────────────────────────

extension IntExtensions on int {
  /// Converte centavos para [FinCoreMoney].
  FinCoreMoney get asMoney => FinCoreMoney.fromCentavos(this);

  /// Formata centavos como `R$ 1.234,56`.
  String get asFormattedMoney => FinCoreMoney.fromCentavos(this).formatted;

  /// Formata centavos sem símbolo: `1.234,56`.
  String get asFormattedMoneyRaw => FinCoreMoney.fromCentavos(this).formattedRaw;

  /// Converte segundos em "2h 30min".
  String get asDuration {
    final h = this ~/ 3600;
    final m = (this % 3600) ~/ 60;
    final s = this % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
    if (m > 0) return '${m}min ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }
}

// ─── List Extensions ─────────────────────────────────────────────────────────

extension ListExtensions<T> on List<T> {
  /// Divide a lista em sublistas de tamanho [size].
  List<List<T>> chunked(int size) {
    final result = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      result.add(sublist(i, (i + size).clamp(0, length)));
    }
    return result;
  }

  /// Agrupa a lista por uma chave derivada de [keySelector].
  Map<K, List<T>> groupBy<K>(K Function(T) keySelector) {
    final result = <K, List<T>>{};
    for (final item in this) {
      final key = keySelector(item);
      result.putIfAbsent(key, () => []).add(item);
    }
    return result;
  }

  /// Retorna o primeiro elemento ou `null` se a lista estiver vazia.
  T? get firstOrNull => isEmpty ? null : first;

  /// Retorna o último elemento ou `null` se a lista estiver vazia.
  T? get lastOrNull => isEmpty ? null : last;

  /// Soma os valores de uma lista de inteiros.
  int sumBy(int Function(T) selector) =>
      fold(0, (acc, item) => acc + selector(item));

  /// Soma os valores de uma lista de doubles.
  double sumByDouble(double Function(T) selector) =>
      fold(0.0, (acc, item) => acc + selector(item));
}
