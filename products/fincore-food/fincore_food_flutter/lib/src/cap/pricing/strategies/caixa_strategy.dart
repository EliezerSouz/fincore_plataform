import '../pricing_strategy.dart';

/// Estratégia para produtos vendidos por caixa.
/// [basePrice] = preço por caixa em centavos.
/// [quantity] = número de caixas.
class CaixaStrategy implements PricingStrategy {
  @override
  int calculate({required int basePrice, required int quantity}) {
    // Preço total = basePrice × número de caixas
    return basePrice * quantity;
  }
}
