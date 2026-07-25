import 'package:flutter/material.dart';

export '../utils/formatters.dart';

/// Tokens do sistema de design da Salgaderia ERP.
abstract class AppColors {
  static const primary = Color(0xFFE85D3F); // Terracota / Laranja aquecido
  static const primaryDark = Color(0xFFC74328);
  static const primaryLight = Color(0xFFFFF0ED);

  static const background = Color(0xFFF8F9FC); // Cinza azulado muito suave
  static const surface = Colors.white;
  static const cardBorder = Color(0xFFEAECF0);

  static const textPrimary = Color(0xFF101828); // Quase preto para alto contraste
  static const textSecondary = Color(0xFF475467);
  static const textMuted = Color(0xFF667085);

  static const success = Color(0xFF12B76A); // Verde esmeralda
  static const successBg = Color(0xFFECFDF3);

  static const warning = Color(0xFFF79009); // Amarelo/Laranja alerta
  static const warningBg = Color(0xFFFFFAEB);

  static const error = Color(0xFFF04438); // Vermelho erro
  static const errorBg = Color(0xFFFEF3F2);

  static const info = Color(0xFF2E90FA);
  static const infoBg = Color(0xFFEFF8FF);
}

ThemeData appTheme() {
  const fontFamily = 'Segoe UI';

  return ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 24,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 15,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          fontFamily: fontFamily,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: const BorderSide(color: AppColors.cardBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          fontFamily: fontFamily,
        ),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.white,
      selectedIconTheme: IconThemeData(color: AppColors.primary),
      unselectedIconTheme: IconThemeData(color: AppColors.textMuted),
      selectedLabelTextStyle: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
        fontFamily: fontFamily,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        fontFamily: fontFamily,
      ),
      indicatorColor: AppColors.primaryLight,
      labelType: NavigationRailLabelType.all,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.cardBorder,
      thickness: 1,
    ),
  );
}
