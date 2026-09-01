// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bowling_ball.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BowlingBallAdapter extends TypeAdapter<BowlingBall> {
  @override
  final int typeId = 19;

  @override
  BowlingBall read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BowlingBall(
      id: fields[0] as String?,
      name: fields[1] as String,
      brand: fields[2] as String?,
      weightLbs: fields[3] as double,
      coverstock: fields[4] as String?,
      finish: fields[5] as String?,
      purchaseDate: fields[6] as DateTime?,
      isActive: fields[7] == null ? true : fields[7] as bool,
      notes: fields[8] as String?,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BowlingBall obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.brand)
      ..writeByte(3)
      ..write(obj.weightLbs)
      ..writeByte(4)
      ..write(obj.coverstock)
      ..writeByte(5)
      ..write(obj.finish)
      ..writeByte(6)
      ..write(obj.purchaseDate)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BowlingBallAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BallMaintenanceAdapter extends TypeAdapter<BallMaintenance> {
  @override
  final int typeId = 20;

  @override
  BallMaintenance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BallMaintenance(
      id: fields[0] as String?,
      ballId: fields[1] as String,
      type: fields[2] as String?,
      date: fields[3] as DateTime?,
      notes: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BallMaintenance obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ballId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BallMaintenanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
