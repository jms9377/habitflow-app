import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:habitflow/app.dart';
import 'package:habitflow/data/habit_repository.dart';
import 'package:habitflow/models/habit.dart';
import 'package:habitflow/models/habit_log.dart';

import '../test_helpers.dart';

/// Complements create_habit_defaults_to_daily_test.dart: switching to
/// "Custom days" and picking specific weekdays must save exactly those
/// days - and crucially, the toggles must start UNSELECTED (not
/// pre-checked) in custom mode, so tapping a day always means "add it".
void main() {
  testWidgets('switching to Custom days and picking one day saves only that day', (tester) async {
    final tempDir = await setUpTestHive();
    final habitsBox = await Hive.openBox<Habit>('habits');
    final logsBox = await Hive.openBox<HabitLog>('habit_logs');
    final repo = HabitRepository(habitsBox: habitsBox, logsBox: logsBox);

    await tester.pumpWidget(HabitFlowApp(repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Long run');

    await tester.tap(find.text('Días personalizados'));
    await tester.pumpAndSettle();

    // the weekday row should now be visible, starting with nothing selected
    await tester.tap(find.text('S').first); // "S" in L M X J V S D = Sábado (day 6)

    await tester.tap(find.text('Crear hábito'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    final habit = repo.allHabits.firstWhere((h) => h.name == 'Long run');
    expect(habit.activeWeekdays, [6]);
    expect(habit.isScheduledOn(DateTime(2025, 1, 4)), isTrue); // a Saturday
    expect(habit.isScheduledOn(DateTime(2025, 1, 5)), isFalse); // a Sunday

    await tearDownTestHive(tempDir);
  });
}
