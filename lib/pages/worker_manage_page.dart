// lib/pages/worker_manage_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/worker_type.dart';
import '../state/providers.dart';
import '../state/refresh_tick.dart';
import '../models/worker_row.dart';

class WorkerManagePage extends ConsumerWidget {
  const WorkerManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workersAsync = ref.watch(allWorkersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('工人管理'),
      ),
      body: workersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
        data: (workers) {
          if (workers.isEmpty) {
            return const Center(child: Text('暂无工人'));
          }
          return ListView.separated(
            itemCount: workers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final w = workers[index];
              return _WorkerTile(worker: w);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    WorkerType selectedType = WorkerType.sewing;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('新增工人'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: '姓名',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButton<WorkerType>(
                  value: selectedType,
                  isExpanded: true,
                  items: WorkerType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      selectedType = v;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              final repo = ref.read(workerRepoProvider);
              await repo.addWorker(name, selectedType);

              // 写入后刷新
              ref.read(refreshTickProvider.notifier).state++;

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _WorkerTile extends ConsumerWidget {
  final WorkerRow worker;
  const _WorkerTile({required this.worker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(worker.name),
      subtitle: Text(worker.type.label),
      trailing: Switch(
        value: worker.isActive,
        onChanged: (v) async {
          final repo = ref.read(workerRepoProvider);
          await repo.setWorkerActive(worker.id, v);

          ref.read(refreshTickProvider.notifier).state++;
        },
      ),
    );
  }
}
