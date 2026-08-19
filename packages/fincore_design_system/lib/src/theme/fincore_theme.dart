import 'package:flutter/material.dart';
import 'fincore_colors.dart';

class FincoreTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: FincoreColors.primary,
      scaffoldBackgroundColor: FincoreColors.background,
      
      // Font family premium — fallback para system se google_fonts não estiver disponível
      fontFamily: 'Inter',

      // Tema de Cores do Esquema
      colorScheme: ColorScheme.dark(
        primary: FincoreColors.primary,
        secondary: FincoreColors.accent,
        surface: FincoreColors.surface,
        error: FincoreColors.danger,
      ),
      
      // Estilo de Barra Superior (AppBar)
      appBarTheme: AppBarTheme(
        backgroundColor: FincoreColors.surface,
        foregroundColor: FincoreColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      
      // Tipografia
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: FincoreColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: FincoreColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: FincoreColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: FincoreColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: FincoreColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: FincoreColors.textPrimary,
          fontSize: 14,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: FincoreColors.textSecondary,
          fontSize: 13,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: FincoreColors.textMuted,
          fontSize: 12,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          color: FincoreColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: FincoreColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.4,
        ),
      ),
      
      // Estilos de Inputs de Formulário
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FincoreColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: FincoreColors.textSecondary, fontSize: 13),
        hintStyle: TextStyle(color: FincoreColors.textMuted, fontSize: 13),
        
        // Bordas
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: FincoreColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: FincoreColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: FincoreColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: FincoreColors.danger, width: 2),
        ),
      ),
      
      // Estilo de Botões Elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FincoreColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Estilo de Botões Outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FincoreColors.textPrimary,
          side: BorderSide(color: FincoreColors.border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      // Scrollbar estilizada
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          FincoreColors.textMuted.withValues(alpha: 0.3),
        ),
        radius: const Radius.circular(10),
        thickness: WidgetStateProperty.all(4),
        thumbVisibility: WidgetStateProperty.all(false),
      ),

      // Tooltip premium
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: FincoreColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FincoreColors.border),
        ),
        textStyle: TextStyle(
          color: FincoreColors.textPrimary,
          fontSize: 12,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: FincoreColors.border,
        thickness: 1,
        space: 1,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: FincoreColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: TextStyle(
          color: FincoreColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FincoreColors.surfaceElevated,
        contentTextStyle: TextStyle(
          color: FincoreColors.textPrimary,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: FincoreColors.primary,
        unselectedLabelColor: FincoreColors.textSecondary,
        indicatorColor: FincoreColors.primary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        dividerColor: FincoreColors.border,
      ),
    );
  }
}
