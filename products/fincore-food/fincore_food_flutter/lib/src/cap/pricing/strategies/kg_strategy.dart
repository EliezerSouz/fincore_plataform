import '../pricing_strategy.dart';

/// Estratégia para produtos vendidos em quilogramas (kg).
/// [basePrice] = preço por kg em centavos.
/// [quantity] = quantidade em gramas (ex.: 500 = 0,5 kg).
class KgStrategy implements PricingStrategy {
  @override
  int calculate({required int basePrice, required int quantity}) {
    // Converte gramas para kg com precisão inteira (sem ponto flutuante)
    // Preço total = (basePrice * quantity) / 1000
    return (basePrice * quantity + 500) ~/ 1000;
  }
}
