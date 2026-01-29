// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FriendRequestAdapter extends TypeAdapter<FriendRequest> {
  @override
  final int typeId = 16;

  @override
  FriendRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FriendRequest(
      requestId: fields[0] as String,
      fromUserId: fields[1] as String,
      fromUserName: fields[2] as String,
      fromUserEmail: fields[3] as String?,
      fromUserPhotoUrl: fields[4] as String?,
      toUserId: fields[5] as String,
      createdAt: fields[6] as DateTime,
      status: fields[7] as String? ?? 'pending',
      respondedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FriendRequest obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.requestId)
      ..writeByte(1)
      ..write(obj.fromUserId)
      ..writeByte(2)
      ..write(obj.fromUserName)
      ..writeByte(3)
      ..write(obj.fromUserEmail)
      ..writeByte(4)
      ..write(obj.fromUserPhotoUrl)
      ..writeByte(5)
      ..write(obj.toUserId)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.respondedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
