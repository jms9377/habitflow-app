import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/habit_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await HabitRepository.registerAdapters();
  await HabitRepository.openBoxes();

  runApp(HabitFlowApp(repository: HabitRepository()));
}
