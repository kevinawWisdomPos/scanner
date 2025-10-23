import 'package:flutter/material.dart';

enum DiscountType { percent, volume, bogo, amount, upto }

class DiscountRule {
  final int id;
  final String name;
  final DiscountType type; // "BOGO", "PERCENT", "VOLUME", "AMOUNT", "UP TO"
  final double? discountPercent;
  final double? discountAmount;
  final int? buyQty;
  final int? getQty;
  final bool autoApply;
  final int? maxQty;
  final double? maxAmount;

  final List<int>? weekDays;
  final List<String>? startTimes;
  final int? durationInMinute;
  final int? date;

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
    this.maxAmount,
    this.weekDays,
    this.startTimes,
    this.durationInMinute = 30,
    this.date,
    this.restricted = false,
  });

  bool isActiveNow(DateTime now) {
    final currentWeekDay = now.weekday; // 1 = Monday ... 7 = Sunday
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    bool matchesDay = true;
    bool matchesDate = true;
    bool matchesTime = true;

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

        // ✅ Convert duration to minutes (default 60)
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
        id: 201,
        name: "Buy each 5 item get 40.000",
        type: DiscountType.amount,
        discountAmount: 40000,
        buyQty: 5,
      ),
      DiscountRule(
        id: 202,
        name: "beli per 5 fanta di hari ini jam 13:30 - 14:30 & 20:30 - 21:30 dapat diskon 50rb",
        type: DiscountType.amount,
        discountAmount: 50000,

        startTimes: ["13:30", "20:30"],
        buyQty: 5,
        maxQty: 2,
      ),
      DiscountRule(
        id: 203,
        name: "beli per 5 fanta di tanggal 24 dapat diskon 55rb",
        type: DiscountType.amount,
        discountAmount: 55000,
        date: 24,
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
        name: "Buy 2 item get 7000",
        type: DiscountType.amount,
        discountAmount: 7000,
        buyQty: 2,
        maxQty: 12,
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
    ];
  }
}
