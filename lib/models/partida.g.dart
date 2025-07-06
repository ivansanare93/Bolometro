// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partida.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PartidaAdapter extends TypeAdapter<Partida> {
  @override
  final int typeId = 0;

  @override
  Partida read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Partida(
      fecha: fields[0] as DateTime,
      lugar: fields[1] as String,
      tipo: fields[2] as String,
      frames: (fields[3] as List)
          .map((dynamic e) => (e as List).cast<String>())
          .toList(),
      notas: fields[4] as String?,
      total: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Partida obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.fecha)
      ..writeByte(1)
      ..write(obj.lugar)
      ..writeByte(2)
      ..write(obj.tipo)
      ..writeByte(3)
      ..write(obj.frames)
      ..writeByte(4)
      ..write(obj.notas)
      ..writeByte(5)
      ..write(obj.total);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartidaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
