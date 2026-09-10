import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/habit_log.dart';

const habitsBoxName = 'habits';
const logsBoxName = 'habit_logs';

/// Owns the two Hive boxes and all read/write + streak logic. Nothing in
/// the UI layer talks to Hive directly - every screen/provider goes
/// through this class, so the storage engine could be swapped later
/// without touching widgets.
class HabitRepository {
  HabitRepository({Box<Habit>? habitsBox, Box<HabitLog>? logsBox})
      : _habitsBox = habitsBox ?? Hive.box<Habit>(habitsBoxName),
        _logsBox = logsBox ?? Hive.box<HabitLog>(logsBoxName);

  final Box<Habit> _habitsBox;
  final Box<HabitLog> _logsBox;
  final _uuid = const Uuid();

  static Future<void> registerAdapters() async {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HabitAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(HabitLogAdapter());
  }

  static Future<void> openBoxes() async {
    await Hive.openBox<Habit>(habitsBoxName);
    await Hive.openBox<HabitLog>(logsBoxName);
  }

  // ---------------------------------------------------------------------
  // Habits CRUD
  // ---------------------------------------------------------------------

  List<Habit> get allHabits =>
      _habitsBox.values.where((h) => !h.archived).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<Habit> habitsByCategory(HabitCategory category) =>
      allHabits.where((h) => h.category == category).toList();

  /// Habits scheduled for [date] (per their active weekdays), not archived.
  List<Habit> habitsForDate(DateTime date) =>
      allHabits.where((h) => h.isScheduledOn(date)).toList();

  Habit? getHabit(String id) => _habitsBox.get(id);

  Future<Habit> addHabit({
    required String name,
    required String emoji,
    required HabitCategory category,
    required int colorValue,
    List<int>? activeWeekdays,
    String? note,
    DateTime? createdAt, // exposed for tests that need to backdate history; UI never passes this
  }) async {
    final habit = Habit.create(
      id: _uuid.v4(),
      name: name,
      emoji: emoji,
      category: category,
      colorValue: colorValue,
      createdAt: createdAt ?? DateTime.now(),
      activeWeekdays: activeWeekdays,
      note: note,
    );
    await _habitsBox.put(habit.id, habit);
    return habit;
  }

  Future<void> updateHabit(Habit habit) async {
    await _habitsBox.put(habit.id, habit);
    await habit.save();
  }

  Future<void> archiveHabit(String habitId) async {
    final habit = _habitsBox.get(habitId);
    if (habit == null) return;
    habit.archived = true;
    await habit.save();
  }

  Future<void> deleteHabitPermanently(String habitId) async {
    final logIds = _logsBox.values
        .where((l) => l.habitId == habitId)
        .map((l) => l.id)
        .toList();
    for (final id in logIds) {
      await _logsBox.delete(id);
    }
    await _habitsBox.delete(habitId);
  }

  // ---------------------------------------------------------------------
  // Completion logs
  // ---------------------------------------------------------------------

  HabitLog? _logFor(String habitId, DateTime date) {
    final normalized = HabitLog.normalize(date);
    try {
      return _logsBox.values.firstWhere(
        (l) => l.habitId == habitId && l.date == normalized,
      );
    } on StateError {
      return null;
    }
  }

  bool isCompletedOn(String habitId, DateTime date) =>
      _logFor(habitId, date)?.completed ?? false;

  /// Flips completion for [habitId] on [date] and returns the new state.
  Future<bool> toggleCompletion(String habitId, DateTime date) async {
    final existing = _logFor(habitId, date);
    if (existing != null) {
      existing.completed = !existing.completed;
      await existing.save();
      return existing.completed;
    }
    final log = HabitLog(
      id: _uuid.v4(),
      habitId: habitId,
      date: HabitLog.normalize(date),
      completed: true,
    );
    await _logsBox.put(log.id, log);
    return true;
  }

  List<HabitLog> logsForHabit(String habitId) => _logsBox.values
      .where((l) => l.habitId == habitId && l.completed)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  // ---------------------------------------------------------------------
  // Streaks and stats
  //
  // DEFINITION: a habit's streak counts consecutive SCHEDULED days (per
  // Habit.activeWeekdays) that were completed, walking backward from
  // today. Non-scheduled days never break a streak - they're simply
  // skipped. Today is special-cased: if today is scheduled but not yet
  // completed, it does not zero out yesterday's streak (the day isn't
  // over), it's just not counted until checked off.
  // ---------------------------------------------------------------------

  int currentStreak(String habitId, {DateTime? asOf}) {
    final habit = getHabit(habitId);
    if (habit == null) return 0;

    var day = HabitLog.normalize(asOf ?? DateTime.now());
    final today = HabitLog.normalize(asOf ?? DateTime.now());
    final earliest = HabitLog.normalize(habit.createdAt);
    int streak = 0;
    bool first = true;

    while (!day.isBefore(earliest)) {
      if (habit.isScheduledOn(day)) {
        final done = isCompletedOn(habitId, day);
        if (!done) {
          if (first && day == today) {
            // today not completed yet - don't break the streak, just don't count it
          } else {
            break;
          }
        } else {
          streak++;
        }
      }
      first = false;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int longestStreak(String habitId) {
    final habit = getHabit(habitId);
    if (habit == null) return 0;

    final completedDates = _logsBox.values
        .where((l) => l.habitId == habitId && l.completed)
        .map((l) => l.date)
        .toSet();
    if (completedDates.isEmpty) return 0;

    var day = completedDates.reduce((a, b) => a.isBefore(b) ? a : b);
    final last = completedDates.reduce((a, b) => a.isAfter(b) ? a : b);

    int longest = 0;
    int running = 0;
    while (!day.isAfter(last)) {
      if (habit.isScheduledOn(day)) {
        if (completedDates.contains(day)) {
          running++;
          longest = running > longest ? running : longest;
        } else {
          running = 0;
        }
      }
      day = day.add(const Duration(days: 1));
    }
    return longest;
  }

  /// Fraction of scheduled days completed in the last [days] days (inclusive of today).
  double completionRate(String habitId, {int days = 30}) {
    final habit = getHabit(habitId);
    if (habit == null) return 0;

    final today = HabitLog.normalize(DateTime.now());
    int scheduled = 0;
    int completed = 0;
    for (int i = 0; i < days; i++) {
      final day = today.subtract(Duration(days: i));
      if (day.isBefore(HabitLog.normalize(habit.createdAt))) break;
      if (habit.isScheduledOn(day)) {
        scheduled++;
        if (isCompletedOn(habitId, day)) completed++;
      }
    }
    return scheduled == 0 ? 0 : completed / scheduled;
  }

  /// (completed, total) for all habits scheduled today.
  (int, int) todaysProgress() {
    final todaysHabits = habitsForDate(DateTime.now());
    final completed =
        todaysHabits.where((h) => isCompletedOn(h.id, DateTime.now())).length;
    return (completed, todaysHabits.length);
  }
}
