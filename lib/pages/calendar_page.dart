import 'package:flutter/material.dart';
import '../data/sqlite_db.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  Future<String> _dbSelfCheck() async {
    final db = await SqliteDb.open();
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;",
    );
    final names = tables.map((e) => e['name'] as String).toList();
    return 'tables: ${names.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('计件助手')),
      body: Center(
        child: ElevatedButton(
//--------------------------------------------------
                onPressed: () async {
    try {
        final msg = await _dbSelfCheck();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('DB error: $e')),
        );
    }
    },
          child: const Text('DB 自检'),
        ),
      ),
    );
  }
}
