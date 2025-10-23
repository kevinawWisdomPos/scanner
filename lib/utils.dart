import 'package:scanner/models/cart.dart';
import 'package:scanner/models/discount.dart';
import 'package:scanner/models/discount_cart.dart';

List<CartItem> recalculateDiscounts(
  List<CartItem> cartData,
  List<DiscountRule> rules,
  List<DiscountItemLink> discountItemLinks,
) {
  final Map<int, List<_DiscountCandidate>> discountCandidatesBySource = {};
  final updatedCart = cartData.map((e) => e.copy()).toList();

  // final now = DateTime.now();
  // final now = DateTime(2025, 10, 23, 06, 30); // 06:30 hari ini // rule 1
  // final now = DateTime(2025, 10, 23, 22, 00); // 14:00 hari ini // rule 2
  // final now = DateTime(2025, 10, 23, 21, 00); // 21:00 hari ini // rule 2
  // final now = DateTime(2025, 10, 24, 14, 00); // 14:30 tanggal 24 // rule 3
  final now = DateTime(2025, 10, 26, 14, 30); // 14:30 minggu // rule 4

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

      double discountValue = 0.0;
      int discountedQty = 0;

      int itemQty = 0;
      double itemPrice = 1;

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
          var eligibleSets = itemQty;
          if (rule.maxQty != null && eligibleSets > rule.maxQty!) {
            eligibleSets = rule.maxQty!;
          }
          discountedQty = eligibleSets;
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
          var eligibleSets = itemQty ~/ buyQty;
          if (rule.maxQty != null && eligibleSets > rule.maxQty!) {
            eligibleSets = rule.maxQty!;
          }

          discountedQty = eligibleSets * buyQty;
          discountValue = discountedQty * itemPrice * discountPercent;
        }
      }
      /// "BOGO":
      /// buy specific quantity get specific discountPercent
      /// buy 2 pcs get 1 pcs discount 50%
      /// buy 1 pcs get 1 pcs discount 100% -> buy 1 get 1
      else if (rule.type == DiscountType.bogo) {
        if (targetItemId == item.id) {
          var eligibleSets = item.qty ~/ (buyQty + getQty);
          if (rule.maxQty != null && eligibleSets > rule.maxQty!) {
            eligibleSets = rule.maxQty!;
          }

          final freeCount = eligibleSets * getQty;
          discountedQty = freeCount;
          discountValue = freeCount * targetItem.price * discountPercent;
        } else {
          if (item.qty >= buyQty) {
            var eligibleQty = (item.qty ~/ buyQty) * getQty;
            if (rule.maxQty != null && eligibleQty > rule.maxQty!) {
              eligibleQty = rule.maxQty!;
            }

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
        var eligibleSets = item.qty ~/ buyQty;
        if (rule.maxQty != null && eligibleSets > rule.maxQty!) {
          eligibleSets = rule.maxQty!;
        }
        discountedQty = eligibleSets * buyQty;
        discountValue = eligibleSets * discountAmount;
      }

      if (discountValue <= 0 || discountedQty <= 0) continue;

      if (rule.maxAmount != null && discountValue > rule.maxAmount!) {
        discountValue = rule.maxAmount!;
      }

      discountCandidatesBySource.putIfAbsent(item.id, () => []);
      discountCandidatesBySource[item.id]!.add(
        _DiscountCandidate(targetItemId, discountValue, discountedQty, rule.name),
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
    }
  }

  return updatedCart;
}

class _DiscountCandidate {
  final int targetId;
  final double value;
  final int discountQty;
  final String discName;

  _DiscountCandidate(this.targetId, this.value, this.discountQty, this.discName);
}
