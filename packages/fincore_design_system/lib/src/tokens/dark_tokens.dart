import 'package:flutter/material.dart';
import '../foundation/colors.dart';
import 'theme_tokens.dart';

/// Implementação dos Design Tokens de cores para o Tema Escuro (Dark Mode).
/// Os estados dinâmicos baseados no brand color (hex) são injetados em tempo de execução.
class DarkTokens implements ThemeTokens {
  final Color brandColor;

  const DarkTokens({
    this.brandColor = FincoreColorsPrimitive.staticPrimary,
  });

  // ── Superfícies Escuro ─────────────────────────────────────────────────────
  @override
  Color get background => FincoreColorsPrimitive.darkBackground;
  
  @override
  Color get surface => FincoreColorsPrimitive.darkSurface;
  
  @override
  Color get surfaceHover => FincoreColorsPrimitive.darkSurfaceOverlay;
  
  @override
  Color get surfaceElevated => FincoreColorsPrimitive.darkSurfaceElevated;

  // ── Bordas e Linhas Escuro ─────────────────────────────────────────────────
  @override
  Color get border => FincoreColorsPrimitive.darkBorder;
  
  @override
  Color get divider => FincoreColorsPrimitive.darkBorderSubtle;

  // ── Marca e Ações Primárias ────────────────────────────────────────────────
  @override
  Color get actionPrimary => brandColor;
  
  @override
  Color get actionHover => brandColor.withValues(alpha: 0.80);
  
  @override
  Color get actionActive => brandColor.withValues(alpha: 0.65);
  
  @override
  Color get actionDisabled => FincoreColorsPrimitive.grey800;

  // ── Alertas e Feedbacks Escuro ─────────────────────────────────────────────
  @override
  Color get success => FincoreColorsPrimitive.green500;
  
  @override
  Color get warning => FincoreColorsPrimitive.yellow500;
  
  @override
  Color get danger => FincoreColorsPrimitive.red500;
  
  @override
  Color get info => FincoreColorsPrimitive.blue500;

  // ── Texto Escuro ───────────────────────────────────────────────────────────
  @override
  Color get textPrimary => FincoreColorsPrimitive.grey100;
  
  @override
  Color get textSecondary => FincoreColorsPrimitive.grey400;
  
  @override
  Color get textMuted => FincoreColorsPrimitive.grey500;
  
  @override
  Color get textOnAction => Colors.white;

  // ── Formulários e Inputs Escuro ─────────────────────────────────────────────
  @override
  Color get inputBackground => FincoreColorsPrimitive.darkBackground;
  
  @override
  Color get inputBorder => FincoreColorsPrimitive.darkBorder;
  
  @override
  Color get inputBorderFocused => brandColor;

  // ── Sidebar Escuro ─────────────────────────────────────────────────────────
  @override
  Color get sidebarBackground => const Color(0xFF0F0F1A);
  
  @override
  Color get sidebarBorder => const Color(0xFF1E1E2E);
}
