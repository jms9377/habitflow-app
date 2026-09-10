import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/habit_repository.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/calendar_heatmap.dart';
import '../widgets/monthly_calendar.dart';
import 'add_edit_habit_screen.dart';

enum _CalendarView { month, heatmap }

class HabitDetailScreen extends StatefulWidget {
  const HabitDetailScreen({super.key, required this.habitId, required this.repository});

  final String habitId;
  final HabitRepository repository;

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  _CalendarView _view = _CalendarView.month;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habit = widget.repository.getHabit(widget.habitId);

    if (habit == null) {
      return const Scaffold(body: Center(child: Text('Hábito no encontrado.')));
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
                builder: (_) => AddEditHabitScreen(repository: widget.repository, existing: habit),
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
                  title: const Text('¿Eliminar hábito?'),
                  content: Text('Esto eliminará "${habit.name}" y todo su historial. No se puede deshacer.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
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
              Expanded(child: _StatCard(label: 'Racha actual', targetValue: current.toDouble(), suffix: ' 🔥', color: color)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Mejor racha', targetValue: longest.toDouble(), color: color)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Tasa 30 días', targetValue: rate * 100, suffix: '%', color: color)),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _view == _CalendarView.month ? 'Calendario' : 'Últimas 14 semanas',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              _ViewToggle(
                view: _view,
                color: color,
                onChanged: (v) => setState(() => _view = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _view == _CalendarView.month
                ? MonthlyCalendar(key: const ValueKey('month'), habit: habit, repository: widget.repository)
                : CalendarHeatmap(key: const ValueKey('heatmap'), habit: habit, repository: widget.repository),
          ),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.view, required this.color, required this.onChanged});

  final _CalendarView view;
  final Color color;
  final ValueChanged<_CalendarView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(icon: Icons.calendar_view_month, selected: view == _CalendarView.month, color: color,
              onTap: () => onChanged(_CalendarView.month)),
          _ToggleButton(icon: Icons.grid_view_rounded, selected: view == _CalendarView.heatmap, color: color,
              onTap: () => onChanged(_CalendarView.heatmap)),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.icon, required this.selected, required this.color, required this.onTap});

  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: selected ? color : AppColors.textSecondary),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.targetValue, required this.color, this.suffix = ''});

  final String label;
  final double targetValue;
  final String suffix;
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
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: targetValue),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              '${value.round()}$suffix',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
