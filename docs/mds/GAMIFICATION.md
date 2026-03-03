# Gamification System - Implementation Summary

## Overview

This document describes the gamification system implemented for Bolometro, fulfilling the requirements for "Logros y Medallas" (Achievements and Medals) and "Sistema de niveles" (Level System).

## Features

### 1. Achievement System (Logros y Medallas)

The system includes 29 unique achievements across multiple categories:

#### Categories and Achievements

**First Steps**
- `first_game`: Play your first game (50 XP, Common)

**Games Played**
- `games_10`: Play 10 games (100 XP, Common)
- `games_50`: Play 50 games (250 XP, Rare)
- `games_100`: Play 100 games (500 XP, Epic)
- `games_250`: Play 250 games (750 XP, Epic)
- `games_500`: Play 500 games (1000 XP, Legendary)

**Strikes**
- `strikes_10`: Get 10 strikes (75 XP, Common)
- `strikes_50`: Get 50 strikes (200 XP, Rare)
- `strikes_100`: Get 100 strikes (400 XP, Epic)
- `strikes_250`: Get 250 strikes (600 XP, Epic)
- `strikes_500`: Get 500 strikes (1000 XP, Legendary)

**High Scores**
- `score_150`: Score 150 points in a game (100 XP, Common)
- `score_200`: Score 200 points in a game (250 XP, Rare)
- `score_250`: Score 250 points in a game (500 XP, Epic)
- `score_275`: Score 275 points in a game (750 XP, Epic)

**Perfect Game**
- `perfect_game`: Score 300 points (1000 XP, Legendary)

**Streaks**
- `streak_3`: Get 3 consecutive strikes (150 XP, Rare)
- `streak_5`: Get 5 consecutive strikes (300 XP, Epic)
- `streak_7`: Get 7 consecutive strikes (500 XP, Epic)
- `streak_10`: Get 10 consecutive strikes (800 XP, Legendary)

**Spares**
- `spares_20`: Get 20 spares (75 XP, Common)
- `spares_100`: Get 100 spares (200 XP, Rare)
- `spares_250`: Get 250 spares (400 XP, Epic)
- `spares_500`: Get 500 spares (600 XP, Epic)

**Consistency**
- `consistency_5`: Play 5 consecutive games with similar scores (±15 points) (200 XP, Rare)
- `consistency_10`: Play 10 consecutive games with similar scores (±15 points) (500 XP, Epic)

**Dedication**
- `dedication_7`: Play at least once on 7 different days (300 XP, Rare)
- `dedication_30`: Play at least once on 30 different days (600 XP, Epic)
- `dedication_100`: Play at least once on 100 different days (1000 XP, Legendary)

#### Rarity System

Achievements are categorized by rarity:
- **Common** (Gray): Easy to obtain, low XP rewards
- **Rare** (Blue): Moderate difficulty, medium XP rewards
- **Epic** (Purple): Hard to obtain, high XP rewards
- **Legendary** (Gold): Very hard to obtain, maximum XP rewards

### 2. Level System

#### XP and Levels

- Users earn XP by unlocking achievements
- XP accumulates to increase user level
- Level requirements use exponential formula: `100 × level^1.5`
- Example progression:
  - Level 1 → 2: 300 XP
  - Level 2 → 3: 450 XP
  - Level 3 → 4: 600 XP
  - And so on...

#### Visual Indicators

- Level badge displayed on user profile
- Progress bar showing advancement to next level
- Current XP and XP needed for next level
- Level icon with star symbol

### 3. User Interface

#### Achievements Screen

New dedicated screen accessible from home menu showing:

1. **User Progress Card**
   - Current level with icon
   - Total XP earned
   - Progress bar to next level
   - XP breakdown (current/needed)

2. **Unlocked Achievements Section**
   - Sorted by unlock date (most recent first)
   - Shows achievement icon, name, description
   - Displays XP earned and rarity
   - Full color with accent borders

3. **Locked Achievements Section**
   - Sorted by progress (closest to unlock first)
   - Shows achievement icon (grayed out), name, description
   - Progress bar showing completion percentage
   - Current progress / target value

#### Achievement Notifications

When unlocking an achievement:
- Green toast notification appears
- Shows trophy icon
- Displays achievement name and XP reward
- Multiple achievements stack with delay

#### Profile Integration

- Level badge overlays profile avatar
- Shows current level number with star icon
- Gradient background matching app theme
- Border to make it stand out

## Technical Implementation

### Architecture

```
lib/
├── models/
│   ├── achievement.dart          # Achievement model
│   ├── achievement.g.dart        # Hive adapter
│   ├── user_progress.dart        # User progress model
│   └── user_progress.g.dart      # Hive adapter
├── services/
│   └── achievement_service.dart  # Core gamification logic
├── screens/
│   └── achievements_screen.dart  # Achievements UI
└── l10n/
    ├── app_es.arb               # Spanish translations
    └── app_en.arb               # English translations
```

### Data Models

#### Achievement
```dart
class Achievement {
  String id;
  String nameKey;
  String descriptionKey;
  String icon;
  int xpReward;
  AchievementType type;
  AchievementRarity rarity;
  int targetValue;
  bool isUnlocked;
  DateTime? unlockedAt;
  int currentProgress;
}
```

#### UserProgress
```dart
class UserProgress {
  int experiencePoints;
  int currentLevel;
  List<String> unlockedAchievementIds;
  DateTime lastUpdated;
}
```

### Services

#### AchievementService

Key responsibilities:
- Initialize achievements and user progress
- Calculate statistics from sessions
- Check unlock conditions for achievements
- Award XP and manage level progression
- Persist data to Hive
- Sync to Firestore for cloud backup

Key methods:
- `initialize()`: Load/create user progress and achievements
- `checkAndUnlockAchievements()`: Check all achievements against current stats
- `addExperience(int xp)`: Add XP and handle level-ups
- `resetProgress()`: Reset for testing/debugging

### Data Persistence

#### Local Storage (Hive)

Boxes:
- `userProgress`: Single UserProgress object
- `achievements`: Map of achievement ID to Achievement

Type IDs:
- 11: Achievement
- 12: UserProgress
- 13: AchievementType enum
- 14: AchievementRarity enum

#### Cloud Storage (Firestore)

Structure:
```
users/{userId}/
  ├── gamification/
  │   └── progress/
  │       ├── (progress document)
  │       └── achievements/{achievementId}
```

Features:
- Batch writes for efficiency
- Merge on update to preserve data
- Achievement merging preserves progress on app updates

### Integration Points

#### Session Creation

When a user saves a session:
1. Session is saved to local/cloud
2. `AchievementService.checkAndUnlockAchievements()` is called
3. Stats are calculated from all sessions
4. Achievements are checked and unlocked if conditions met
5. XP is awarded and user may level up
6. Notifications are shown for new achievements

#### Navigation

- Home screen menu includes "Achievements" option
- Tapping navigates to `AchievementsScreen`
- Pull-to-refresh updates achievement progress

## Localization

All text is fully localized in Spanish and English:

### Spanish (app_es.arb)
- All achievement names and descriptions
- UI labels (Level, Achievements, Unlocked, Locked)
- Rarity names
- Notification text

### English (app_en.arb)
- Complete matching translations

### Translation Keys

Format: `achievement.{achievement_id}.{name|description}`

Example:
- `achievement.first_game.name` → "Primera Partida" / "First Game"
- `achievement.first_game.description` → "Juega tu primera partida" / "Play your first game"

## Testing

### Unit Tests

Created comprehensive tests in:
- `test/achievement_model_test.dart`: Achievement model tests
- `test/user_progress_model_test.dart`: UserProgress model tests

Coverage includes:
- Model creation with default and custom values
- XP and level calculations
- Progress percentage calculations
- Achievement unlock logic
- JSON serialization/deserialization
- Edge cases and null handling

### Test Scenarios

- XP calculation for each level
- Level-up detection (single and multiple levels)
- Achievement unlock conditions
- Progress tracking
- Data persistence
- Localization

## Usage Flow

### First Time User

1. User opens app and plays first game
2. After saving, "First Game" achievement unlocks
3. Notification shows: "¡Logro Desbloqueado! Primera Partida (+50 XP)"
4. User is now Level 1 with 50 XP
5. User can view achievements screen to see progress

### Returning User

1. User plays more games
2. Achievements unlock as milestones are reached
3. XP accumulates, user levels up
4. Progress visible in achievements screen
5. Level badge shown on profile
6. Data syncs to cloud for persistence

### Viewing Achievements

1. User taps "Logros" / "Achievements" from home menu
2. Screen shows:
   - Current level and XP
   - Progress to next level
   - All unlocked achievements
   - All locked achievements with progress
3. Pull down to refresh and check for new unlocks

## Future Enhancements

Potential additions (not in current scope):

1. **Special Challenges**: Time-limited special achievements
2. **Social Achievements**: Compare with friends
3. **Seasonal Achievements**: Time-limited special achievements
4. **Achievement Categories**: Filter by category
5. **Leaderboards**: Compare levels with friends
6. **Rewards**: Unlock themes, avatars, or features
7. **Statistics**: Detailed achievement progress analytics
8. **Daily/Weekly Challenges**: Rotating challenges with special rewards

## Files Modified/Created

### New Files
- `lib/models/achievement.dart`
- `lib/models/achievement.g.dart`
- `lib/models/user_progress.dart`
- `lib/models/user_progress.g.dart`
- `lib/services/achievement_service.dart`
- `lib/screens/achievements_screen.dart`
- `test/achievement_model_test.dart`
- `test/user_progress_model_test.dart`

### Modified Files
- `lib/main.dart`: Register Hive adapters, add AchievementService provider
- `lib/screens/home.dart`: Add achievements navigation
- `lib/screens/perfil_usuario.dart`: Add level badge
- `lib/screens/registro_completo_sesion.dart`: Integrate achievement checking
- `lib/services/firestore_service.dart`: Add gamification sync methods
- `lib/l10n/app_es.arb`: Add Spanish translations
- `lib/l10n/app_en.arb`: Add English translations

## Conclusion

The gamification system successfully implements both requested features:

✅ **Logros y Medallas**: Complete achievement system with 29 unique achievements, progress tracking, and rewards

✅ **Sistema de niveles**: XP-based level system with visual progression, badges, and automatic level-ups

✅ **Más logros y desafíos especiales**: Extended achievement system with:
- 14 additional achievements (from 15 to 29 total)
- Advanced tier achievements for games played, strikes, spares, and high scores
- Consistency achievements for maintaining similar performance
- Dedication achievements for long-term engagement
- Higher XP rewards for harder achievements

The implementation follows Flutter best practices, integrates seamlessly with the existing codebase, and provides a motivating experience for users to track their bowling progress.
