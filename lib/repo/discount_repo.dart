import 'package:scanner/models/discount.dart';
import 'package:scanner/models/discount_usage.dart';
import 'package:scanner/utils/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class DiscountRepo {
  Future<List<Map<String, dynamic>>> getDiscountUsageLast30Days() async {
    final db = await DBHelper.database;
    final now = DateTime.now();
    final last30 = now.subtract(const Duration(days: 30));

    final result = await db.query(
      'discount_usage',
      where: 'date >= ?',
      whereArgs: [last30.toIso8601String()],
      orderBy: 'date DESC',
    );

    return result;
  }

  static Future<List<DiscountUsage>> getFilteredDiscountUsages(
    Database db,
    List<DiscountRule> rules,
    DateTime now,
  ) async {
    final last30 = now.subtract(const Duration(days: 30));

    final raw = await db.query('discount_usage', where: 'date >= ?', whereArgs: [last30.toIso8601String()]);

    final usages = raw.map((e) => DiscountUsage.fromMap(e)).toList();
    final result = <DiscountUsage>[];

    // 2️⃣ Filter and group by (ruleId, itemId)
    for (final rule in rules) {
      // get all usages for this rule
      final ruleUsages = usages.where((u) => u.ruleId == rule.id).toList();
      if (ruleUsages.isEmpty) continue;

      // determine active time window
      DateTime start;
      DateTime end;

      // filter start and end date
      switch (rule.limitType) {
        case LimitType.daily:
          start = DateTime(now.year, now.month, now.day);
          end = start.add(const Duration(days: 1));
          break;

        case LimitType.weekly:
          final monday = now.subtract(Duration(days: now.weekday - 1));
          start = DateTime(monday.year, monday.month, monday.day);
          end = start.add(const Duration(days: 7));
          break;

        case LimitType.monthly:
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 1);
          break;

        case LimitType.days:
          if (rule.startDate == null || rule.limitValue == null) continue;
          final diff = now.difference(rule.startDate!).inDays;
          final cycle = (diff / rule.limitValue!).floor();
          start = rule.startDate!.add(Duration(days: cycle * rule.limitValue!));
          end = start.add(Duration(days: rule.limitValue!));
          break;

        default:
          start = DateTime(2000);
          end = DateTime(9999);
          break;
      }

      final filtered = ruleUsages.where((u) => u.date.isAfter(start) && u.date.isBefore(end));

      final grouped = <String, List<DiscountUsage>>{};
      for (final u in filtered) {
        final key = '${u.ruleId}-${u.itemId}';
        grouped.putIfAbsent(key, () => []).add(u);
      }

      for (final entries in grouped.entries) {
        final groupedUsages = entries.value;
        final first = groupedUsages.first;
        final totalSum = groupedUsages.fold<int>(0, (sum, u) => sum + u.totalApplied);

        result.add(
          DiscountUsage(
            id: first.id,
            ruleId: first.ruleId,
            itemId: first.itemId,
            date: now,
            totalApplied: totalSum,
            startDate: start,
            limitValue: rule.limitValue,
          ),
        );
      }
    }

    return result;
  }
}
