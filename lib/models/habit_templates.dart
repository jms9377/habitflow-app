import 'habit_category.dart';

/// A starting point offered when creating a habit - not a distinct data
/// model, just pre-filled values for the Add Habit form.
class HabitTemplate {
  const HabitTemplate({
    required this.name,
    required this.emoji,
    required this.category,
    this.note,
  });

  final String name;
  final String emoji;
  final HabitCategory category;
  final String? note;
}

const List<HabitTemplate> generalHabitTemplates = [
  HabitTemplate(name: 'Drink water', emoji: '💧', category: HabitCategory.general),
  HabitTemplate(name: 'Exercise', emoji: '🏃', category: HabitCategory.general),
  HabitTemplate(name: 'Read 10 pages', emoji: '📖', category: HabitCategory.general),
  HabitTemplate(name: 'Sleep 7+ hours', emoji: '😴', category: HabitCategory.general),
  HabitTemplate(name: 'Meditate', emoji: '🧘', category: HabitCategory.general),
  HabitTemplate(name: 'No sugar', emoji: '🍬', category: HabitCategory.general),
  HabitTemplate(name: 'Tidy workspace', emoji: '🧹', category: HabitCategory.general),
  HabitTemplate(name: 'Learn something new', emoji: '💡', category: HabitCategory.general),
];

const List<HabitTemplate> tradingHabitTemplates = [
  HabitTemplate(
    name: 'Followed my trading plan',
    emoji: '📋',
    category: HabitCategory.trading,
    note: 'Did every trade today match a pre-defined setup and rule, not impulse?',
  ),
  HabitTemplate(
    name: 'Respected max risk per trade',
    emoji: '🛡️',
    category: HabitCategory.trading,
    note: 'Stayed within your configured risk-per-trade on every position.',
  ),
  HabitTemplate(
    name: 'No revenge trading',
    emoji: '🚫',
    category: HabitCategory.trading,
    note: 'Did not try to "win back" a loss with an unplanned trade.',
  ),
  HabitTemplate(
    name: 'Journaled every trade',
    emoji: '📝',
    category: HabitCategory.trading,
  ),
  HabitTemplate(
    name: 'Pre-market checklist',
    emoji: '✅',
    category: HabitCategory.trading,
    note: 'Reviewed bias, key levels and news before the session opened.',
  ),
  HabitTemplate(
    name: 'Stopped at daily loss limit',
    emoji: '🛑',
    category: HabitCategory.trading,
  ),
  HabitTemplate(
    name: 'Reviewed today\'s trades',
    emoji: '🔍',
    category: HabitCategory.trading,
  ),
];
