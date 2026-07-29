import 'package:flutter_test/flutter_test.dart';
import 'package:fincore_food_flutter/src/cap/pricing/pricing_strategy_factory.dart';
import 'package:fincore_core/common/master_data_models.dart';

void main() {
  group('PricingStrategyFactory — Estratégias Unitárias', () {
    const factory = PricingStrategyFactory();

    group('UnidadeStrategy', () {
      final strategy = factory.getStrategy(UnidadeVenda.un);

      test('1 unidade × R\$6,00 = R\$6,00', () {
        expect(strategy.calculate(basePrice: 600, quantity: 1), equals(600));
      });

      test('25 unidades × R\$6,00 = R\$150,00', () {
        expect(strategy.calculate(basePrice: 600, quantity: 25), equals(15000));
      });
    });

    group('CentoStrategy', () {
      final strategy = factory.getStrategy(UnidadeVenda.cento);

      test('100 unidades = 1 centena → 1 × basePrice', () {
        // 100 unidades = 1 cento → preço = 1 × base
        expect(strategy.calculate(basePrice: 5000, quantity: 100), equals(5000));
      });

      test('50 unidades = 0,5 centena → arredonda para 1 cento', () {
        // (50 + 99) ~/ 100 = 1 centena
        expect(strategy.calculate(basePrice: 5000, quantity: 50), equals(5000));
      });

      test('200 unidades = 2 centenas → 2 × basePrice', () {
        expect(strategy.calculate(basePrice: 5000, quantity: 200), equals(10000));
      });
    });

    group('KgStrategy', () {
      final strategy = factory.getStrategy(UnidadeVenda.kg);

      test('1000g = 1kg → 1 × basePrice (R\$20,00/kg)', () {
        // (2000 * 1000 + 500) ~/ 1000 = 2000
        expect(strategy.calculate(basePrice: 2000, quantity: 1000), equals(2000));
      });

      test('500g = 0,5kg → metade do preço', () {
        // (2000 * 500 + 500) ~/ 1000 = 1000
        expect(strategy.calculate(basePrice: 2000, quantity: 500), equals(1000));
      });

      test('250g → R\$5,00 (arredondado)', () {
        // (2000 * 250 + 500) ~/ 1000 = 500
        expect(strategy.calculate(basePrice: 2000, quantity: 250), equals(500));
      });
    });

    group('LitroStrategy', () {
      final strategy = factory.getStrategy(UnidadeVenda.l);

      test('1000ml = 1L → basePrice', () {
        expect(strategy.calculate(basePrice: 1500, quantity: 1000), equals(1500));
      });

      test('500ml = 0,5L → metade', () {
        expect(strategy.calculate(basePrice: 1500, quantity: 500), equals(750));
      });
    });

    group('CaixaStrategy', () {
      final strategy = factory.getStrategy(UnidadeVenda.caixa);

      test('1 caixa → basePrice', () {
        expect(strategy.calculate(basePrice: 3000, quantity: 1), equals(3000));
      });

      test('3 caixas → 3 × basePrice', () {
        expect(strategy.calculate(basePrice: 3000, quantity: 3), equals(9000));
      });
    });

    group('BandejaStrategy', () {
      final strategy = factory.getStrategy(UnidadeVenda.bandeja);

      test('1 bandeja → basePrice', () {
        expect(strategy.calculate(basePrice: 1800, quantity: 1), equals(1800));
      });

      test('5 bandejas → 5 × basePrice', () {
        expect(strategy.calculate(basePrice: 1800, quantity: 5), equals(9000));
      });
    });
  });
}
