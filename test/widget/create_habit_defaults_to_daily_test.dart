import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:habitflow/app.dart';
import 'package:habitflow/data/habit_repository.dart';
import 'package:habitflow/models/habit.dart';
import 'package:habitflow/models/habit_log.dart';

import '../test_helpers.dart';

/// Regression test for a real bug report: a newly created habit didn't
/// show up in Home's "All" list even though it appeared in Stats. Root
/// cause was the Repeat-on weekday toggles starting pre-selected as
/// "every day" with no indication of that - tapping a day to "choose" it
/// actually deselected it, silently excluding days from the schedule.
/// This asserts the fix: creating a habit WITHOUT touching the Repeat
/// section at all must produce a habit scheduled every day.
void main() {
  testWidgets('a new habit defaults to every day when Repeat is left untouched', (tester) async {
    final tempDir = await setUpTestHive();
    final habitsBox = await Hive.openBox<Habit>('habits');
    final logsBox = await Hive.openBox<HabitLog>('habit_logs');
    final repo = HabitRepository(habitsBox: habitsBox, logsBox: logsBox);

    await tester.pumpWidget(HabitFlowApp(repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Stretch');
    await tester.tap(find.text('Crear hábito'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    final habit = repo.allHabits.firstWhere((h) => h.name == 'Stretch');
    expect(habit.isDaily, isTrue);
    expect(habit.activeWeekdays, unorderedEquals([1, 2, 3, 4, 5, 6, 7]));

    // and it must actually show up under Home's "All" list right away
    expect(find.text('Stretch'), findsOneWidget);

    await tearDownTestHive(tempDir);
  });
}
