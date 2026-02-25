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

          // 合计：仅统计 display 集合（和 UI 展示一致）
final sewingTotal = display
    .where((w) => w.type == WorkerType.sewing)
    .fold<int>(0, (sum, w) => sum + (countsMap[w.id] ?? 0));

final ironingTotal = display
    .where((w) => w.type == WorkerType.ironing)
    .fold<int>(0, (sum, w) => sum + (countsMap[w.id] ?? 0));
          // 按工种分组（制衣/熨衣）
          final sewing =
              display.where((w) => w.type == WorkerType.sewing).toList();
          final ironing =
              display.where((w) => w.type == WorkerType.ironing).toList();

          return Stack(
            children: [
              ListView(
                physics: const ClampingScrollPhysics(), // 去掉弹跳
                padding: const EdgeInsets.only(bottom: 88), // 给底部合计栏留空间
                children: [
                  _Section(
                    title: WorkerType.sewing.label,
                    workers: sewing,
                    countsMap: countsMap,
                    onTapWorker: (w) => _openEdit(
                      context,
                      dateKey: dateKey,
                      initialWorkerId: w.id,
                      orderedWorkerIds:
                          display.map((e) => e.id).toList(), // 按 id asc 的链
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
                ],
              ),

              // 底部合计栏
              Align(
                alignment: Alignment.bottomCenter,
                child: _TotalBar(
                    sewingTotal: sewingTotal,
                    ironingTotal: ironingTotal),
              ),
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

//--------------------------------------

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

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final dividerColor = Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== 现代化标题（浅色块）=====
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.08), // ✅ 很浅的主色
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primary, // 主色文字
            ),
          ),
        ),

        Container(height: 0.6, color: dividerColor),

        // ===== 内容区 =====
        Container(
          color: Colors.white,
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: workers.length,
            separatorBuilder: (_, __) => Container(
              height: 0.6,
              color: dividerColor,
              margin: const EdgeInsets.only(left: 16),
            ),
            //-------------------------------
            itemBuilder: (context, i) {
              final w = workers[i];
              final count = countsMap[w.id] ?? 0;

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                visualDensity: const VisualDensity(vertical: 0), // ✅ 更高
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        w.name,
                        style: const TextStyle(
                          fontSize: 18, // ✅ 和数字一样大
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 18, // ✅ 同级
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                onTap: () => onTapWorker(w),
              );
            },
          ),
        ),
      ],
    );
  }
}

//--------------
class _TotalBar extends StatelessWidget {
  const _TotalBar({
    required this.sewingTotal,
    required this.ironingTotal,
  });

  final int sewingTotal;
  final int ironingTotal;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(child: _TotalChip(label: '制衣合计', value: sewingTotal)),
              const SizedBox(width: 12),
              Expanded(child: _TotalChip(label: '熨衣合计', value: ironingTotal)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: primary.withOpacity(0.06),
        border: Border.all(color: primary.withOpacity(0.18), width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
