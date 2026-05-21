// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nota.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotaAdapter extends TypeAdapter<Nota> {
  @override
  final int typeId = 2;

  @override
  Nota read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Nota(
      titulo: fields[0] as String,
      contenido: fields[1] as String,
      fechaCreacion: fields[2] as DateTime,
      fechaModificacion: fields[3] as DateTime,
      categoria: fields[4] as String?,
      favorita: fields[5] == null ? false : fields[5] as bool,
      colorValue: fields[6] as int?,
      id: fields[7] as String?,
      tags: (fields[8] as List?)?.cast<String>(),
      pinned: fields[9] == null ? false : fields[9] as bool,
      archivada: fields[10] == null ? false : fields[10] as bool,
      relatedSessionId: fields[11] as String?,
      tipo: fields[12] as String?,
      estado: fields[13] as String?,
      bolera: fields[14] as String?,
      patronAceite: fields[15] as String?,
      equipamientoUsado: fields[16] as String?,
      condicionPista: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Nota obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.titulo)
      ..writeByte(1)
      ..write(obj.contenido)
      ..writeByte(2)
      ..write(obj.fechaCreacion)
      ..writeByte(3)
      ..write(obj.fechaModificacion)
      ..writeByte(4)
      ..write(obj.categoria)
      ..writeByte(5)
      ..write(obj.favorita)
      ..writeByte(6)
      ..write(obj.colorValue)
      ..writeByte(7)
      ..write(obj.id)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.pinned)
      ..writeByte(10)
      ..write(obj.archivada)
      ..writeByte(11)
      ..write(obj.relatedSessionId)
      ..writeByte(12)
      ..write(obj.tipo)
      ..writeByte(13)
      ..write(obj.estado)
      ..writeByte(14)
      ..write(obj.bolera)
      ..writeByte(15)
      ..write(obj.patronAceite)
      ..writeByte(16)
      ..write(obj.equipamientoUsado)
      ..writeByte(17)
      ..write(obj.condicionPista);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
