import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/habit_repository.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';

const _weekdayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// A real month-grid calendar (not the compact contribution heatmap) for
/// one habit: navigate between months, and tap any past/today cell to
/// toggle its completion directly - useful for backfilling a day you
/// forgot to check off in the app. Future days and days before the
/// habit's creation are shown but not tappable.
class MonthlyCalendar extends StatefulWidget {
  const MonthlyCalendar({super.key, required this.habit, required this.repository});

  final Habit habit;
  final HabitRepository repository;

  @override
  State<MonthlyCalendar> createState() => _MonthlyCalendarState();
}

class _MonthlyCalendarState extends State<MonthlyCalendar> {
  late DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _visibleMonth.year == now.year && _visibleMonth.month == now.month;
  }

  void _shiftMonth(int delta) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final color = AppColors.forCategory(widget.habit.category);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final createdAt = DateTime(widget.habit.createdAt.year, widget.habit.createdAt.month, widget.habit.createdAt.day);

    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1; // Monday = 1

    final cells = <Widget>[
      for (int i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
      for (int day = 1; day <= daysInMonth; day++)
        _DayCell(
          date: DateTime(_visibleMonth.year, _visibleMonth.month, day),
          today: today,
          createdAt: createdAt,
          habit: widget.habit,
          color: color,
          completed: provider.isCompleted(
            widget.habit.id,
            DateTime(_visibleMonth.year, _visibleMonth.month, day),
          ),
          onToggle: () => provider.toggleCompletion(
            widget.habit.id,
            date: DateTime(_visibleMonth.year, _visibleMonth.month, day),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _shiftMonth(-1),
            ),
            Text(
              DateFormat.yMMMM().format(_visibleMonth),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _isCurrentMonth ? null : () => _shiftMonth(1),
            ),
          ],
        ),
        Row(
          children: [
            for (final label in _weekdayHeaders)
              Expanded(
                child: Center(
                  child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(animation),
              child: child,
            ),
          ),
          child: GridView.count(
            key: ValueKey(_visibleMonth),
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cells,
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.today,
    required this.createdAt,
    required this.habit,
    required this.color,
    required this.completed,
    required this.onToggle,
  });

  final DateTime date;
  final DateTime today;
  final DateTime createdAt;
  final Habit habit;
  final Color color;
  final bool completed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isFuture = date.isAfter(today);
    final beforeCreation = date.isBefore(createdAt);
    final scheduled = habit.isScheduledOn(date);
    final tappable = !isFuture && !beforeCreation;

    Color background;
    Color textColor = AppColors.textPrimary;
    if (isFuture || beforeCreation || !scheduled) {
      background = Colors.transparent;
      textColor = AppColors.textSecondary.withValues(alpha: 0.5);
    } else if (completed) {
      background = color;
      textColor = Colors.black;
    } else if (date == today) {
      background = AppColors.surfaceAlt;
    } else {
      background = AppColors.danger.withValues(alpha: 0.18);
    }

    return Padding(
      padding: const EdgeInsets.all(3),
      child: GestureDetector(
        onTap: tappable && scheduled ? onToggle : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: date == today ? Border.all(color: color, width: 1.5) : null,
          ),
          alignment: Alignment.center,
          child: Text('${date.day}', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
