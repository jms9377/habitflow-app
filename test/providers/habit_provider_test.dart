import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:habitflow/data/habit_repository.dart';
import 'package:habitflow/models/habit.dart';
import 'package:habitflow/models/habit_category.dart';
import 'package:habitflow/models/habit_log.dart';
import 'package:habitflow/providers/habit_provider.dart';

import '../test_helpers.dart';

void main() {
  late Directory tempDir;
  late HabitRepository repo;
  late HabitProvider provider;

  setUp(() async {
    tempDir = await setUpTestHive();
    final habitsBox = await Hive.openBox<Habit>('habits');
    final logsBox = await Hive.openBox<HabitLog>('habit_logs');
    repo = HabitRepository(habitsBox: habitsBox, logsBox: logsBox);
    provider = HabitProvider(repo);
  });

  tearDown(() async {
    await tearDownTestHive(tempDir);
  });

  test('toggleCompletion notifies listeners', () async {
    final habit = await provider.addHabit(
      name: 'Water', emoji: '💧', category: HabitCategory.general, colorValue: 0xFF2DD4BF,
    );

    var notified = 0;
    provider.addListener(() => notified++);

    await provider.toggleCompletion(habit.id);
    expect(notified, greaterThan(0));
    expect(provider.isCompleted(habit.id), isTrue);
  });

  test('toggleCompletion returns the milestone streak length on day 7', () async {
    // created 20 days ago so the backdated completions below are within its lifetime
    final habit = await repo.addHabit(
      name: 'Streaky', emoji: '🔥', category: HabitCategory.trading, colorValue: 0xFFF5B342,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    );
    // manually complete the 6 previous days directly via the repository
    for (int i = 6; i >= 1; i--) {
      await repo.toggleCompletion(habit.id, DateTime.now().subtract(Duration(days: i)));
    }

    final milestone = await provider.toggleCompletion(habit.id);
    expect(milestone, 7);
  });

  test('toggleCompletion returns null when no milestone is reached', () async {
    final habit = await provider.addHabit(
      name: 'Solo', emoji: '✨', category: HabitCategory.general, colorValue: 0xFF2DD4BF,
    );
    final milestone = await provider.toggleCompletion(habit.id);
    expect(milestone, isNull);
  });

  test('habitsByCategory filters correctly', () async {
    await provider.addHabit(name: 'G1', emoji: '✨', category: HabitCategory.general, colorValue: 0xFF2DD4BF);
    await provider.addHabit(name: 'T1', emoji: '📋', category: HabitCategory.trading, colorValue: 0xFFF5B342);

    expect(provider.habitsByCategory(HabitCategory.general).map((h) => h.name), ['G1']);
    expect(provider.habitsByCategory(HabitCategory.trading).map((h) => h.name), ['T1']);
  });

  test('todaysProgress counts only habits scheduled today', () async {
    final habit = await provider.addHabit(
      name: 'Daily', emoji: '✨', category: HabitCategory.general, colorValue: 0xFF2DD4BF,
    );
    var (completed, total) = provider.todaysProgress();
    expect(total, 1);
    expect(completed, 0);

    await provider.toggleCompletion(habit.id);
    (completed, total) = provider.todaysProgress();
    expect(completed, 1);
  });
}
