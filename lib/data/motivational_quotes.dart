/// Short motivational lines shown on Home, one per day (deterministic by
/// day-of-year so it's stable across app opens on the same day, but
/// changes every day). Mixes general-habit encouragement with
/// trading-discipline framing, matching the app's two habit domains.
const List<String> motivationalQuotes = [
  "Small steps, repeated daily, beat big plans that never start.",
  "Discipline is choosing what you want most over what you want now.",
  "You don't rise to your goals - you fall to your systems. Trust the system.",
  "One more day of showing up is one more brick in the wall.",
  "The trade you didn't take because it broke your rules is a win.",
  "Consistency compounds quietly, then all at once.",
  "Your streak isn't the goal - the habit becoming automatic is.",
  "Protect your capital and your consistency the same way.",
  "Every checkmark today is evidence for the person you're becoming.",
  "A missed day isn't failure. Two in a row is a pattern - watch for it.",
  "Plan the trade, trade the plan, journal the result. Every time.",
  "Progress isn't a straight line, but it does need a direction.",
  "You don't need motivation if the habit is already scheduled.",
  "The market will still be there tomorrow. Your discipline should be too.",
  "Do it today so future-you doesn't have to catch up.",
  "Boring, repeated actions build the results everyone else calls luck.",
  "Risk management is a habit, not a reaction.",
  "Show up for the days you don't feel like it - that's the whole game.",
  "Your future self is watching what you do right now.",
  "Habits are votes for the identity you're trying to build.",
];

String quoteOfTheDay([DateTime? now]) {
  final today = now ?? DateTime.now();
  final dayOfYear = int.parse(
    '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}',
  );
  final index = dayOfYear % motivationalQuotes.length;
  return motivationalQuotes[index];
}
