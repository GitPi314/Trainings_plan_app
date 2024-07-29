import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:reorderables/reorderables.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/set.dart';
import 'set_detail_page.dart';
import 'active_workout_page.dart';

class WorkoutDetailPage extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailPage({super.key, required this.workout});

  @override
  _WorkoutDetailPageState createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  late Box<Exercise> exerciseBox;
  late Box<Set> setBox;
  List<Exercise> exercises = [];

  @override
  void initState() {
    super.initState();
    exerciseBox = Hive.box<Exercise>('exerciseBox');
    setBox = Hive.box<Set>('setBox');
    exercises = exerciseBox.values.where((exercise) => exercise.workoutId == widget.workout.key as int).cast<Exercise>().toList();
  }

  void _addExercise() {
    showDialog(
      context: context,
      builder: (context) {
        String exerciseName = '';
        return AlertDialog(
          title: const Text('Add Exercise'),
          content: TextFormField(
            decoration: const InputDecoration(labelText: 'Exercise Name'),
            onChanged: (value) {
              exerciseName = value;
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (exerciseName.isNotEmpty) {
                  final newExercise = Exercise(name: exerciseName, workoutId: widget.workout.key as int);
                  exerciseBox.add(newExercise);
                  setState(() {
                    exercises = exerciseBox.values.where((exercise) => exercise.workoutId == widget.workout.key as int).cast<Exercise>().toList();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _selectImage(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Image'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    exercise.image = 'assets/image1.png';
                    exercise.save();
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: Image.asset('assets/image1.png', height: 50),
                ),
                GestureDetector(
                  onTap: () {
                    exercise.image = 'assets/image2.png';
                    exercise.save();
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: Image.asset('assets/image2.png', height: 50),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Exercise item = exercises.removeAt(oldIndex);
      exercises.insert(newIndex, item);
    });
  }

  void _deleteExercise(int index) {
    exerciseBox.delete(exercises[index].key);
    setState(() {
      exercises.removeAt(index);
    });
  }

  Future<void> _startWorkout() async {
    final int? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutPage(workout: widget.workout),
      ),
    );
    if (result != null) {
      setState(() {
        exercises = exerciseBox.values.where((e) => e.workoutId == widget.workout.key as int).cast<Exercise>().toList();
      });
    }
  }

  Future<void> _navigateToSetDetail(Exercise exercise) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetDetailPage(exercise: exercise),
      ),
    );
    setState(() {
      exercises = exerciseBox.values.where((e) => e.workoutId == widget.workout.key as int).cast<Exercise>().toList();
    });
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
          ElevatedButton(
            onPressed: exercises.isNotEmpty ? _startWorkout : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
            ),
            child: const Text(
              "Start Workout",
              style: TextStyle(color: Colors.white70, fontSize: 28),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ReorderableColumn(
              onReorder: _onReorder,
              children: [
                for (int index = 0; index < exercises.length; index++)
                  Dismissible(
                    key: ValueKey(exercises[index]),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      _deleteExercise(index);
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: GestureDetector(
                      onTap: () => _navigateToSetDetail(exercises[index]),
                      child: ExerciseBox(
                        exercise: exercises[index],
                        onSelectImage: _selectImage,
                        setBox: setBox,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExercise,
        label: const Text('Add Exercise'),
        icon: const Icon(Icons.add),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ExerciseBox extends StatelessWidget {
  final Exercise exercise;
  final Function(Exercise) onSelectImage;
  final Box<Set> setBox;

  const ExerciseBox({
    super.key,
    required this.exercise,
    required this.onSelectImage,
    required this.setBox,
  });

  @override
  Widget build(BuildContext context) {
    final sets = setBox.values.where((set) => set.exerciseId == exercise.key)
        .toList();
    final setCount = sets.length;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => onSelectImage(exercise),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey,
                    backgroundImage: (exercise.image != null &&
                        exercise.image!.isNotEmpty)
                        ? AssetImage(exercise.image!)
                        : null,
                    child: (exercise.image == null || exercise.image!.isEmpty)
                        ? const Icon(Icons.edit, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Sets: $setCount',
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const Text('Avg. Duration: 0',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Info logic
                  },
                  icon: const Icon(Icons.info, color: Colors.white),
                  label: const Text('Info',
                      style: TextStyle(color: Colors.white, fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(90, 35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // History logic
                  },
                  icon: const Icon(Icons.timeline, color: Colors.white),
                  label: const Text('History',
                      style: TextStyle(color: Colors.white, fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(90, 35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
