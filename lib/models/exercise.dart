import 'package:hive/hive.dart';

part 'exercise.g.dart';

@HiveType(typeId: 1)
class Exercise extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int? workoutId;

  @HiveField(2)
  String? image;

  @HiveField(3)
  String? notes;

  Exercise({required this.name, this.workoutId, this.image, this.notes});
}
