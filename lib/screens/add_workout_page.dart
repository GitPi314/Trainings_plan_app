import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/workout.dart';

class AddWorkoutPage extends StatefulWidget {
  const AddWorkoutPage({super.key});

  @override
  _AddWorkoutPageState createState() => _AddWorkoutPageState();
}

class _AddWorkoutPageState extends State<AddWorkoutPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  List<String> _muscleGroups = [];
  List<String> selectedMuscleGroups = [];

  // Vordefinierte Muskelgruppen
  final List<String> predefinedMuscleGroups = [
    'Chest',
    'Back',
    'Tricep',
    'Shoulders',
    //'Legs',
    //'Arms',
    //'Core',
  ];

  void _saveWorkout() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newWorkout = Workout(
        title: _title,
        muscleGroups: selectedMuscleGroups,  // Gespeicherte Muskelgruppen
        averageDuration: 0,
        lastTrained: DateTime.now().millisecondsSinceEpoch,
      );
      final workoutBox = Hive.box<Workout>('workoutBox');
      workoutBox.add(newWorkout);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(height: 30,),
              TextFormField(
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(  // Rahmenfarbe, wenn das Feld fokussiert ist
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  enabledBorder: OutlineInputBorder(  // Rahmenfarbe, wenn das Feld nicht fokussiert ist
                    borderSide: BorderSide(color: Colors.grey, width: 2.0),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  hintText: "Workout Name",
                  fillColor: Colors.grey[600],  // Hintergrundfarbe des Textfelds
                  filled: true,  // Aktiviert die Hintergrundfarbe
                ),
                cursorColor: Colors.grey[200],
                onSaved: (value) {
                  _title = value!;
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),
              const Text(
                'Select Muscle Groups:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20,),
              Wrap(
                spacing: 14.0, // Abstand zwischen den Chips
                children: predefinedMuscleGroups.map((muscleGroup) {
                  final isSelected = selectedMuscleGroups.contains(muscleGroup);
                  return FilterChip(
                    label: Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8),  // Abstand für den Text nach dem Bild
                      child: Text(muscleGroup),
                    ),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          selectedMuscleGroups.add(muscleGroup);
                        } else {
                          selectedMuscleGroups.remove(muscleGroup);
                        }
                      });
                    },
                    avatar: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
                      ),  // Rundung nur auf der linken Seite
                      child: Image.asset(
                        'lib/assets/images/$muscleGroup.png',
                        height: 50,  // Bildhöhe gleich dem Chip
                        width: 50,   // Bildbreite passend zur Höhe
                        fit: BoxFit.cover,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),  // Runde Ecken des Chips
                    ),
                    backgroundColor: Color(0XFF1C2428),
                    selectedColor: Colors.blue.shade400,
                    padding: EdgeInsets.zero,  // Entferne jegliches Padding, damit das Bild bündig ist
                  );
                }).toList(),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Textfarbe des Buttons
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20), // Button größer machen (Abstände innen)
                  textStyle: const TextStyle(fontSize: 18), // Textgröße im Button
                  shape: RoundedRectangleBorder( // Button abgerundet machen
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _saveWorkout,
                child: const Text(
                  'Save Workout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
