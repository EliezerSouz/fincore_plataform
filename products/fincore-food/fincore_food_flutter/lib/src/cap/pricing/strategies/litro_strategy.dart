import '../pricing_strategy.dart';

/// Estratégia para produtos vendidos em litros.
/// [basePrice] = preço por litro em centavos.
/// [quantity] = quantidade em mililitros (ex.: 500 = 0,5 L).
class LitroStrategy implements PricingStrategy {
  @override
  int calculate({required int basePrice, required int quantity}) {
    // Converte ml para litros com arredondamento bancário
    // Preço total = (basePrice * quantity) / 1000
    return (basePrice * quantity + 500) ~/ 1000;
  }
}
