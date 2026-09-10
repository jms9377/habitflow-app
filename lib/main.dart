import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/habit_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es');
  await Hive.initFlutter();
  await HabitRepository.registerAdapters();
  await HabitRepository.openBoxes();

  runApp(HabitFlowApp(repository: HabitRepository()));
}
