import 'package:scanner/models/discount.dart';

List<Map<String, dynamic>> recalculateDiscounts(List<Map<String, dynamic>> cartData, List<DiscountRule> rules) {
  final updatedCart = List<Map<String, dynamic>>.from(cartData);
  final now = DateTime.now();

  // Reset all discounts first
  for (var item in updatedCart) {
    item['discountApplied'] = 0.0;
    item['discountQty'] = 0; // new field
  }

  final Map<int, List<_DiscountCandidate>> discountCandidatesBySource = {};

  for (var rule in rules) {
    // -------------------------
    // CHECK ACTIVE PERIOD
    // -------------------------
    final isAlwaysActive = rule.startDate == null && rule.endDate == null;
    final isActive =
        isAlwaysActive ||
        (rule.startDate != null && rule.endDate != null && now.isAfter(rule.startDate!) && now.isBefore(rule.endDate!));

    if (!isActive) continue;

    final ruleType = rule.type;
    final itemId = rule.itemId;
    final targetItemId = rule.targetItemId;
    final buyQty = rule.buyQty;
    final getQty = rule.getQty ?? 0;
    final discountPercent = (rule.discountPercent) / 100.0;
    final discountAmount = (rule.discountAmount).toDouble();
    final maxUse = rule.maxUse;

    final sourceItem = updatedCart.firstWhere((i) => i['id'] == itemId, orElse: () => {});
    if (sourceItem.isEmpty) continue;

    final targetItem = updatedCart.firstWhere((i) => i['id'] == (targetItemId ?? itemId), orElse: () => {});
    if (targetItem.isEmpty) continue;

    double discountValue = 0.0;
    int discountedQty = 0;

    // -------------------------
    // APPLY RULE TYPES
    // -------------------------
    if (ruleType == 'BOGO') {
      var eligibleSets = sourceItem['qty'] ~/ (buyQty + getQty);
      if (maxUse != null && eligibleSets > maxUse) eligibleSets = maxUse;

      final freeCount = eligibleSets * getQty;
      discountedQty = freeCount;
      discountValue = freeCount * targetItem['price'] * discountPercent;
    } else if (ruleType == 'CROSS_BOGO' || ruleType == 'CROSS_DISCOUNT') {
      if (sourceItem['qty'] >= buyQty && targetItem['qty'] > 0) {
        var eligibleQty = (sourceItem['qty'] ~/ buyQty) * getQty;
        if (maxUse != null && eligibleQty > maxUse) eligibleQty = maxUse;

        final affectedQty = eligibleQty > targetItem['qty'] ? targetItem['qty'] : eligibleQty;
        discountedQty = affectedQty;
        discountValue = affectedQty * targetItem['price'] * discountPercent;
      }
    } else if (ruleType == 'VOLUME') {
      final qty = sourceItem['qty'];
      if (qty >= buyQty) {
        var eligibleSets = qty ~/ buyQty;
        if (maxUse != null && eligibleSets > maxUse) eligibleSets = maxUse;

        final discountedQtyCalc = eligibleSets * buyQty;
        discountedQty = discountedQtyCalc;
        discountValue = discountedQtyCalc * sourceItem['price'] * discountPercent;
      }
    } else if (ruleType == 'AMOUNT') {
      final qty = sourceItem['qty'];
      var eligibleSets = qty ~/ buyQty;
      if (maxUse != null && eligibleSets > maxUse) eligibleSets = maxUse;

      discountedQty = eligibleSets * buyQty;
      discountValue = eligibleSets * discountAmount;
    }

    if (discountValue <= 0 || discountedQty <= 0) continue;

    discountCandidatesBySource.putIfAbsent(itemId, () => []);
    discountCandidatesBySource[itemId]!.add(
      _DiscountCandidate(targetItemId ?? itemId, discountValue, discountedQty, isolated: rule.isolated),
    );
  }

  // -------------------------
  // APPLY BIGGEST DISCOUNT
  // -------------------------
  for (var sourceId in discountCandidatesBySource.keys) {
    final candidates = discountCandidatesBySource[sourceId]!;
    final biggest = candidates.reduce((a, b) => a.value > b.value ? a : b);

    final targetItem = updatedCart.firstWhere((i) => i['id'] == biggest.targetId, orElse: () => {});
    if (targetItem.isNotEmpty) {
      targetItem['discountApplied'] = biggest.value;
      targetItem['discountQty'] = biggest.discountQty;
      targetItem['isolated'] = biggest.isolated;
    }
  }

  return updatedCart;
}

class _DiscountCandidate {
  final int targetId;
  final double value;
  final int discountQty;
  final bool isolated;

  _DiscountCandidate(this.targetId, this.value, this.discountQty, {this.isolated = false});
}
