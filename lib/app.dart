import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/habit_repository.dart';
import 'providers/habit_provider.dart';
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'theme/app_theme.dart';

class HabitFlowApp extends StatelessWidget {
  const HabitFlowApp({super.key, required this.repository});

  final HabitRepository repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HabitProvider(repository),
      child: MaterialApp(
        title: 'HabitFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: RootShell(repository: repository),
      ),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.repository});

  final HabitRepository repository;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(repository: widget.repository),
      StatsScreen(repository: widget.repository),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Stats'),
        ],
      ),
    );
  }
}
