import 'package:flutter/material.dart';
import '../foundation/colors.dart';
import 'theme_tokens.dart';

/// Implementação dos Design Tokens de cores para o Tema Claro (Light Mode).
/// Os estados dinâmicos baseados no brand color (hex) são injetados em tempo de execução.
class LightTokens implements ThemeTokens {
  final Color brandColor;

  const LightTokens({
    this.brandColor = FincoreColorsPrimitive.staticPrimary,
  });

  // ── Superfícies Claro ──────────────────────────────────────────────────────
  @override
  Color get background => FincoreColorsPrimitive.grey100;
  
  @override
  Color get surface => Colors.white;
  
  @override
  Color get surfaceHover => FincoreColorsPrimitive.grey50;
  
  @override
  Color get surfaceElevated => Colors.white;

  // ── Bordas e Linhas Claro ──────────────────────────────────────────────────
  @override
  Color get border => FincoreColorsPrimitive.grey300;
  
  @override
  Color get divider => FincoreColorsPrimitive.grey200;

  // ── Marca e Ações Primárias ────────────────────────────────────────────────
  @override
  Color get actionPrimary => brandColor;
  
  @override
  Color get actionHover => brandColor.withValues(alpha: 0.85);
  
  @override
  Color get actionActive => brandColor.withValues(alpha: 0.70);
  
  @override
  Color get actionDisabled => FincoreColorsPrimitive.grey300;

  // ── Alertas e Feedbacks Claro ──────────────────────────────────────────────
  @override
  Color get success => FincoreColorsPrimitive.green600;
  
  @override
  Color get warning => FincoreColorsPrimitive.yellow600;
  
  @override
  Color get danger => FincoreColorsPrimitive.red600;
  
  @override
  Color get info => FincoreColorsPrimitive.blue600;

  // ── Texto Claro ────────────────────────────────────────────────────────────
  @override
  Color get textPrimary => FincoreColorsPrimitive.grey900;
  
  @override
  Color get textSecondary => FincoreColorsPrimitive.grey600;
  
  @override
  Color get textMuted => FincoreColorsPrimitive.grey400;
  
  @override
  Color get textOnAction => Colors.white;

  // ── Formulários e Inputs Claro ──────────────────────────────────────────────
  @override
  Color get inputBackground => Colors.white;
  
  @override
  Color get inputBorder => FincoreColorsPrimitive.grey300;
  
  @override
  Color get inputBorderFocused => brandColor;

  // ── Sidebar Claro ──────────────────────────────────────────────────────────
  @override
  Color get sidebarBackground => Colors.white;
  
  @override
  Color get sidebarBorder => FincoreColorsPrimitive.grey300;
}
