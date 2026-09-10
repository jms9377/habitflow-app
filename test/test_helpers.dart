import 'dart:io';

import 'package:hive/hive.dart';

import 'package:habitflow/data/habit_repository.dart';
import 'package:habitflow/models/habit.dart';
import 'package:habitflow/models/habit_log.dart';

/// Sets up a throwaway Hive instance backed by a temp directory (not
/// Hive.initFlutter, which needs path_provider's platform channel - this
/// keeps the whole test suite platform-independent, pure Dart). Call
/// [tearDownTestHive] after each test.
Future<Directory> setUpTestHive() async {
  final dir = Directory.systemTemp.createTempSync('habitflow_test_');
  Hive.init(dir.path);
  await HabitRepository.registerAdapters();
  return dir;
}

/// Closes boxes individually rather than calling `Hive.deleteFromDisk()`.
/// The latter raced against Hive's own internal change-notification
/// stream when a box had just been written to (a `put()` right before
/// teardown) - manifesting as "Bad state: Cannot close sink while adding
/// stream" and hanging the test runner indefinitely (reproduced both
/// locally and in CI, where it ran for the full 6-hour job timeout before
/// being killed). Closing each box explicitly, after letting any pending
/// stream notification settle, avoids the race.
Future<void> tearDownTestHive(Directory dir) async {
  await Future<void>.delayed(Duration.zero);
  if (Hive.isBoxOpen(habitsBoxName)) {
    await Hive.box<Habit>(habitsBoxName).close();
  }
  if (Hive.isBoxOpen(logsBoxName)) {
    await Hive.box<HabitLog>(logsBoxName).close();
  }
  if (dir.existsSync()) dir.deleteSync(recursive: true);
}
