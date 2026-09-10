import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/habit_repository.dart';
import 'providers/habit_provider.dart';
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/glass_bottom_nav.dart';

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
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
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

  static const _items = [
    GlassNavItem(
      icon: Icons.checklist_rounded,
      activeIcon: Icons.checklist_rounded,
      label: 'Hoy',
      color: AppColors.general,
    ),
    GlassNavItem(
      icon: Icons.bar_chart_rounded,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Estadísticas',
      color: AppColors.trading,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screen = _index == 0
        ? HomeScreen(key: const ValueKey('home'), repository: widget.repository)
        : StatsScreen(key: const ValueKey('stats'), repository: widget.repository);

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        child: screen,
      ),
      bottomNavigationBar: GlassBottomNav(
        items: _items,
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
