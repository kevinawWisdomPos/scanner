class CartItem {
  final int id;
  final String name;
  final double price;
  int qty;
  int discountApplied;

  CartItem({required this.id, required this.name, required this.price, this.qty = 1, this.discountApplied = 0});

  double get total => (price * qty) - discountApplied;
}
