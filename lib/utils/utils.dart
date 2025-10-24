import 'dart:developer';

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
  final Map<int, List<_DiscountCandidate>> discountCandidatesBySource = {};
  final updatedCart = cartData.map((e) => e.copy()).toList();

  // final now = DateTime.now();
  // final now = DateTime(2025, 10, 24, 06, 30); // 06:30 hari ini // rule 1
  // final now = DateTime(2025, 10, 24, 13, 59); // 13:59 hari ini // rule 2
  // final now = DateTime(2025, 10, 24, 14, 10); // 14:10 hari ini // rule 2
  final now = DateTime(2025, 10, 26, 14, 00); // 14:30 tanggal 25 // rule 3
  // final now = DateTime(2025, 10, 26, 14, 30); // 14:30 minggu // rule 4

  // final now = scannedTime;

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
      final link = applicableLinks[i];
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
      log("usage.totalApplied : ${rule.id} - ${item.id}");
      final usage = discountUsages.firstWhere(
        (u) => u.ruleId == rule.id && u.itemId == item.id,
        orElse: () => DiscountUsage(
          id: -1,
          ruleId: rule.id,
          itemId: item.id,
          date: now,
          totalApplied: 0,
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
          eligibleQty = itemQty;
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
          eligibleQty = itemQty ~/ buyQty;
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

      /// ================================================================
      if (discountValue <= 0 || discountedQty <= 0) continue;

      if (rule.maxAmount != null && discountValue > rule.maxAmount!) {
        discountValue = rule.maxAmount!;
      }

      discountCandidatesBySource.putIfAbsent(item.id, () => []);
      discountCandidatesBySource[item.id]!.add(
        _DiscountCandidate(targetItemId, discountValue, discountedQty, rule.name, rule.id),
      );
    }
  }

  // -------- APPLY BIGGEST DISCOUNT --------
  for (var sourceId in discountCandidatesBySource.keys) {
    final candidates = discountCandidatesBySource[sourceId]!;
    final biggest = candidates.reduce((a, b) => a.value > b.value ? a : b);

    final target = updatedCart.firstWhere(
      (c) => c.id == biggest.targetId,
      orElse: () => CartItem(id: -1, name: '', price: 0),
    );

    if (target.id != -1) {
      target.discountApplied = biggest.value;
      target.qtyDiscounted = biggest.discountQty;
      target.discName = biggest.discName;
      target.autoDiscountId = biggest.discId;
    }
  }

  return updatedCart;
}

class _DiscountCandidate {
  final int targetId;
  final double value;
  final int discountQty;
  final String discName;
  final int discId;

  _DiscountCandidate(this.targetId, this.value, this.discountQty, this.discName, this.discId);
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
