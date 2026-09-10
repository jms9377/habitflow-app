import 'package:hive/hive.dart';

part 'habit_log.g.dart';

/// A single day's completion record for one habit. `date` is always
/// normalized to midnight (local time) so lookups are exact-match, not
/// range queries.
@HiveType(typeId: 1)
class HabitLog extends HiveObject {
  HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String habitId;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  bool completed;

  static DateTime normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
