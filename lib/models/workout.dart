import 'package:hive/hive.dart';

part 'workout.g.dart';

@HiveType(typeId: 0)
class Workout extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  List<String> muscleGroups;

  @HiveField(2)
  int? lastTrained;

  @HiveField(3)
  int orderIndex;

  @HiveField(4)
  int averageDuration;

  @HiveField(5)
  int totalDuration;

  @HiveField(6)
  int totalWorkouts;

  @HiveField(7)
  bool completed = false;

  @HiveField(8)
  bool archived = false;

  Workout({
    required this.title,
    required this.muscleGroups,
    this.lastTrained,
    this.orderIndex = 0,
    this.averageDuration = 0,
    this.totalDuration = 0,
    this.totalWorkouts = 0,
    this.completed = false,
    this.archived = false,
  });
}
