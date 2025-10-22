import 'package:scanner/models/discount.dart';

List<Map<String, dynamic>> recalculateDiscounts(List<Map<String, dynamic>> cartData, List<DiscountRule> rules) {
  final updatedCart = List<Map<String, dynamic>>.from(cartData);

  // Reset all discounts first
  for (var item in updatedCart) {
    item['discountApplied'] = 0.0;
  }

  // Store discount candidates grouped by source
  final Map<int, List<_DiscountCandidate>> discountCandidatesBySource = {};

  for (var rule in rules) {
    final ruleType = rule.type;
    final itemId = rule.itemId;
    final targetItemId = rule.targetItemId;
    final buyQty = rule.buyQty;
    final getQty = rule.getQty ?? 0;
    final discountPercent = (rule.discountPercent) / 100.0;
    final discountAmount = (rule.discountAmount).toDouble();

    // Find items
    final sourceItem = updatedCart.firstWhere((i) => i['id'] == itemId, orElse: () => {});
    if (sourceItem.isEmpty) continue;

    final targetItem = updatedCart.firstWhere((i) => i['id'] == (targetItemId ?? itemId), orElse: () => {});
    if (targetItem.isEmpty) continue;

    double discountValue = 0.0;

    // -------------------------
    // APPLY RULE TYPES
    // -------------------------
    if (ruleType == 'BOGO') {
      // buy 1 get 1 same item (based on price and discount%)
      final eligibleSets = sourceItem['qty'] ~/ (buyQty + getQty);
      final freeCount = eligibleSets * getQty;
      discountValue = freeCount * targetItem['price'] * discountPercent;
    } else if (ruleType == 'CROSS_BOGO' || ruleType == 'CROSS_DISCOUNT') {
      // buy A get B discount or free
      if (sourceItem['qty'] >= buyQty && targetItem['qty'] > 0) {
        final eligibleQty = (sourceItem['qty'] ~/ buyQty) * getQty;
        final affectedQty = eligibleQty > targetItem['qty'] ? targetItem['qty'] : eligibleQty;
        discountValue = affectedQty * targetItem['price'] * discountPercent;
      }
    } else if (ruleType == 'VOLUME') {
      final qty = sourceItem['qty'];
      if (qty >= buyQty) {
        final eligibleSets = qty ~/ (buyQty);
        final discountedQty = eligibleSets * buyQty;
        discountValue = discountedQty * sourceItem['price'] * discountPercent;
      }
    } else if (ruleType == 'AMOUNT') {
      final qty = sourceItem['qty'];
      final eligibleSets = qty ~/ buyQty;
      discountValue = eligibleSets * discountAmount;
    }

    if (discountValue <= 0) continue;

    // -------------------------
    // STORE DISCOUNT CANDIDATE
    // -------------------------
    discountCandidatesBySource.putIfAbsent(itemId, () => []);
    discountCandidatesBySource[itemId]!.add(_DiscountCandidate(targetItemId ?? itemId, discountValue));
  }

  // -------------------------
  // APPLY BIGGEST DISCOUNT PER TARGET ITEM
  // -------------------------

  for (var sourceId in discountCandidatesBySource.keys) {
    // dicount value per rules
    final candidates = discountCandidatesBySource[sourceId]!;

    // find biggest discount
    final biggest = candidates.reduce((a, b) => a.value > b.value ? a : b);

    // apply the biggest to target item
    final targetItem = updatedCart.firstWhere((i) => i['id'] == biggest.targetId, orElse: () => {});
    if (targetItem.isNotEmpty) {
      targetItem['discountApplied'] = biggest.value;
    }
  }

  return updatedCart;
}

class _DiscountCandidate {
  final int targetId;
  final double value;
  _DiscountCandidate(this.targetId, this.value);
}
