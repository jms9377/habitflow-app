import 'package:flutter/material.dart';

import '../data/habit_repository.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';

/// A GitHub-contributions-style grid of the last [weeks] weeks for one
/// habit: filled with the category color when completed, a faint outline
/// when scheduled-but-missed, and almost invisible when the day wasn't
/// scheduled at all or is still in the future.
class CalendarHeatmap extends StatelessWidget {
  const CalendarHeatmap({
    super.key,
    required this.habit,
    required this.repository,
    this.weeks = 14,
  });

  final Habit habit;
  final HabitRepository repository;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forCategory(habit.category);
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    // Align the grid so the last column ends on the current week's Sunday.
    final daysBack = weeks * 7 - 1;
    final start = todayNormalized.subtract(Duration(days: daysBack));
    final gridStart = start.subtract(Duration(days: start.weekday - 1));

    final columns = <Widget>[];
    for (int w = 0; w < weeks + 1; w++) {
      final cells = <Widget>[];
      for (int d = 0; d < 7; d++) {
        final day = gridStart.add(Duration(days: w * 7 + d));
        cells.add(_buildCell(day, todayNormalized, color));
      }
      columns.add(Column(
        mainAxisSize: MainAxisSize.min,
        children: cells,
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: columns,
      ),
    );
  }

  Widget _buildCell(DateTime day, DateTime today, Color color) {
    const size = 14.0;
    const gap = 3.0;

    Color cellColor;
    if (day.isAfter(today) || day.isBefore(DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day))) {
      cellColor = Colors.transparent;
    } else if (!habit.isScheduledOn(day)) {
      cellColor = AppColors.surfaceAlt.withValues(alpha: 0.3);
    } else if (repository.isCompletedOn(habit.id, day)) {
      cellColor = color;
    } else {
      cellColor = AppColors.danger.withValues(alpha: 0.25);
    }

    return Padding(
      padding: const EdgeInsets.all(gap / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
