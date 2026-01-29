import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/models/user_progress.dart';

/// Tests for UserProgress model
void main() {
  group('UserProgress Model', () {
    test('UserProgress should be created with default values', () {
      // Act
      final progress = UserProgress();

      // Assert
      expect(progress.experiencePoints, equals(0));
      expect(progress.currentLevel, equals(1));
      expect(progress.unlockedAchievementIds, isEmpty);
      expect(progress.lastUpdated, isNotNull);
    });

    test('UserProgress should be created with custom values', () {
      // Arrange
      final lastUpdated = DateTime.now();
      final achievementIds = ['achievement1', 'achievement2'];

      // Act
      final progress = UserProgress(
        experiencePoints: 500,
        currentLevel: 5,
        unlockedAchievementIds: achievementIds,
        lastUpdated: lastUpdated,
      );

      // Assert
      expect(progress.experiencePoints, equals(500));
      expect(progress.currentLevel, equals(5));
      expect(progress.unlockedAchievementIds, equals(achievementIds));
      expect(progress.lastUpdated, equals(lastUpdated));
    });

    test('xpForNextLevel should calculate correctly', () {
      // Arrange
      final progress = UserProgress(currentLevel: 1);

      // Act
      final xpForNextLevel = progress.xpForNextLevel;

      // Assert
      // Formula: 100 * (level + 1) * 1.5 = 100 * 2 * 1.5 = 300
      expect(xpForNextLevel, equals(300));
    });

    test('xpForCurrentLevel should return 0 for level 1', () {
      // Arrange
      final progress = UserProgress(currentLevel: 1);

      // Act
      final xpForCurrentLevel = progress.xpForCurrentLevel;

      // Assert
      expect(xpForCurrentLevel, equals(0));
    });

    test('xpForCurrentLevel should calculate correctly for higher levels', () {
      // Arrange
      final progress = UserProgress(currentLevel: 3);

      // Act
      final xpForCurrentLevel = progress.xpForCurrentLevel;

      // Assert
      // Formula: 100 * level * 1.5 = 100 * 3 * 1.5 = 450
      expect(xpForCurrentLevel, equals(450));
    });

    test('xpInCurrentLevel should calculate correctly', () {
      // Arrange
      // Level 2 requires 300 XP (100 * 2 * 1.5)
      // Level 3 requires 450 XP (100 * 3 * 1.5)
      final progress = UserProgress(
        experiencePoints: 400,
        currentLevel: 2,
      );

      // Act
      final xpInCurrentLevel = progress.xpInCurrentLevel;

      // Assert
      // 400 - 300 = 100 XP in current level
      expect(xpInCurrentLevel, equals(100));
    });

    test('progressToNextLevel should calculate correctly', () {
      // Arrange
      // Level 2 requires 300 XP, Level 3 requires 450 XP
      // So need 150 XP to go from level 2 to 3
      // Current XP: 400, so 100 XP into level 2
      final progress = UserProgress(
        experiencePoints: 400,
        currentLevel: 2,
      );

      // Act
      final progressPercent = progress.progressToNextLevel;

      // Assert
      // (100 / 150) * 100 = 66.67%
      expect(progressPercent, closeTo(66.67, 0.01));
    });

    test('addExperience should add XP and not level up', () {
      // Arrange
      final progress = UserProgress(experiencePoints: 100, currentLevel: 1);

      // Act
      final leveledUp = progress.addExperience(50);

      // Assert
      expect(leveledUp, isFalse);
      expect(progress.experiencePoints, equals(150));
      expect(progress.currentLevel, equals(1));
    });

    test('addExperience should add XP and level up once', () {
      // Arrange
      final progress = UserProgress(experiencePoints: 250, currentLevel: 1);

      // Act - adding 100 XP should push from 250 to 350, surpassing 300 needed for level 2
      final leveledUp = progress.addExperience(100);

      // Assert
      expect(leveledUp, isTrue);
      expect(progress.experiencePoints, equals(350));
      expect(progress.currentLevel, equals(2));
    });

    test('addExperience should level up multiple times', () {
      // Arrange
      final progress = UserProgress(experiencePoints: 100, currentLevel: 1);

      // Act - adding 1000 XP should level up multiple times
      final leveledUp = progress.addExperience(1000);

      // Assert
      expect(leveledUp, isTrue);
      expect(progress.experiencePoints, equals(1100));
      expect(progress.currentLevel, greaterThan(1));
    });

    test('unlockAchievement should add achievement ID', () {
      // Arrange
      final progress = UserProgress();

      // Act
      progress.unlockAchievement('achievement1');

      // Assert
      expect(progress.unlockedAchievementIds, contains('achievement1'));
    });

    test('unlockAchievement should not add duplicate achievement ID', () {
      // Arrange
      final progress = UserProgress();
      progress.unlockAchievement('achievement1');

      // Act
      progress.unlockAchievement('achievement1');

      // Assert
      expect(progress.unlockedAchievementIds.length, equals(1));
    });

    test('isAchievementUnlocked should return true for unlocked achievement', () {
      // Arrange
      final progress = UserProgress();
      progress.unlockAchievement('achievement1');

      // Act & Assert
      expect(progress.isAchievementUnlocked('achievement1'), isTrue);
    });

    test('isAchievementUnlocked should return false for locked achievement', () {
      // Arrange
      final progress = UserProgress();

      // Act & Assert
      expect(progress.isAchievementUnlocked('achievement1'), isFalse);
    });

    test('copyWith should create new instance with updated values', () {
      // Arrange
      final progress = UserProgress(experiencePoints: 100, currentLevel: 1);

      // Act
      final newProgress = progress.copyWith(experiencePoints: 200);

      // Assert
      expect(newProgress.experiencePoints, equals(200));
      expect(newProgress.currentLevel, equals(1));
      expect(progress.experiencePoints, equals(100)); // Original unchanged
    });

    test('toJson should serialize correctly', () {
      // Arrange
      final lastUpdated = DateTime(2024, 1, 1, 12, 0);
      final progress = UserProgress(
        experiencePoints: 500,
        currentLevel: 3,
        unlockedAchievementIds: ['achievement1', 'achievement2'],
        lastUpdated: lastUpdated,
      );

      // Act
      final json = progress.toJson();

      // Assert
      expect(json['experiencePoints'], equals(500));
      expect(json['currentLevel'], equals(3));
      expect(json['unlockedAchievementIds'], equals(['achievement1', 'achievement2']));
      expect(json['lastUpdated'], equals(lastUpdated.toIso8601String()));
    });

    test('fromJson should deserialize correctly', () {
      // Arrange
      final json = {
        'experiencePoints': 500,
        'currentLevel': 3,
        'unlockedAchievementIds': ['achievement1', 'achievement2'],
        'lastUpdated': '2024-01-01T12:00:00.000',
      };

      // Act
      final progress = UserProgress.fromJson(json);

      // Assert
      expect(progress.experiencePoints, equals(500));
      expect(progress.currentLevel, equals(3));
      expect(progress.unlockedAchievementIds, equals(['achievement1', 'achievement2']));
      expect(progress.lastUpdated, equals(DateTime.parse('2024-01-01T12:00:00.000')));
    });

    test('fromJson should handle missing fields with defaults', () {
      // Arrange
      final json = <String, dynamic>{};

      // Act
      final progress = UserProgress.fromJson(json);

      // Assert
      expect(progress.experiencePoints, equals(0));
      expect(progress.currentLevel, equals(1));
      expect(progress.unlockedAchievementIds, isEmpty);
      expect(progress.lastUpdated, isNotNull);
    });
  });
}
