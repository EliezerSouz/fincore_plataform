import '../pricing_strategy.dart';

class CentoStrategy implements PricingStrategy {
  @override
  int calculate({required int basePrice, required int quantity}) {
    // Preço por centena: cada 100 unidades têm o preço base.
    // Caso a quantidade não seja múltipla de 100, arredonda para cima.
    final int units = (quantity + 99) ~/ 100; // número de centenas
    return basePrice * units;
  }
}
