import 'package:hive/hive.dart';

part 'achievement.g.dart';

/// Tipos de logros disponibles en el sistema de gamificación
enum AchievementType {
  gamesPlayed,     // Partidas jugadas
  strike,          // Strikes
  spare,           // Spares
  perfectGame,     // Partida perfecta (300 puntos)
  highScore,       // Puntuación alta
  streak,          // Rachas
  consistency,     // Consistencia
  firstGame,       // Primera partida
  dedication,      // Dedicación (días jugando)
}

/// Rareza del logro
enum AchievementRarity {
  common,    // Común
  rare,      // Raro
  epic,      // Épico
  legendary, // Legendario
}

@HiveType(typeId: 11)
class Achievement extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String nameKey; // Clave para traducción

  @HiveField(2)
  final String descriptionKey; // Clave para traducción

  @HiveField(3)
  final String icon; // Nombre del icono

  @HiveField(4)
  final int xpReward; // Puntos de experiencia otorgados

  @HiveField(5)
  final AchievementType type;

  @HiveField(6)
  final AchievementRarity rarity;

  @HiveField(7)
  final int targetValue; // Valor objetivo para desbloquear

  @HiveField(8)
  final bool isUnlocked;

  @HiveField(9)
  final DateTime? unlockedAt;

  @HiveField(10)
  final int currentProgress; // Progreso actual hacia el objetivo

  Achievement({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.icon,
    required this.xpReward,
    required this.type,
    required this.rarity,
    required this.targetValue,
    this.isUnlocked = false,
    this.unlockedAt,
    this.currentProgress = 0,
  });

  /// Calcula el porcentaje de progreso (0-100)
  double get progressPercentage {
    if (targetValue == 0) return 0;
    return (currentProgress / targetValue * 100).clamp(0, 100);
  }

  /// Crea una copia del logro con valores actualizados
  Achievement copyWith({
    String? id,
    String? nameKey,
    String? descriptionKey,
    String? icon,
    int? xpReward,
    AchievementType? type,
    AchievementRarity? rarity,
    int? targetValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? currentProgress,
  }) {
    return Achievement(
      id: id ?? this.id,
      nameKey: nameKey ?? this.nameKey,
      descriptionKey: descriptionKey ?? this.descriptionKey,
      icon: icon ?? this.icon,
      xpReward: xpReward ?? this.xpReward,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      targetValue: targetValue ?? this.targetValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentProgress: currentProgress ?? this.currentProgress,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameKey': nameKey,
        'descriptionKey': descriptionKey,
        'icon': icon,
        'xpReward': xpReward,
        'type': type.index,
        'rarity': rarity.index,
        'targetValue': targetValue,
        'isUnlocked': isUnlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
        'currentProgress': currentProgress,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'],
        nameKey: json['nameKey'],
        descriptionKey: json['descriptionKey'],
        icon: json['icon'],
        xpReward: json['xpReward'],
        type: AchievementType.values[json['type']],
        rarity: AchievementRarity.values[json['rarity']],
        targetValue: json['targetValue'],
        isUnlocked: json['isUnlocked'] ?? false,
        unlockedAt: json['unlockedAt'] != null
            ? DateTime.parse(json['unlockedAt'])
            : null,
        currentProgress: json['currentProgress'] ?? 0,
      );
}
