import 'package:flutter/material.dart';

import '../models/habit_category.dart';

/// HabitFlow's visual identity: a calm, modern dark-first palette with two
/// accent colors that map to the two habit domains - teal for general
/// habits, amber/gold for trading habits - so the eye can tell them apart
/// at a glance across every screen.
class AppColors {
  static const background = Color(0xFF0E1116);
  static const surface = Color(0xFF171B22);
  static const surfaceAlt = Color(0xFF1F2530);
  static const border = Color(0xFF2A3140);

  static const textPrimary = Color(0xFFEDEFF4);
  static const textSecondary = Color(0xFF9AA4B2);

  static const general = Color(0xFF2DD4BF); // teal
  static const trading = Color(0xFFF5B342); // amber/gold

  static const success = Color(0xFF4ADE80);
  static const danger = Color(0xFFF87171);

  static Color forCategory(HabitCategory category) =>
      category == HabitCategory.trading ? trading : general;
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    // Deliberately uses the platform's bundled font (no network fetch at
    // runtime, unlike a Google Fonts CDN dependency) - a habit tracker
    // should render its UI instantly and fully offline. The distinct look
    // instead comes from refined weights/letter-spacing on top of it.
    final textTheme = base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ).copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(letterSpacing: 0.1),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        surface: AppColors.surface,
        primary: AppColors.general,
        secondary: AppColors.trading,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.general,
        foregroundColor: Colors.black,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.general,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
