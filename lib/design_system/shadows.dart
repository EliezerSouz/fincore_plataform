import 'package:flutter/material.dart';
import 'colors.dart';

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get small => [
        BoxShadow(
          color: Colors.black.withAlpha(10), // Approx 0.04 opacity
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: Colors.black.withAlpha(20), // Approx 0.08 opacity
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get large => [
        BoxShadow(
          color: Colors.black.withAlpha(30), // Approx 0.12 opacity
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];
}
