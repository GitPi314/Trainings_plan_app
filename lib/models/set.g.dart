// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SetAdapter extends TypeAdapter<Set> {
  @override
  final int typeId = 2;

  @override
  Set read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Set(
      exerciseId: fields[0] as int,
      reps: fields[1] as int,
      weight: fields[2] as double,
      rest: fields[3] as int,
      completed: fields[4] as bool,
      initialReps: fields[5] as int,
      initialWeight: fields[6] as double,
      initialRest: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Set obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.reps)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.rest)
      ..writeByte(4)
      ..write(obj.completed)
      ..writeByte(5)
      ..write(obj.initialReps)
      ..writeByte(6)
      ..write(obj.initialWeight)
      ..writeByte(7)
      ..write(obj.initialRest);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
