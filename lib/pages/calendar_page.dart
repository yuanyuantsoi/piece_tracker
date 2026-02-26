// lib/pages/calendar_page.dart
import 'package:share_plus/share_plus.dart';
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

  @override
  Widget build(BuildContext context) {
    // 提前触发 DB 打开：避免第一次点导出/进页面时卡住（仍不写业务逻辑）
    ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('计件助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: '工人管理',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorkerManagePage()),
              );
            },
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
          locale: 'zh_CN',

          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: _focusedDay,

          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {
            CalendarFormat.month: '月',
          },

          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            headerPadding: EdgeInsets.symmetric(vertical: 10),
            titleTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            leftChevronPadding: EdgeInsets.all(8),
            rightChevronPadding: EdgeInsets.all(8),
          ),

          calendarBuilders: CalendarBuilders(
            headerTitleBuilder: (context, day) {
              final t = DateTime.now();
              final today = DateTime(t.year, t.month, t.day);

              return SizedBox(
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${day.year}年${day.month}月',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _focusedDay = today;
                              _selectedDay = today;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.today, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  '今天',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          daysOfWeekHeight: 22,
          rowHeight: 44,
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
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
        ),
      ),
    );
  }
}

enum _ExportAction { month, year }
