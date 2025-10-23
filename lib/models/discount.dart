enum DiscountType { percent, volume, bogo, amount, upto }

class DiscountRule {
  final int id;
  final String name;
  final DiscountType type; // "BOGO", "PERCENT", "VOLUME", "AMOUNT", "UP TO"
  final double? discountPercent;
  final double? discountAmount;
  final int? buyQty;
  final int? getQty;
  final bool autoApply;
  final int? maxQty;
  final double? maxAmount;

  DiscountRule({
    required this.id,
    required this.name,
    required this.type,
    this.discountPercent,
    this.discountAmount,
    this.buyQty,
    this.getQty,
    this.autoApply = true,
    this.maxQty,
    this.maxAmount,
  });

  static List<DiscountRule> discountRules() {
    return [
      DiscountRule(
        id: 101,
        name: "Buy Min 5 Disc 10%",
        type: DiscountType.percent,
        discountPercent: 10,
        buyQty: 5,
        autoApply: true,
      ),
      DiscountRule(
        id: 102,
        name: "Buy Min 10 Disc 20%",
        type: DiscountType.percent,
        discountPercent: 20,
        buyQty: 10,
        autoApply: true,
      ),
      DiscountRule(
        id: 103,
        name: "Buy 25 Disc Item B 40%",
        type: DiscountType.percent,
        discountPercent: 40,
        buyQty: 25,
        autoApply: true,
        maxAmount: 250000,
      ),
      DiscountRule(
        id: 201,
        name: "Buy each 5 item Disc 5%",
        type: DiscountType.volume,
        discountPercent: 5,
        buyQty: 5,
        autoApply: true,
      ),
      DiscountRule(
        id: 202,
        name: "Buy each 10 item Disc 10%",
        type: DiscountType.volume,
        discountPercent: 10,
        buyQty: 10,
        autoApply: true,
      ),
      DiscountRule(
        id: 203,
        name: "Buy each 20 item Disc 50%",
        type: DiscountType.volume,
        discountPercent: 50,
        buyQty: 20,
        autoApply: true,
      ),
      DiscountRule(
        id: 204,
        name: "Buy each 25 item Disc 100%",
        type: DiscountType.volume,
        discountPercent: 100,
        buyQty: 25,
        maxQty: 1,
        autoApply: true,
      ),

      DiscountRule(
        id: 301,
        name: "Buy 2 item free 1 item",
        type: DiscountType.bogo,
        discountPercent: 100,
        buyQty: 2,
        getQty: 1,
        autoApply: true,
      ),
      DiscountRule(
        id: 302,
        name: "Buy 5 item free 3 item",
        type: DiscountType.bogo,
        discountPercent: 100,
        buyQty: 5,
        getQty: 3,
        autoApply: true,
      ),
      DiscountRule(
        id: 303,
        name: "Buy 10 item free 7 item",
        type: DiscountType.bogo,
        discountPercent: 100,
        buyQty: 10,
        getQty: 7,
        autoApply: true,
      ),
      DiscountRule(
        id: 401,
        name: "Buy 2 item get 7000",
        type: DiscountType.amount,
        discountAmount: 7000,
        buyQty: 2,
        autoApply: true,
      ),
      DiscountRule(
        id: 402,
        name: "Buy 7 item get 21000",
        type: DiscountType.amount,
        discountAmount: 29000,
        buyQty: 7,
        autoApply: true,
        maxQty: 2,
      ),
    ];
  }
}
