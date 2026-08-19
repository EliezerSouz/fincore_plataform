import 'package:flutter/material.dart';
import '../foundation/spacing.dart';
import '../foundation/radius.dart';
import '../foundation/motion.dart';
import '../foundation/shadows.dart';
import '../tokens/theme_tokens.dart';

/// Provedor oficial de tokens de design via BuildContext no ecossistema FINCORE.
class FincoreThemeScope extends InheritedWidget {
  final ThemeTokens tokens;
  final FincoreSpacing spacing;
  final FincoreRadius radius;
  final FincoreMotion motion;
  final FincoreShadowsFoundation shadows;

  const FincoreThemeScope({
    super.key,
    required this.tokens,
    required this.spacing,
    required this.radius,
    required this.motion,
    required this.shadows,
    required super.child,
  });

  static FincoreThemeScope of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<FincoreThemeScope>();
    assert(provider != null, 'Nenhum FincoreThemeScope encontrado no contexto.');
    return provider!;
  }

  @override
  bool updateShouldNotify(FincoreThemeScope oldWidget) {
    return tokens != oldWidget.tokens ||
        spacing != oldWidget.spacing ||
        radius != oldWidget.radius ||
        motion != oldWidget.motion ||
        shadows != oldWidget.shadows;
  }
}

/// Extensão idiomática do [BuildContext] para acesso rápido a todos os Design Tokens.
extension FincoreThemeExtension on BuildContext {
  /// Tokens de cor ativos (Claro/Escuro dinâmico)
  ThemeTokens get tokens => FincoreThemeScope.of(this).tokens;

  /// Tokens de espaçamento unificados
  FincoreSpacing get spacing => FincoreThemeScope.of(this).spacing;

  /// Tokens de cantos arredondados (BorderRadius)
  FincoreRadius get radius => FincoreThemeScope.of(this).radius;

  /// Tokens de transição e animações (durações e curvas)
  FincoreMotion get motion => FincoreThemeScope.of(this).motion;

  /// Tokens de sombras e elevações
  FincoreShadowsFoundation get shadows => FincoreThemeScope.of(this).shadows;
}
