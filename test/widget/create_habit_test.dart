import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:habitflow/app.dart';
import 'package:habitflow/data/habit_repository.dart';
import 'package:habitflow/models/habit.dart';
import 'package:habitflow/models/habit_log.dart';

import '../test_helpers.dart';

/// Two gotchas this file's structure exists to avoid regressing on:
///
/// 1. `HabitRepository` does real dart:io file writes (Hive). Inside a
///    `testWidgets` body, Flutter runs on a fake clock that does not let
///    genuine async I/O resolve on its own - any await on real repository
///    I/O triggered during the test body (not just in setUp) needs a real
///    event-loop turn, which `tester.runAsync(...)` provides.
/// 2. A duration-LESS `tester.pump()` advances the fake animation clock
///    by zero. A page-transition `AnimationController` (e.g. from
///    `Navigator.pop()`) never progresses under that, so a popped route's
///    widgets would appear to "never leave the tree" no matter how many
///    times you pump - `pumpAndSettle()` already passes real durations
///    internally, so prefer it (or an explicit `pump(duration)`) over a
///    bare `pump()` whenever an animation needs to actually finish.
///
/// This is its own file (not grouped with other widget tests) so it runs
/// as its own `flutter_tester` process - some Hive/box-registry state
/// seemed to linger between `testWidgets` in the same file in this dev
/// environment, and isolating each real-I/O widget test into its own
/// file sidesteps that entirely.
void main() {
  testWidgets('shows empty state, creates a habit via the FAB, and it appears on Home',
      (tester) async {
    final tempDir = await setUpTestHive();
    final habitsBox = await Hive.openBox<Habit>('habits');
    final logsBox = await Hive.openBox<HabitLog>('habit_logs');
    final repo = HabitRepository(habitsBox: habitsBox, logsBox: logsBox);

    await tester.pumpWidget(HabitFlowApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('HabitFlow'), findsOneWidget);
    expect(find.textContaining('No habits scheduled'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('New habit'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Drink water');
    await tester.tap(find.text('Create habit'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing, reason: 'should have navigated back off the form');
    expect(find.text('Drink water'), findsOneWidget);
    expect(find.textContaining('No habits scheduled'), findsNothing);

    await tearDownTestHive(tempDir);
  });
}
