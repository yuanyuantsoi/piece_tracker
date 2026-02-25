// lib/app.dart

import 'package:flutter/material.dart';
import 'pages/calendar_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '计件助手',
      debugShowCheckedModeBanner: false,

         scrollBehavior: const ScrollBehavior().copyWith(
        overscroll: false, // 禁用 Android 12+ 的 Stretch 和旧版的 Glow
      ),

      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const CalendarPage(),
    );
  }
}
