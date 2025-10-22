class DiscountRule {
  final String id;
  final String type; // "BOGO", "VOLUME"
  final int? buyQty;
  final int? getQty;
  final int? minQty;
  final double? discount; // e.g. 0.2 = 20% off
  final int? buyItemId; // item that must be bought
  final int? getItemId; // item that will be discounted
  final bool isFree; // if true, discount = 100%

  const DiscountRule({
    required this.id,
    required this.type,
    this.buyQty,
    this.getQty,
    this.minQty,
    this.discount,
    this.buyItemId,
    this.getItemId,
    this.isFree = false,
  });
}
