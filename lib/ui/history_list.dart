import 'package:flutter/material.dart';
import 'package:scanner/utils/db_helper.dart';

class HistoryList extends StatefulWidget {
  const HistoryList({super.key});

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  late Future<List<Map<String, dynamic>>> _historyFuture;
  Future<void> deleteDb() async {
    await DBHelper.deleteDb();
  }

  @override
  void initState() {
    super.initState();
    _historyFuture = DBHelper.getHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("History"),
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
      future: _historyFuture,
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
              subtitle: Text('Qty: ${item['qty']} | Date: ${item['date']}'),
            );
          },
        );
      },
    );
  }
}
