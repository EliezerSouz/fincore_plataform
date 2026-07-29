import 'package:flutter/material.dart';
import 'fincore_colors.dart';

class FincoreTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: FincoreColors.primary,
      scaffoldBackgroundColor: FincoreColors.background,
      
      // Tema de Cores do Esquema
      colorScheme: const ColorScheme.dark(
        primary: FincoreColors.primary,
        secondary: FincoreColors.accent,
        surface: FincoreColors.surface,
        error: FincoreColors.danger,
      ),
      
      // Estilo de Barra Superior (AppBar)
      appBarTheme: const AppBarTheme(
        backgroundColor: FincoreColors.surface,
        foregroundColor: FincoreColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      
      // Tipografia Padrão
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: FincoreColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: FincoreColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: FincoreColors.textPrimary,
          fontSize: 14,
        ),
        bodyMedium: TextStyle(
          color: FincoreColors.textSecondary,
          fontSize: 12,
        ),
      ),
      
      // Estilos de Inputs de Formulário
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FincoreColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: FincoreColors.textSecondary),
        hintStyle: const TextStyle(color: FincoreColors.textMuted),
        
        // Bordas
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: FincoreColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: FincoreColors.primary, width: 2), // Borda Laranja Forno de 2px
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: FincoreColors.danger, width: 1.5),
        ),
      ),
      
      // Estilo de Botões Elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FincoreColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
      
      // Estilo de Botões Outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FincoreColors.textPrimary,
          side: const BorderSide(color: FincoreColors.border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
