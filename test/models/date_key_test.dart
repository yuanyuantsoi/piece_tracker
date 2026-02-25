import 'package:flutter_test/flutter_test.dart';
import 'package:piece_tracker/models/date_key.dart';

void main() {
  group('DateKey', () {
    test('fromDate/toDate roundtrip', () {
      final d = DateTime(2026, 2, 25);
      final key = DateKey.fromDate(d);
      expect(key, 20260225);

      final back = DateKey.toDate(key);
      expect(back.year, 2026);
      expect(back.month, 2);
      expect(back.day, 25);
    });

    test('monthRange Feb 2026', () {
      final r = DateKey.monthRange(DateTime(2026, 2, 10));
      expect(r.startKey, 20260201);
      expect(r.endKey, 20260228); // 2026 非闰年
    });

    test('monthRange leap year Feb 2024', () {
      final r = DateKey.monthRange(DateTime(2024, 2, 10));
      expect(r.startKey, 20240201);
      expect(r.endKey, 20240229);
    });

    test('yearRange 2026', () {
      final r = DateKey.yearRange(2026);
      expect(r.startKey, 20260101);
      expect(r.endKey, 20261231);
    });
  });
}
