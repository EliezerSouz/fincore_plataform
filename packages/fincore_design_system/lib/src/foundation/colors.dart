import 'package:flutter/material.dart';

/// Cores primitivas brutas (Physical Colors) do FINCORE Design System.
/// Esta camada nunca deve ser usada diretamente por widgets da aplicação;
/// em vez disso, use os tokens semânticos (ex: ThemeTokens.background).
class FincoreColorsPrimitive {
  FincoreColorsPrimitive._();

  // ── Neutrals (Escala de cinzas para tema Escuro/Claro) ──────────────────────
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);
  static const Color grey950 = Color(0xFF030712);

  // ── Neutrals Escuros Especiais (UI Dark Mode Premium) ──────────────────────
  static const Color darkBackground = Color(0xFF121214);
  static const Color darkSurface = Color(0xFF1E1E24);
  static const Color darkSurfaceElevated = Color(0xFF252530);
  static const Color darkSurfaceOverlay = Color(0xFF2A2A36);
  static const Color darkBorder = Color(0xFF2E2E38);
  static const Color darkBorderSubtle = Color(0xFF232330);

  // ── Alertas Físicos (Feedbacks Primitivos) ──────────────────────────────────
  static const Color green500 = Color(0xFF10B981);
  static const Color green600 = Color(0xFF059669);
  
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);
  
  static const Color yellow500 = Color(0xFFFBBF24);
  static const Color yellow600 = Color(0xFFD97706);
  
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);

  // ── Default Brand Colors ───────────────────────────────────────────────────
  static const Color staticPrimary = Color(0xFFF97316);
  static const Color staticAccent = Color(0xFF06B6D4);
}
