// lib/models/worker_type.dart

enum WorkerType { sewing, ironing }

extension WorkerTypeDb on WorkerType {
  /// DB 映射：0=sewing, 1=ironing
  int toDb() {
    switch (this) {
      case WorkerType.sewing:
        return 0;
      case WorkerType.ironing:
        return 1;
    }
  }

  String get label {
    switch (this) {
      case WorkerType.sewing:
        return '制衣';
      case WorkerType.ironing:
        return '熨衣';
    }
  }

  static WorkerType fromDb(int v) {
    switch (v) {
      case 0:
        return WorkerType.sewing;
      case 1:
        return WorkerType.ironing;
      default:
        // v1.0.1：遇到脏数据直接兜底为 sewing，避免 UI 崩
        return WorkerType.sewing;
    }
  }
}
