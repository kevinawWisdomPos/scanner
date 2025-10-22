class DiscountRule {
  final String type;
  final int itemId;
  final int? targetItemId;
  final String description;
  final int buyQty;
  final int? getQty;
  final double discountPercent;
  final double discountAmount;

  final DateTime? startDate;
  final DateTime? endDate;

  final int? maxUse;
  final bool isolated;

  DiscountRule({
    required this.type,
    required this.itemId,
    this.targetItemId,
    required this.description,
    required this.buyQty,
    this.getQty,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.startDate,
    this.endDate,
    this.maxUse,
    this.isolated = false,
  });

  static final List<DiscountRule> discountRules = [
    DiscountRule(
      type: "BOGO",
      itemId: 40000,
      description: "Buy 1 Coca Cola, get 1 Disc 50%",
      buyQty: 1,
      getQty: 1,
      discountPercent: 10,
      maxUse: 2,
    ),
    DiscountRule(
      type: "BOGO",
      itemId: 40000,
      description: "Buy 1 Coca Cola, get 1 Disc 50% in specific time",
      buyQty: 1,
      getQty: 1,
      discountPercent: 100,

      startDate: DateTime(2025, 10, 22, 15, 0, 0),
      endDate: DateTime(2025, 10, 22, 16, 0, 0),
    ),
    DiscountRule(
      type: "BOGO",
      itemId: 40001,
      targetItemId: 40001,
      description: "Buy 1 Fanta, get 1 Disc 40%",
      buyQty: 1,
      getQty: 1,
      discountPercent: 40,
      isolated: true,
    ),
    DiscountRule(
      type: "CROSS_BOGO",
      itemId: 40001,
      targetItemId: 40002,
      description: "Buy 1 Fanta, get 1 Sprite free",
      buyQty: 1,
      getQty: 1,
      discountPercent: 80,
      maxUse: 2,
    ),
    DiscountRule(type: "VOLUME", itemId: 40003, description: "Buy 5 Water, get 50%", buyQty: 5, discountPercent: 50),
    DiscountRule(
      type: "AMOUNT",
      itemId: 40004,
      description: "Buy 5 Pocari, get \$20000 off",
      buyQty: 5,
      discountAmount: 20000,
    ),
    DiscountRule(
      type: "BOGO",
      itemId: 40005,
      description: "Buy 1 Bomb, get 1 Disc 50%",
      buyQty: 1,
      getQty: 1,
      discountPercent: 50,
    ),
    DiscountRule(
      type: "VOLUME",
      itemId: 40005,
      description: "Buy 5 Bomb, get 5 Disc 50%",
      buyQty: 5,
      discountPercent: 50,
    ),
  ];
}
