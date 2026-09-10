import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/habit_repository.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/calendar_heatmap.dart';
import 'add_edit_habit_screen.dart';

class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habitId, required this.repository});

  final String habitId;
  final HabitRepository repository;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habit = repository.getHabit(habitId);

    if (habit == null) {
      return const Scaffold(body: Center(child: Text('Habit not found.')));
    }

    final color = AppColors.forCategory(habit.category);
    final current = provider.currentStreak(habit.id);
    final longest = provider.longestStreak(habit.id);
    final rate = provider.completionRate(habit.id);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddEditHabitScreen(repository: repository, existing: habit),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Delete habit?'),
                  content: Text('This removes "${habit.name}" and all its history. This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await context.read<HabitProvider>().deleteHabitPermanently(habit.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Hero(
                tag: 'habit-emoji-${habit.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(habit.emoji, style: const TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name, style: Theme.of(context).textTheme.titleLarge),
                    Text(habit.category.label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          if (habit.note != null && habit.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(habit.note!, style: TextStyle(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Current streak', value: '$current 🔥', color: color)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Best streak', value: '$longest', color: color)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: '30-day rate', value: '${(rate * 100).round()}%', color: color)),
            ],
          ),
          const SizedBox(height: 28),
          Text('Last 14 weeks', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          CalendarHeatmap(habit: habit, repository: repository),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
