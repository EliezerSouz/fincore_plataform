import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get _base => GoogleFonts.inter(
        color: const Color(0xFF1F2937),
      );

  static TextStyle get h1 => _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get h2 => _base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600, // SemiBold
      );

  static TextStyle get h3 => _base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get cardTitle => _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get text => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get caption => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );
}
