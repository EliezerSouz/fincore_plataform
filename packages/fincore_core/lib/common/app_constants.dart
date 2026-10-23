/// Constantes globais do aplicativo FINCORE FOOD.
///
/// ## Por que centralizar aqui?
/// - Versão da aplicação era hardcoded em múltiplos pontos (P2-05)
/// - Facilita bump de versão: alterar apenas este arquivo
/// - Acessível de qualquer package que importe fincore_core
library app_constants;

class AppConstants {
  AppConstants._();

  /// Versão atual do aplicativo (bumpar a cada release)
  static const String version = 'v1.8.10';

  /// Nome oficial do produto
  static const String appName = 'FINCORE Food';

  /// Identificador técnico do canal do aplicativo
  static const String channel = 'stable';
}
