class CartItem {
  final int id;
  final String name;
  final double price;
  int qty;
  double discountApplied;
  int qtyDiscounted;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.qty = 1,
    this.discountApplied = 0.0,
    this.qtyDiscounted = 0,
  });

  /// ✅ Convert JSON → CartItem
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      qty: json['qty'] ?? 1,
      discountApplied: (json['discountApplied'] ?? 0.0).toDouble(),
      qtyDiscounted: json['qtyDiscounted'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'qty': qty,
      'discountApplied': discountApplied,
      'qtyDiscounted': qtyDiscounted,
    };
  }

  CartItem copy({int? id, String? name, double? price, int? qty, double? discountApplied, int? qtyDiscounted}) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      qty: qty ?? this.qty,
      discountApplied: discountApplied ?? this.discountApplied,
      qtyDiscounted: qtyDiscounted ?? this.qtyDiscounted,
    );
  }

  static List<CartItem> copyCartItemList(List<CartItem> source) {
    return source.map((item) => item.copy()).toList();
  }
}
