import 'package:flutter/material.dart';
import 'package:scanner/models/discount.dart';

Future<DiscountRule?> showManualDiscountDialog(BuildContext context) async {
  final manualDiscounts = DiscountRule.discountRules().where((rule) => rule.autoApply == false).toList();

  return showDialog<DiscountRule>(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, offset: const Offset(0, 4), blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Manual Discounts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // --- Discount List ---
              if (manualDiscounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("No manual discounts available.", style: TextStyle(color: Colors.grey)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: manualDiscounts.length,
                    itemBuilder: (context, index) {
                      final rule = manualDiscounts[index];
                      return _discountRuleCard(context, rule);
                    },
                  ),
                ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

Widget _discountRuleCard(BuildContext context, DiscountRule rule) {
  Color badgeColor = rule.restricted ? Colors.redAccent : Colors.blueAccent;
  String badgeText = rule.restricted ? "RESTRICTED" : "MANUAL";

  String detail = '';
  switch (rule.type) {
    case DiscountType.percent:
      detail = "Discount ${rule.discountPercent?.toStringAsFixed(0)}%";
      break;
    case DiscountType.amount:
      detail = "Discount Rp ${rule.discountAmount?.toStringAsFixed(0)}";
      break;
    case DiscountType.bogo:
      detail = "Buy ${rule.buyQty} Get ${rule.getQty}";
      break;
    case DiscountType.volume:
      detail = "Every ${rule.buyQty} pcs → ${rule.discountPercent?.toStringAsFixed(0)}% off";
      break;
    case DiscountType.upto:
      detail = "Up to ${rule.discountPercent?.toStringAsFixed(0)}%";
      break;
  }

  return InkWell(
    onTap: () => Navigator.pop(context, rule),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Left icon / emoji
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: badgeColor.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(rule.restricted ? Icons.lock_outline : Icons.discount_outlined, color: badgeColor, size: 22),
          ),
          const SizedBox(width: 12),

          // Middle: rule info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),

          // Right badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
            child: Text(
              badgeText,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}
