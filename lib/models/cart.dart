import 'package:scanner/models/discount.dart';

class CartItem {
  final int id;
  final String name;
  final double price;
  int qty;

  // auto discount
  String? discName;
  int? autoDiscountId;
  double discountApplied;
  int qtyDiscounted;
  bool isRestricted;
  int? targetItemId;

  // manual discount
  DiscountRule? manualDiscountRule;
  double? manualDiscountAmount;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.qty = 1,
    this.discountApplied = 0.0,
    this.qtyDiscounted = 0,
    this.isRestricted = false,
    this.autoDiscountId,
    this.manualDiscountAmount,
    this.discName,
    this.targetItemId,
    this.manualDiscountRule,
  });

  CartItem copy({
    int? id,
    String? name,
    double? price,
    int? qty,
    double? discountApplied,
    int? qtyDiscounted,
    bool? isRestricted,
    int? manualDiscountId,
    String? manualDiscName,
    double? manualDiscount,
    String? discName,
    DiscountRule? manualDiscountRule,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      qty: qty ?? this.qty,
      discountApplied: discountApplied ?? this.discountApplied,
      qtyDiscounted: qtyDiscounted ?? this.qtyDiscounted,
      isRestricted: isRestricted ?? this.isRestricted,
      manualDiscountAmount: manualDiscount ?? manualDiscountAmount,
      discName: discName ?? this.discName,
      manualDiscountRule: manualDiscountRule ?? this.manualDiscountRule,
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
      final hasDiscount = (item.discountApplied > 0) || ((item.manualDiscountAmount ?? 0) > 0);
      final discountedQty = item.qtyDiscounted;
      final normalQty = item.qty - discountedQty;

      if (hasDiscount && discountedQty > 0 && normalQty > 0) {
        result.add(
          item.copy(
            qty: discountedQty,
            discountApplied: item.discountApplied,
            manualDiscount: item.manualDiscountAmount,
          ),
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
