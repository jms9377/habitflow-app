import 'dart:io';

import 'package:hive/hive.dart';

import 'package:habitflow/data/habit_repository.dart';

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

Future<void> tearDownTestHive(Directory dir) async {
  await Hive.deleteFromDisk();
  if (dir.existsSync()) dir.deleteSync(recursive: true);
}
