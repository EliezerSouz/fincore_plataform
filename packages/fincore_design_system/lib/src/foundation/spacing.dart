/// Escala unificada de espaçamento (Margens e Paddings) do FINCORE Design System.
class FincoreSpacing {
  final double scaleFactor;

  const FincoreSpacing({this.scaleFactor = 1.0});

  /// 2 pixels (escala básica * scaleFactor)
  double get xxs => 2.0 * scaleFactor;

  /// 4 pixels
  double get xs => 4.0 * scaleFactor;

  /// 8 pixels (padrão compacto de espaçamento interno)
  double get sm => 8.0 * scaleFactor;

  /// 12 pixels
  double get md => 12.0 * scaleFactor;

  /// 16 pixels (padrão confortável de margens e cartões)
  double get lg => 16.0 * scaleFactor;

  /// 24 pixels
  double get xl => 24.0 * scaleFactor;

  /// 32 pixels
  double get xxl => 32.0 * scaleFactor;

  /// 48 pixels
  double get xxxl => 48.0 * scaleFactor;
}
