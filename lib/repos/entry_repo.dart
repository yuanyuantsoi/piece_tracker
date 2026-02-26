// lib/repos/entry_repo.dart

import 'package:sqflite/sqflite.dart';

class EntryRepo {
  final Database db;
  EntryRepo(this.db);

  /// 只返回“有记录的” workerId -> count
  /// v1.0.1：用于 DayOverview/PieceEdit 补 0（UI 用 ??0）
  Future<Map<int, int>> getCountsByDate(int dateKey) async {
    final rows = await db.query(
      'piece_entries',
      columns: const ['worker_id', 'count'],
      where: 'date_key = ?',
      whereArgs: [dateKey],
    );

    final map = <int, int>{};
    for (final r in rows) {
      final wid = r['worker_id'] as int;
      final cnt = r['count'] as int;
      map[wid] = cnt;
    }
    return map;
  }

  /// 写入口：0 不存储
  /// - count <= 0：delete
  /// - count > 0：upsert（ON CONFLICT(date_key, worker_id) DO UPDATE）
  Future<void> setCount(int dateKey, int workerId, int count) async {
    if (count <= 0) {
      await db.delete(
        'piece_entries',
        where: 'date_key = ? AND worker_id = ?',
        whereArgs: [dateKey, workerId],
      );
      return;
    }

    // upsert
    await db.rawInsert(
      '''
INSERT INTO piece_entries(date_key, worker_id, count)
VALUES(?, ?, ?)
ON CONFLICT(date_key, worker_id) DO UPDATE SET
  count = excluded.count;
''',
      [dateKey, workerId, count],
    );
  }

Future<Set<int>> getMarkedDateKeysInRange(int startKey, int endKey) async {
  final rows = await db.rawQuery(
    '''
SELECT DISTINCT date_key
FROM piece_entries
WHERE date_key BETWEEN ? AND ?
''',
    [startKey, endKey],
  );

  return rows.map((r) => r['date_key'] as int).toSet();
}




}
