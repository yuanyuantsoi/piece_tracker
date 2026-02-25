// lib/pages/calendar_page.dart
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/date_key.dart';
import '../state/providers.dart';
import 'day_overview_page.dart';
import 'worker_manage_page.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  void _openDay(DateTime day) {
    final key = DateKey.fromDate(day);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DayOverviewPage(dateKey: key)),
    );
  }
//--------------------------------------------------------------------
Future<void> _exportMonth() async {
  final service = ref.read(exportServiceProvider);
  final range = DateKey.monthRange(_focusedDay);

  final path = await service.exportCsvToFile(
    startKey: range.startKey,
    endKey: range.endKey,
    fileName: 'piece_month_${range.startKey}_${range.endKey}.csv',
  );

  if (!mounted) return;

  await Share.shareXFiles(
    [XFile(path)],
    text: '计件数据（本月）',
  );
}
//----------------------------------------------------------------
Future<void> _exportYear() async {
  final service = ref.read(exportServiceProvider);
  final range = DateKey.yearRange(_focusedDay.year);

  final path = await service.exportCsvToFile(
    startKey: range.startKey,
    endKey: range.endKey,
    fileName: 'piece_year_${range.startKey}_${range.endKey}.csv',
  );

  if (!mounted) return;

  await Share.shareXFiles(
    [XFile(path)],
    text: '计件数据（本年）',
  );
}
//----------------------------------------------------------
  void _showTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: Text(content)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 提前触发 DB 打开：避免第一次点导出/进页面时卡住（仍不写业务逻辑）
    ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('计件助手',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.normal,
                ),
            ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorkerManagePage()),
              );
            },
            tooltip: '工人管理',
          ),
          PopupMenuButton<_ExportAction>(
            tooltip: '导出',
            onSelected: (v) async {
              if (v == _ExportAction.month) {
                await _exportMonth();
              } else {
                await _exportYear();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _ExportAction.month,
                child: Text('导出本月'),
              ),
              PopupMenuItem(
                value: _ExportAction.year,
                child: Text('导出本年'),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.upload_file),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: _focusedDay,

            calendarFormat: CalendarFormat.month,
availableCalendarFormats: const {
  CalendarFormat.month: 'Month',
},
headerStyle: const HeaderStyle(
  formatButtonVisible: false,
),

          selectedDayPredicate: (d) =>
              _selectedDay != null && isSameDay(_selectedDay, d),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = _normalize(selectedDay);
              _focusedDay = _normalize(focusedDay);
            });
            _openDay(_selectedDay!);
          },
          onPageChanged: (focusedDay) {
            setState(() => _focusedDay = _normalize(focusedDay));
          },
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
          ),
        ),
      ),
    );
  }
}

enum _ExportAction { month, year }
