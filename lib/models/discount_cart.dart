class DiscountItemLink {
  final int discountId;
  final int itemId;
  final int? targetItemId;

  DiscountItemLink({required this.discountId, required this.itemId, this.targetItemId});

  static List<DiscountItemLink> getDummy() {
    return [
      // DiscountItemLink(discountId: 101, itemId: 40000),
      // DiscountItemLink(discountId: 102, itemId: 40000),
      // DiscountItemLink(discountId: 103, itemId: 40000),
      // DiscountItemLink(discountId: 104, itemId: 40000),
      // DiscountItemLink(discountId: 101, itemId: 40002, targetItemId: 40003),
      // DiscountItemLink(discountId: 102, itemId: 40002, targetItemId: 40003),
      // DiscountItemLink(discountId: 103, itemId: 40002, targetItemId: 40003),
      // DiscountItemLink(discountId: 104, itemId: 40002, targetItemId: 40003),
      // DiscountItemLink(discountId: 105, itemId: 40002),
      DiscountItemLink(discountId: 201, itemId: 40001),
      DiscountItemLink(discountId: 202, itemId: 40001),
      DiscountItemLink(discountId: 203, itemId: 40001),
      DiscountItemLink(discountId: 204, itemId: 40001),
      DiscountItemLink(discountId: 205, itemId: 40001),

      // DiscountItemLink(discountId: 301, itemId: 40003),
      // DiscountItemLink(discountId: 302, itemId: 40003),
      // DiscountItemLink(discountId: 303, itemId: 40003, targetItemId: 40004),
      DiscountItemLink(discountId: 401, itemId: 40005),
      DiscountItemLink(discountId: 402, itemId: 40005),
      DiscountItemLink(discountId: 403, itemId: 40005),

      DiscountItemLink(discountId: 601, itemId: 40006, targetItemId: 40007),
      DiscountItemLink(discountId: 602, itemId: 40000, targetItemId: 40005),

      DiscountItemLink(discountId: 701, itemId: 40001, targetItemId: 40000),
      DiscountItemLink(discountId: 702, itemId: 40000, targetItemId: 40000),
      DiscountItemLink(discountId: 703, itemId: 40002, targetItemId: 40000),
      DiscountItemLink(discountId: 704, itemId: 40003, targetItemId: 40002),
      DiscountItemLink(discountId: 705, itemId: 40003, targetItemId: 40005),
    ];
  }
}
