import 'package:flutter_test/flutter_test.dart';
import 'package:piece_tracker/models/worker_row.dart';
import 'package:piece_tracker/models/worker_type.dart';

void main() {
  group('WorkerRow.fromMap', () {
    test('parse int is_active (1/0)', () {
      final row1 = WorkerRow.fromMap({
        'id': 1,
        'name': '张三',
        'type': 0,
        'is_active': 1,
      });
      expect(row1.isActive, true);
      expect(row1.type, WorkerType.sewing);

      final row0 = WorkerRow.fromMap({
        'id': 2,
        'name': '李四',
        'type': 1,
        'is_active': 0,
      });
      expect(row0.isActive, false);
      expect(row0.type, WorkerType.ironing);
    });

    test('parse bool is_active', () {
      final row = WorkerRow.fromMap({
        'id': 3,
        'name': '王五',
        'type': 0,
        'is_active': true,
      });
      expect(row.isActive, true);
    });

    test('missing is_active defaults to true (v1)', () {
      final row = WorkerRow.fromMap({
        'id': 4,
        'name': '赵六',
        'type': 1,
        // no is_active
      });
      expect(row.isActive, true);
    });

    test('throws on invalid types', () {
      expect(
        () => WorkerRow.fromMap({
          'id': 'bad',
          'name': 'x',
          'type': 0,
          'is_active': 1,
        }),
        throwsFormatException,
      );
    });
  });
}
