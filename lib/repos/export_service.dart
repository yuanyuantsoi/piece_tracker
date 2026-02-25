// lib/repos/export_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

import 'package:sqflite/sqflite.dart';
import '../models/export_row.dart';
import '../models/worker_type.dart';

class ExportService {
  final Database db;
  ExportService(this.db);

  /// 查询导出行（只导出有记录的项）
  /// 口径冻结：
  /// - piece_entries JOIN workers
  /// - date_key BETWEEN startKey AND endKey
  /// - ORDER BY date_key ASC, workers.id ASC
  Future<List<ExportRow>> queryRows(int startKey, int endKey) async {
    final rows = await db.rawQuery(
      '''
SELECT
  e.date_key AS date_key,
  w.name     AS worker_name,
  w.type     AS worker_type,
  e.count    AS count
FROM piece_entries e
JOIN workers w ON w.id = e.worker_id
WHERE e.date_key BETWEEN ? AND ?
ORDER BY e.date_key ASC, w.id ASC;
''',
      [startKey, endKey],
    );

    return rows.map((r) {
      final dateKey = r['date_key'] as int;
      final workerName = r['worker_name'] as String;
      final workerType = WorkerTypeDb.fromDb(r['worker_type'] as int);
      final count = r['count'] as int;

      return ExportRow(
        dateKey: dateKey,
        workerName: workerName,
        workerType: workerType,
        count: count,
      );
    }).toList();
  }

  /// CSV 构建（UI 不拼 CSV）
  /// v1.0.1：最小字段集
  String buildCsv(List<ExportRow> rows) {
    final b = StringBuffer();

    // header
    b.writeln(_csvLine(const ['dateKey', 'workerName', 'workerType', 'count']));

    for (final r in rows) {
      b.writeln(_csvLine([
        r.dateKey.toString(),
        r.workerName,
        r.workerType.label,
        r.count.toString(),
      ]));
    }
    return b.toString();
  }

  //--------------------------
  /// 真正落盘导出：写入 App 文档目录，返回文件绝对路径
  /// - 默认加 UTF-8 BOM，Excel 打开中文更稳
  Future<String> exportCsvToFile({
    required int startKey,
    required int endKey,
    String? fileName, // 可自定义
    bool withBom = true,
  }) async {
    final rows = await queryRows(startKey, endKey);
    final csv = buildCsv(rows);

    final dir = await getApplicationDocumentsDirectory();

    final safeName = (fileName == null || fileName.trim().isEmpty)
        ? 'piece_${startKey}_to_${endKey}.csv'
        : fileName.trim();

    final path = '${dir.path}/$safeName';
    final f = File(path);

    if (withBom) {
      // UTF-8 BOM: EF BB BF
      final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(csv)];
      await f.writeAsBytes(bytes, flush: true);
    } else {
      await f.writeAsString(csv, encoding: utf8, flush: true);
    }

    return path;
  }
  //---------------------------

  /// 简单 CSV 转义：包含逗号/引号/换行时加双引号，并把内部引号变成 ""。
  String _csvEscape(String s) {
    final needsQuote =
        s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r');
    if (!needsQuote) return s;
    final escaped = s.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _csvLine(List<String> cols) {
    return cols.map(_csvEscape).join(',');
  }
}
