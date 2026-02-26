// lib/state/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../data/sqlite_db.dart';
import '../repos/worker_repo.dart';
import '../repos/entry_repo.dart';
import '../repos/export_service.dart';
import '../models/worker_row.dart';
import '../models/date_key.dart';

import 'refresh_tick.dart';

/// DB 单例 Provider
final dbProvider = FutureProvider<Database>((ref) async {
  return SqliteDb.open();
});

/// repos / services
final workerRepoProvider = Provider<WorkerRepo>((ref) {
  final db = ref.watch(dbProvider).requireValue;
  return WorkerRepo(db);
});

final entryRepoProvider = Provider<EntryRepo>((ref) {
  final db = ref.watch(dbProvider).requireValue;
  return EntryRepo(db);
});

final exportServiceProvider = Provider<ExportService>((ref) {
  final db = ref.watch(dbProvider).requireValue;
  return ExportService(db);
});

/// workers：全量（WorkerManage + DayOverview 的“补停用但有记录”）
final allWorkersProvider = FutureProvider<List<WorkerRow>>((ref) async {
  ref.watch(refreshTickProvider); // 任何写入 tick++，强制刷新
  final repo = ref.watch(workerRepoProvider);
  return repo.listAllByIdAsc();
});

/// workers：仅启用（DayOverview 主列表）
final activeWorkersProvider = FutureProvider<List<WorkerRow>>((ref) async {
  ref.watch(refreshTickProvider);
  final repo = ref.watch(workerRepoProvider);
  return repo.listActiveByIdAsc();
});

/// 某天的计件 map（只含有记录项）
final countsByDateProvider =
    FutureProvider.family<Map<int, int>, int>((ref, int dateKey) async {
  ref.watch(refreshTickProvider);
  final repo = ref.watch(entryRepoProvider);
  return repo.getCountsByDate(dateKey);
});


/// 日历打点：当前月份范围内哪些 dateKey 有记录
final markedDateKeysByMonthProvider =
    FutureProvider.family<Set<int>, DateTime>((ref, DateTime focusedDay) async {
  ref.watch(refreshTickProvider); // 写入 tick++ 后刷新

  final repo = ref.watch(entryRepoProvider);
  final range = DateKey.monthRange(focusedDay);

  return repo.getMarkedDateKeysInRange(range.startKey, range.endKey);
});
