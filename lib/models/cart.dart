class CartItem {
  final int id;
  final String name;
  final double price;
  String? discName;
  int qty;
  double discountApplied;
  int qtyDiscounted;
  bool isRestricted;

  // manual discount
  int? mountedDiscountId;
  double? manualDiscount;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.qty = 1,
    this.discountApplied = 0.0,
    this.qtyDiscounted = 0,
    this.isRestricted = false,
    this.mountedDiscountId,
    this.manualDiscount,
    this.discName,
  });

  CartItem copy({
    int? id,
    String? name,
    double? price,
    int? qty,
    double? discountApplied,
    int? qtyDiscounted,
    bool? isRestricted,
    int? mountedDiscountId,
    double? manualDiscount,
    String? discName,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      qty: qty ?? this.qty,
      discountApplied: discountApplied ?? this.discountApplied,
      qtyDiscounted: qtyDiscounted ?? this.qtyDiscounted,
      isRestricted: isRestricted ?? this.isRestricted,
      mountedDiscountId: mountedDiscountId ?? this.mountedDiscountId,
      manualDiscount: manualDiscount ?? this.manualDiscount,
      discName: discName ?? this.discName,
    );
  }

  static List<CartItem> copyCartItemList(List<CartItem> source) {
    return source.map((item) => item.copy()).toList();
  }

  static List<CartItem> getDummy() {
    return [
      CartItem(id: 40000, name: "Coca Cola", price: 10000, qty: 10),
      CartItem(id: 40001, name: "Fanta", price: 12000, qty: 10),
      CartItem(id: 40002, name: "Sprite", price: 8000, qty: 20),
      CartItem(id: 40003, name: "Pepsi", price: 11000, qty: 15),
      CartItem(id: 40004, name: "Pepsi Blue", price: 9000, qty: 10),
    ];
  }

  static List<CartItem> splitDiscountedItems(List<CartItem> cart) {
    final List<CartItem> result = [];

    for (final item in cart) {
      final hasDiscount = (item.discountApplied > 0) || ((item.manualDiscount ?? 0) > 0);
      final discountedQty = item.qtyDiscounted;
      final normalQty = item.qty - discountedQty;

      if (hasDiscount && discountedQty > 0 && normalQty > 0) {
        result.add(
          item.copy(qty: discountedQty, discountApplied: item.discountApplied, manualDiscount: item.manualDiscount),
        );
        result.add(item.copy(qty: normalQty, discountApplied: 0, manualDiscount: 0, qtyDiscounted: 0));
      } else if (hasDiscount) {
        result.add(item.copy());
      } else {
        result.add(item.copy());
      }
    }

    return result;
  }
}
