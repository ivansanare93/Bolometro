import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bolometro/services/achievement_service.dart';
import 'package:bolometro/models/achievement.dart';
import 'package:bolometro/models/user_progress.dart';

/// Tests for AchievementService reset functionality
void main() {
  group('AchievementService Reset', () {
    late AchievementService achievementService;

    setUpAll(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
      
      // Register adapters if not already registered (using generated adapters)
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(AchievementAdapter());
      }
      if (!Hive.isAdapterRegistered(13)) {
        Hive.registerAdapter(AchievementTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(14)) {
        Hive.registerAdapter(AchievementRarityAdapter());
      }
      if (!Hive.isAdapterRegistered(17)) {
        Hive.registerAdapter(UserProgressAdapter());
      }
    });

    setUp(() async {
      // Clean up before each test
      await Hive.deleteBoxFromDisk('userProgress');
      await Hive.deleteBoxFromDisk('achievements');
      
      // Get singleton instance
      achievementService = AchievementService();
    });

    tearDown(() async {
      // Clean up after each test
      if (Hive.isBoxOpen('userProgress')) {
        await Hive.box<UserProgress>('userProgress').close();
      }
      if (Hive.isBoxOpen('achievements')) {
        await Hive.box<Achievement>('achievements').close();
      }
      
      await Hive.deleteBoxFromDisk('userProgress');
      await Hive.deleteBoxFromDisk('achievements');
    });

    test('resetProgress should clear all achievements and user progress', () async {
      // Arrange - Initialize service and simulate some progress
      await achievementService.initialize();
      
      // Add some XP to simulate progress
      await achievementService.addExperience(500);
      
      // Verify we have progress before reset
      expect(achievementService.userProgress?.experiencePoints, equals(500));
      expect(achievementService.userProgress?.currentLevel, greaterThan(1));
      
      // Act - Reset progress
      await achievementService.resetProgress();
      
      // Assert - Verify reset state
      expect(achievementService.isInitialized, isFalse, 
        reason: 'Service should be marked as not initialized after reset');
      
      // Re-initialize to load from Hive
      await achievementService.initialize();
      
      expect(achievementService.userProgress?.experiencePoints, equals(0),
        reason: 'Experience points should be reset to 0');
      expect(achievementService.userProgress?.currentLevel, equals(1),
        reason: 'Level should be reset to 1');
      expect(achievementService.userProgress?.unlockedAchievementIds, isEmpty,
        reason: 'No achievements should be unlocked after reset');
      
      // Verify all achievements are locked
      final achievements = achievementService.achievements;
      expect(achievements.every((a) => !a.isUnlocked), isTrue,
        reason: 'All achievements should be locked after reset');
      expect(achievements.every((a) => a.currentProgress == 0), isTrue,
        reason: 'All achievements should have 0 progress after reset');
    });

    test('resetProgress should persist reset state to Hive', () async {
      // Arrange - Initialize and add progress
      await achievementService.initialize();
      await achievementService.addExperience(1000);
      
      // Act - Reset and close boxes to force persistence
      await achievementService.resetProgress();
      
      if (Hive.isBoxOpen('userProgress')) {
        await Hive.box<UserProgress>('userProgress').close();
      }
      if (Hive.isBoxOpen('achievements')) {
        await Hive.box<Achievement>('achievements').close();
      }
      
      // Assert - Open boxes again and verify persisted state
      final progressBox = await Hive.openBox<UserProgress>('userProgress');
      final achievementsBox = await Hive.openBox<Achievement>('achievements');
      
      expect(progressBox.length, equals(1),
        reason: 'Progress box should have exactly one entry after reset');
      
      final progress = progressBox.getAt(0);
      expect(progress?.experiencePoints, equals(0));
      expect(progress?.currentLevel, equals(1));
      expect(progress?.unlockedAchievementIds, isEmpty);
      
      // Verify achievements are saved to Hive (should match initialized count)
      expect(achievementsBox.length, greaterThan(0),
        reason: 'All achievements should be saved to Hive');
      
      // Verify all persisted achievements are locked
      for (var achievement in achievementsBox.values) {
        expect(achievement.isUnlocked, isFalse,
          reason: 'Achievement ${achievement.id} should be locked in Hive');
        expect(achievement.currentProgress, equals(0),
          reason: 'Achievement ${achievement.id} should have 0 progress in Hive');
      }
    });

    test('achievements screen should see reset state after navigation', () async {
      // This simulates the user flow:
      // 1. User has progress
      // 2. User resets progress
      // 3. User navigates to achievements screen (calls initialize again)
      
      // Arrange - Initialize and add progress
      await achievementService.initialize();
      await achievementService.addExperience(2000);
      
      // Verify we have progress
      expect(achievementService.userProgress?.experiencePoints, equals(2000));
      
      // Act - Reset progress
      await achievementService.resetProgress();
      
      // Simulate navigation to achievements screen
      // The screen calls initialize() which should reload from Hive
      await achievementService.initialize();
      
      // Assert - Achievements should be reset
      expect(achievementService.userProgress?.experiencePoints, equals(0));
      expect(achievementService.userProgress?.currentLevel, equals(1));
      expect(achievementService.getUnlockedAchievements(), isEmpty);
      
      final allAchievements = achievementService.achievements;
      expect(allAchievements.every((a) => !a.isUnlocked), isTrue,
        reason: 'All achievements should appear locked on achievements screen');
    });
  });
}
