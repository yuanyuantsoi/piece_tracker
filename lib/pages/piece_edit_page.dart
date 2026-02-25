// lib/pages/piece_edit_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../state/refresh_tick.dart';
import '../models/date_key.dart';

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
  String _input = '';
  int _loadedValue = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.orderedWorkerIds.indexOf(widget.initialWorkerId);
  }

  int get _currentWorkerId => widget.orderedWorkerIds[_index];

  @override
  Widget build(BuildContext context) {
    final countsAsync =
        ref.watch(countsByDateProvider(widget.dateKey));

    return countsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('错误: $e'))),
      data: (counts) {
        final value = counts[_currentWorkerId] ?? 0;

        // 首次加载
        if (_input.isEmpty) {
          _loadedValue = value;
          _input = value == 0 ? '' : value.toString();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('录入 ${widget.dateKey}'),
          ),
          body: Column(
            children: [
              const SizedBox(height: 24),

              Text(
                '当前工人ID: $_currentWorkerId',
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 16),

              Text(
                _input.isEmpty ? '0' : _input,
                style: const TextStyle(
                    fontSize: 40, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              _buildKeypad(),

              const SizedBox(height: 24),

              _buildNavButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeypad() {
    Widget key(String text, {VoidCallback? onTap}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: ElevatedButton(
            onPressed: onTap,
            child: Text(text, style: const TextStyle(fontSize: 22)),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            key('1', onTap: () => _append('1')),
            key('2', onTap: () => _append('2')),
            key('3', onTap: () => _append('3')),
          ],
        ),
        Row(
          children: [
            key('4', onTap: () => _append('4')),
            key('5', onTap: () => _append('5')),
            key('6', onTap: () => _append('6')),
          ],
        ),
        Row(
          children: [
            key('7', onTap: () => _append('7')),
            key('8', onTap: () => _append('8')),
            key('9', onTap: () => _append('9')),
          ],
        ),
        Row(
          children: [
            key('清', onTap: _clear),
            key('0', onTap: () => _append('0')),
            key('←', onTap: _backspace),
          ],
        ),
      ],
    );
  }

  Widget _buildNavButtons(BuildContext context) {
    final isFirst = _index == 0;
    final isLast = _index == widget.orderedWorkerIds.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: isFirst ? null : _prev,
              child: const Text('上一个'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveAndNext,
              child: Text(isLast ? '保存并返回' : '保存并下一个'),
            ),
          ),
        ],
      ),
    );
  }

  void _append(String d) {
    setState(() {
      _input += d;
    });
  }

  void _clear() {
    setState(() {
      _input = '';
    });
  }

  void _backspace() {
    if (_input.isEmpty) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
    });
  }

  Future<void> _saveAndNext() async {
    final repo = ref.read(entryRepoProvider);

    final value = _input.isEmpty ? 0 : int.parse(_input);

    await repo.setCount(widget.dateKey, _currentWorkerId, value);

    // 刷新
    ref.read(refreshTickProvider.notifier).state++;

    if (_index == widget.orderedWorkerIds.length - 1) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      _index++;
      _input = '';
    });
  }

  void _prev() {
    if (_index == 0) return;
    setState(() {
      _index--;
      _input = '';
    });
  }
}
