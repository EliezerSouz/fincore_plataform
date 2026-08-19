import 'package:flutter/material.dart';

/// Contrato estrutural dos Design Tokens de Cores do FINCORE Design System.
/// Todo tema (Claro ou Escuro) deve implementar estes tokens semânticos.
abstract class ThemeTokens {
  const ThemeTokens();

  // ── Superfícies ────────────────────────────────────────────────────────────
  Color get background;
  Color get surface;
  Color get surfaceHover;
  Color get surfaceElevated;

  // ── Bordas e Linhas ────────────────────────────────────────────────────────
  Color get border;
  Color get divider;

  // ── Marca e Ações Primárias ────────────────────────────────────────────────
  Color get actionPrimary;
  Color get actionHover;
  Color get actionActive;
  Color get actionDisabled;

  // ── Alertas e Feedbacks ────────────────────────────────────────────────────
  Color get success;
  Color get warning;
  Color get danger;
  Color get info;

  // ── Texto e Tipografia ─────────────────────────────────────────────────────
  Color get textPrimary;
  Color get textSecondary;
  Color get textMuted;
  Color get textOnAction;

  // ── Formulários e Inputs ────────────────────────────────────────────────────
  Color get inputBackground;
  Color get inputBorder;
  Color get inputBorderFocused;

  // ── Sidebar ────────────────────────────────────────────────────────────────
  Color get sidebarBackground;
  Color get sidebarBorder;
}
