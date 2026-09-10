// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitLogAdapter extends TypeAdapter<HabitLog> {
  @override
  final int typeId = 1;

  @override
  HabitLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitLog(
      id: fields[0] as String,
      habitId: fields[1] as String,
      date: fields[2] as DateTime,
      completed: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HabitLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.habitId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.completed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
