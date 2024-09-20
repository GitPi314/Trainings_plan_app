import 'package:Fitness/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../models/exercise.dart';
import '../models/workout.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Box settingsBox;
  late int totalWorkouts;
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settings');
    totalWorkouts = settingsBox.get('totalWorkouts', defaultValue: 3);
    isDarkMode = settingsBox.get('isDarkMode', defaultValue: false);
  }

  void _updateTotalWorkouts(int value) {
    setState(() {
      totalWorkouts = value;
    });
    settingsBox.put('totalWorkouts', value);
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      isDarkMode = value;
    });
    settingsBox.put('isDarkMode', value);
    final parentState = context.findAncestorStateOfType<HomeScreenState>();
    parentState?.widget.onThemeChanged(value);
  }

  void _clearDatabase() async {
    var workoutBox = Hive.box<Workout>('workoutBox');
    var exerciseBox = Hive.box<Exercise>('exerciseBox');
    var setBox = Hive.box<Set>('setBox');
    var settingsBox = Hive.box('settings');

    await workoutBox.clear();
    await exerciseBox.clear();
    await setBox.clear();
    await settingsBox.clear();

    Fluttertoast.showToast(
      msg: "All data has been cleared.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
    );

    setState(() {
      totalWorkouts = 3;
      isDarkMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: isDarkMode,
              onChanged: _toggleDarkMode,
            ),
          ),
          ListTile(
            title: const Text('Total Workouts per Week'),
            subtitle: Text('$totalWorkouts'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    int tempValue = totalWorkouts;
                    return AlertDialog(
                      title: const Text('Edit Total Workouts'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Select the total number of workouts you aim to complete per week.'),
                          const SizedBox(height: 10),
                          DropdownButton<int>(
                            value: tempValue,
                            items: List.generate(7, (index) => index + 1)
                                .map((value) => DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString()),
                            ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                tempValue = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            _updateTotalWorkouts(tempValue);
                            Navigator.pop(context);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          ListTile(
            title: const Text('Clear All Data'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Clear All Data'),
                      content: const Text('Are you sure you want to clear all data? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            _clearDatabase();
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
