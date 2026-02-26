// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/calendar_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '计件助手',
      debugShowCheckedModeBanner: false,

localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('zh', 'CN'),
  ],
  locale: const Locale('zh', 'CN'),

         scrollBehavior: const ScrollBehavior().copyWith(
        overscroll: false, // 禁用 Android 12+ 的 Stretch 和旧版的 Glow
      ),

      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        // 全局修改AppBar标题样式
        appBarTheme: const AppBarTheme(
        centerTitle: false, // 是否居中
    titleTextStyle: TextStyle(
      fontSize: 15,            // 修改字体大小
      fontWeight: FontWeight.w900, // 加粗
      fontStyle: FontStyle.normal,
      color: Colors.black87,    // 颜色
      letterSpacing: 1.2,       // 字间距
      // fontFamily: 'YourCustomFont', // 如果你有自定义字体在此设置
      ),
    ),
        ),
      home: const CalendarPage(),
    );
  }
}
