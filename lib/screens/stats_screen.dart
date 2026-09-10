import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/habit_repository.dart';
import '../models/habit_category.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.repository});

  final HabitRepository repository;

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
              Expanded(child: _SummaryCard(label: 'Habits', value: '${habits.length}')),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(label: 'Best streak', value: '$bestStreak 🔥')),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(label: 'Avg. rate', value: '${(overallRate * 100).round()}%')),
            ],
          ),
          const SizedBox(height: 28),
          Text('Last 7 days', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          SizedBox(height: 180, child: _LastWeekChart(repository: repository, habits: habits)),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});
  final String label;
  final String value;

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
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _LastWeekChart extends StatelessWidget {
  const _LastWeekChart({required this.repository, required this.habits});

  final HabitRepository repository;
  final List habits;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final counts = <int>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      final scheduled = habits.where((h) => h.isScheduledOn(day)).toList();
      final done = scheduled.where((h) => repository.isCompletedOn(h.id, day)).length;
      counts.add(done);
    }
    final maxY = (counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b)).toDouble();

    return BarChart(
      BarChartData(
        maxY: maxY < 1 ? 1 : maxY + 1,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final day = today.subtract(Duration(days: 6 - value.toInt()));
                const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(labels[day.weekday - 1], style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < counts.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: counts[i].toDouble(),
                  color: i == counts.length - 1 ? AppColors.trading : AppColors.general,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
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
