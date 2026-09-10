import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../data/habit_repository.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';

enum _Period { week, month }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.repository});

  final HabitRepository repository;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _Period _period = _Period.week;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.allHabits;

    final bestStreak = habits.isEmpty
        ? 0
        : habits.map((h) => provider.longestStreak(h.id)).reduce((a, b) => a > b ? a : b);

    final overallRate = habits.isEmpty
        ? 0.0
        : habits.map((h) => provider.completionRate(h.id)).reduce((a, b) => a + b) / habits.length;

    final generalHabits = provider.habitsByCategory(HabitCategory.general);
    final tradingHabits = provider.habitsByCategory(HabitCategory.trading);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: _SummaryCard(label: 'Habits', targetValue: habits.length.toDouble())),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(label: 'Best streak', targetValue: bestStreak.toDouble(), suffix: ' 🔥')),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(label: 'Avg. rate', targetValue: overallRate * 100, suffix: '%')),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress', style: Theme.of(context).textTheme.labelLarge),
              _PeriodToggle(period: _period, onChanged: (p) => setState(() => _period = p)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _ProgressChart(
                key: ValueKey(_period),
                repository: widget.repository,
                habits: habits,
                period: _period,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _CategorySection(
            title: 'General habits',
            color: AppColors.general,
            habits: generalHabits,
            provider: provider,
          ),
          const SizedBox(height: 20),
          _CategorySection(
            title: 'Trading habits',
            color: AppColors.trading,
            habits: tradingHabits,
            provider: provider,
          ),
        ],
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.period, required this.onChanged});

  final _Period period;
  final ValueChanged<_Period> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PeriodButton(label: 'Week', selected: period == _Period.week, onTap: () => onChanged(_Period.week)),
          _PeriodButton(label: 'Month', selected: period == _Period.month, onTap: () => onChanged(_Period.month)),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.general.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.general : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.targetValue, this.suffix = ''});
  final String label;
  final double targetValue;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: targetValue),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              '${value.round()}$suffix',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Shows either the last 7 days' daily completion rate, or the last ~5
/// weeks' weekly completion rate, as percentages - so "week" and "month"
/// are directly comparable on the same 0-100 scale.
class _ProgressChart extends StatelessWidget {
  const _ProgressChart({super.key, required this.repository, required this.habits, required this.period});

  final HabitRepository repository;
  final List<Habit> habits;
  final _Period period;

  @override
  Widget build(BuildContext context) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final values = <double>[];
    final labels = <String>[];

    if (period == _Period.week) {
      const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      for (int i = 6; i >= 0; i--) {
        final day = today.subtract(Duration(days: i));
        final scheduled = habits.where((h) => h.isScheduledOn(day)).toList();
        final done = scheduled.where((h) => repository.isCompletedOn(h.id, day)).length;
        values.add(scheduled.isEmpty ? 0 : done / scheduled.length * 100);
        labels.add(dayLabels[day.weekday - 1]);
      }
    } else {
      for (int w = 4; w >= 0; w--) {
        final weekEnd = today.subtract(Duration(days: w * 7));
        final weekStart = weekEnd.subtract(const Duration(days: 6));
        int scheduledCount = 0;
        int doneCount = 0;
        for (var day = weekStart; !day.isAfter(weekEnd); day = day.add(const Duration(days: 1))) {
          final scheduled = habits.where((h) => h.isScheduledOn(day) && !h.createdAt.isAfter(day)).toList();
          scheduledCount += scheduled.length;
          doneCount += scheduled.where((h) => repository.isCompletedOn(h.id, day)).length;
        }
        values.add(scheduledCount == 0 ? 0 : doneCount / scheduledCount * 100);
        labels.add(w == 0 ? 'This wk' : '-${w}w');
      }
    }

    return BarChart(
      BarChartData(
        maxY: 100,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(labels[value.toInt()], style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ),
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: i == values.length - 1 ? AppColors.trading : AppColors.general,
                  width: period == _Period.week ? 18 : 26,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.color,
    required this.habits,
    required this.provider,
  });

  final String title;
  final Color color;
  final List habits;
  final HabitProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (habits.isEmpty)
            Text('No habits yet.', style: TextStyle(color: AppColors.textSecondary))
          else
            for (final h in habits)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(h.emoji),
                    const SizedBox(width: 8),
                    Expanded(child: Text(h.name)),
                    Text('${(provider.completionRate(h.id) * 100).round()}%',
                        style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
