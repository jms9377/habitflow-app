import 'package:flutter/foundation.dart';

import '../data/habit_repository.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';

const milestoneStreaks = [7, 14, 30, 60, 100, 365];

/// Thin ChangeNotifier wrapper around [HabitRepository]. Screens never talk
/// to Hive directly - they read/act through this provider so the UI stays
/// declarative and testable independent of the storage engine.
class HabitProvider extends ChangeNotifier {
  HabitProvider(this._repo);

  final HabitRepository _repo;
  DateTime _selectedDate = HabitLogDateHelper.today();

  DateTime get selectedDate => _selectedDate;

  void selectDate(DateTime date) {
    _selectedDate = HabitLogDateHelper.normalize(date);
    notifyListeners();
  }

  List<Habit> get allHabits => _repo.allHabits;

  List<Habit> habitsForSelectedDate() => _repo.habitsForDate(_selectedDate);

  List<Habit> habitsByCategory(HabitCategory category) =>
      _repo.habitsByCategory(category);

  bool isCompleted(String habitId, [DateTime? date]) =>
      _repo.isCompletedOn(habitId, date ?? _selectedDate);

  int currentStreak(String habitId) => _repo.currentStreak(habitId);

  int longestStreak(String habitId) => _repo.longestStreak(habitId);

  double completionRate(String habitId, {int days = 30}) =>
      _repo.completionRate(habitId, days: days);

  (int, int) todaysProgress() => _repo.todaysProgress();

  /// Toggles completion for [date] (defaults to the globally selected
  /// date used by Home) and returns a milestone streak length if this
  /// toggle just reached one (for the UI to celebrate), else null. Passing
  /// an explicit [date] lets other views (e.g. the monthly calendar)
  /// backfill/edit a specific day without disturbing Home's own selection.
  Future<int?> toggleCompletion(String habitId, {DateTime? date}) async {
    final target = date != null ? HabitLogDateHelper.normalize(date) : _selectedDate;
    final wasCompleted = _repo.isCompletedOn(habitId, target);
    await _repo.toggleCompletion(habitId, target);
    notifyListeners();

    if (!wasCompleted) {
      final streak = _repo.currentStreak(habitId, asOf: target);
      if (milestoneStreaks.contains(streak)) return streak;
    }
    return null;
  }

  Future<Habit> addHabit({
    required String name,
    required String emoji,
    required HabitCategory category,
    required int colorValue,
    List<int>? activeWeekdays,
    String? note,
  }) async {
    final habit = await _repo.addHabit(
      name: name,
      emoji: emoji,
      category: category,
      colorValue: colorValue,
      activeWeekdays: activeWeekdays,
      note: note,
    );
    notifyListeners();
    return habit;
  }

  Future<void> updateHabit(Habit habit) async {
    await _repo.updateHabit(habit);
    notifyListeners();
  }

  Future<void> archiveHabit(String habitId) async {
    await _repo.archiveHabit(habitId);
    notifyListeners();
  }

  Future<void> deleteHabitPermanently(String habitId) async {
    await _repo.deleteHabitPermanently(habitId);
    notifyListeners();
  }
}

/// Small helper so the provider doesn't need to import HabitLog just for
/// date normalization.
class HabitLogDateHelper {
  static DateTime today() => normalize(DateTime.now());
  static DateTime normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
