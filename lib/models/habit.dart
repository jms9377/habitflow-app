import 'package:hive/hive.dart';

import 'habit_category.dart';

part 'habit.g.dart';

/// A habit definition (the "what", not the daily record of doing it -
/// see [HabitLog] for that).
@HiveType(typeId: 0)
class Habit extends HiveObject {
  Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.categoryIndex,
    required this.colorValue,
    required this.createdAt,
    List<int>? activeWeekdays,
    this.note,
    this.archived = false,
  }) : activeWeekdays = activeWeekdays ?? const [1, 2, 3, 4, 5, 6, 7];

  factory Habit.create({
    required String id,
    required String name,
    required String emoji,
    required HabitCategory category,
    required int colorValue,
    required DateTime createdAt,
    List<int>? activeWeekdays,
    String? note,
  }) =>
      Habit(
        id: id,
        name: name,
        emoji: emoji,
        categoryIndex: category.index,
        colorValue: colorValue,
        createdAt: createdAt,
        activeWeekdays: activeWeekdays,
        note: note,
      );

  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String emoji;

  @HiveField(3)
  int categoryIndex;

  @HiveField(4)
  int colorValue;

  @HiveField(5)
  final DateTime createdAt;

  /// DateTime.weekday values (1=Mon..7=Sun) this habit is scheduled on.
  /// All seven means "every day".
  @HiveField(6)
  List<int> activeWeekdays;

  @HiveField(7)
  String? note;

  @HiveField(8)
  bool archived;

  HabitCategory get category => HabitCategory.values[categoryIndex];
  set category(HabitCategory value) => categoryIndex = value.index;

  bool get isDaily => activeWeekdays.length >= 7;

  bool isScheduledOn(DateTime day) => activeWeekdays.contains(day.weekday);
}
