import 'package:hive/hive.dart';

part 'user_progress.g.dart';

@HiveType(typeId: 17)
class UserProgress extends HiveObject {
  @HiveField(0)
  int experiencePoints; // XP total acumulado

  @HiveField(1)
  int currentLevel; // Nivel actual

  @HiveField(2)
  List<String> unlockedAchievementIds; // IDs de logros desbloqueados

  @HiveField(3)
  DateTime lastUpdated;

  UserProgress({
    this.experiencePoints = 0,
    this.currentLevel = 1,
    List<String>? unlockedAchievementIds,
    DateTime? lastUpdated,
  })  : unlockedAchievementIds = unlockedAchievementIds ?? [],
        lastUpdated = lastUpdated ?? DateTime.now();

  /// Calcula el XP requerido para el siguiente nivel
  /// Usa una fórmula exponencial: XP = 100 * nivel^1.5
  int get xpForNextLevel {
    return (100 * (currentLevel + 1) * 1.5).round();
  }

  /// Calcula el XP requerido para el nivel actual
  int get xpForCurrentLevel {
    if (currentLevel <= 1) return 0;
    return (100 * currentLevel * 1.5).round();
  }

  /// XP dentro del nivel actual
  int get xpInCurrentLevel {
    return experiencePoints - xpForCurrentLevel;
  }

  /// Progreso hacia el siguiente nivel (0-100)
  double get progressToNextLevel {
    final xpNeeded = xpForNextLevel - xpForCurrentLevel;
    if (xpNeeded == 0) return 100;
    return (xpInCurrentLevel / xpNeeded * 100).clamp(0, 100);
  }

  /// Añade XP y actualiza el nivel si es necesario
  /// Retorna true si subió de nivel
  bool addExperience(int xp) {
    experiencePoints += xp;
    lastUpdated = DateTime.now();
    
    bool leveledUp = false;
    
    // Verificar si subió de nivel
    while (experiencePoints >= xpForNextLevel) {
      currentLevel++;
      leveledUp = true;
    }
    
    return leveledUp;
  }

  /// Desbloquea un logro
  void unlockAchievement(String achievementId) {
    if (!unlockedAchievementIds.contains(achievementId)) {
      unlockedAchievementIds.add(achievementId);
      lastUpdated = DateTime.now();
    }
  }

  /// Verifica si un logro está desbloqueado
  bool isAchievementUnlocked(String achievementId) {
    return unlockedAchievementIds.contains(achievementId);
  }

  UserProgress copyWith({
    int? experiencePoints,
    int? currentLevel,
    List<String>? unlockedAchievementIds,
    DateTime? lastUpdated,
  }) {
    return UserProgress(
      experiencePoints: experiencePoints ?? this.experiencePoints,
      currentLevel: currentLevel ?? this.currentLevel,
      unlockedAchievementIds:
          unlockedAchievementIds ?? this.unlockedAchievementIds,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
        'experiencePoints': experiencePoints,
        'currentLevel': currentLevel,
        'unlockedAchievementIds': unlockedAchievementIds,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
        experiencePoints: json['experiencePoints'] ?? 0,
        currentLevel: json['currentLevel'] ?? 1,
        unlockedAchievementIds:
            List<String>.from(json['unlockedAchievementIds'] ?? []),
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'])
            : DateTime.now(),
      );
}
