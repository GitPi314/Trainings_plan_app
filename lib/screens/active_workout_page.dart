import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/set.dart';
import 'set_detail_page.dart';
import 'dart:async';
import 'set_rest_timer_page.dart';

class ActiveWorkoutPage extends StatefulWidget {
  final Workout workout;

  const ActiveWorkoutPage({super.key, required this.workout});

  @override
  _ActiveWorkoutPageState createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  late Box<Exercise> exerciseBox;
  late Box<Set> setBox;
  List<Exercise> exercises = [];
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  bool _shouldSaveWorkout = true;

  @override
  void initState() {
    super.initState();
    exerciseBox = Hive.box<Exercise>('exerciseBox');
    setBox = Hive.box<Set>('setBox');
    exercises = exerciseBox.values.where((exercise) => exercise.workoutId == widget.workout.key as int).cast<Exercise>().toList();
    _resetSetCompletion();
    _startTimer();
  }

  void _resetSetCompletion() {
    for (var set in setBox.values) {
      if (exercises.any((exercise) => exercise.key == set.exerciseId)) {
        set.completed = false;
        set.save();
      }
    }
  }

  void _startTimer() {
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _isRunning = false;
  }

  void _endWorkout() {
    _stopTimer();
    if (_shouldSaveWorkout) {
      final currentDuration = (widget.workout.totalDuration ?? 0) + _elapsedSeconds;
      final totalWorkouts = (widget.workout.totalWorkouts ?? 0) + 1;

      widget.workout.lastTrained = DateTime.now().millisecondsSinceEpoch;
      widget.workout.totalDuration = currentDuration;
      widget.workout.totalWorkouts = totalWorkouts;
      widget.workout.completed = true;
      widget.workout.averageDuration = (currentDuration / totalWorkouts).round(); // Speichern Sie die durchschnittliche Dauer in Sekunden
      widget.workout.save();
    }

    Navigator.pop(context, _elapsedSeconds);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _toggleSetCompletion(Set set, int setIndex) {
    set.completed = !set.completed;
    set.save();
    setState(() {});
    if (set.completed) {
      int restTime = set.rest ?? 60;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SetRestTimerPage(setIndex: setIndex, restTime: restTime),
        ),
      );
    }
  }

  bool _isExerciseCompleted(Exercise exercise) {
    final sets = setBox.values.where((s) => s.exerciseId == exercise.key).toList();
    return sets.every((set) => set.completed == true); // Sicherheitsüberprüfung
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.title),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text(
              'Workout Timer: ${_formatDuration(_elapsedSeconds)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                final sets = setBox.values.where((set) => set.exerciseId == exercise.key).toList();
                //final exerciseCompleted = _isExerciseCompleted(exercise);
                final isCurrentExercise = index == 0 || _isExerciseCompleted(exercises[index - 1]);

                return Stack(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.all(10),
                      //color: Colors.grey[600],
                      color: Colors.black,
                      //color: exerciseCompleted ? Colors.grey[700] : (isCurrentExercise ? Colors.grey[400] : Colors.grey[700]),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  exercise.name,
                                  style: TextStyle(
                                    fontSize: isCurrentExercise ? 22 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add, color: Colors.blue, size: isCurrentExercise ? 30 : 24),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SetDetailPage(exercise: exercise),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            if (exercise.notes != null && exercise.notes!.isNotEmpty)
                              Text(
                                exercise.notes!,
                                style: TextStyle(
                                  fontSize: isCurrentExercise ? 18 : 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white70,
                                ),
                              ),
                            const Divider(color: Colors.white70),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                    child: Text('Satz', style: TextStyle(fontSize: isCurrentExercise ? 18.5 : 16, color: Colors.white)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Wdh.', style: TextStyle(fontSize: isCurrentExercise ? 18.5 : 16, color: Colors.white), textAlign: TextAlign.center),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Gewicht', style: TextStyle(fontSize: isCurrentExercise ? 18.5 : 16, color: Colors.white), textAlign: TextAlign.center),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Pause', style: TextStyle(fontSize: isCurrentExercise ? 18.5 : 16, color: Colors.white), textAlign: TextAlign.center),
                                ),
                                const SizedBox(width: 50), // Platzhalter für das Erledigt-Symbol
                              ],
                            ),
                            Column(
                              children: sets.map((set) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                                  padding: const EdgeInsets.all(0.0),
                                  decoration: BoxDecoration(
                                    color: set.completed ? Colors.grey[850] : Colors.grey[750],
                                    borderRadius: BorderRadius.circular(50.0),
                                    border: Border.all(color: Colors.grey),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Text(
                                            (sets.indexOf(set) + 1).toString(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isCurrentExercise ? 22 : 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Text(
                                            set.reps.toString(),
                                            style: TextStyle(
                                              color: set.reps > set.initialReps ? Colors.green : Colors.white,
                                              fontSize: isCurrentExercise ? 22 : 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Text(
                                            set.weight.toString(),
                                            style: TextStyle(
                                              color: set.weight > set.initialWeight ? Colors.green : Colors.white,
                                              fontSize: isCurrentExercise ? 22 : 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Text(
                                            set.rest.toString(),
                                            style: TextStyle(
                                              color: set.rest > set.initialRest ? Colors.green : Colors.white,
                                              fontSize: isCurrentExercise ? 22 : 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.check_circle, color: set.completed ? Colors.green : Colors.grey),
                                        onPressed: () => _toggleSetCompletion(set, sets.indexOf(set) + 1),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    /*
                    if (exerciseCompleted)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            // Möglichkeit zum Zurücksetzen der Übung, wenn sie abgeschlossen ist
                            for (var set in sets) {
                              set.completed = false;
                              set.save();
                            }
                            setState(() {});
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),

                            child: const Center(
                              child: Text(
                                "Übung abgeschlossen",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                     */
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Checkbox(
                checkColor: Colors.black,
                activeColor: Colors.grey,
                value: _shouldSaveWorkout,
                onChanged: (bool? value) {
                  setState(() {
                    _shouldSaveWorkout = value ?? true;
                  });
                },
              ),
              const Text('Workout Speichern?'),
            ],
          ),
          ElevatedButton(
            onPressed: _isRunning ? _endWorkout : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
            ),
            child: const Text('End Workout', style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
