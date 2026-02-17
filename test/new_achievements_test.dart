import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/models/achievement.dart';
import 'package:bolometro/services/achievement_service.dart';

/// Tests for new achievements (consistency and dedication)
void main() {
  group('New Achievements', () {
    group('Consistency Achievements', () {
      test('Consistency achievement should be created with correct values', () {
        // Act
        final achievement = Achievement(
          id: 'consistency_5',
          nameKey: 'achievement.consistency_5.name',
          descriptionKey: 'achievement.consistency_5.description',
          icon: 'trending_flat',
          xpReward: 200,
          type: AchievementType.consistency,
          rarity: AchievementRarity.rare,
          targetValue: 5,
        );

        // Assert
        expect(achievement.id, equals('consistency_5'));
        expect(achievement.type, equals(AchievementType.consistency));
        expect(achievement.rarity, equals(AchievementRarity.rare));
        expect(achievement.targetValue, equals(5));
        expect(achievement.xpReward, equals(200));
        expect(achievement.isUnlocked, isFalse);
      });

      test('Consistency_10 achievement should have higher XP and epic rarity', () {
        // Act
        final achievement = Achievement(
          id: 'consistency_10',
          nameKey: 'achievement.consistency_10.name',
          descriptionKey: 'achievement.consistency_10.description',
          icon: 'equalizer',
          xpReward: 500,
          type: AchievementType.consistency,
          rarity: AchievementRarity.epic,
          targetValue: 10,
        );

        // Assert
        expect(achievement.id, equals('consistency_10'));
        expect(achievement.type, equals(AchievementType.consistency));
        expect(achievement.rarity, equals(AchievementRarity.epic));
        expect(achievement.targetValue, equals(10));
        expect(achievement.xpReward, equals(500));
      });
    });

    group('Dedication Achievements', () {
      test('Dedication_7 achievement should be created with correct values', () {
        // Act
        final achievement = Achievement(
          id: 'dedication_7',
          nameKey: 'achievement.dedication_7.name',
          descriptionKey: 'achievement.dedication_7.description',
          icon: 'event_repeat',
          xpReward: 300,
          type: AchievementType.dedication,
          rarity: AchievementRarity.rare,
          targetValue: 7,
        );

        // Assert
        expect(achievement.id, equals('dedication_7'));
        expect(achievement.type, equals(AchievementType.dedication));
        expect(achievement.rarity, equals(AchievementRarity.rare));
        expect(achievement.targetValue, equals(7));
        expect(achievement.xpReward, equals(300));
        expect(achievement.isUnlocked, isFalse);
      });

      test('Dedication_30 achievement should have higher target and XP', () {
        // Act
        final achievement = Achievement(
          id: 'dedication_30',
          nameKey: 'achievement.dedication_30.name',
          descriptionKey: 'achievement.dedication_30.description',
          icon: 'calendar_month',
          xpReward: 600,
          type: AchievementType.dedication,
          rarity: AchievementRarity.epic,
          targetValue: 30,
        );

        // Assert
        expect(achievement.id, equals('dedication_30'));
        expect(achievement.targetValue, equals(30));
        expect(achievement.xpReward, equals(600));
        expect(achievement.rarity, equals(AchievementRarity.epic));
      });

      test('Dedication_100 achievement should be legendary', () {
        // Act
        final achievement = Achievement(
          id: 'dedication_100',
          nameKey: 'achievement.dedication_100.name',
          descriptionKey: 'achievement.dedication_100.description',
          icon: 'celebration',
          xpReward: 1000,
          type: AchievementType.dedication,
          rarity: AchievementRarity.legendary,
          targetValue: 100,
        );

        // Assert
        expect(achievement.id, equals('dedication_100'));
        expect(achievement.rarity, equals(AchievementRarity.legendary));
        expect(achievement.targetValue, equals(100));
        expect(achievement.xpReward, equals(1000));
      });
    });

    group('Advanced Tier Achievements', () {
      test('Games_250 achievement should have epic rarity', () {
        // Act
        final achievement = Achievement(
          id: 'games_250',
          nameKey: 'achievement.games_250.name',
          descriptionKey: 'achievement.games_250.description',
          icon: 'workspace_premium',
          xpReward: 750,
          type: AchievementType.gamesPlayed,
          rarity: AchievementRarity.epic,
          targetValue: 250,
        );

        // Assert
        expect(achievement.id, equals('games_250'));
        expect(achievement.targetValue, equals(250));
        expect(achievement.xpReward, equals(750));
        expect(achievement.rarity, equals(AchievementRarity.epic));
      });

      test('Games_500 achievement should be legendary', () {
        // Act
        final achievement = Achievement(
          id: 'games_500',
          nameKey: 'achievement.games_500.name',
          descriptionKey: 'achievement.games_500.description',
          icon: 'diamond',
          xpReward: 1000,
          type: AchievementType.gamesPlayed,
          rarity: AchievementRarity.legendary,
          targetValue: 500,
        );

        // Assert
        expect(achievement.id, equals('games_500'));
        expect(achievement.rarity, equals(AchievementRarity.legendary));
        expect(achievement.targetValue, equals(500));
        expect(achievement.xpReward, equals(1000));
      });

      test('Strikes_250 achievement should have correct values', () {
        // Act
        final achievement = Achievement(
          id: 'strikes_250',
          nameKey: 'achievement.strikes_250.name',
          descriptionKey: 'achievement.strikes_250.description',
          icon: 'flash_auto',
          xpReward: 600,
          type: AchievementType.strike,
          rarity: AchievementRarity.epic,
          targetValue: 250,
        );

        // Assert
        expect(achievement.id, equals('strikes_250'));
        expect(achievement.type, equals(AchievementType.strike));
        expect(achievement.targetValue, equals(250));
        expect(achievement.xpReward, equals(600));
      });

      test('Strikes_500 achievement should be legendary', () {
        // Act
        final achievement = Achievement(
          id: 'strikes_500',
          nameKey: 'achievement.strikes_500.name',
          descriptionKey: 'achievement.strikes_500.description',
          icon: 'thunderstorm',
          xpReward: 1000,
          type: AchievementType.strike,
          rarity: AchievementRarity.legendary,
          targetValue: 500,
        );

        // Assert
        expect(achievement.id, equals('strikes_500'));
        expect(achievement.rarity, equals(AchievementRarity.legendary));
      });

      test('Score_275 achievement should be near-perfect', () {
        // Act
        final achievement = Achievement(
          id: 'score_275',
          nameKey: 'achievement.score_275.name',
          descriptionKey: 'achievement.score_275.description',
          icon: 'auto_awesome',
          xpReward: 750,
          type: AchievementType.highScore,
          rarity: AchievementRarity.epic,
          targetValue: 275,
        );

        // Assert
        expect(achievement.id, equals('score_275'));
        expect(achievement.type, equals(AchievementType.highScore));
        expect(achievement.targetValue, equals(275));
        expect(achievement.xpReward, equals(750));
      });

      test('Streak_7 and Streak_10 achievements should have increasing difficulty', () {
        // Act
        final streak7 = Achievement(
          id: 'streak_7',
          nameKey: 'achievement.streak_7.name',
          descriptionKey: 'achievement.streak_7.description',
          icon: 'flame',
          xpReward: 500,
          type: AchievementType.streak,
          rarity: AchievementRarity.epic,
          targetValue: 7,
        );

        final streak10 = Achievement(
          id: 'streak_10',
          nameKey: 'achievement.streak_10.name',
          descriptionKey: 'achievement.streak_10.description',
          icon: 'fireplace',
          xpReward: 800,
          type: AchievementType.streak,
          rarity: AchievementRarity.legendary,
          targetValue: 10,
        );

        // Assert
        expect(streak7.targetValue, equals(7));
        expect(streak7.xpReward, equals(500));
        expect(streak7.rarity, equals(AchievementRarity.epic));
        
        expect(streak10.targetValue, equals(10));
        expect(streak10.xpReward, equals(800));
        expect(streak10.rarity, equals(AchievementRarity.legendary));
        
        // Verify progression
        expect(streak10.targetValue, greaterThan(streak7.targetValue));
        expect(streak10.xpReward, greaterThan(streak7.xpReward));
      });

      test('Spares_250 and Spares_500 achievements should have correct values', () {
        // Act
        final spares250 = Achievement(
          id: 'spares_250',
          nameKey: 'achievement.spares_250.name',
          descriptionKey: 'achievement.spares_250.description',
          icon: 'check_circle_outline',
          xpReward: 400,
          type: AchievementType.spare,
          rarity: AchievementRarity.epic,
          targetValue: 250,
        );

        final spares500 = Achievement(
          id: 'spares_500',
          nameKey: 'achievement.spares_500.name',
          descriptionKey: 'achievement.spares_500.description',
          icon: 'verified_user',
          xpReward: 600,
          type: AchievementType.spare,
          rarity: AchievementRarity.epic,
          targetValue: 500,
        );

        // Assert
        expect(spares250.targetValue, equals(250));
        expect(spares250.xpReward, equals(400));
        
        expect(spares500.targetValue, equals(500));
        expect(spares500.xpReward, equals(600));
        
        // Verify progression
        expect(spares500.targetValue, greaterThan(spares250.targetValue));
        expect(spares500.xpReward, greaterThan(spares250.xpReward));
      });
    });

    group('Achievement Progress Calculations', () {
      test('Progress percentage should be calculated correctly', () {
        // Arrange
        final achievement = Achievement(
          id: 'test',
          nameKey: 'test',
          descriptionKey: 'test',
          icon: 'test',
          xpReward: 100,
          type: AchievementType.gamesPlayed,
          rarity: AchievementRarity.common,
          targetValue: 100,
          currentProgress: 50,
        );

        // Act & Assert
        expect(achievement.progressPercentage, equals(50.0));
      });

      test('Progress percentage should be 0 when no progress', () {
        // Arrange
        final achievement = Achievement(
          id: 'test',
          nameKey: 'test',
          descriptionKey: 'test',
          icon: 'test',
          xpReward: 100,
          type: AchievementType.gamesPlayed,
          rarity: AchievementRarity.common,
          targetValue: 100,
          currentProgress: 0,
        );

        // Act & Assert
        expect(achievement.progressPercentage, equals(0.0));
      });

      test('Progress percentage should be 100 when completed', () {
        // Arrange
        final achievement = Achievement(
          id: 'test',
          nameKey: 'test',
          descriptionKey: 'test',
          icon: 'test',
          xpReward: 100,
          type: AchievementType.gamesPlayed,
          rarity: AchievementRarity.common,
          targetValue: 100,
          currentProgress: 100,
        );

        // Act & Assert
        expect(achievement.progressPercentage, equals(100.0));
      });
    });
  });
}
