// lib/pages/piece_edit_page.dart

import 'package:flutter/material.dart';

class PieceEditPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('录入')),
      body: Center(
        child: Text(
          'TODO PieceEdit\n'
          'dateKey=$dateKey\n'
          'initialWorkerId=$initialWorkerId\n'
          'orderedWorkerIds=${orderedWorkerIds.join(',')}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
