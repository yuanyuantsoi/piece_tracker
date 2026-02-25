// lib/models/date_key.dart

class DateKey {
  /// YYYYMMDD，例如 20260225
  static int fromDate(DateTime d) {
    final y = d.year;
    final m = d.month;
    final day = d.day;
    return y * 10000 + m * 100 + day;
  }

  static DateTime toDate(int key) {
    final y = key ~/ 10000;
    final m = (key % 10000) ~/ 100;
    final d = key % 100;
    return DateTime(y, m, d);
  }

  /// 任意一天所在“月”的范围：[startKey, endKey]（闭区间）
  static ({int startKey, int endKey}) monthRange(DateTime anyDay) {
    final start = DateTime(anyDay.year, anyDay.month, 1);
    final nextMonth = DateTime(anyDay.year, anyDay.month + 1, 1);
    final end = nextMonth.subtract(const Duration(days: 1));
    return (startKey: fromDate(start), endKey: fromDate(end));
  }

  /// 某年的范围：[startKey, endKey]（闭区间）
  static ({int startKey, int endKey}) yearRange(int year) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1).subtract(const Duration(days: 1));
    return (startKey: fromDate(start), endKey: fromDate(end));
  }
}
