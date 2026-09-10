import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:habitflow/data/habit_repository.dart';
import 'package:habitflow/models/habit.dart';
import 'package:habitflow/models/habit_category.dart';
import 'package:habitflow/models/habit_log.dart';

import '../test_helpers.dart';

void main() {
  late Directory tempDir;
  late Box<Habit> habitsBox;
  late Box<HabitLog> logsBox;
  late HabitRepository repo;

  setUp(() async {
    tempDir = await setUpTestHive();
    habitsBox = await Hive.openBox<Habit>('habits');
    logsBox = await Hive.openBox<HabitLog>('habit_logs');
    repo = HabitRepository(habitsBox: habitsBox, logsBox: logsBox);
  });

  tearDown(() async {
    await tearDownTestHive(tempDir);
  });

  DateTime d(int daysAgo) =>
      DateTime.now().subtract(Duration(days: daysAgo)).let((t) => DateTime(t.year, t.month, t.day));

  test('addHabit persists and allHabits returns it', () async {
    final habit = await repo.addHabit(
      name: 'Drink water',
      emoji: '💧',
      category: HabitCategory.general,
      colorValue: 0xFF2DD4BF,
    );
    expect(repo.allHabits.map((h) => h.id), contains(habit.id));
    expect(repo.getHabit(habit.id)?.name, 'Drink water');
  });

  test('toggleCompletion flips state and is idempotent-safe', () async {
    final habit = await repo.addHabit(
      name: 'Meditate', emoji: '🧘', category: HabitCategory.general, colorValue: 0xFF2DD4BF,
    );
    final today = DateTime.now();

    expect(repo.isCompletedOn(habit.id, today), isFalse);
    final first = await repo.toggleCompletion(habit.id, today);
    expect(first, isTrue);
    expect(repo.isCompletedOn(habit.id, today), isTrue);

    final second = await repo.toggleCompletion(habit.id, today);
    expect(second, isFalse);
    expect(repo.isCompletedOn(habit.id, today), isFalse);
  });

  group('currentStreak', () {
    test('counts consecutive completed days, today-not-done does not zero it', () async {
      final habit = await repo.addHabit(
        name: 'Journal', emoji: '📝', category: HabitCategory.trading, colorValue: 0xFFF5B342,
        createdAt: d(20),
      );
      // completed 3, 2, 1 days ago; not completed today
      await repo.toggleCompletion(habit.id, d(3));
      await repo.toggleCompletion(habit.id, d(2));
      await repo.toggleCompletion(habit.id, d(1));

      expect(repo.currentStreak(habit.id), 3);
    });

    test('a gap resets the streak to the most recent unbroken run', () async {
      final habit = await repo.addHabit(
        name: 'Exercise', emoji: '🏃', category: HabitCategory.general, colorValue: 0xFF2DD4BF,
        createdAt: d(20),
      );
      // completed 5 days ago, then a MISS at 4 days ago, then completed 3,2,1 days ago
      await repo.toggleCompletion(habit.id, d(5));
      await repo.toggleCompletion(habit.id, d(3));
      await repo.toggleCompletion(habit.id, d(2));
      await repo.toggleCompletion(habit.id, d(1));

      expect(repo.currentStreak(habit.id), 3, reason: 'the miss at day 4 should break the streak before it');
    });

    test('non-scheduled days are skipped, not counted as breaks', () async {
      // schedule only weekday matching "d(2)"'s weekday and "d(0)" (today)'s weekday would
      // normally differ - instead use a habit scheduled every day EXCEPT verify skip logic
      // by scheduling only on the weekdays that d(2) and d(0) fall on, leaving d(1) unscheduled.
      final day0 = d(0);
      final day1 = d(1);
      final day2 = d(2);
      final habit = await repo.addHabit(
        name: 'Custom schedule',
        emoji: '📅',
        category: HabitCategory.general,
        colorValue: 0xFF2DD4BF,
        activeWeekdays: {day0.weekday, day2.weekday}.toList(),
        createdAt: d(20),
      );

      await repo.toggleCompletion(habit.id, day2);
      // day1 is intentionally left uncompleted - it should not matter if it's not scheduled
      final streak = repo.currentStreak(habit.id);

      if (habit.isScheduledOn(day1)) {
        // day0/day1/day2 happened to share a weekday (mod 7 chance) - skip assumption-based check
        return;
      }
      expect(streak, 1, reason: 'day1 is not scheduled so it must not break the streak from day2');
    });
  });

  test('longestStreak finds the best historical run even if current streak is shorter', () async {
    final habit = await repo.addHabit(
      name: 'Read', emoji: '📖', category: HabitCategory.general, colorValue: 0xFF2DD4BF,
      createdAt: d(20),
    );
    // a 4-day run further back, then a gap, then nothing recent
    await repo.toggleCompletion(habit.id, d(10));
    await repo.toggleCompletion(habit.id, d(9));
    await repo.toggleCompletion(habit.id, d(8));
    await repo.toggleCompletion(habit.id, d(7));
    // gap at d(6)..d(1)
    expect(repo.longestStreak(habit.id), 4);
    expect(repo.currentStreak(habit.id), 0);
  });

  test('completionRate reflects completed vs scheduled days', () async {
    final habit = await repo.addHabit(
      name: 'No sugar', emoji: '🍬', category: HabitCategory.general, colorValue: 0xFF2DD4BF,
      createdAt: d(20),
    );
    // complete 3 out of the last 5 scheduled days (daily habit)
    await repo.toggleCompletion(habit.id, d(4));
    await repo.toggleCompletion(habit.id, d(3));
    await repo.toggleCompletion(habit.id, d(1));

    final rate = repo.completionRate(habit.id, days: 5);
    expect(rate, closeTo(3 / 5, 0.0001));
  });

  test('archiveHabit hides it from allHabits without deleting its data', () async {
    final habit = await repo.addHabit(
      name: 'Temp', emoji: '✨', category: HabitCategory.general, colorValue: 0xFF2DD4BF,
    );
    await repo.toggleCompletion(habit.id, DateTime.now());
    await repo.archiveHabit(habit.id);

    expect(repo.allHabits.map((h) => h.id), isNot(contains(habit.id)));
    expect(repo.getHabit(habit.id)?.archived, isTrue);
    expect(repo.isCompletedOn(habit.id, DateTime.now()), isTrue);
  });

  test('deleteHabitPermanently removes the habit and its logs', () async {
    final habit = await repo.addHabit(
      name: 'Temp2', emoji: '✨', category: HabitCategory.general, colorValue: 0xFF2DD4BF,
    );
    await repo.toggleCompletion(habit.id, DateTime.now());
    await repo.deleteHabitPermanently(habit.id);

    expect(repo.getHabit(habit.id), isNull);
    expect(repo.isCompletedOn(habit.id, DateTime.now()), isFalse);
  });
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
