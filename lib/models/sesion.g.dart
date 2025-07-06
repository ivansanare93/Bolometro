// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sesion.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SesionAdapter extends TypeAdapter<Sesion> {
  @override
  final int typeId = 1;

  @override
  Sesion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sesion(
      fecha: fields[0] as DateTime,
      lugar: fields[1] as String,
      tipo: fields[2] as String,
      partidas: (fields[3] as List).cast<Partida>(),
      notas: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Sesion obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.fecha)
      ..writeByte(1)
      ..write(obj.lugar)
      ..writeByte(2)
      ..write(obj.tipo)
      ..writeByte(3)
      ..write(obj.partidas)
      ..writeByte(4)
      ..write(obj.notas);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SesionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
