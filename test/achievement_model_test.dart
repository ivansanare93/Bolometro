import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/models/achievement.dart';

/// Tests for Achievement model
void main() {
  group('Achievement Model', () {
    test('Achievement should be created with required fields', () {
      // Act
      final achievement = Achievement(
        id: 'test_achievement',
        nameKey: 'achievement.test.name',
        descriptionKey: 'achievement.test.description',
        icon: 'star',
        xpReward: 100,
        type: AchievementType.gamesPlayed,
        rarity: AchievementRarity.common,
        targetValue: 10,
      );

      // Assert
      expect(achievement.id, equals('test_achievement'));
      expect(achievement.nameKey, equals('achievement.test.name'));
      expect(achievement.descriptionKey, equals('achievement.test.description'));
      expect(achievement.icon, equals('star'));
      expect(achievement.xpReward, equals(100));
      expect(achievement.type, equals(AchievementType.gamesPlayed));
      expect(achievement.rarity, equals(AchievementRarity.common));
      expect(achievement.targetValue, equals(10));
      expect(achievement.isUnlocked, isFalse);
      expect(achievement.unlockedAt, isNull);
      expect(achievement.currentProgress, equals(0));
    });

    test('Achievement should be created with all fields', () {
      // Arrange
      final unlockedAt = DateTime.now();

      // Act
      final achievement = Achievement(
        id: 'test_achievement',
        nameKey: 'achievement.test.name',
        descriptionKey: 'achievement.test.description',
        icon: 'star',
        xpReward: 100,
        type: AchievementType.strike,
        rarity: AchievementRarity.legendary,
        targetValue: 50,
        isUnlocked: true,
        unlockedAt: unlockedAt,
        currentProgress: 50,
      );

      // Assert
      expect(achievement.isUnlocked, isTrue);
      expect(achievement.unlockedAt, equals(unlockedAt));
      expect(achievement.currentProgress, equals(50));
    });

    test('progressPercentage should return 0 when target is 0', () {
      // Arrange
      final achievement = Achievement(
        id: 'test',
        nameKey: 'test.name',
        descriptionKey: 'test.desc',
        icon: 'star',
        xpReward: 100,
        type: AchievementType.gamesPlayed,
        rarity: AchievementRarity.common,
        targetValue: 0,
        currentProgress: 5,
      );

      // Act & Assert
      expect(achievement.progressPercentage, equals(0));
    });

    test('progressPercentage should calculate correctly', () {
      // Arrange
      final achievement = Achievement(
        id: 'test',
        nameKey: 'test.name',
        descriptionKey: 'test.desc',
        icon: 'star',
        xpReward: 100,
        type: AchievementType.gamesPlayed,
        rarity: AchievementRarity.common,
        targetValue: 10,
        currentProgress: 5,
      );

      // Act & Assert
      expect(achievement.progressPercentage, equals(50.0));
    });

    test('progressPercentage should cap at 100', () {
      // Arrange
      final achievement = Achievement(
        id: 'test',
        nameKey: 'test.name',
        descriptionKey: 'test.desc',
        icon: 'star',
        xpReward: 100,
        type: AchievementType.gamesPlayed,
        rarity: AchievementRarity.common,
        targetValue: 10,
        currentProgress: 15,
      );

      // Act & Assert
      expect(achievement.progressPercentage, equals(100.0));
    });

    test('copyWith should create new instance with updated values', () {
      // Arrange
      final achievement = Achievement(
        id: 'test',
        nameKey: 'test.name',
        descriptionKey: 'test.desc',
        icon: 'star',
        xpReward: 100,
        type: AchievementType.gamesPlayed,
        rarity: AchievementRarity.common,
        targetValue: 10,
      );

      // Act
      final updated = achievement.copyWith(
        currentProgress: 5,
        isUnlocked: true,
      );

      // Assert
      expect(updated.currentProgress, equals(5));
      expect(updated.isUnlocked, isTrue);
      expect(updated.id, equals('test')); // Unchanged fields
      expect(achievement.currentProgress, equals(0)); // Original unchanged
      expect(achievement.isUnlocked, isFalse);
    });

    test('toJson should serialize correctly', () {
      // Arrange
      final unlockedAt = DateTime(2024, 1, 1, 12, 0);
      final achievement = Achievement(
        id: 'test_achievement',
        nameKey: 'achievement.test.name',
        descriptionKey: 'achievement.test.description',
        icon: 'star',
        xpReward: 100,
        type: AchievementType.strike,
        rarity: AchievementRarity.rare,
        targetValue: 50,
        isUnlocked: true,
        unlockedAt: unlockedAt,
        currentProgress: 50,
      );

      // Act
      final json = achievement.toJson();

      // Assert
      expect(json['id'], equals('test_achievement'));
      expect(json['nameKey'], equals('achievement.test.name'));
      expect(json['descriptionKey'], equals('achievement.test.description'));
      expect(json['icon'], equals('star'));
      expect(json['xpReward'], equals(100));
      expect(json['type'], equals(AchievementType.strike.index));
      expect(json['rarity'], equals(AchievementRarity.rare.index));
      expect(json['targetValue'], equals(50));
      expect(json['isUnlocked'], isTrue);
      expect(json['unlockedAt'], equals(unlockedAt.toIso8601String()));
      expect(json['currentProgress'], equals(50));
    });

    test('fromJson should deserialize correctly', () {
      // Arrange
      final json = {
        'id': 'test_achievement',
        'nameKey': 'achievement.test.name',
        'descriptionKey': 'achievement.test.description',
        'icon': 'star',
        'xpReward': 100,
        'type': AchievementType.strike.index,
        'rarity': AchievementRarity.rare.index,
        'targetValue': 50,
        'isUnlocked': true,
        'unlockedAt': '2024-01-01T12:00:00.000',
        'currentProgress': 50,
      };

      // Act
      final achievement = Achievement.fromJson(json);

      // Assert
      expect(achievement.id, equals('test_achievement'));
      expect(achievement.nameKey, equals('achievement.test.name'));
      expect(achievement.descriptionKey, equals('achievement.test.description'));
      expect(achievement.icon, equals('star'));
      expect(achievement.xpReward, equals(100));
      expect(achievement.type, equals(AchievementType.strike));
      expect(achievement.rarity, equals(AchievementRarity.rare));
      expect(achievement.targetValue, equals(50));
      expect(achievement.isUnlocked, isTrue);
      expect(achievement.unlockedAt, equals(DateTime.parse('2024-01-01T12:00:00.000')));
      expect(achievement.currentProgress, equals(50));
    });

    test('fromJson should handle null optional fields', () {
      // Arrange
      final json = {
        'id': 'test_achievement',
        'nameKey': 'achievement.test.name',
        'descriptionKey': 'achievement.test.description',
        'icon': 'star',
        'xpReward': 100,
        'type': AchievementType.gamesPlayed.index,
        'rarity': AchievementRarity.common.index,
        'targetValue': 10,
      };

      // Act
      final achievement = Achievement.fromJson(json);

      // Assert
      expect(achievement.isUnlocked, isFalse);
      expect(achievement.unlockedAt, isNull);
      expect(achievement.currentProgress, equals(0));
    });

    test('AchievementType enum should have all expected values', () {
      // Assert
      expect(AchievementType.values.length, equals(9));
      expect(AchievementType.values, contains(AchievementType.gamesPlayed));
      expect(AchievementType.values, contains(AchievementType.strike));
      expect(AchievementType.values, contains(AchievementType.spare));
      expect(AchievementType.values, contains(AchievementType.perfectGame));
      expect(AchievementType.values, contains(AchievementType.highScore));
      expect(AchievementType.values, contains(AchievementType.streak));
      expect(AchievementType.values, contains(AchievementType.consistency));
      expect(AchievementType.values, contains(AchievementType.firstGame));
      expect(AchievementType.values, contains(AchievementType.dedication));
    });

    test('AchievementRarity enum should have all expected values', () {
      // Assert
      expect(AchievementRarity.values.length, equals(4));
      expect(AchievementRarity.values, contains(AchievementRarity.common));
      expect(AchievementRarity.values, contains(AchievementRarity.rare));
      expect(AchievementRarity.values, contains(AchievementRarity.epic));
      expect(AchievementRarity.values, contains(AchievementRarity.legendary));
    });
  });
}
