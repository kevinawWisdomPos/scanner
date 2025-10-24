import 'package:flutter/material.dart';
import 'package:scanner/ui/scanner_page.dart';
import 'package:scanner/utils/db_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.database;
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HardwareScannerPage());
  }
}
