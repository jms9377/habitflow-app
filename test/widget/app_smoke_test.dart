import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:habitflow/app.dart';
import 'package:habitflow/data/habit_repository.dart';
import 'package:habitflow/models/habit.dart';
import 'package:habitflow/models/habit_category.dart';
import 'package:habitflow/models/habit_log.dart';

import '../test_helpers.dart';

/// IMPORTANT: HabitRepository does real dart:io file writes (Hive). Inside
/// a `testWidgets` body, Flutter runs on a fake clock (`FakeAsync`) that
/// does not let genuine async I/O resolve on its own - any await on real
/// repository I/O triggered during the test body (not just in setUp) must
/// go through `tester.runAsync(...)`, or the awaited Future simply never
/// completes. This bit us once already (see git history) - don't remove
/// the runAsync wrappers below.
void main() {
  late Directory tempDir;
  late HabitRepository repo;

  setUp(() async {
    tempDir = await setUpTestHive();
    final habitsBox = await Hive.openBox<Habit>('habits');
    final logsBox = await Hive.openBox<HabitLog>('habit_logs');
    repo = HabitRepository(habitsBox: habitsBox, logsBox: logsBox);
  });

  tearDown(() async {
    await tearDownTestHive(tempDir);
  });

  testWidgets('shows empty state, creates a habit via the FAB, and it appears on Home',
      (tester) async {
    await tester.pumpWidget(HabitFlowApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('HabitFlow'), findsOneWidget);
    expect(find.textContaining('No habits scheduled'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('New habit'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Drink water');
    await tester.runAsync(() async {
      await tester.tap(find.text('Create habit'));
      // The button's onPressed (_save) is fire-and-forget from the
      // framework's point of view - it awaits a REAL Hive write that
      // isn't tied to the frame scheduler, so pumpAndSettle alone won't
      // wait for it. Give the real event loop a turn first.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
    });

    expect(find.byType(TextField), findsNothing, reason: 'should have navigated back off the form');
    expect(find.text('Drink water'), findsOneWidget);
    expect(find.textContaining('No habits scheduled'), findsNothing);
  });

  testWidgets('the today progress ring reflects toggling a habit complete', (tester) async {
    final habit = await repo.addHabit(
      name: 'Meditate',
      emoji: '🧘',
      category: HabitCategory.general,
      colorValue: 0xFF2DD4BF,
    );

    await tester.pumpWidget(HabitFlowApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('0 / 1'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(ValueKey('toggle-${habit.id}')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
    });

    expect(find.textContaining('1 / 1'), findsOneWidget);
  });
}
