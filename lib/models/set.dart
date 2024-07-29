import 'package:hive/hive.dart';

part 'set.g.dart';

@HiveType(typeId: 2)
class Set extends HiveObject {
  @HiveField(0)
  int exerciseId;

  @HiveField(1)
  int reps;

  @HiveField(2)
  double weight;

  @HiveField(3)
  int rest;

  @HiveField(4)
  bool completed;

  @HiveField(5)
  int initialReps;

  @HiveField(6)
  double initialWeight;

  @HiveField(7)
  int initialRest;

  Set({
    required this.exerciseId,
    this.reps = 0,
    this.weight = 0.0,
    this.rest = 0,
    this.completed = false,
    this.initialReps = 0,
    this.initialWeight = 0.0,
    this.initialRest = 0,
  });
}
