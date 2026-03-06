import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/achievement.dart';
import '../models/user_progress.dart';
import '../models/sesion.dart';
import '../models/partida.dart';
import '../utils/app_constants.dart';

/// Servicio para gestionar el sistema de gamificación
/// Maneja logros, niveles y experiencia
class AchievementService extends ChangeNotifier {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  UserProgress? _userProgress;
  Map<String, Achievement> _achievements = {};
  bool _isInitialized = false;
  String _sesionesBoxName = AppConstants.boxSesiones;

  UserProgress? get userProgress => _userProgress;
  List<Achievement> get achievements => _achievements.values.toList();
  bool get isInitialized => _isInitialized;

  /// Actualiza el nombre del box de sesiones a usar para calcular estadísticas.
  /// Debe llamarse cuando el usuario inicia o cierra sesión.
  void updateSesionesBoxName(String boxName) {
    _sesionesBoxName = boxName;
  }

  /// Inicializa el servicio de logros
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Cargar progreso del usuario
      final progressBox = await Hive.openBox<UserProgress>('userProgress');
      if (progressBox.isEmpty) {
        _userProgress = UserProgress();
        await progressBox.add(_userProgress!);
      } else {
        _userProgress = progressBox.getAt(0);
      }

      // Inicializar todos los logros
      _initializeAchievements();

      // Cargar estado de logros desde Hive
      final achievementsBox = await Hive.openBox<Achievement>('achievements');
      
      // Merge new achievements with existing ones
      for (var newAchievement in _achievements.values) {
        final existingAchievement = achievementsBox.get(newAchievement.id);
        if (existingAchievement != null) {
          // Use existing achievement to preserve progress
          _achievements[newAchievement.id] = existingAchievement;
        } else {
          // Save new achievement
          await achievementsBox.put(newAchievement.id, newAchievement);
        }
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al inicializar AchievementService: $e');
    }
  }

  /// Define todos los logros del juego
  void _initializeAchievements() {
    _achievements = {
      // Primera partida
      'first_game': Achievement(
        id: 'first_game',
        nameKey: 'achievement.first_game.name',
        descriptionKey: 'achievement.first_game.description',
        icon: 'sports_bowling',
        xpReward: 50,
        type: AchievementType.firstGame,
        rarity: AchievementRarity.common,
        targetValue: 1,
      ),

      // Partidas jugadas
      'games_10': Achievement(
        id: 'games_10',
        nameKey: 'achievement.games_10.name',
        descriptionKey: 'achievement.games_10.description',
        icon: 'looks_one',
        xpReward: 100,
        type: AchievementType.gamesPlayed,
        rarity: AchievementRarity.common,
        targetValue: 10,
      ),
      'games_50': Achievement(
        id: 'games_50',
        nameKey: 'achievement.games_50.name',
        descriptionKey: 'achievement.games_50.description',
        icon: 'looks_5',
        xpReward: 250,
        type: AchievementType.gamesPlayed,
        rarity: AchievementRarity.rare,
        targetValue: 50,
      ),
      'games_100': Achievement(
        id: 'games_100',
        nameKey: 'achievement.games_100.name',
        descriptionKey: 'achievement.games_100.description',
        icon: 'military_tech',
        xpReward: 500,
        type: AchievementType.gamesPlayed,
        rarity: AchievementRarity.epic,
        targetValue: 100,
      ),
      'games_250': Achievement(
        id: 'games_250',
        nameKey: 'achievement.games_250.name',
        descriptionKey: 'achievement.games_250.description',
        icon: 'workspace_premium',
        xpReward: 750,
        type: AchievementType.gamesPlayed,
        rarity: AchievementRarity.epic,
        targetValue: 250,
      ),
      'games_500': Achievement(
        id: 'games_500',
        nameKey: 'achievement.games_500.name',
        descriptionKey: 'achievement.games_500.description',
        icon: 'diamond',
        xpReward: 1000,
        type: AchievementType.gamesPlayed,
        rarity: AchievementRarity.legendary,
        targetValue: 500,
      ),

      // Strikes
      'strikes_10': Achievement(
        id: 'strikes_10',
        nameKey: 'achievement.strikes_10.name',
        descriptionKey: 'achievement.strikes_10.description',
        icon: 'flash_on',
        xpReward: 75,
        type: AchievementType.strike,
        rarity: AchievementRarity.common,
        targetValue: 10,
      ),
      'strikes_50': Achievement(
        id: 'strikes_50',
        nameKey: 'achievement.strikes_50.name',
        descriptionKey: 'achievement.strikes_50.description',
        icon: 'bolt',
        xpReward: 200,
        type: AchievementType.strike,
        rarity: AchievementRarity.rare,
        targetValue: 50,
      ),
      'strikes_100': Achievement(
        id: 'strikes_100',
        nameKey: 'achievement.strikes_100.name',
        descriptionKey: 'achievement.strikes_100.description',
        icon: 'electric_bolt',
        xpReward: 400,
        type: AchievementType.strike,
        rarity: AchievementRarity.epic,
        targetValue: 100,
      ),
      'strikes_250': Achievement(
        id: 'strikes_250',
        nameKey: 'achievement.strikes_250.name',
        descriptionKey: 'achievement.strikes_250.description',
        icon: 'flash_auto',
        xpReward: 600,
        type: AchievementType.strike,
        rarity: AchievementRarity.epic,
        targetValue: 250,
      ),
      'strikes_500': Achievement(
        id: 'strikes_500',
        nameKey: 'achievement.strikes_500.name',
        descriptionKey: 'achievement.strikes_500.description',
        icon: 'thunderstorm',
        xpReward: 1000,
        type: AchievementType.strike,
        rarity: AchievementRarity.legendary,
        targetValue: 500,
      ),

      // Puntuación alta
      'score_150': Achievement(
        id: 'score_150',
        nameKey: 'achievement.score_150.name',
        descriptionKey: 'achievement.score_150.description',
        icon: 'trending_up',
        xpReward: 100,
        type: AchievementType.highScore,
        rarity: AchievementRarity.common,
        targetValue: 150,
      ),
      'score_200': Achievement(
        id: 'score_200',
        nameKey: 'achievement.score_200.name',
        descriptionKey: 'achievement.score_200.description',
        icon: 'stars',
        xpReward: 250,
        type: AchievementType.highScore,
        rarity: AchievementRarity.rare,
        targetValue: 200,
      ),
      'score_250': Achievement(
        id: 'score_250',
        nameKey: 'achievement.score_250.name',
        descriptionKey: 'achievement.score_250.description',
        icon: 'star',
        xpReward: 500,
        type: AchievementType.highScore,
        rarity: AchievementRarity.epic,
        targetValue: 250,
      ),
      'score_275': Achievement(
        id: 'score_275',
        nameKey: 'achievement.score_275.name',
        descriptionKey: 'achievement.score_275.description',
        icon: 'auto_awesome',
        xpReward: 750,
        type: AchievementType.highScore,
        rarity: AchievementRarity.epic,
        targetValue: 275,
      ),

      // Partida perfecta
      'perfect_game': Achievement(
        id: 'perfect_game',
        nameKey: 'achievement.perfect_game.name',
        descriptionKey: 'achievement.perfect_game.description',
        icon: 'emoji_events',
        xpReward: 1000,
        type: AchievementType.perfectGame,
        rarity: AchievementRarity.legendary,
        targetValue: 300,
      ),

      // Racha de strikes
      'streak_3': Achievement(
        id: 'streak_3',
        nameKey: 'achievement.streak_3.name',
        descriptionKey: 'achievement.streak_3.description',
        icon: 'whatshot',
        xpReward: 150,
        type: AchievementType.streak,
        rarity: AchievementRarity.rare,
        targetValue: 3,
      ),
      'streak_5': Achievement(
        id: 'streak_5',
        nameKey: 'achievement.streak_5.name',
        descriptionKey: 'achievement.streak_5.description',
        icon: 'local_fire_department',
        xpReward: 300,
        type: AchievementType.streak,
        rarity: AchievementRarity.epic,
        targetValue: 5,
      ),
      'streak_7': Achievement(
        id: 'streak_7',
        nameKey: 'achievement.streak_7.name',
        descriptionKey: 'achievement.streak_7.description',
        icon: 'flame',
        xpReward: 500,
        type: AchievementType.streak,
        rarity: AchievementRarity.epic,
        targetValue: 7,
      ),
      'streak_10': Achievement(
        id: 'streak_10',
        nameKey: 'achievement.streak_10.name',
        descriptionKey: 'achievement.streak_10.description',
        icon: 'fireplace',
        xpReward: 800,
        type: AchievementType.streak,
        rarity: AchievementRarity.legendary,
        targetValue: 10,
      ),

      // Spares
      'spares_20': Achievement(
        id: 'spares_20',
        nameKey: 'achievement.spares_20.name',
        descriptionKey: 'achievement.spares_20.description',
        icon: 'check_circle',
        xpReward: 75,
        type: AchievementType.spare,
        rarity: AchievementRarity.common,
        targetValue: 20,
      ),
      'spares_100': Achievement(
        id: 'spares_100',
        nameKey: 'achievement.spares_100.name',
        descriptionKey: 'achievement.spares_100.description',
        icon: 'verified',
        xpReward: 200,
        type: AchievementType.spare,
        rarity: AchievementRarity.rare,
        targetValue: 100,
      ),
      'spares_250': Achievement(
        id: 'spares_250',
        nameKey: 'achievement.spares_250.name',
        descriptionKey: 'achievement.spares_250.description',
        icon: 'check_circle_outline',
        xpReward: 400,
        type: AchievementType.spare,
        rarity: AchievementRarity.epic,
        targetValue: 250,
      ),
      'spares_500': Achievement(
        id: 'spares_500',
        nameKey: 'achievement.spares_500.name',
        descriptionKey: 'achievement.spares_500.description',
        icon: 'verified_user',
        xpReward: 600,
        type: AchievementType.spare,
        rarity: AchievementRarity.epic,
        targetValue: 500,
      ),

      // Logros especiales de consistencia
      'consistency_5': Achievement(
        id: 'consistency_5',
        nameKey: 'achievement.consistency_5.name',
        descriptionKey: 'achievement.consistency_5.description',
        icon: 'trending_flat',
        xpReward: 200,
        type: AchievementType.consistency,
        rarity: AchievementRarity.rare,
        targetValue: 5,
      ),
      'consistency_10': Achievement(
        id: 'consistency_10',
        nameKey: 'achievement.consistency_10.name',
        descriptionKey: 'achievement.consistency_10.description',
        icon: 'equalizer',
        xpReward: 500,
        type: AchievementType.consistency,
        rarity: AchievementRarity.epic,
        targetValue: 10,
      ),

      // Logros de dedicación
      'dedication_7': Achievement(
        id: 'dedication_7',
        nameKey: 'achievement.dedication_7.name',
        descriptionKey: 'achievement.dedication_7.description',
        icon: 'event_repeat',
        xpReward: 300,
        type: AchievementType.dedication,
        rarity: AchievementRarity.rare,
        targetValue: 7,
      ),
      'dedication_30': Achievement(
        id: 'dedication_30',
        nameKey: 'achievement.dedication_30.name',
        descriptionKey: 'achievement.dedication_30.description',
        icon: 'calendar_month',
        xpReward: 600,
        type: AchievementType.dedication,
        rarity: AchievementRarity.epic,
        targetValue: 30,
      ),
      'dedication_100': Achievement(
        id: 'dedication_100',
        nameKey: 'achievement.dedication_100.name',
        descriptionKey: 'achievement.dedication_100.description',
        icon: 'celebration',
        xpReward: 1000,
        type: AchievementType.dedication,
        rarity: AchievementRarity.legendary,
        targetValue: 100,
      ),
    };
  }

  /// Calcula estadísticas de todas las sesiones
  Future<Map<String, int>> _calculateStats() async {
    try {
      final Box<Sesion> sesionesBox;
      if (Hive.isBoxOpen(_sesionesBoxName)) {
        sesionesBox = Hive.box<Sesion>(_sesionesBoxName);
      } else {
        sesionesBox = await Hive.openBox<Sesion>(_sesionesBoxName);
      }
      final sesiones = sesionesBox.values.toList();

      int totalGames = 0;
      int totalStrikes = 0;
      int totalSpares = 0;
      int maxScore = 0;
      int maxStreak = 0;
      
      // Para calcular consistencia: partidas con puntuación similar (±15 puntos)
      List<int> allScores = [];
      
      // Para calcular dedicación: días únicos con sesiones
      Set<String> uniqueDays = {};

      for (var sesion in sesiones) {
        // Añadir día único para tracking de dedicación
        final day = sesion.fecha.day.toString().padLeft(2, '0');
        final month = sesion.fecha.month.toString().padLeft(2, '0');
        final year = sesion.fecha.year;
        final dayKey = '$year-$month-$day';
        uniqueDays.add(dayKey);
        
        for (var partida in sesion.partidas) {
          totalGames++;
          allScores.add(partida.total);
          
          // Contar strikes y spares
          int currentStreak = 0;
          for (var frame in partida.frames) {
            if (frame.isEmpty) continue;
            if (frame.first == AppConstants.simboloStrike) {
              totalStrikes++;
              currentStreak++;
              maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
            } else {
              currentStreak = 0;
              if (frame.length > 1 && frame.contains(AppConstants.simboloSpare)) {
                totalSpares++;
              }
            }
          }
          
          // Puntuación máxima
          if (partida.total > maxScore) {
            maxScore = partida.total;
          }
        }
      }
      
      // Calcular consistencia: contar secuencias de partidas con puntuaciones similares
      int maxConsistency = 0;
      if (allScores.length >= 2) {
        int currentConsistency = 1;
        for (int i = 1; i < allScores.length; i++) {
          // Partidas consistentes si la diferencia es menor a 15 puntos
          if ((allScores[i] - allScores[i-1]).abs() <= 15) {
            currentConsistency++;
            if (currentConsistency > maxConsistency) {
              maxConsistency = currentConsistency;
            }
          } else {
            currentConsistency = 1;
          }
        }
      }

      return {
        'totalGames': totalGames,
        'totalStrikes': totalStrikes,
        'totalSpares': totalSpares,
        'maxScore': maxScore,
        'maxStreak': maxStreak,
        'maxConsistency': maxConsistency,
        'daysPlayed': uniqueDays.length,
      };
    } catch (e) {
      debugPrint('Error al calcular estadísticas: $e');
      return {};
    }
  }

  /// Verifica y desbloquea logros basados en las estadísticas actuales
  Future<List<Achievement>> checkAndUnlockAchievements() async {
    if (!_isInitialized) await initialize();
    
    final stats = await _calculateStats();
    final newlyUnlocked = <Achievement>[];

    for (var achievement in _achievements.values) {
      if (achievement.isUnlocked) continue;

      bool shouldUnlock = false;
      int progress = 0;

      switch (achievement.type) {
        case AchievementType.gamesPlayed:
        case AchievementType.firstGame:
          progress = stats['totalGames'] ?? 0;
          shouldUnlock = progress >= achievement.targetValue;
          break;
        
        case AchievementType.strike:
          progress = stats['totalStrikes'] ?? 0;
          shouldUnlock = progress >= achievement.targetValue;
          break;
        
        case AchievementType.spare:
          progress = stats['totalSpares'] ?? 0;
          shouldUnlock = progress >= achievement.targetValue;
          break;
        
        case AchievementType.highScore:
        case AchievementType.perfectGame:
          progress = stats['maxScore'] ?? 0;
          shouldUnlock = progress >= achievement.targetValue;
          break;
        
        case AchievementType.streak:
          progress = stats['maxStreak'] ?? 0;
          shouldUnlock = progress >= achievement.targetValue;
          break;
        
        case AchievementType.consistency:
          progress = stats['maxConsistency'] ?? 0;
          shouldUnlock = progress >= achievement.targetValue;
          break;
        
        case AchievementType.dedication:
          progress = stats['daysPlayed'] ?? 0;
          shouldUnlock = progress >= achievement.targetValue;
          break;
      }

      // Actualizar progreso
      final updatedAchievement = achievement.copyWith(
        currentProgress: progress,
        isUnlocked: shouldUnlock,
        unlockedAt: shouldUnlock ? DateTime.now() : null,
      );

      _achievements[achievement.id] = updatedAchievement;

      // Guardar en Hive
      final achievementsBox = Hive.box<Achievement>('achievements');
      await achievementsBox.put(achievement.id, updatedAchievement);

      if (shouldUnlock) {
        // Añadir XP y desbloquear logro
        _userProgress?.unlockAchievement(achievement.id);
        final leveledUp = _userProgress?.addExperience(achievement.xpReward) ?? false;
        
        // Guardar progreso
        final progressBox = Hive.box<UserProgress>('userProgress');
        await progressBox.putAt(0, _userProgress!);
        
        newlyUnlocked.add(updatedAchievement);
        
        debugPrint('Logro desbloqueado: ${achievement.id}');
        if (leveledUp) {
          debugPrint('¡Subiste de nivel! Nuevo nivel: ${_userProgress?.currentLevel}');
        }
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      notifyListeners();
    }

    return newlyUnlocked;
  }

  /// Añade XP al usuario
  Future<bool> addExperience(int xp) async {
    if (!_isInitialized) await initialize();
    
    final leveledUp = _userProgress?.addExperience(xp) ?? false;
    
    // Guardar progreso
    final progressBox = Hive.box<UserProgress>('userProgress');
    await progressBox.putAt(0, _userProgress!);
    
    notifyListeners();
    
    return leveledUp;
  }

  /// Obtiene un logro por su ID
  Achievement? getAchievement(String id) {
    return _achievements[id];
  }

  /// Obtiene logros por tipo
  List<Achievement> getAchievementsByType(AchievementType type) {
    return _achievements.values
        .where((achievement) => achievement.type == type)
        .toList();
  }

  /// Obtiene logros desbloqueados
  List<Achievement> getUnlockedAchievements() {
    return _achievements.values
        .where((achievement) => achievement.isUnlocked)
        .toList();
  }

  /// Obtiene logros bloqueados
  List<Achievement> getLockedAchievements() {
    return _achievements.values
        .where((achievement) => !achievement.isUnlocked)
        .toList();
  }

  /// Resetea el progreso (solo para desarrollo/testing)
  Future<void> resetProgress() async {
    debugPrint('=== INICIO DE RESETEO DE PROGRESO ===');
    
    // Log estado actual antes del reset
    debugPrint('Estado antes del reset:');
    debugPrint('  - Nivel actual: ${_userProgress?.currentLevel}');
    debugPrint('  - XP total: ${_userProgress?.experiencePoints}');
    debugPrint('  - Logros desbloqueados: ${_userProgress?.unlockedAchievementIds.length ?? 0}');
    debugPrint('  - Total de logros: ${_achievements.length}');
    
    // Resetear progreso del usuario
    debugPrint('Creando nuevo UserProgress...');
    _userProgress = UserProgress();
    debugPrint('UserProgress creado - Nivel: ${_userProgress?.currentLevel}, XP: ${_userProgress?.experiencePoints}');
    
    // Limpiar y guardar en Hive
    debugPrint('Limpiando progressBox de Hive...');
    final progressBox = Hive.box<UserProgress>('userProgress');
    final itemsBeforeClear = progressBox.length;
    await progressBox.clear();
    debugPrint('ProgressBox limpiado (items eliminados: $itemsBeforeClear)');
    
    debugPrint('Guardando nuevo progreso en Hive...');
    await progressBox.add(_userProgress!);
    debugPrint('Nuevo progreso guardado en Hive (items en box: ${progressBox.length})');
    
    // Resetear logros
    debugPrint('Reinicializando logros...');
    _initializeAchievements();
    debugPrint('Logros reinicializados (total: ${_achievements.length})');
    
    debugPrint('Limpiando achievementsBox de Hive...');
    final achievementsBox = Hive.box<Achievement>('achievements');
    final achievementsBeforeClear = achievementsBox.length;
    await achievementsBox.clear();
    debugPrint('AchievementsBox limpiado (items eliminados: $achievementsBeforeClear)');
    
    debugPrint('Guardando logros reinicializados en Hive...');
    int achievementsSaved = 0;
    for (var achievement in _achievements.values) {
      await achievementsBox.put(achievement.id, achievement);
      achievementsSaved++;
    }
    debugPrint('Logros guardados: $achievementsSaved/${_achievements.length}');
    
    debugPrint('Estado después del reset:');
    debugPrint('  - Nivel actual: ${_userProgress?.currentLevel}');
    debugPrint('  - XP total: ${_userProgress?.experiencePoints}');
    debugPrint('  - Logros desbloqueados: ${_userProgress?.unlockedAchievementIds.length ?? 0}');
    debugPrint('  - Total de logros: ${_achievements.length}');
    
    // Marcar servicio como no inicializado para forzar recarga desde Hive
    // IMPORTANTE: Esto debe hacerse ANTES de notificar listeners para evitar condiciones de carrera
    debugPrint('Marcando servicio como no inicializado para forzar recarga...');
    _isInitialized = false;
    
    // Notificar cambios DESPUÉS de marcar como no inicializado
    debugPrint('Notificando listeners...');
    notifyListeners();
    
    debugPrint('=== FIN DE RESETEO DE PROGRESO ===');
  }
}
