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

  void _saveWorkout() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newWorkout = Workout(
        title: _title,
        muscleGroups: _muscleGroups,
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
      appBar: AppBar(
        title: const Text('Add Workout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
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
              TextFormField(
                decoration: const InputDecoration(labelText: 'Muscle Groups (comma separated)'),
                onSaved: (value) {
                  _muscleGroups = value!.split(',').map((e) => e.trim()).toList();
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter muscle groups';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveWorkout,
                child: const Text('Save Workout', style: TextStyle(color: Colors.white),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
