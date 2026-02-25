import 'package:flutter_test/flutter_test.dart';
import 'package:piece_tracker/models/worker_type.dart';

void main() {
  group('WorkerType', () {
    test('toDb/fromDb mapping', () {
      expect(WorkerType.sewing.toDb(), 0);
      expect(WorkerType.ironing.toDb(), 1);

      expect(WorkerTypeDb.fromDb(0), WorkerType.sewing);
      expect(WorkerTypeDb.fromDb(1), WorkerType.ironing);
    });

    test('label', () {
      expect(WorkerType.sewing.label, '制衣');
      expect(WorkerType.ironing.label, '熨衣');
    });

    test('fromDb fallback on unknown', () {
      expect(WorkerTypeDb.fromDb(999), WorkerType.sewing);
    });
  });
}
