import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/habit_repository.dart';
import '../models/habit_category.dart';
import '../providers/habit_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/category_chip.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/habit_tile.dart';
import '../widgets/motivation_card.dart';
import '../widgets/progress_ring.dart';
import 'add_edit_habit_screen.dart';
import 'habit_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final HabitRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _celebrationKey = GlobalKey<CelebrationOverlayState>();
  HabitCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider
        .habitsForSelectedDate()
        .where((h) => _filter == null || h.category == _filter)
        .toList();
    // All habits in the current filter, regardless of the selected date's
    // schedule - used only to tell "nothing in this category yet" apart
    // from "these exist, just not scheduled on this day" in the empty state.
    final habitsInFilterAnyDay =
        _filter == null ? provider.allHabits : provider.habitsByCategory(_filter!);
    final (completed, total) = provider.todaysProgress();
    final isToday = provider.selectedDate == HabitLogDateHelper.today();

    return CelebrationOverlay(
      key: _celebrationKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('HabitFlow'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddEditHabitScreen(repository: widget.repository, initialCategory: _filter),
            ),
          ),
          child: const Icon(Icons.add),
        ),
        body: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _DateStrip(
                selected: provider.selectedDate,
                onSelect: provider.selectDate,
              ),
              const SizedBox(height: 16),
              const MotivationCard(),
              const SizedBox(height: 20),
              Center(
                child: ProgressRing(
                  progress: total == 0 ? 0 : completed / total,
                  label: isToday
                      ? '$completed / $total hoy'
                      : '$completed / $total ese día',
                ),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
              const SizedBox(height: 24),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _filter = null),
                    child: _AllChip(selected: _filter == null),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _filter = HabitCategory.general),
                    child: CategoryChip(
                      category: HabitCategory.general,
                      selected: _filter == HabitCategory.general,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _filter = HabitCategory.trading),
                    child: CategoryChip(
                      category: HabitCategory.trading,
                      selected: _filter == HabitCategory.trading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (habits.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      habitsInFilterAnyDay.isEmpty
                          ? 'Aún no hay hábitos programados aquí.\nToca + para añadir uno.'
                          : 'Ninguno de tus hábitos aquí está programado para ${isToday ? "hoy" : "este día"}.\n'
                              '${habitsInFilterAnyDay.length == 1 ? "Tienes 1 hábito con" : "Tienes ${habitsInFilterAnyDay.length} hábitos con"} otros días activos - tócalo en Estadísticas para ver o cambiar sus días.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                for (int i = 0; i < habits.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: HabitTile(
                      habit: habits[i],
                      completed: provider.isCompleted(habits[i].id),
                      streak: provider.currentStreak(habits[i].id),
                      onToggle: () async {
                        final milestone =
                            await provider.toggleCompletion(habits[i].id);
                        if (milestone != null) {
                          _celebrationKey.currentState?.play();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🔥 ¡Racha de $milestone días en ${habits[i].name}!'),
                                backgroundColor: AppColors.forCategory(habits[i].category),
                              ),
                            );
                          }
                        }
                      },
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HabitDetailScreen(
                            habitId: habits[i].id,
                            repository: widget.repository,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: (60 * i).ms, duration: 300.ms).slideY(
                        begin: 0.08,
                        end: 0,
                        curve: Curves.easeOut,
                      ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllChip extends StatelessWidget {
  const _AllChip({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withValues(alpha: 0.12) : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? Colors.white38 : AppColors.border),
      ),
      child: Text(
        'Todos',
        style: TextStyle(
          color: selected ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.selected, required this.onSelect});

  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final today = HabitLogDateHelper.today();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    return SizedBox(
      height: 64,
      child: Row(
        children: [
          for (final day in days)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: day == selected ? AppColors.general.withValues(alpha: 0.18) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: day == selected ? AppColors.general : AppColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat.E('es').format(day).substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: day == selected ? AppColors.general : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: day == selected ? AppColors.general : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
