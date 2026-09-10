/// The two habit domains HabitFlow tracks side by side.
///
/// `general` covers everyday habits (water, exercise, reading, sleep...).
/// `trading` covers trading-discipline habits (followed the plan, journaled,
/// respected risk limits...) - kept as a first-class category rather than a
/// tag so the Home and Stats screens can group and celebrate them
/// separately.
enum HabitCategory {
  general,
  trading;

  String get label => switch (this) {
        HabitCategory.general => 'General',
        HabitCategory.trading => 'Trading',
      };
}
