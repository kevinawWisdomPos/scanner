// ===========================
// ENUM DEFINITIONS
// ===========================
import 'package:flutter/material.dart';

enum DiscountType {
  percentage, // e.g., 10% off
  amount, // e.g., Rp5000 off
  bogo, // buy one get one
  volume, // buy 5 get 10% off
  cross, // buy item A get discount on item B
}

enum DiscountApplicationType {
  auto, // auto-applied by system
  manual, // requires user action
}

enum DiscountMaxUseType {
  perDay, // e.g., max 10 times per day
  perTransaction, // e.g., max 10 times this sale
}

// ===========================
// DISCOUNT TIMING RULE
// ===========================
class DiscountTimingRule {
  final List<int>? activeDays; // 1=Monday ... 7=Sunday
  final List<TimeRange>? activeTimeRanges; // e.g. 07:00–10:00
  final DateTime? startDate;
  final DateTime? endDate;

  const DiscountTimingRule({this.activeDays, this.activeTimeRanges, this.startDate, this.endDate});

  bool isActiveNow() {
    final now = DateTime.now();
    final currentDay = now.weekday;
    final currentTime = TimeOfDay.fromDateTime(now);

    // Date range check
    if (startDate != null && endDate != null) {
      if (now.isBefore(startDate!) || now.isAfter(endDate!)) return false;
    }

    // Day check
    if (activeDays != null && activeDays!.isNotEmpty) {
      if (!activeDays!.contains(currentDay)) return false;
    }

    // Time range check
    if (activeTimeRanges != null && activeTimeRanges!.isNotEmpty) {
      final inRange = activeTimeRanges!.any((r) => r.contains(currentTime));
      if (!inRange) return false;
    }

    return true;
  }
}

class TimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  const TimeRange(this.start, this.end);

  bool contains(TimeOfDay time) {
    final tMin = time.hour * 60 + time.minute;
    final sMin = start.hour * 60 + start.minute;
    final eMin = end.hour * 60 + end.minute;
    return tMin >= sMin && tMin <= eMin;
  }
}

// ===========================
// DISCOUNT RULE
// ===========================
class DiscountRule {
  final int id;
  final String name;
  final DiscountType type;
  final DiscountApplicationType applyType;
  final DiscountMaxUseType? maxUseType;
  final double? discountPercent;
  final double? discountAmount;
  final int? buyQty;
  final int? getQty;
  final int? maxUse; // max times per rule (depends on maxUseType)
  final DiscountTimingRule? timingRule;
  final List<DiscountTarget> targets;

  const DiscountRule({
    required this.id,
    required this.name,
    required this.type,
    required this.applyType,
    this.maxUseType,
    this.discountPercent,
    this.discountAmount,
    this.buyQty,
    this.getQty,
    this.maxUse,
    this.timingRule,
    this.targets = const [],
  });

  bool isActiveNow() => timingRule?.isActiveNow() ?? true;
}

// ===========================
// DISCOUNT TARGET (Many-to-Many)
// ===========================
class DiscountTarget {
  final int sourceItemId; // item that triggers discount
  final int targetItemId; // item that gets discount (can be same)
  const DiscountTarget(this.sourceItemId, this.targetItemId);
}

// ===========================
// CART ITEM
// ===========================
class CartItem {
  final int id;
  final String name;
  final double price;
  int qty;
  double discountApplied;

  CartItem({required this.id, required this.name, required this.price, this.qty = 1, this.discountApplied = 0});

  double get total => (price * qty) - discountApplied;
}

// ===========================
// USAGE TRACKER
// ===========================
class DiscountUsageTracker {
  final Map<int, int> _dailyUsage = {}; // ruleId -> count
  final Map<int, int> _transactionUsage = {};

  void increment(int ruleId, DiscountMaxUseType type) {
    if (type == DiscountMaxUseType.perDay) {
      _dailyUsage[ruleId] = (_dailyUsage[ruleId] ?? 0) + 1;
    } else {
      _transactionUsage[ruleId] = (_transactionUsage[ruleId] ?? 0) + 1;
    }
  }

  bool canUse(int ruleId, int maxUse, DiscountMaxUseType type) {
    final used = type == DiscountMaxUseType.perDay ? (_dailyUsage[ruleId] ?? 0) : (_transactionUsage[ruleId] ?? 0);
    return used < maxUse;
  }

  void resetTransaction() => _transactionUsage.clear();
}
