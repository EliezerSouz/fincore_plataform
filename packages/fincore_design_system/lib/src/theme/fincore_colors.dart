import 'package:flutter/material.dart';
import 'theme_controller.dart';

/// Paleta de cores do FINCORE Platform (Bridge de Compatibilidade).
///
/// Mantém compatibilidade com construtores const para cores estáticas,
/// enquanto expõe a cor primária de marca de forma dinâmica.
class FincoreColors {
  FincoreColors._();

  // ── Superfícies ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF121214);
  static const Color surface = Color(0xFF1E1E24);
  static const Color surfaceElevated = Color(0xFF252530);
  static const Color surfaceOverlay = Color(0xFF2A2A36);
  static const Color border = Color(0xFF2E2E38);
  static const Color borderSubtle = Color(0xFF232330);

  // ── Brand (Dinâmica) ───────────────────────────────────────────────────────
  static const Color staticPrimary = Color(0xFFF97316);
  static Color get primary {
    try {
      return ThemeController.instance.primaryColor;
    } catch (_) {
      return staticPrimary;
    }
  }
  static Color get dynamicPrimary => primary;
  static Color get primaryLight => primary.withValues(alpha: 0.8);
  
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentLight = Color(0xFF22D3EE);

  // ── Semânticas ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info = Color(0xFF3B82F6);

  // ── Texto ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF4B5563);

  // ── Hover / Active States ──────────────────────────────────────────────────
  static Color get hoverPrimary => primary.withValues(alpha: 0.20);
  static const Color hoverSurface = Color(0x1AFFFFFF);   // 10% white
  static Color get activePrimary => primary.withValues(alpha: 0.30);

  // ── Sidebar ────────────────────────────────────────────────────────────────
  static const Color sidebarBackground = Color(0xFF0F0F1A);
  static const Color sidebarBorder = Color(0xFF1E1E2E);

  // ── Gradientes ─────────────────────────────────────────────────────────────
  static LinearGradient get primaryGradient {
    try {
      final hex = ThemeController.instance.settings.brandColorHex.toUpperCase();
      if (hex.contains('2563EB')) {
        // Azul Elétrico
        return const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (hex.contains('10B981')) {
        // Verde Sucesso
        return const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (hex.contains('A855F7')) {
        // Roxo Nobre
        return const LinearGradient(
          colors: [Color(0xFF7E22CE), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (hex.contains('4B5563')) {
        // Cinza Grafite
        return const LinearGradient(
          colors: [Color(0xFF374151), Color(0xFF4B5563)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (hex.contains('EF4444')) {
        // Vermelho Carmim
        return const LinearGradient(
          colors: [Color(0xFFB91C1C), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
    } catch (_) {}
    // Laranja Fincore (Default)
    return const LinearGradient(
      colors: [Color(0xFFFF6B2B), Color(0xFFFF9500)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente dinâmico por período do dia
  static LinearGradient get timeGradient {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      // Manhã: dourado quente
      return const LinearGradient(
        colors: [Color(0xFFFF9500), Color(0xFFFBBF24)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (hour < 18) {
      // Tarde: laranja vibrante
      return primaryGradient;
    } else {
      // Noite: azul índigo
      return const LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }
}
