import 'package:flutter/material.dart';

/// Escala unificada de cantos arredondados (BorderRadius) do FINCORE Design System.
class FincoreRadius {
  final double baseRadius;

  const FincoreRadius({this.baseRadius = 8.0});

  /// 4 pixels - Para botões pequenos, tags, badges
  double get small => 4.0;

  /// baseRadius (dinâmico configurado no tenant) - Para inputs, botões padrão
  double get medium => baseRadius;

  /// baseRadius * 1.5 - Para Cards, Panels, Modais
  double get large => baseRadius * 1.5;

  /// 9999 pixels - Para badges circulares, avatares, chips em formato pílula
  double get pill => 9999.0;

  // Helpers para retornar BorderRadius completo
  BorderRadius get borderSmall => BorderRadius.circular(small);
  BorderRadius get borderMedium => BorderRadius.circular(medium);
  BorderRadius get borderLarge => BorderRadius.circular(large);
  BorderRadius get borderPill => BorderRadius.circular(pill);
}
