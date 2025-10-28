import 'package:scanner/models/cart.dart';
import 'package:scanner/models/discount.dart';
import 'package:scanner/models/discount_cart.dart';
import 'package:scanner/models/discount_usage.dart';

List<CartItem> recalculateDiscounts(
  List<CartItem> cartData,
  List<DiscountRule> rules,
  List<DiscountItemLink> discountItemLinks,
  List<DiscountUsage> discountUsages,
  DateTime scannedTime,
) {
  final Map<int, List<DiscountCandidate>> discountCandidatesBySource = {};
  final updatedCart = cartData.map((e) => e.copy()).toList();

  // final now = DateTime.now();
  // final now = DateTime(2025, 10, 24, 14, 00); // 06:30 hari ini // rule 1
  // final now = DateTime(2025, 10, 24, 13, 59); // 13:59 hari ini // rule 2
  // final now = DateTime(2025, 10, 24, 14, 10); // 14:10 hari ini // rule 2
  // final now = DateTime(2025, 10, 26, 14, 00); // 14:30 tanggal 25 // rule 3
  // final now = DateTime(2025, 10, 26, 14, 30); // 14:30 minggu // rule 4

  final now = scannedTime;

  for (var item in updatedCart) {
    final applicableLinks = discountItemLinks.where((link) => link.itemId == item.id).toList();
    if (applicableLinks.isEmpty) continue;

    final applicableRules = applicableLinks
        .map((link) {
          try {
            return rules.firstWhere((rule) => rule.id == link.discountId && rule.autoApply);
          } catch (e) {
            return null;
          }
        })
        .whereType<DiscountRule>()
        .toList();

    for (var i = 0; i < applicableRules.length; i++) {
      final rule = applicableRules[i];
      final link = applicableLinks.firstWhere((element) => element.discountId == rule.id);
      if (!rule.isActiveNow(now)) continue;

      final buyQty = rule.buyQty ?? 0;
      final getQty = rule.getQty ?? 0;
      final discountPercent = (rule.discountPercent ?? 0) / 100;
      final discountAmount = rule.discountAmount ?? 0;
      final targetItemId = link.targetItemId ?? item.id;
      final targetItem = link.targetItemId == item.id
          ? item
          : updatedCart.firstWhere((c) => c.id == targetItemId, orElse: () => CartItem(id: -1, name: '', price: 0));
      if (targetItem.id == -1) continue;

      // 🔹 Check discount usage limit
      final usage = discountUsages.firstWhere(
        (u) => u.ruleId == rule.id && u.itemId == item.id,
        orElse: () => DiscountUsage(
          id: -1,
          ruleId: rule.id,
          itemId: item.id,
          date: now,
          totalApplied: 0,
          amountApplied: 0,
          startDate: null,
          limitValue: null,
        ),
      );

      double discountValue = 0.0;
      int discountedQty = 0;

      int itemQty = 0;
      double itemPrice = 1;

      int eligibleQty = 0;

      /// "PERCENT":
      /// buy minimum quantity pcs get discountPercent
      /// buy 5 pcs disc 10%
      /// "UP TO": set discount rule maxAmount to specific amount
      /// buy 2 pcs disc 40% up to 20000:
      ///   set buyQty 2 - discountPercent 40 - maxAmount - 20000
      if (rule.type == DiscountType.percent) {
        if (targetItem.id == item.id) {
          itemQty = item.qty;
          itemPrice = item.price;
        } else {
          itemQty = targetItem.qty;
          itemPrice = targetItem.price;
        }

        if (itemQty >= buyQty && buyQty > 0) {
          if (targetItem.qty > item.qty) {
            eligibleQty = item.qty ~/ buyQty;
          } else {
            eligibleQty = targetItem.qty ~/ buyQty;
          }
          eligibleQty = recalculateEligibleQty(eligibleQty, usage.totalApplied, rule.maxQty);
          discountedQty = eligibleQty;
          discountValue = discountedQty * itemPrice * discountPercent;
        }
      }
      /// "VOLUME":
      /// buy specific quantity get discountPercent
      /// buy 5 pcs discount 10%
      /// buy 8 pcs:
      ///   5 pcs discount 10%
      ///   3 pcs normal price
      else if (rule.type == DiscountType.volume) {
        if (targetItem.id == item.id) {
          itemQty = item.qty;
          itemPrice = item.price;
        } else {
          itemQty = targetItem.qty;
          itemPrice = targetItem.price;
        }

        if (itemQty >= buyQty) {
          if (targetItem.qty > item.qty) {
            eligibleQty = item.qty ~/ buyQty;
          } else {
            eligibleQty = targetItem.qty ~/ buyQty;
          }
          eligibleQty = recalculateEligibleQty(eligibleQty, usage.totalApplied, rule.maxQty);

          discountedQty = eligibleQty * buyQty;
          discountValue = discountedQty * itemPrice * discountPercent;
        }
      }
      /// "BOGO":
      /// buy specific quantity get specific discountPercent
      /// buy 2 pcs get 1 pcs discount 50%
      /// buy 1 pcs get 1 pcs discount 100% -> buy 1 get 1
      else if (rule.type == DiscountType.bogo) {
        if (targetItemId == item.id) {
          eligibleQty = item.qty ~/ (buyQty + getQty);
          eligibleQty = recalculateEligibleQty(eligibleQty, usage.totalApplied, rule.maxQty);

          final freeCount = eligibleQty * getQty;
          discountedQty = freeCount;
          discountValue = freeCount * targetItem.price * discountPercent;
        } else {
          if (item.qty >= buyQty) {
            eligibleQty = (item.qty ~/ buyQty) * getQty;
            eligibleQty = recalculateEligibleQty(eligibleQty, usage.totalApplied, rule.maxQty);

            final affectedQty = eligibleQty > targetItem.qty ? targetItem.qty : eligibleQty;
            discountedQty = affectedQty;
            discountValue = affectedQty * targetItem.price * discountPercent;
          }
        }
      }
      /// "AMOUNT":
      /// buy specific quantity get specific discountAmount
      /// each buy 2 pcs get 20.000
      else if (rule.type == DiscountType.amount) {
        eligibleQty = item.qty ~/ buyQty;
        eligibleQty = recalculateEligibleQty(eligibleQty, usage.totalApplied, rule.maxQty);
        discountedQty = eligibleQty * buyQty;
        discountValue = eligibleQty * discountAmount;
      }
      /// "BUNDLING":
      /// buy x and y get z amount
      /// every 2 cola & 1 fanta get 20.000
      else if (rule.type == DiscountType.bundling) {
        final itemX = item;
        final itemY = updatedCart.firstWhere(
          (c) => c.id == (link.targetItemId ?? -1),
          orElse: () => CartItem(id: -1, name: '', price: 0),
        );

        if (itemY.id == -1) continue;

        if (itemX.qty >= (rule.buyQty ?? 1) && itemY.qty >= (rule.getQty ?? 1)) {
          final int bundleCount = [
            itemX.qty ~/ (rule.buyQty ?? 1),
            itemY.qty ~/ (rule.getQty ?? 1),
          ].reduce((a, b) => a < b ? a : b);

          final int eligibleQty = recalculateEligibleQty(bundleCount, usage.totalApplied, rule.maxQty);

          discountedQty = eligibleQty * (rule.getQty ?? 1);
          discountValue = eligibleQty * (rule.discountAmount ?? 0);
        }
      }

      /// ================================================================
      if (discountValue <= 0 || discountedQty <= 0) continue;

      if (rule.maxAmount != null && discountValue > rule.maxAmount!) {
        discountValue = rule.maxAmount!;
      }

      if (rule.maxAmount != null) {
        if (usage.amountApplied >= rule.maxAmount!) {
          discountedQty = 0;
          discountValue = 0;
        } else if (usage.amountApplied + discountValue > rule.maxAmount!) {
          discountValue = rule.maxAmount! - usage.amountApplied;
        }
      }

      discountCandidatesBySource.putIfAbsent(item.id, () => []);
      discountCandidatesBySource[item.id]!.add(
        DiscountCandidate(item.id, targetItemId, discountValue, discountedQty, rule.name, rule.id),
      );
    }
  }

  // normalCombination(updatedCart, discountCandidatesBySource);
  bestCombination1(updatedCart, discountCandidatesBySource);

  return updatedCart;
}

class DiscountCandidate {
  final int itemId;
  final int targetId;
  final double value;
  final int discountQty;
  final String discName;
  final int discId;

  DiscountCandidate(this.itemId, this.targetId, this.value, this.discountQty, this.discName, this.discId);
}

int recalculateEligibleQty(int eligible, int usage, int? max) {
  if (max == null) {
    return eligible;
  }
  if (eligible > max) {
    if ((eligible + usage) > max) {
      eligible = max - usage;
    } else {
      eligible = max;
    }
  } else if ((eligible + usage) > max) {
    eligible = max - usage;
  }
  return eligible;
}

void normalCombination(List<CartItem> updatedCart, Map<int, List<DiscountCandidate>> discountCandidatesBySource) {
  // Clear all previous auto discounts
  for (var c in updatedCart) {
    c.discountApplied = 0;
    c.qtyDiscounted = 0;
    c.discName = null;
    c.autoDiscountId = null;
  }

  final Map<int, DiscountCandidate> bestCandidatePerSource = {};
  for (var sourceId in discountCandidatesBySource.keys) {
    final candidates = discountCandidatesBySource[sourceId]!;

    // Find the biggest discount within the same source
    final biggestForSource = candidates.reduce((a, b) => a.value > b.value ? a : b);
    final existing = bestCandidatePerSource[sourceId];
    if (existing == null || biggestForSource.value > existing.value) {
      bestCandidatePerSource[sourceId] = biggestForSource;
    }
  }

  final Map<int, DiscountCandidate> bestCandidatePerTarget = {};
  for (final cand in bestCandidatePerSource.values) {
    final existing = bestCandidatePerTarget[cand.targetId];
    if (existing == null || cand.value > existing.value) {
      bestCandidatePerTarget[cand.targetId] = cand;
    }
  }

  // Apply discounts to target items
  for (final cand in bestCandidatePerTarget.values) {
    final target = updatedCart.firstWhere(
      (c) => c.id == cand.targetId,
      orElse: () => CartItem(id: -1, name: '', price: 0),
    );

    if (target.id == -1) continue;

    target.discountApplied = cand.value;
    target.qtyDiscounted = cand.discountQty;
    target.discName = cand.discName;
    target.autoDiscountId = cand.discId;
  }
}

// 1 item can only have 1 discount
void bestCombination1(List<CartItem> updatedCart, Map<int, List<DiscountCandidate>> discountCandidatesBySource) {
  // Flatten all discount candidates into one list
  final allCandidates = discountCandidatesBySource.values.expand((e) => e).toList();

  // Sort candidates by discount value (highest first)
  allCandidates.sort((a, b) => b.value.compareTo(a.value));

  final usedItems = <int>{}; // items that already used as source or target
  final bestCombo = <DiscountCandidate>[];

  // Pick the best combination (no shared items)
  for (final cand in allCandidates) {
    if (usedItems.contains(cand.itemId) || usedItems.contains(cand.targetId)) {
      continue; // skip if either item already involved in another discount
    }

    usedItems.add(cand.itemId);
    usedItems.add(cand.targetId);
    bestCombo.add(cand);
  }

  // Reset previous discounts
  for (final item in updatedCart) {
    item
      ..discountApplied = 0
      ..qtyDiscounted = 0
      ..discName = null
      ..autoDiscountId = null;
  }

  // Apply the selected best discounts
  for (final cand in bestCombo) {
    final target = updatedCart.firstWhere(
      (c) => c.id == cand.targetId,
      orElse: () => CartItem(id: -1, name: '', price: 0),
    );
    if (target.id == -1) continue;

    target
      ..discountApplied = cand.value
      ..qtyDiscounted = cand.discountQty
      ..discName = cand.discName
      ..autoDiscountId = cand.discId;
  }
}

// all remaining qty can have discount
void bestCombination2(List<CartItem> updatedCart, Map<int, List<DiscountCandidate>> discountCandidatesBySource) {
  final allCandidates = discountCandidatesBySource.values.expand((e) => e).toList();
  allCandidates.sort((a, b) {
    final aRatio = a.discountQty == 0 ? a.value : a.value / a.discountQty;
    final bRatio = b.discountQty == 0 ? b.value : b.value / b.discountQty;
    return bRatio.compareTo(aRatio);
  });

  // Remaining quantity map for each item (so discount can reuse remaining)
  final remainingQty = {for (final item in updatedCart) item.id: item.qty};

  final bestCombo = <DiscountCandidate>[];

  // Pick the best discount candidates
  for (final cand in allCandidates) {
    final sourceRemain = remainingQty[cand.itemId] ?? 0;
    final targetRemain = remainingQty[cand.targetId] ?? 0;

    // no remain qty
    if (sourceRemain <= 0 || targetRemain <= 0) continue;

    // how many units can we apply for this discount
    final usableQty = cand.discountQty.clamp(0, targetRemain);

    if (usableQty <= 0) continue;

    // Add to best combination
    bestCombo.add(
      DiscountCandidate(
        cand.itemId,
        cand.targetId,
        cand.value * (usableQty / cand.discountQty), // partial proportional discount
        usableQty,
        cand.discName,
        cand.discId,
      ),
    );

    // Reduce available qty for next discounts
    remainingQty[cand.itemId] = (sourceRemain - usableQty).clamp(0, sourceRemain);
    remainingQty[cand.targetId] = (targetRemain - usableQty).clamp(0, targetRemain);
  }

  // Reset all discount info
  for (final item in updatedCart) {
    item
      ..discountApplied = 0
      ..qtyDiscounted = 0
      ..discName = null
      ..autoDiscountId = null;
  }

  // Apply chosen best combination
  for (final cand in bestCombo) {
    final target = updatedCart.firstWhere(
      (c) => c.id == cand.targetId,
      orElse: () => CartItem(id: -1, name: '', price: 0),
    );
    if (target.id == -1) continue;

    target
      ..discountApplied += cand.value
      ..qtyDiscounted += cand.discountQty
      ..discName = cand.discName
      ..autoDiscountId = cand.discId;
  }
}

double recalculateManualDiscounts(DiscountRule rule, CartItem item, List<DiscountUsage> discountUsages, DateTime now) {
  if (!rule.isActiveNow(now)) return 0;

  final previousManualDiscount = item.manualDiscountAmount ?? 0.0;
  double previousAutoDiscount = item.discountApplied - previousManualDiscount;

  // Remove only the old manual discount (keep auto)
  item.manualDiscountRule = rule;
  if (item.isRestricted || rule.restricted) {
    item.autoDiscountId = null;
    item.discName = null;
    item.discountApplied = 0;
    item.manualDiscountAmount = null;
    item.manualDiscountRule = null;
    item.isRestricted = true;
    item.qtyDiscounted = 0;
    previousAutoDiscount = 0;
  }

  final buyQty = rule.buyQty ?? 0;
  final getQty = rule.getQty ?? 0;
  final discountPercent = (rule.discountPercent ?? 0) / 100;
  final discountAmount = rule.discountAmount ?? 0;
  final targetItemId = item.id;
  final targetItem = item;

  // 🔹 Check discount usage limit
  final usage = discountUsages.firstWhere(
    (u) => u.ruleId == rule.id && u.itemId == item.id,
    orElse: () => DiscountUsage(
      id: -1,
      ruleId: rule.id,
      itemId: item.id,
      date: now,
      totalApplied: 0,
      amountApplied: 0,
      startDate: null,
      limitValue: null,
    ),
  );

  double discountValue = 0.0;
  int discountedQty = 0;

  int itemQty = item.qty;
  double itemPrice = item.price;

  int eligibleQty = 0;

  /// "PERCENT":
  /// buy minimum quantity pcs get discountPercent
  /// buy 5 pcs disc 10%
  /// "UP TO": set discount rule maxAmount to specific amount
  /// buy 2 pcs disc 40% up to 20000:
  ///   set buyQty 2 - discountPercent 40 - maxAmount - 20000
  if (rule.type == DiscountType.percent) {
    if (itemQty >= buyQty && buyQty > 0) {
      eligibleQty = itemQty;
      eligibleQty = recalculateEligibleQty(eligibleQty, usage.totalApplied, rule.maxQty);
      final double itemSubtotal = itemPrice * eligibleQty;
      final double remainingTotal = itemSubtotal - previousAutoDiscount;

      discountedQty = itemQty;
      discountValue = (remainingTotal) * discountPercent;
    }
  }
  /// "VOLUME":
  /// buy specific quantity get discountPercent
  /// buy 5 pcs discount 10%
  /// buy 8 pcs:
  ///   5 pcs discount 10%
  ///   3 pcs normal price
  else if (rule.type == DiscountType.volume) {
    if (itemQty >= buyQty) {
      eligibleQty = itemQty ~/ buyQty;
      eligibleQty = recalculateEligibleQty(eligibleQty, usage.totalApplied, rule.maxQty);

      discountedQty = eligibleQty * buyQty;
      final double itemSubtotal = itemPrice * discountedQty;
      final double remainingTotal = itemSubtotal - previousAutoDiscount;

      discountValue = remainingTotal * discountPercent;
    }
  }
  /// "BOGO":
  /// buy specific quantity get specific discountPercent
  /// buy 2 pcs get 1 pcs discount 50%
  /// buy 1 pcs get 1 pcs discount 100% -> buy 1 get 1
  else if (rule.type == DiscountType.bogo) {
    eligibleQty = item.qty ~/ (buyQty + getQty);
    eligibleQty = recalculateEligibleQty(eligibleQty, usage.totalApplied, rule.maxQty);

    final freeCount = eligibleQty * getQty;
    discountedQty = freeCount;
    discountValue = freeCount * targetItem.price * discountPercent;

    if (targetItemId == item.id) {
      eligibleQty = item.qty ~/ (buyQty + getQty);
      eligibleQty = recalculateEligibleQty(eligibleQty, usage.totalApplied, rule.maxQty);

      final freeCount = eligibleQty * getQty;
      discountedQty = freeCount;
      discountValue = freeCount * targetItem.price * discountPercent;
    } else {
      if (item.qty >= buyQty) {
        eligibleQty = (item.qty ~/ buyQty) * getQty;
        eligibleQty = recalculateEligibleQty(eligibleQty, usage.totalApplied, rule.maxQty);

        final affectedQty = eligibleQty > targetItem.qty ? targetItem.qty : eligibleQty;
        discountedQty = affectedQty;
        discountValue = affectedQty * targetItem.price * discountPercent;
      }
    }
  }
  /// "AMOUNT":
  /// buy specific quantity get specific discountAmount
  /// each buy 2 pcs get 20.000
  else if (rule.type == DiscountType.amount) {
    eligibleQty = item.qty ~/ buyQty;
    discountedQty = eligibleQty * buyQty;
    discountValue = eligibleQty * discountAmount;
  }

  /// ================================================================
  if (discountValue <= 0 || discountedQty <= 0) return 0;

  if (rule.maxAmount != null && discountValue > rule.maxAmount!) {
    discountValue = rule.maxAmount!;
  }

  if (rule.maxAmount != null) {
    if (usage.amountApplied >= rule.maxAmount!) {
      discountedQty = 0;
      discountValue = 0;
    } else if (usage.amountApplied + discountValue > rule.maxAmount!) {
      discountValue = rule.maxAmount! - usage.amountApplied;
    }
  }

  item.qtyDiscounted = item.qty;
  item.manualDiscountAmount = discountValue;
  item.discountApplied = previousAutoDiscount + discountValue;
  item.manualDiscountRule = rule;
  return discountValue;
}
