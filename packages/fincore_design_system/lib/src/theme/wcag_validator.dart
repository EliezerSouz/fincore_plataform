import 'dart:math';
import 'package:flutter/material.dart';

/// Validador de Acessibilidade Visual baseado no padrão WCAG 2.0.
/// Garante que o contraste de cores entre texto e fundo atinja o mínimo exigido para legibilidade.
class WcagValidator {
  WcagValidator._();

  /// Calcula a luminância relativa de uma cor de acordo com a WCAG.
  /// Retorna um valor entre 0.0 (preto absoluto) e 1.0 (branco absoluto).
  static double getRelativeLuminance(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    final rL = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4).toDouble();
    final gL = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4).toDouble();
    final bL = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * rL + 0.7152 * gL + 0.0722 * bL;
  }

  /// Calcula a razão de contraste (Contrast Ratio) entre duas cores.
  /// Retorna um valor entre 1.0 (sem contraste) e 21.0 (contraste máximo).
  static double getContrastRatio(Color color1, Color color2) {
    final l1 = getRelativeLuminance(color1);
    final l2 = getRelativeLuminance(color2);

    final lighter = max(l1, l2);
    final darker = min(l1, l2);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Verifica se o contraste atinge o nível mínimo AA da WCAG (4.5:1 para texto normal).
  static bool isContrastAccessible(Color color1, Color color2, {double threshold = 4.5}) {
    return getContrastRatio(color1, color2) >= threshold;
  }
}
