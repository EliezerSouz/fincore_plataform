class PdvItem {
  final String productId;
  final String name;
  final int priceInCents;
  double quantity;

  PdvItem({
    required this.productId,
    required this.name,
    required this.priceInCents,
    required this.quantity,
  });

  int get totalInCents => (priceInCents * quantity).round();

  PdvItem copyWith({
    String? productId,
    String? name,
    int? priceInCents,
    double? quantity,
  }) {
    return PdvItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      priceInCents: priceInCents ?? this.priceInCents,
      quantity: quantity ?? this.quantity,
    );
  }
}
