import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:habitflow/app.dart';
import 'package:habitflow/data/habit_repository.dart';
import 'package:habitflow/models/habit.dart';
import 'package:habitflow/models/habit_category.dart';
import 'package:habitflow/models/habit_log.dart';

import '../test_helpers.dart';

/// See the comment at the top of create_habit_test.dart for why this is a
/// standalone file rather than grouped with the other widget test.
void main() {
  testWidgets('the today progress ring reflects toggling a habit complete', (tester) async {
    final tempDir = await setUpTestHive();
    final habitsBox = await Hive.openBox<Habit>('habits');
    final logsBox = await Hive.openBox<HabitLog>('habit_logs');
    final repo = HabitRepository(habitsBox: habitsBox, logsBox: logsBox);

    final habit = await repo.addHabit(
      name: 'Meditate',
      emoji: '🧘',
      category: HabitCategory.general,
      colorValue: 0xFF2DD4BF,
    );

    await tester.pumpWidget(HabitFlowApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('0 / 1'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('toggle-${habit.id}')));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('1 / 1'), findsOneWidget);

    await tearDownTestHive(tempDir);
  });
}
