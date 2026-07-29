import '../pricing_strategy.dart';

/// Estratégia para produtos vendidos por bandeja.
/// [basePrice] = preço por bandeja em centavos.
/// [quantity] = número de bandejas.
class BandejaStrategy implements PricingStrategy {
  @override
  int calculate({required int basePrice, required int quantity}) {
    // Preço total = basePrice × número de bandejas
    return basePrice * quantity;
  }
}
