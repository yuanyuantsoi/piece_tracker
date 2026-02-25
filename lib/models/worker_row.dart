// lib/models/worker_row.dart

import 'worker_type.dart';

class WorkerRow {
  final int id;
  final String name;
  final WorkerType type;
  final bool isActive;

  const WorkerRow({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
  });

  factory WorkerRow.fromMap(Map<String, Object?> map) {
    final id = map['id'];
    final name = map['name'];
    final type = map['type'];
    final isActive = map['is_active'];

    if (id is! int) throw FormatException('WorkerRow.id invalid: $id');
    if (name is! String) throw FormatException('WorkerRow.name invalid: $name');
    if (type is! int) throw FormatException('WorkerRow.type invalid: $type');

    // sqflite 常见：bool 用 0/1 存
    final activeBool = switch (isActive) {
      final int v => v != 0,
      final bool v => v,
      null => true, // v1：缺省兜底 true
      _ => throw FormatException('WorkerRow.is_active invalid: $isActive'),
    };

    return WorkerRow(
      id: id,
      name: name,
      type: WorkerTypeDb.fromDb(type),
      isActive: activeBool,
    );
  }
}
