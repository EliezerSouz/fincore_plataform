import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_food_flutter/src/pdv_express/models/pricing_result.dart';

void main() {
  group('Validação de Quantidade Mínima de Grupos / Categorias no PDV', () {
    test('Grupo que não atingiu a quantidade mínima deve acusar pendência e quantidade faltante', () {
      const summary = GroupPricingSummary(
        group: PricingGroup(id: 'grupo_salgados', name: 'Mini Salgados'),
        totalQty: 15.0,
        appliedUnitPriceInCents: 150,
        minRequiredQty: 25,
      );

      expect(summary.atingiuMinimo, isFalse);
      expect(summary.missingQty, equals(10.0));
      expect(summary.minRequiredQty, equals(25));
    });

    test('Grupo que atingiu ou superou a quantidade mínima acumulada deve ser considerado válido', () {
      const summaryAtingido = GroupPricingSummary(
        group: PricingGroup(id: 'grupo_salgados', name: 'Mini Salgados'),
        totalQty: 25.0,
        appliedUnitPriceInCents: 150,
        minRequiredQty: 25,
      );

      expect(summaryAtingido.atingiuMinimo, isTrue);
      expect(summaryAtingido.missingQty, equals(0.0));

      const summarySuperado = GroupPricingSummary(
        group: PricingGroup(id: 'grupo_salgados', name: 'Mini Salgados'),
        totalQty: 30.0,
        appliedUnitPriceInCents: 145,
        minRequiredQty: 25,
      );

      expect(summarySuperado.atingiuMinimo, isTrue);
      expect(summarySuperado.missingQty, equals(0.0));
    });

    test('Grupo unitário ou sem quantidade mínima configurada (<= 1) sempre é válido', () {
      const summaryUnitario = GroupPricingSummary(
        group: PricingGroup(id: 'grupo_bebidas', name: 'Bebidas'),
        totalQty: 1.0,
        appliedUnitPriceInCents: 500,
        minRequiredQty: 1,
      );

      expect(summaryUnitario.atingiuMinimo, isTrue);
      expect(summaryUnitario.missingQty, equals(0.0));
    });
  });
}
