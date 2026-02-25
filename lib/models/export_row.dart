// lib/models/export_row.dart

import 'worker_type.dart';

class ExportRow {
  final int dateKey; // YYYYMMDD
  final String workerName;
  final WorkerType workerType;
  final int count;

  const ExportRow({
    required this.dateKey,
    required this.workerName,
    required this.workerType,
    required this.count,
  });
}
