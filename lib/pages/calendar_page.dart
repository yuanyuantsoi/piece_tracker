import 'package:flutter/material.dart';
import '../data/sqlite_db.dart';
import '../repos/entry_repo.dart';
import '../repos/export_service.dart';
import '../repos/worker_repo.dart';
import '../models/date_key.dart';
import '../models/worker_type.dart';

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

  Future<String> _repoSelfCheck() async {
  final db = await SqliteDb.open();
  final repo = EntryRepo(db);

  final dateKey = DateKey.fromDate(DateTime.now());

  // 先确保干净
  await repo.setCount(dateKey, 1, 0);

  // upsert insert
  await repo.setCount(dateKey, 1, 12);
  var m = await repo.getCountsByDate(dateKey);
  final a = m[1];

  // upsert update
  await repo.setCount(dateKey, 1, 34);
  m = await repo.getCountsByDate(dateKey);
  final b = m[1];

  // delete
  await repo.setCount(dateKey, 1, 0);
  m = await repo.getCountsByDate(dateKey);
  final c = m.containsKey(1);

  return 'insert=$a update=$b deleted=${!c}';
}

Future<String> _workerRepoSelfCheck() async {
  final db = await SqliteDb.open();
  final repo = WorkerRepo(db);

  // 调试自检：清空 workers（只在 v1 开发阶段用）
  await db.delete('workers');

  final id1 = await repo.addWorker('张三', WorkerType.sewing);
  final id2 = await repo.addWorker('李四', WorkerType.ironing);

  final all = await repo.listAllByIdAsc();
  final active1 = await repo.listActiveByIdAsc();

  await repo.setWorkerActive(id2, false);

  final active2 = await repo.listActiveByIdAsc();

  return 'ids=[$id1,$id2] all=${all.length} active(before)=${active1.length} active(after)=${active2.length}';
}

Future<String> _exportSelfCheck() async {
  final db = await SqliteDb.open();
  final workerRepo = WorkerRepo(db);
  final entryRepo = EntryRepo(db);
  final exportService = ExportService(db);

  // 调试自检：清空（仅开发阶段）
  await db.delete('piece_entries');
  await db.delete('workers');

  final w1 = await workerRepo.addWorker('张三', WorkerType.sewing);
  final w2 = await workerRepo.addWorker('李四', WorkerType.ironing);

  final todayKey = DateKey.fromDate(DateTime.now());
  final yesterdayKey = DateKey.fromDate(DateTime.now().subtract(const Duration(days: 1)));

  await entryRepo.setCount(yesterdayKey, w1, 10);
  await entryRepo.setCount(yesterdayKey, w2, 20);
  await entryRepo.setCount(todayKey, w1, 30);

  final range = DateKey.monthRange(DateTime.now());
  final rows = await exportService.queryRows(range.startKey, range.endKey);
  final csv = exportService.buildCsv(rows);

  // 只展示前 N 行，避免弹窗太长
  final lines = csv.split('\n');
  final preview = lines.take(8).join('\n');
  return 'rows=${rows.length}\n$preview';
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('计件助手')),
      //-------------
           body: Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ElevatedButton(
        onPressed: () async {
          try {
            final msg = await _dbSelfCheck();
            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('DB 自检结果'),
                content: Text(msg),
              ),
            );
          } catch (e) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('DB 错误'),
                content: Text(e.toString()),
              ),
            );
          }
        },
        child: const Text('DB 自检'),
      ),

      const SizedBox(height: 16),

      ElevatedButton(
        onPressed: () async {
          try {
            final msg = await _exportSelfCheck();
            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Export 自检结果'),
                content: SingleChildScrollView(child: Text(msg)),
              ),
            );
          } catch (e) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Export 自检失败'),
                content: Text(e.toString()),
              ),
            );
          }
        },
        child: const Text('Export 自检'),
      ),
    ],
  ),
),

      //-------------


    );
  }
}
