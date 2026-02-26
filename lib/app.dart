// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/calendar_page.dart';
import 'state/providers.dart';

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
        overscroll: false,
      ),
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.normal,
            color: Colors.black87,
            letterSpacing: 1.2,
          ),
        ),
      ),
      home: const _DbGate(),
    );
  }
}

class _DbGate extends ConsumerWidget {
  const _DbGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(dbProvider);

    return dbAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(child: Text('DB 打开失败：$e')),
      ),
      data: (_) => const CalendarPage(),
    );
  }
}
