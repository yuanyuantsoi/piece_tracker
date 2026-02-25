// lib/pages/day_overview_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/worker_row.dart';
import '../models/worker_type.dart';
import '../state/providers.dart';
import 'piece_edit_page.dart';

class DayOverviewPage extends ConsumerWidget {
  const DayOverviewPage({super.key, required this.dateKey});

  final int dateKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeWorkersProvider);
    final allAsync = ref.watch(allWorkersProvider);
    final countsAsync = ref.watch(countsByDateProvider(dateKey));

    return Scaffold(
      appBar: AppBar(
        title: Text('当天概览 $dateKey'),
      ),
      body: _TripleAsyncBody(
        activeAsync: activeAsync,
        allAsync: allAsync,
        countsAsync: countsAsync,
        builder: (activeWorkers, allWorkers, countsMap) {
          // 组装展示集合（冻结规则）
          // 展示 = active + (inactive && countsMap contains workerId)
          final activeIds = activeWorkers.map((w) => w.id).toSet();

          final inactiveWithRecord = allWorkers.where((w) {
            if (activeIds.contains(w.id)) return false;
            return countsMap.containsKey(w.id);
          }).toList();

          final display = <WorkerRow>[
            ...activeWorkers,
            ...inactiveWithRecord,
          ];

          // 按工种分组（制衣/熨衣）
          final sewing = display.where((w) => w.type == WorkerType.sewing).toList();
          final ironing = display.where((w) => w.type == WorkerType.ironing).toList();

          return ListView(
            children: [
              _Section(
                title: WorkerType.sewing.label,
                workers: sewing,
                countsMap: countsMap,
                onTapWorker: (w) => _openEdit(
                  context,
                  dateKey: dateKey,
                  initialWorkerId: w.id,
                  orderedWorkerIds: display.map((e) => e.id).toList(), // 按 id asc 的链
                ),
              ),
              _Section(
                title: WorkerType.ironing.label,
                workers: ironing,
                countsMap: countsMap,
                onTapWorker: (w) => _openEdit(
                  context,
                  dateKey: dateKey,
                  initialWorkerId: w.id,
                  orderedWorkerIds: display.map((e) => e.id).toList(),
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  void _openEdit(
    BuildContext context, {
    required int dateKey,
    required int initialWorkerId,
    required List<int> orderedWorkerIds,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PieceEditPage(
          dateKey: dateKey,
          initialWorkerId: initialWorkerId,
          orderedWorkerIds: orderedWorkerIds,
        ),
      ),
    );
  }
}

/// 把三个 AsyncValue 合并处理（避免 when 嵌套地狱）
class _TripleAsyncBody extends StatelessWidget {
  const _TripleAsyncBody({
    required this.activeAsync,
    required this.allAsync,
    required this.countsAsync,
    required this.builder,
  });

  final AsyncValue<List<WorkerRow>> activeAsync;
  final AsyncValue<List<WorkerRow>> allAsync;
  final AsyncValue<Map<int, int>> countsAsync;

  final Widget Function(
    List<WorkerRow> activeWorkers,
    List<WorkerRow> allWorkers,
    Map<int, int> countsMap,
  ) builder;

  @override
  Widget build(BuildContext context) {
    if (activeAsync.isLoading || allAsync.isLoading || countsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final err = activeAsync.error ?? allAsync.error ?? countsAsync.error;
    if (err != null) {
      return Center(child: Text('错误: $err'));
    }

    final active = activeAsync.value ?? const <WorkerRow>[];
    final all = allAsync.value ?? const <WorkerRow>[];
    final counts = countsAsync.value ?? const <int, int>{};

    return builder(active, all, counts);
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.workers,
    required this.countsMap,
    required this.onTapWorker,
  });

  final String title;
  final List<WorkerRow> workers;
  final Map<int, int> countsMap;
  final void Function(WorkerRow w) onTapWorker;

  @override
  Widget build(BuildContext context) {
    if (workers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...workers.map((w) {
          final count = countsMap[w.id] ?? 0;
          return ListTile(
            title: Text(w.name),
            trailing: Text(
              '$count',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            onTap: () => onTapWorker(w),
          );
        }),
      ],
    );
  }
}
