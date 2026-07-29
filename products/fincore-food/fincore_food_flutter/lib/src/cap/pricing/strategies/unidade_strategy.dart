import '../pricing_strategy.dart';

class UnidadeStrategy implements PricingStrategy {
  @override
  int calculate({required int basePrice, required int quantity}) {
    // Simple per-unit pricing
    return basePrice * quantity;
  }
}
