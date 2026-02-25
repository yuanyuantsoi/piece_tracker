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

  /// 中文展示名
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
        return WorkerType.sewing;
    }
  }
}
