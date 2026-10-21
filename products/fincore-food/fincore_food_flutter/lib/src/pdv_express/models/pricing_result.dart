class PricingGroup {
  final String id;
  final String name;

  const PricingGroup({required this.id, required this.name});
}

class PricingRange {
  final String id;
  final String groupId;
  final int minQty;
  final int? maxQty;
  final int unitPriceInCents;

  const PricingRange({
    required this.id,
    required this.groupId,
    required this.minQty,
    this.maxQty,
    required this.unitPriceInCents,
  });
}

class GroupPricingSummary {
  final PricingGroup group;
  final double totalQty;
  final int appliedUnitPriceInCents;
  final PricingRange? appliedRange;
  final PricingRange? nextRange;
  final double? qtyNeededForNextRange;
  final int? potentialSavingsInCents;
  final int minRequiredQty;

  const GroupPricingSummary({
    required this.group,
    required this.totalQty,
    required this.appliedUnitPriceInCents,
    this.appliedRange,
    this.nextRange,
    this.qtyNeededForNextRange,
    this.potentialSavingsInCents,
    this.minRequiredQty = 0,
  });

  bool get atingiuMinimo => minRequiredQty <= 1 || totalQty >= minRequiredQty;
  double get missingQty => (minRequiredQty - totalQty).clamp(0, double.infinity);
}

class PricingResult {
  final Map<String, int> unitPrices;
  final List<GroupPricingSummary> groupSummaries;

  const PricingResult({
    required this.unitPrices,
    required this.groupSummaries,
  });
}
