import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'models/workout.dart';
import 'models/exercise.dart';
import 'models/set.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  Hive.registerAdapter(WorkoutAdapter());
  Hive.registerAdapter(ExerciseAdapter());
  Hive.registerAdapter(SetAdapter());

  await Hive.openBox<Workout>('workoutBox');
  await Hive.openBox<Exercise>('exerciseBox');
  await Hive.openBox('settings');
  await Hive.openBox<Set>('setBox');
  await Hive.openBox<int>('favoriteTimesBox'); // Öffnen der favoriteTimesBox

  migrateExercises(); // Führen Sie die Migration durch
  migrateWorkouts(); // Führen Sie die Migration durch

  runApp(const MyApp());
}

/*
Future<void> clearHiveData() async {
  var workoutBox = Hive.box<Workout>('workoutBox');
  var exerciseBox = Hive.box<Exercise>('exerciseBox');
  await workoutBox.clear();
  await exerciseBox.clear();
}
 */

void migrateExercises() {
  final exerciseBox = Hive.box<Exercise>('exerciseBox');
  for (var exercise in exerciseBox.values) {
    if (exercise.workoutId == null) {
      exercise.workoutId = 0;  // Ein Standardwert, falls kein `workoutId` vorhanden ist
      exercise.save();
    }
  }
}

void migrateWorkouts() {
  final workoutBox = Hive.box<Workout>('workoutBox');
  for (var i = 0; i < workoutBox.length; i++) {
    var workout = workoutBox.getAt(i);
    if (workout != null) {
      if (workout.lastTrained is DateTime) {
        workout.lastTrained = (workout.lastTrained as DateTime).millisecondsSinceEpoch;
      } else {
        workout.lastTrained ??= 0;
      }
      workout.save();
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = Hive.box('settings').get('isDarkMode', defaultValue: false);

  void toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });
    Hive.box('settings').put('isDarkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Training Plan App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
        ),
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
        ),
        appBarTheme: AppBarTheme(
          color: Colors.blue,
          iconTheme: const IconThemeData(color: Colors.white),
          toolbarTextStyle: const TextTheme(
            titleLarge: TextStyle(color: Colors.white, fontSize: 20),
          ).bodyMedium,
          titleTextStyle: const TextTheme(
            titleLarge: TextStyle(color: Colors.white, fontSize: 20),
          ).titleLarge,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
        ),
        scaffoldBackgroundColor: Color(0XFF303D44),
        //scaffoldBackgroundColor: Color(0XFF60727B),
        cardColor: const Color(0XFF1C2428),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white54, fontSize: 17),
        ),
        appBarTheme: AppBarTheme(
          color: Colors.grey[900],
          iconTheme: const IconThemeData(color: Colors.white),
          toolbarTextStyle: const TextTheme(
            titleLarge: TextStyle(color: Colors.white, fontSize: 20),
          ).bodyMedium,
          titleTextStyle: const TextTheme(
            titleLarge: TextStyle(color: Colors.white, fontSize: 20),
          ).titleLarge,
        ),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        onThemeChanged: toggleTheme,
      ),
    );
  }
}
