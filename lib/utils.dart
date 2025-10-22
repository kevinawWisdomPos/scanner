import 'package:scanner/models/cart.dart';
import 'package:scanner/models/discount.dart';

void applyDiscounts(List<CartItem> cart, List<DiscountRule> rules) {
  for (var rule in rules) {
    if (rule.type == 'BOGO') {
      final buyItem = cart.firstWhere(
        (c) => c.id == rule.buyItemId,
        orElse: () => CartItem(id: -1, name: '', price: 0),
      );
      if (buyItem.id == -1) continue;

      final eligibleFreeCount = (buyItem.qty ~/ (rule.buyQty ?? 1)) * (rule.getQty ?? 0);

      final targetItem = cart.firstWhere(
        (c) => c.id == rule.getItemId,
        orElse: () => CartItem(id: -1, name: '', price: 0),
      );

      if (targetItem.id != -1 && eligibleFreeCount > 0) {
        final discountValue =
            (rule.isFree ? targetItem.price : targetItem.price * (rule.discount ?? 0)) * eligibleFreeCount;

        targetItem.discountApplied += discountValue;
      }
    }

    if (rule.type == 'VOLUME') {
      final target = cart.firstWhere((c) => c.id == rule.buyItemId, orElse: () => CartItem(id: -1, name: '', price: 0));

      if (target.id == -1) continue;
      if (target.qty >= (rule.minQty ?? 0)) {
        final discountValue = target.price * target.qty * (rule.discount ?? 0);
        target.discountApplied += discountValue;
      }
    }
  }
}
