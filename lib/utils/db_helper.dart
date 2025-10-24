import 'dart:developer';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database? _db;
  static const dbName = "cashier_app.db";

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  static Future<void> _createDB(Database db, int version) async {
    // Table for purchase history (for daily/weekly/monthly rule checking)
    await db.execute('''
      CREATE TABLE purchase_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemId INTEGER,
        itemName TEXT,
        qty INTEGER,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE discount_usage(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ruleId INTEGER,
        itemId INTEGER,
        date TEXT,                 -- date of usage
        totalApplied INTEGER,      -- how many times applied
        amountApplied DOUBLE,      -- how many times applied
        start_date TEXT,           -- when the limit started (for daily/weekly/monthly)
        limit_value INTEGER       -- the limit count 
      )
    ''');
  }

  static Future<void> deleteDb() async {
    log("LOADING");
    await deleteDatabase('${await getDatabasesPath()}/$dbName');
    log("DELETE SUCCESS");
  }

  static Future<void> saveDiscountUsage(int ruleId, int totalApplied) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert('discount_usage', {'ruleId': ruleId, 'date': now, 'totalApplied': totalApplied});
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await database;
    final result = await db.query('purchase_history', orderBy: 'date DESC');
    return result;
  }

  static Future<List<Map<String, dynamic>>> getDiscountUsage() async {
    final db = await database;
    final result = await db.query('discount_usage');
    return result;
  }
}
