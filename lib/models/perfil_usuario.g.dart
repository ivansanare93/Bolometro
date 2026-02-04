// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'perfil_usuario.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PerfilUsuarioAdapter extends TypeAdapter<PerfilUsuario> {
  @override
  final int typeId = 10;

  @override
  PerfilUsuario read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PerfilUsuario(
      nombre: fields[0] as String,
      email: fields[1] as String?,
      avatarPath: fields[2] as String?,
      club: fields[3] as String?,
      manoDominante: fields[4] as String?,
      fechaNacimiento: fields[5] as DateTime?,
      bio: fields[6] as String?,
      googlePhotoUrl: fields[7] as String?,
      googleDisplayName: fields[8] as String?,
      isFromGoogle: fields[9] as bool? ?? false,
      friendCode: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PerfilUsuario obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.nombre)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.avatarPath)
      ..writeByte(3)
      ..write(obj.club)
      ..writeByte(4)
      ..write(obj.manoDominante)
      ..writeByte(5)
      ..write(obj.fechaNacimiento)
      ..writeByte(6)
      ..write(obj.bio)
      ..writeByte(7)
      ..write(obj.googlePhotoUrl)
      ..writeByte(8)
      ..write(obj.googleDisplayName)
      ..writeByte(9)
      ..write(obj.isFromGoogle)
      ..writeByte(10)
      ..write(obj.friendCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerfilUsuarioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
