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
      fecha: fields[0] as DateTime?,
      lugar: fields[1] as String?,
      frames: (fields[2] as List)
          .map((dynamic e) => (e as List).cast<String>())
          .toList(),
      notas: fields[3] as String?,
      total: fields[4] as int,
      pinesPorTiro: (fields[5] as List?)
          ?.map((dynamic e) => (e as List)
              .map((dynamic e) => (e as List?)?.cast<int>())
              .toList())
          ?.toList(),
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
      ..write(obj.frames)
      ..writeByte(3)
      ..write(obj.notas)
      ..writeByte(4)
      ..write(obj.total)
      ..writeByte(5)
      ..write(obj.pinesPorTiro);
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
