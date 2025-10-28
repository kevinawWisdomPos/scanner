import 'package:flutter/material.dart';

enum DiscountType { percent, volume, bogo, amount, bundling, minAmount }

enum LimitType { transaction, daily, weekly, monthly, days }

class DiscountRule {
  final int id;
  final String name;
  final DiscountType type; // "BOGO", "PERCENT", "VOLUME", "AMOUNT", "BUNDLING"
  final double? discountPercent;
  final double? discountAmount;
  final int? buyQty;
  final int? getQty;
  final bool autoApply;
  final double? minAmount;
  final double? maxAmount;

  final List<int>? weekDays;
  final List<String>? startTimes;
  final int? durationInMinute;
  final int? date;

  // max timing
  final int? maxQty;

  /// if limitType = days && startDate != null
  /// limit become duration
  /// ex:
  /// limit discount each 4 days start from 24 oct:
  /// limitValue = 4
  /// limitType = LImitType.days
  /// startDate = "24-10-2025"
  final DateTime? startDate;
  final LimitType limitType;
  final int? limitValue;

  /// if true then cannot combine with manual discount
  final bool restricted;

  DiscountRule({
    required this.id,
    required this.name,
    required this.type,
    this.discountPercent,
    this.discountAmount,
    this.buyQty,
    this.getQty,
    this.autoApply = true,
    this.maxQty,
    this.minAmount,
    this.maxAmount,
    this.weekDays,
    this.startTimes,
    this.durationInMinute = 30,
    this.date,
    this.restricted = false,
    this.startDate,
    this.limitType = LimitType.transaction,
    this.limitValue,
  });

  bool isActiveNow(DateTime now) {
    final currentWeekDay = now.weekday; // 1 = Monday ... 7 = Sunday
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    bool matchesDay = true;
    bool matchesDate = true;
    bool matchesTime = true;

    if (startDate != null && limitValue != null) {
      var start = startDate!;
      var end = start.add(Duration(days: limitValue!));
      if ((now.isAfter(start) || now.isAtSameMomentAs(start)) && (now.isBefore(end) || now.isAtSameMomentAs(end))) {
      } else {
        return false;
      }
    }

    // --- repeat every that date ---
    if (date != null) {
      matchesDate = now.day == date;
    }

    // --- repeat every that weekday ---
    if (weekDays != null && weekDays!.isNotEmpty) {
      matchesDay = weekDays!.contains(currentWeekDay);
    }

    // --- check time window (with cross-midnight + cross-day support) ---
    if (startTimes != null && startTimes!.isNotEmpty) {
      matchesTime = false;
      for (var timeStr in startTimes!) {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = parts.length > 1 ? int.parse(parts[1]) : 0;

        final start = TimeOfDay(hour: hour, minute: minute);

        final totalMinutes = durationInMinute ?? 60;
        final addedHours = totalMinutes ~/ 60;
        final addedMinutes = totalMinutes % 60;

        int endHour = (hour + addedHours) % 24;
        int endMinute = (minute + addedMinutes) % 60;

        // Handle minute overflow
        if (minute + addedMinutes >= 60) {
          endHour = (endHour + 1) % 24;
        }

        final end = TimeOfDay(hour: endHour, minute: endMinute);

        // Check if crosses midnight
        bool crossesMidnight = end.hour < start.hour || (end.hour == start.hour && end.minute < start.minute);
        bool inRange = false;

        if (crossesMidnight) {
          // Cross-day case (e.g. 22:00 → 02:00)
          final afterStart =
              currentTime.hour > start.hour || (currentTime.hour == start.hour && currentTime.minute >= start.minute);
          final beforeEnd =
              currentTime.hour < end.hour || (currentTime.hour == end.hour && currentTime.minute <= end.minute);

          // Either same-day after start OR next-day before end
          if ((afterStart && matchesDay) || (beforeEnd && _isNextDayMatch(now.weekday))) {
            inRange = true;
          }
        } else {
          // Normal case
          final afterStart =
              currentTime.hour > start.hour || (currentTime.hour == start.hour && currentTime.minute >= start.minute);
          final beforeEnd =
              currentTime.hour < end.hour || (currentTime.hour == end.hour && currentTime.minute <= end.minute);
          if (afterStart && beforeEnd) {
            inRange = true;
          }
        }

        if (inRange) {
          matchesTime = true;
          break;
        }
      }
    }

    return (matchesDay && matchesDate) && matchesTime;
  }

  /// Helper: check if today is the next day after a weekday in [weekDays]
  bool _isNextDayMatch(int todayWeekday) {
    final previousDay = todayWeekday == 1 ? 7 : todayWeekday - 1; // wrap around Sunday → Monday
    if (weekDays == null || weekDays!.isEmpty) return false;
    return weekDays!.contains(previousDay);
  }

  static List<DiscountRule> discountRules() {
    return [
      DiscountRule(
        id: 101,
        name: "beli coca cola 1 gratis 1 max 4 item",
        type: DiscountType.bogo,
        discountPercent: 100,
        buyQty: 1,
        getQty: 1,
        maxQty: 4,
      ),
      DiscountRule(
        id: 102,
        name: "beli coca cola per 7 cola diskon 40%",
        type: DiscountType.volume,
        discountPercent: 40,
        buyQty: 7,
      ),
      DiscountRule(
        id: 103,
        name: "beli coca cola 20 diskon 70% up to 175rb",
        type: DiscountType.percent,
        discountPercent: 70,
        buyQty: 20,
        maxAmount: 175000,
      ),
      DiscountRule(
        id: 104,
        name: "beli coca cola 30 diskon 80% up to 35 item",
        type: DiscountType.percent,
        discountPercent: 80,
        buyQty: 30,
        maxQty: 35,
      ),
      DiscountRule(
        id: 105,
        name: "Buy 1 Disc get 1 free",
        type: DiscountType.bogo,
        discountPercent: 100,
        buyQty: 1,
        getQty: 1,
        startTimes: ["12:30"],
        maxQty: 5,
        restricted: true,
      ),
      DiscountRule(
        id: 105,
        name: "Buy 1 Disc get 1 free",
        type: DiscountType.bogo,
        discountPercent: 100,
        buyQty: 1,
        getQty: 1,
      ),

      DiscountRule(
        id: 201,
        name: "Buy each 5 item get 40.000",
        type: DiscountType.amount,
        discountAmount: 40000,
        buyQty: 5,
      ),
      DiscountRule(
        id: 202,
        name: "beli per 5 fanta di hari ini jam 13:30 - 14:00 & 20:30 - 21:00 dapat diskon 50rb",
        type: DiscountType.amount,
        discountAmount: 50000,
        startTimes: ["13:30", "20:30"],
        durationInMinute: 30,
        buyQty: 5,
        maxQty: 2,
      ),
      DiscountRule(
        id: 203,
        name: "beli per 5 fanta di tanggal 24 dapat diskon 55rb",
        type: DiscountType.amount,
        discountAmount: 55000,
        date: 25,
        buyQty: 5,
        maxQty: 2,
      ),
      DiscountRule(
        id: 204,
        name: "beli per 5 fanta di hari minggu dapat diskon 65rb",
        type: DiscountType.amount,
        discountAmount: 65000,
        weekDays: [7],
        buyQty: 5,
        maxQty: 2,
      ),

      DiscountRule(
        id: 301,
        name: "Buy 2 item free 1 item",
        type: DiscountType.bogo,
        discountPercent: 100,
        buyQty: 2,
        getQty: 1,
      ),
      DiscountRule(
        id: 302,
        name: "Buy 5 item free 3 item",
        type: DiscountType.bogo,
        discountPercent: 100,
        buyQty: 5,
        getQty: 3,
      ),
      DiscountRule(
        id: 303,
        name: "Buy 10 item free 7 item",
        type: DiscountType.bogo,
        discountPercent: 100,
        buyQty: 10,
        getQty: 7,
      ),
      DiscountRule(
        id: 401,
        name: "Buy 5 bomb free 1 bomb, limit 10 each week, start on friday, 24 Oct",
        type: DiscountType.bogo,
        discountPercent: 100,
        buyQty: 5,
        getQty: 1,
        maxQty: 10,
        startDate: DateTime(2025, 10, 24),
        limitType: LimitType.weekly,
      ),
      DiscountRule(
        id: 402,
        name: "Buy each 5 x disc 50%, limit Rp 100k each month",
        type: DiscountType.volume,
        discountPercent: 50,
        buyQty: 5,
        maxAmount: 100000,
        limitType: LimitType.monthly,
      ),
      DiscountRule(
        id: 403,
        name: "Buy 5 x disc 90%, limit Rp 50k each 2 days start from 20 oct",
        type: DiscountType.percent,
        discountPercent: 90,
        buyQty: 5,
        maxAmount: 50000,
        limitType: LimitType.days,
        limitValue: 2,
        startDate: DateTime(2025, 10, 20),
      ),
      DiscountRule(
        id: 501,
        name: "Buy Min 5 Disc 50%",
        type: DiscountType.percent,
        discountPercent: 50,
        buyQty: 5,
        autoApply: false,
      ),
      DiscountRule(
        id: 502,
        name: "Buy Min 7 Disc 70%",
        type: DiscountType.percent,
        discountPercent: 70,
        buyQty: 7,
        autoApply: false,
        restricted: true,
      ),
      DiscountRule(
        id: 503,
        name: "Buy Min Rp 250.000 get disc 10%",
        type: DiscountType.minAmount,
        discountPercent: 10,
        minAmount: 250000,
        autoApply: false,
      ),
      DiscountRule(
        id: 504,
        name: "Buy Min Rp 250.000 get disc Rp 30.000",
        type: DiscountType.minAmount,
        discountAmount: 30000,
        minAmount: 250000,
        autoApply: false,
      ),
      DiscountRule(
        id: 504,
        name: "Buy Min Rp 300.000 get disc 50%",
        type: DiscountType.minAmount,
        discountPercent: 50,
        minAmount: 300000,
        autoApply: false,
        restricted: true,
      ),
      DiscountRule(
        id: 601,
        name: "Buy 2 Pepsi + 1 Chips get 20k",
        type: DiscountType.bundling,
        discountAmount: 20000,
        buyQty: 2,
        getQty: 1,
        autoApply: true,
      ),
      DiscountRule(
        id: 602,
        name: "Buy 5 Cola + 5 Bomb get 50k",
        type: DiscountType.bundling,
        discountAmount: 50000,
        buyQty: 5,
        getQty: 5,
        autoApply: true,
      ),
      DiscountRule(
        id: 701,
        name: "Buy 3 Fanta get 2 cola",
        type: DiscountType.bogo,
        discountPercent: 100,
        buyQty: 3,
        getQty: 2,
      ),
      DiscountRule(
        id: 702,
        name: "Buy 2 Cola get 1 cola",
        type: DiscountType.bogo,
        discountPercent: 100,
        buyQty: 2,
        getQty: 1,
      ),
      DiscountRule(
        id: 703,
        name: "Buy 5 Sprite get 4 cola",
        type: DiscountType.bogo,
        discountPercent: 100,
        buyQty: 5,
        getQty: 4,
      ),
      DiscountRule(
        id: 704,
        name: "Buy 5 Water get 3 Sprite",
        type: DiscountType.bogo,
        discountPercent: 100,
        buyQty: 5,
        getQty: 3,
      ),
      DiscountRule(
        id: 705,
        name: "Buy 8 Water get 4 bomb",
        type: DiscountType.bogo,
        discountPercent: 100,
        buyQty: 8,
        getQty: 4,
      ),
    ];
  }
}
