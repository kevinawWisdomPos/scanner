class DiscountUsage {
  final int id;
  final int ruleId;
  final int itemId;
  final DateTime date;
  final int totalApplied;
  final double amountApplied;
  final DateTime? startDate;
  final int? limitValue;

  DiscountUsage({
    required this.id,
    required this.ruleId,
    required this.itemId,
    required this.date,
    required this.totalApplied,
    required this.amountApplied,
    this.startDate,
    this.limitValue,
  });

  factory DiscountUsage.fromMap(Map<String, dynamic> map) {
    return DiscountUsage(
      id: map['id'],
      ruleId: map['ruleId'],
      itemId: map['itemId'],
      date: DateTime.parse(map['date']),
      totalApplied: map['totalApplied'],
      amountApplied: map['amountApplied'],
      startDate: map['start_date'] != null ? DateTime.tryParse(map['start_date']) : null,
      limitValue: map['limit_value'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'ruleId': ruleId,
    'itemId': itemId,
    'date': date.toIso8601String(),
    'totalApplied': totalApplied,
    'amountApplied': amountApplied,
    'start_date': startDate?.toIso8601String(),
    'limit_value': limitValue,
  };
}
