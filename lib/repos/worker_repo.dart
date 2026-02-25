// lib/repos/worker_repo.dart

import 'package:sqflite/sqflite.dart';
import '../models/worker_row.dart';
import '../models/worker_type.dart';

class WorkerRepo {
  final Database db;
  WorkerRepo(this.db);

  /// WorkerManage 用：全部工人，按 id 升序
  Future<List<WorkerRow>> listAllByIdAsc() async {
    final rows = await db.query(
      'workers',
      columns: const ['id', 'name', 'type', 'is_active'],
      orderBy: 'id ASC',
    );
    return rows.map(WorkerRow.fromMap).toList();
  }

  /// DayOverview 用：启用工人，按 id 升序
  Future<List<WorkerRow>> listActiveByIdAsc() async {
    final rows = await db.query(
      'workers',
      columns: const ['id', 'name', 'type', 'is_active'],
      where: 'is_active = 1',
      orderBy: 'id ASC',
    );
    return rows.map(WorkerRow.fromMap).toList();
  }

  /// 新增工人：返回新 workerId（便于后续立刻使用）
  Future<int> addWorker(String name, WorkerType type) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('name cannot be empty');
    }

    final id = await db.insert(
      'workers',
      {
        'name': trimmed,
        'type': type.toDb(),
        'is_active': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return id;
  }

  /// 启用/停用工人（不删除）
  Future<void> setWorkerActive(int workerId, bool active) async {
    await db.update(
      'workers',
      {'is_active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [workerId],
    );
  }
}
