import 'package:flutter/material.dart';

/// Escala unificada de Sombras e Elevações do FINCORE Design System.
class FincoreShadowsFoundation {
  final Color shadowColor;

  const FincoreShadowsFoundation({
    this.shadowColor = const Color(0x0F000000), // Cor base translúcida
  });

  /// Sombra extra sutil (Bordas de cards simples)
  List<BoxShadow> get shadowXS => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  /// Sombra pequena (Dropdowns, menus simples)
  List<BoxShadow> get shadowSM => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Sombra média (Cards suspensos, modais menores)
  List<BoxShadow> get shadowMD => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.12),
          blurRadius: 10,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
      ];

  /// Sombra grande (Dialogs, Sidebars overlays, drawers)
  List<BoxShadow> get shadowLG => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.18),
          blurRadius: 20,
          spreadRadius: -4,
          offset: const Offset(0, 10),
        ),
      ];

  /// Glow especial (para botões primários da marca)
  static List<BoxShadow> glow(Color color, {double intensity = 0.2}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: intensity),
        blurRadius: 16,
        spreadRadius: -4,
        offset: const Offset(0, 6),
      ),
    ];
  }
}
