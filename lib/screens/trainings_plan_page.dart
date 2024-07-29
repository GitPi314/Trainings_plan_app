import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:reorderables/reorderables.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import 'workout_detail_page.dart';
import 'add_workout_page.dart';
import 'calendar_page.dart'; // Importiere die Kalenderseite
import 'package:intl/intl.dart';

class TrainingPlanPage extends StatefulWidget {
  const TrainingPlanPage({super.key});

  @override
  _TrainingPlanPageState createState() => _TrainingPlanPageState();
}

class _TrainingPlanPageState extends State<TrainingPlanPage> {
  late Box<Workout> workoutBox;
  late Box<Exercise> exerciseBox;
  late Box settingsBox;
  int completedWorkouts = 0;
  List<Workout> workouts = [];
  List<Workout> archivedWorkouts = [];
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    workoutBox = Hive.box<Workout>('workoutBox');
    exerciseBox = Hive.box<Exercise>('exerciseBox');
    settingsBox = Hive.box('settings');
    _loadCompletedWorkouts();
    workouts = workoutBox.values.where((workout) => !workout.archived).toList().cast<Workout>();
    archivedWorkouts = workoutBox.values.where((workout) => workout.archived).toList().cast<Workout>();
    workouts.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    archivedWorkouts.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    // Reset weekly stats if needed and schedule next reset
    _resetWeeklyStats();

    workoutBox.listenable().addListener(_updateWorkouts);
  }

  @override
  void dispose() {
    workoutBox.listenable().removeListener(_updateWorkouts);
    _resetTimer?.cancel();
    super.dispose();
  }

  void _loadCompletedWorkouts() {
    completedWorkouts = workoutBox.values.where((workout) => workout.completed).length;
  }

  void _updateWorkouts() {
    if (!mounted) return;
    setState(() {
      workouts = workoutBox.values.where((workout) => !workout.archived).toList().cast<Workout>();
      archivedWorkouts = workoutBox.values.where((workout) => workout.archived).toList().cast<Workout>();
      workouts.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      archivedWorkouts.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      _loadCompletedWorkouts(); // Lade die Anzahl der abgeschlossenen Workouts neu
    });
  }

  void _addWorkout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddWorkoutPage()),
    );
  }

  void _deleteWorkout(int index) {
    final workout = workouts[index];
    final exercises = exerciseBox.values.where((exercise) => exercise.workoutId == workout.key).cast<Exercise>().toList();
    for (var exercise in exercises) {
      exercise.delete();
    }
    workout.delete();
    setState(() {
      workouts.removeAt(index);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Workout item = workouts.removeAt(oldIndex);
      workouts.insert(newIndex, item);
      for (int i = 0; i < workouts.length; i++) {
        workouts[i].orderIndex = i;
        workouts[i].save();
      }
    });
  }

  int get totalWorkouts => settingsBox.get('totalWorkouts', defaultValue: 3);

  void _resetWeeklyStats() {
    final DateTime now = DateTime.now();
    final DateTime lastReset = settingsBox.get('lastReset', defaultValue: DateTime(1970)) as DateTime;
    final DateTime nextReset = _getNextMondayAtSixAM(now);

    if (now.isAfter(nextReset)) {
      setState(() {
        completedWorkouts = 0;
        settingsBox.put('completedWorkouts', completedWorkouts);
        settingsBox.put('lastReset', now);
        for (var workout in workouts) {
          workout.completed = false;
          workout.save();
        }
      });
    }

    // Schedule the next reset
    final Duration timeUntilNextReset = nextReset.difference(now);
    _resetTimer = Timer(timeUntilNextReset, _resetWeeklyStats);
  }

  DateTime _getNextMondayAtSixAM(DateTime from) {
    final int daysToAdd = (DateTime.monday - from.weekday + 7) % 7;
    final DateTime nextMonday = from.add(Duration(days: daysToAdd));
    return DateTime(nextMonday.year, nextMonday.month, nextMonday.day, 6);
  }

  void _markWorkoutCompleted(int index) {
    setState(() {
      completedWorkouts++;
      settingsBox.put('completedWorkouts', completedWorkouts);
      workouts[index].completed = true;
      workouts[index].save();
    });
  }

  void _archiveWorkout(int index) {
    setState(() {
      final workout = workouts.removeAt(index);
      workout.archived = true;
      workout.save();
      archivedWorkouts.add(workout);
    });
  }

  void _unarchiveWorkout(int index) {
    setState(() {
      final workout = archivedWorkouts.removeAt(index);
      workout.archived = false;
      workout.save();
      workouts.add(workout);
      workouts.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    });
  }

  void _navigateToCalendarPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CalendarPage()), // Leite zur Kalenderseite weiter
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GestureDetector(
            onTap: _navigateToCalendarPage, // Navigiere zur Kalenderseite
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                color: Colors.blue,
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    'Workouts Completed: $completedWorkouts / $totalWorkouts',
                    style: const TextStyle(color: Colors.white, fontSize: 21),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: completedWorkouts / totalWorkouts,
                    backgroundColor: Colors.white54,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: workoutBox.listenable(),
              builder: (context, Box<Workout> box, _) {
                if (box.values.isEmpty) {
                  return const Center(
                    child: Text('No workouts added.'),
                  );
                }

                return ListView(
                  children: [
                    ReorderableColumn(
                      onReorder: _onReorder,
                      children: [
                        for (int index = 0; index < workouts.length; index++)
                          Dismissible(
                            key: ValueKey(workouts[index]),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              _deleteWorkout(index);
                            },
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: WorkoutBox(
                              workout: workouts[index],
                              onCompleted: () => _markWorkoutCompleted(index),
                              onArchive: () => _archiveWorkout(index),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ExpansionTile(
                      title: const Text(
                        'Archivierte Pläne',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      collapsedIconColor: Colors.white,
                      iconColor: Colors.white,
                      children: archivedWorkouts.map((workout) {
                        int index = archivedWorkouts.indexOf(workout);
                        return WorkoutBox(
                          workout: workout,
                          onCompleted: () {},
                          onArchive: () => _unarchiveWorkout(index),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addWorkout,
        label: const Text('Add Workout'),
        icon: const Icon(Icons.add),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class WorkoutBox extends StatefulWidget {
  final Workout workout;
  final VoidCallback onCompleted;
  final VoidCallback onArchive;

  const WorkoutBox({super.key, required this.workout, required this.onCompleted, required this.onArchive});

  @override
  _WorkoutBoxState createState() => _WorkoutBoxState();
}

class _WorkoutBoxState extends State<WorkoutBox> {
  bool isEditing = false;
  late String _title;
  late List<String> _muscleGroups;

  @override
  void initState() {
    super.initState();
    _title = widget.workout.title;
    _muscleGroups = widget.workout.muscleGroups;
  }

  void _saveWorkout() {
    setState(() {
      widget.workout.title = _title;
      widget.workout.muscleGroups = _muscleGroups;
      widget.workout.save();
      isEditing = false;
    });
  }

  String _formatDate(int timestamp) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: !isEditing
          ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDetailPage(workout: widget.workout),
          ),
        );
      }
          : null,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  isEditing
                      ? Expanded(
                    child: TextFormField(
                      initialValue: _title,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      onChanged: (value) {
                        _title = value;
                      },
                    ),
                  )
                      : Row(
                    children: [
                      Text(
                        widget.workout.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.workout.completed)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                  isEditing
                      ? IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _saveWorkout,
                  )
                      : PopupMenuButton(
                    onSelected: (value) {
                      if (value == 'edit') {
                        setState(() {
                          isEditing = true;
                        });
                      } else if (value == 'archive') {
                        widget.onArchive();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(widget.workout.archived ? Icons.unarchive : Icons.archive, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(widget.workout.archived ? 'Unarchive' : 'Archive'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              isEditing
                  ? TextFormField(
                initialValue: _muscleGroups.join(', '),
                decoration: InputDecoration(
                  labelText: 'Muscle Groups (comma separated)',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                onChanged: (value) {
                  _muscleGroups = value.split(',').map((e) => e.trim()).toList();
                },
              )
                  : Text(
                widget.workout.muscleGroups.join(', '),
                style: const TextStyle(fontSize: 20, color: Colors.white, decoration: TextDecoration.underline),
              ),
              const SizedBox(height: 10),
              Text(
                'Avg. Duration: ${(widget.workout.averageDuration / 60).toStringAsFixed(2)} min',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Last trained:    ${widget.workout.lastTrained != null ? _formatDate(widget.workout.lastTrained!) : 'N/A'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
