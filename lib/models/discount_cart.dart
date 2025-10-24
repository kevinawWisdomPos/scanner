class DiscountItemLink {
  final int discountId;
  final int itemId;
  final int? targetItemId;

  DiscountItemLink({required this.discountId, required this.itemId, this.targetItemId});

  static List<DiscountItemLink> getDummy() {
    return [
      DiscountItemLink(discountId: 101, itemId: 40000),
      DiscountItemLink(discountId: 102, itemId: 40000),
      DiscountItemLink(discountId: 103, itemId: 40000),
      DiscountItemLink(discountId: 104, itemId: 40000),
      DiscountItemLink(discountId: 101, itemId: 40002, targetItemId: 40003),
      DiscountItemLink(discountId: 102, itemId: 40002, targetItemId: 40003),
      DiscountItemLink(discountId: 103, itemId: 40002, targetItemId: 40003),
      DiscountItemLink(discountId: 104, itemId: 40002, targetItemId: 40003),

      DiscountItemLink(discountId: 201, itemId: 40001),
      DiscountItemLink(discountId: 202, itemId: 40001),
      DiscountItemLink(discountId: 203, itemId: 40001),
      DiscountItemLink(discountId: 204, itemId: 40001),
      DiscountItemLink(discountId: 205, itemId: 40001),

      // DiscountItemLink(discountId: 301, itemId: 40003),
      // DiscountItemLink(discountId: 302, itemId: 40003),
      // DiscountItemLink(discountId: 303, itemId: 40003, targetItemId: 40004),
      DiscountItemLink(discountId: 401, itemId: 40005),
    ];
  }
}
