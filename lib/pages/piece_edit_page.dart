// lib/pages/piece_edit_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/worker_row.dart';
import '../models/worker_type.dart';
import '../state/providers.dart';
import '../state/refresh_tick.dart';

class PieceEditPage extends ConsumerStatefulWidget {
  const PieceEditPage({
    super.key,
    required this.dateKey,
    required this.initialWorkerId,
    required this.orderedWorkerIds,
  });

  final int dateKey;
  final int initialWorkerId;
  final List<int> orderedWorkerIds;

  @override
  ConsumerState<PieceEditPage> createState() => _PieceEditPageState();
}

class _PieceEditPageState extends ConsumerState<PieceEditPage> {
  late int _index;

  // 当前输入（字符串）
  String _input = '';

  // 当前工人的“加载值”（用于 dirty 判断）
  int _loadedValue = 0;

  // 用于判断是否已为“当前 worker”初始化过 input
  int? _inputBoundWorkerId;

  @override
  void initState() {
    super.initState();
    final idx = widget.orderedWorkerIds.indexOf(widget.initialWorkerId);
    _index = idx >= 0 ? idx : 0;
  }

  int get _currentWorkerId => widget.orderedWorkerIds[_index];

  int _parseInput() {
    if (_input.isEmpty) return 0;
    return int.tryParse(_input) ?? 0;
  }

  bool get _isDirty => _parseInput() != _loadedValue;

  bool get _isFirst => _index == 0;
  bool get _isLast => _index == widget.orderedWorkerIds.length - 1;

  @override
  Widget build(BuildContext context) {
    final allWorkersAsync = ref.watch(allWorkersProvider);
    final countsAsync = ref.watch(countsByDateProvider(widget.dateKey));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.dateKey} 录入'),
      ),
      body: allWorkersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
        data: (allWorkers) {
          final byId = {for (final w in allWorkers) w.id: w};

          return countsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('错误: $e')),
            data: (countsMap) {
              final workerId = _currentWorkerId;
              final worker = byId[workerId];

              final currentValue = countsMap[workerId] ?? 0;

              // 当切换到新 worker 时，把 input 初始化为 DB 当前值
              if (_inputBoundWorkerId != workerId) {
                _inputBoundWorkerId = workerId;
                _loadedValue = currentValue;
                _input = currentValue == 0 ? '' : currentValue.toString();
              }

              return PopScope(
                canPop: false,
                onPopInvoked: (didPop) async {
                  if (didPop) return;
                  final ok = await _confirmLeave(context);
                  if (ok && context.mounted) Navigator.of(context).pop();
                },
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    _Header(worker: worker, workerId: workerId),

                    const SizedBox(height: 12),

                    Text(
                      _input.isEmpty ? '0' : _input,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (_isDirty)
                      const Text(
                        '未保存',
                        style: TextStyle(fontSize: 12),
                      ),

                    const SizedBox(height: 12),

                        // ✅ 键盘占据中间剩余空间（更大）
                    Expanded(
                           // flex: 20, //键盘高度权重
                      child: _Keypad(
                        onDigit: _append,
                        onClear: _clear,
                        onBackspace: _backspace,
                      ),
                    ),

                    // ✅ 底部按钮：两行布局
                  Padding(
  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
  child: Column(
    mainAxisSize: MainAxisSize.min, // ✅ 关键：按内容高度，不要撑满
    children: [
      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isFirst ? null : () => _goPrev(context),
              child: const Text('上一个'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLast ? null : () => _goNextSkip(context),
              child: const Text('下一个（跳过）'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _saveAndNext(context),
          child: Text(_isLast ? '保存并返回' : '保存并下一个'),
        ),
      ),
    ],
  ),
),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- 输入 ---
  void _append(String d) {
    setState(() {
      // 防止无意义前导 0（但允许输入 0）
      if (_input == '0') _input = '';
      _input += d;
    });
  }

  void _clear() {
    setState(() => _input = '');
  }

  void _backspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  // --- 导航：上一个/下一个跳过 ---
  Future<void> _goPrev(BuildContext context) async {
    if (_isFirst) return;
    final ok = await _confirmDiscardOrSave(context, nextIndex: _index - 1);
    if (!ok) return;
  }

  Future<void> _goNextSkip(BuildContext context) async {
    if (_isLast) return;
    final ok = await _confirmDiscardOrSave(context, nextIndex: _index + 1);
    if (!ok) return;
  }

  /// 返回 true 代表已经处理并切换到了 nextIndex（或已经保存并切换）
  Future<bool> _confirmDiscardOrSave(BuildContext context,
      {required int nextIndex}) async {
    if (!_isDirty) {
      setState(() {
        _index = nextIndex;
        _inputBoundWorkerId = null; // 强制下一帧按 DB 初始化
      });
      return true;
    }

    final choice = await showDialog<_DirtyChoice>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('未保存'),
        content: const Text('当前修改尚未保存，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _DirtyChoice.cancel),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _DirtyChoice.discard),
            child: const Text('丢弃'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _DirtyChoice.save),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (choice == null || choice == _DirtyChoice.cancel) return false;

    if (choice == _DirtyChoice.save) {
      await _saveOnly();
    }

    if (!mounted) return false;
    setState(() {
      _index = nextIndex;
      _inputBoundWorkerId = null;
    });
    return true;
  }

  // --- 保存 ---
  Future<void> _saveOnly() async {
    final repo = ref.read(entryRepoProvider);
    final v = _parseInput();
    await repo.setCount(widget.dateKey, _currentWorkerId, v);
    ref.read(refreshTickProvider.notifier).state++;

    // 保存后，当前页的“加载值”应当更新为 v（避免一直 dirty）
    _loadedValue = v;
  }

  Future<void> _saveAndNext(BuildContext context) async {
    await _saveOnly();

    if (!mounted) return;

    if (_isLast) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _index++;
      _inputBoundWorkerId = null;
    });
  }

  // --- 离开页（返回键/左上角返回） ---
  Future<bool> _confirmLeave(BuildContext context) async {
    if (!_isDirty) return true;

    final choice = await showDialog<_DirtyChoice>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('未保存'),
        content: const Text('要离开吗？未保存的修改将丢失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _DirtyChoice.cancel),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _DirtyChoice.discard),
            child: const Text('丢弃'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _DirtyChoice.save),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (choice == _DirtyChoice.save) {
      await _saveOnly();
      return true;
    }
    if (choice == _DirtyChoice.discard) return true;
    return false;
  }
}

enum _DirtyChoice { cancel, discard, save }

class _Header extends StatelessWidget {
  const _Header({required this.worker, required this.workerId});

  final WorkerRow? worker;
  final int workerId;

  @override
  Widget build(BuildContext context) {
    final name = worker?.name ?? 'Worker#$workerId';
    final type = worker?.type.label ?? '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
          alignment: Alignment.centerLeft,
          width: double.infinity,
            child: Text(
              name,
              style: TextStyle(fontSize: 40, 
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.w900,),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onClear,
    required this.onBackspace,
  });

  final void Function(String d) onDigit;
  final VoidCallback onClear;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    Widget key(String text, {VoidCallback? onTap, int flex = 1}) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
          // ✅ 关键：设置最小高度为很大，迫使它填满父容器（Expanded）
          minimumSize: const Size.fromHeight(double.infinity), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
            onPressed: onTap,
            child: Text(text, style: const TextStyle(fontSize: 22)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
            Expanded(
            child: Row(children: [
              key('1', onTap: () => onDigit('1')),
              key('2', onTap: () => onDigit('2')),
              key('3', onTap: () => onDigit('3')),
            ]),
          ),
          Expanded(
            child: Row(children: [
              key('4', onTap: () => onDigit('4')),
              key('5', onTap: () => onDigit('5')),
              key('6', onTap: () => onDigit('6')),
            ]),
          ),
          Expanded(
            child: Row(children: [
              key('7', onTap: () => onDigit('7')),
              key('8', onTap: () => onDigit('8')),
              key('9', onTap: () => onDigit('9')),
            ]),
          ),
          Expanded(
            child: Row(children: [
              key('清', onTap: onClear),
              key('0', onTap: () => onDigit('0')),
              key('←', onTap: onBackspace),
            ]), ),
        ],
      ),
    );
  }
}
