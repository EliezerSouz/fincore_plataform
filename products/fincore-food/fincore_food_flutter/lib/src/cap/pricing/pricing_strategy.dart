abstract class PricingStrategy {
  /// Calculate the unit price in cents for a given product and quantity.
  ///
  /// [basePrice] is the price from the price table (in cents) for the product.
  /// Returns the calculated unit price in cents.
  int calculate({required int basePrice, required int quantity});
}
