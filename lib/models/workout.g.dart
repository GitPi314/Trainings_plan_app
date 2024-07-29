// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutAdapter extends TypeAdapter<Workout> {
  @override
  final int typeId = 0;

  @override
  Workout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Workout(
      title: fields[0] as String,
      muscleGroups: (fields[1] as List).cast<String>(),
      lastTrained: fields[2] as int?,
      orderIndex: fields[3] as int,
      averageDuration: fields[4] as int,
      totalDuration: fields[5] as int,
      totalWorkouts: fields[6] as int,
      completed: fields[7] as bool,
      archived: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Workout obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.muscleGroups)
      ..writeByte(2)
      ..write(obj.lastTrained)
      ..writeByte(3)
      ..write(obj.orderIndex)
      ..writeByte(4)
      ..write(obj.averageDuration)
      ..writeByte(5)
      ..write(obj.totalDuration)
      ..writeByte(6)
      ..write(obj.totalWorkouts)
      ..writeByte(7)
      ..write(obj.completed)
      ..writeByte(8)
      ..write(obj.archived);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
