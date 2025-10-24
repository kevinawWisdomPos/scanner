import 'package:flutter/material.dart';
import 'package:scanner/utils/db_helper.dart';

class RuleUsage extends StatefulWidget {
  const RuleUsage({super.key});

  @override
  State<RuleUsage> createState() => _RuleUsageState();
}

class _RuleUsageState extends State<RuleUsage> {
  late Future<List<Map<String, dynamic>>> _discountUsage;
  Future<void> deleteDb() async {
    await DBHelper.deleteDb();
  }

  @override
  void initState() {
    super.initState();
    _discountUsage = DBHelper.getDiscountUsage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ROLE USAGE"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              await deleteDb();
            },
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _discountUsage,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No history found.'));
        }

        final history = snapshot.data!;
        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return ListTile(
              title: Text(item['itemName'] ?? 'Unknown Item'),
              subtitle: Text(
                '| ruleId: ${item['ruleId']} \n'
                '| itemId: ${item['itemId']} \n'
                '| totalApplied: ${item['totalApplied']} \n'
                '| amountApplied: ${item['amountApplied']} \n'
                '| start_date: ${item['start_date']} \n'
                '| limit_value: ${item['limit_value']}',
              ),
            );
          },
        );
      },
    );
  }
}
