class TimezoneHelper {
  /// Retorna a data/hora atual ajustada para o fuso de Brasília/São Paulo (UTC-3)
  static DateTime get localNow {
    final nowUtc = DateTime.now().toUtc();
    return nowUtc.add(const Duration(hours: -3));
  }
}
