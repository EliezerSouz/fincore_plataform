import 'package:flutter/material.dart';

/// Escala unificada de transições e animações (Motion) do FINCORE Design System.
class FincoreMotion {
  const FincoreMotion();

  // ── Durações ───────────────────────────────────────────────────────────────
  
  /// 150 milissegundos - Ideal para micro-interações de feedback (hover, active)
  Duration get fast => const Duration(milliseconds: 150);

  /// 300 milissegundos - Ideal para expansões de cards, aberturas de inputs, rotas curtas
  Duration get medium => const Duration(milliseconds: 300);

  /// 500 milissegundos - Ideal para transições de páginas, modais de tela cheia, layouts grandes
  Duration get slow => const Duration(milliseconds: 500);

  // ── Curvas de Animação ──────────────────────────────────────────────────────

  /// Curva padrão suave de aceleração e desaceleração (easeInOut)
  Curve get standard => Curves.easeInOut;

  /// Curva de desaceleração (easeOut) - Excelente para elementos que entram na tela
  Curve get decelerate => Curves.easeOut;

  /// Curva de aceleração (easeIn) - Excelente para elementos saindo da tela
  Curve get accelerate => Curves.easeIn;
}
