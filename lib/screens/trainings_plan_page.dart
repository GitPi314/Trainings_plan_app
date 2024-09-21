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

          Container(
            color: const Color(0XFF075584),
            padding: const EdgeInsets.all(16.0),
            /*
              decoration: BoxDecoration(
                //borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent, Colors.pink.shade400],
                  stops: [0.0, 0.5, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),

               */
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Linke Seite: "Workouts Completed" Box (2/3 der Breite)
                Expanded(
                  flex: 4,
                  child: GestureDetector(
                    onTap: _navigateToCalendarPage,
                    child: Container(
                      padding: const EdgeInsets.only(left: 0.0, top: 16.0, bottom: 16.0, right: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // Minimiert die Höhe auf das Notwendige
                        children: [
                          Text(
                            'Workouts Completed: $completedWorkouts / $totalWorkouts',
                            style: const TextStyle(color: Colors.white, fontSize: 21),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            borderRadius: const BorderRadius.all(Radius.circular(50)),
                            minHeight: 8,
                            value: completedWorkouts / totalWorkouts,
                            backgroundColor: Colors.white54,
                            //valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0XFF43A047)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Rechte Seite: Plus-Icon (1/3 der Breite)
                Expanded(
                  flex: -2,
                  child: GestureDetector(
                    onTap: _addWorkout,
                    child: Container(
                      padding: const EdgeInsets.only(right: 6.0, top: 16.0, bottom: 16.0, left: 8.0),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              colors: [Colors.blue, Colors.green],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcIn,
                          child: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.white, // Die Farbe wird durch den Shader überschrieben
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ... Restlicher Code

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
      /*
      floatingActionButton: Container(

        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(50)),
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.blueAccent, Colors.pink],
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: MaterialButton(
          onPressed: _addWorkout,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.white),
              SizedBox(width: 8),
              Text('Add Workout', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
      */

      //floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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

  void _removeMuscleGroup(String muscleGroup) {
    setState(() {
      // Entferne die Muskelgruppe aus der Liste
      _muscleGroups.remove(muscleGroup);

      // Aktualisiere das Workout-Objekt und speichere es in Hive
      widget.workout.muscleGroups = _muscleGroups;
      widget.workout.save();
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
                          fontSize: 28,
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
                    color: Color(0XFF1C2428),
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
              const SizedBox(height: 14),
              SizedBox(
                height: 35,  // Höhe der Tags angepasst
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: widget.workout.muscleGroups.map((muscleGroup) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 14.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0XFF1C2428),  // Hintergrundfarbe des Tags
                          borderRadius: BorderRadius.circular(30),  // Abgerundete Ecken
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,  // Minimale Breite, passend zum Inhalt
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                bottomLeft: Radius.circular(30),
                              ),  // Runden nur für die linke Seite (wo das Bild ist)
                              child: Image.asset(
                                'lib/assets/images/$muscleGroup.png',
                                height: 50,  // Höhe des Bildes gleich der Höhe des gesamten Tags
                                width: 50,   // Breite des Bildes
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),  // Abstand zum Text
                              child: Text(
                                muscleGroup,
                                style: TextStyle(fontSize: 16, color: Colors.grey[300]),
                              ),
                            ),
                            if (isEditing)
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _removeMuscleGroup(muscleGroup),  // Entferne Muskelgruppe
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 15),
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
