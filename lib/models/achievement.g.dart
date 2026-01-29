// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AchievementAdapter extends TypeAdapter<Achievement> {
  @override
  final int typeId = 11;

  @override
  Achievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Achievement(
      id: fields[0] as String,
      nameKey: fields[1] as String,
      descriptionKey: fields[2] as String,
      icon: fields[3] as String,
      xpReward: fields[4] as int,
      type: fields[5] as AchievementType,
      rarity: fields[6] as AchievementRarity,
      targetValue: fields[7] as int,
      isUnlocked: fields[8] as bool,
      unlockedAt: fields[9] as DateTime?,
      currentProgress: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Achievement obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nameKey)
      ..writeByte(2)
      ..write(obj.descriptionKey)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.xpReward)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.rarity)
      ..writeByte(7)
      ..write(obj.targetValue)
      ..writeByte(8)
      ..write(obj.isUnlocked)
      ..writeByte(9)
      ..write(obj.unlockedAt)
      ..writeByte(10)
      ..write(obj.currentProgress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AchievementTypeAdapter extends TypeAdapter<AchievementType> {
  @override
  final int typeId = 13;

  @override
  AchievementType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AchievementType.gamesPlayed;
      case 1:
        return AchievementType.strike;
      case 2:
        return AchievementType.spare;
      case 3:
        return AchievementType.perfectGame;
      case 4:
        return AchievementType.highScore;
      case 5:
        return AchievementType.streak;
      case 6:
        return AchievementType.consistency;
      case 7:
        return AchievementType.firstGame;
      case 8:
        return AchievementType.dedication;
      default:
        return AchievementType.gamesPlayed;
    }
  }

  @override
  void write(BinaryWriter writer, AchievementType obj) {
    switch (obj) {
      case AchievementType.gamesPlayed:
        writer.writeByte(0);
        break;
      case AchievementType.strike:
        writer.writeByte(1);
        break;
      case AchievementType.spare:
        writer.writeByte(2);
        break;
      case AchievementType.perfectGame:
        writer.writeByte(3);
        break;
      case AchievementType.highScore:
        writer.writeByte(4);
        break;
      case AchievementType.streak:
        writer.writeByte(5);
        break;
      case AchievementType.consistency:
        writer.writeByte(6);
        break;
      case AchievementType.firstGame:
        writer.writeByte(7);
        break;
      case AchievementType.dedication:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AchievementRarityAdapter extends TypeAdapter<AchievementRarity> {
  @override
  final int typeId = 14;

  @override
  AchievementRarity read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AchievementRarity.common;
      case 1:
        return AchievementRarity.rare;
      case 2:
        return AchievementRarity.epic;
      case 3:
        return AchievementRarity.legendary;
      default:
        return AchievementRarity.common;
    }
  }

  @override
  void write(BinaryWriter writer, AchievementRarity obj) {
    switch (obj) {
      case AchievementRarity.common:
        writer.writeByte(0);
        break;
      case AchievementRarity.rare:
        writer.writeByte(1);
        break;
      case AchievementRarity.epic:
        writer.writeByte(2);
        break;
      case AchievementRarity.legendary:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementRarityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
