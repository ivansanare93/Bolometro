import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/achievement_service.dart';
import '../models/achievement.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Pantalla de logros y progreso del usuario
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAchievements();
  }

  Future<void> _initializeAchievements() async {
    final achievementService = context.read<AchievementService>();
    if (!achievementService.isInitialized) {
      await achievementService.initialize();
    }
    await achievementService.checkAndUnlockAchievements();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.achievements ?? 'Achievements'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<AchievementService>(
              builder: (context, achievementService, child) {
                final userProgress = achievementService.userProgress;
                final achievements = achievementService.achievements;

                if (userProgress == null) {
                  return Center(
                    child: Text(l10n?.noDataAvailable ?? 'No data available'),
                  );
                }

                // Separar logros desbloqueados y bloqueados
                final unlockedAchievements = achievements
                    .where((a) => a.isUnlocked)
                    .toList()
                  ..sort((a, b) {
                    if (a.unlockedAt == null && b.unlockedAt == null) return 0;
                    if (a.unlockedAt == null) return 1;
                    if (b.unlockedAt == null) return -1;
                    return b.unlockedAt!.compareTo(a.unlockedAt!);
                  });
                
                final lockedAchievements = achievements
                    .where((a) => !a.isUnlocked)
                    .toList()
                  ..sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));

                return RefreshIndicator(
                  onRefresh: () async {
                    await achievementService.checkAndUnlockAchievements();
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Tarjeta de nivel y XP
                      _buildUserProgressCard(userProgress, theme, l10n),
                      const SizedBox(height: 24),

                      // Logros desbloqueados
                      if (unlockedAchievements.isNotEmpty) ...[
                        Text(
                          l10n?.unlockedAchievements ?? 'Unlocked Achievements',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...unlockedAchievements.map((achievement) =>
                            _buildAchievementCard(achievement, theme, l10n, true)),
                        const SizedBox(height: 24),
                      ],

                      // Logros bloqueados
                      if (lockedAchievements.isNotEmpty) ...[
                        Text(
                          l10n?.lockedAchievements ?? 'Locked Achievements',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...lockedAchievements.map((achievement) =>
                            _buildAchievementCard(achievement, theme, l10n, false)),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildUserProgressCard(
    dynamic userProgress,
    ThemeData theme,
    AppLocalizations? l10n,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Icono de nivel
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${userProgress.currentLevel}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n?.level ?? 'Level',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // XP actual
            Text(
              '${userProgress.experiencePoints} XP',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Barra de progreso
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n?.level ?? 'Level'} ${userProgress.currentLevel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${l10n?.level ?? 'Level'} ${userProgress.currentLevel + 1}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: userProgress.progressToNextLevel / 100,
                    minHeight: 12,
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    '${userProgress.xpInCurrentLevel} / ${userProgress.xpForNextLevel - userProgress.xpForCurrentLevel} XP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(
    Achievement achievement,
    ThemeData theme,
    AppLocalizations? l10n,
    bool isUnlocked,
  ) {
    final rarityColor = _getRarityColor(achievement.rarity);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnlocked ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUnlocked ? rarityColor : Colors.grey.shade300,
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono del logro
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isUnlocked ? rarityColor.withOpacity(0.2) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(achievement.icon),
                  color: isUnlocked ? rarityColor : Colors.grey,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Información del logro
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLocalizedText(l10n, achievement.nameKey),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getLocalizedText(l10n, achievement.descriptionKey),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isUnlocked ? Colors.grey.shade700 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Barra de progreso o XP ganado
                    if (isUnlocked)
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '+${achievement.xpReward} XP',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _getRarityText(achievement.rarity, l10n),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: rarityColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${achievement.currentProgress} / ${achievement.targetValue}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${achievement.progressPercentage.toStringAsFixed(0)}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: achievement.progressPercentage / 100,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey.shade600;
      case AchievementRarity.rare:
        return Colors.blue.shade600;
      case AchievementRarity.epic:
        return Colors.purple.shade600;
      case AchievementRarity.legendary:
        return Colors.amber.shade700;
    }
  }

  String _getRarityText(AchievementRarity rarity, AppLocalizations? l10n) {
    switch (rarity) {
      case AchievementRarity.common:
        return l10n?.common ?? 'Common';
      case AchievementRarity.rare:
        return l10n?.rare ?? 'Rare';
      case AchievementRarity.epic:
        return l10n?.epic ?? 'Epic';
      case AchievementRarity.legendary:
        return l10n?.legendary ?? 'Legendary';
    }
  }

  IconData _getIconData(String iconName) {
    // Mapear nombres de iconos a IconData
    final iconMap = <String, IconData>{
      'sports_bowling': Icons.sports_bowling,
      'looks_one': Icons.looks_one,
      'looks_5': Icons.looks_5,
      'military_tech': Icons.military_tech,
      'flash_on': Icons.flash_on,
      'bolt': Icons.bolt,
      'electric_bolt': Icons.electric_bolt,
      'trending_up': Icons.trending_up,
      'stars': Icons.stars,
      'star': Icons.star,
      'emoji_events': Icons.emoji_events,
      'whatshot': Icons.whatshot,
      'local_fire_department': Icons.local_fire_department,
      'check_circle': Icons.check_circle,
      'verified': Icons.verified,
    };
    
    return iconMap[iconName] ?? Icons.emoji_events;
  }

  String _getLocalizedText(AppLocalizations? l10n, String key) {
    if (l10n == null) return key;
    
    // Map achievement keys to localized strings
    final achievementMap = {
      'achievement.first_game.name': l10n.achievementFirstGameName,
      'achievement.first_game.description': l10n.achievementFirstGameDesc,
      'achievement.games_10.name': l10n.achievementGames10Name,
      'achievement.games_10.description': l10n.achievementGames10Desc,
      'achievement.games_50.name': l10n.achievementGames50Name,
      'achievement.games_50.description': l10n.achievementGames50Desc,
      'achievement.games_100.name': l10n.achievementGames100Name,
      'achievement.games_100.description': l10n.achievementGames100Desc,
      'achievement.strikes_10.name': l10n.achievementStrikes10Name,
      'achievement.strikes_10.description': l10n.achievementStrikes10Desc,
      'achievement.strikes_50.name': l10n.achievementStrikes50Name,
      'achievement.strikes_50.description': l10n.achievementStrikes50Desc,
      'achievement.strikes_100.name': l10n.achievementStrikes100Name,
      'achievement.strikes_100.description': l10n.achievementStrikes100Desc,
      'achievement.score_150.name': l10n.achievementScore150Name,
      'achievement.score_150.description': l10n.achievementScore150Desc,
      'achievement.score_200.name': l10n.achievementScore200Name,
      'achievement.score_200.description': l10n.achievementScore200Desc,
      'achievement.score_250.name': l10n.achievementScore250Name,
      'achievement.score_250.description': l10n.achievementScore250Desc,
      'achievement.perfect_game.name': l10n.achievementPerfectGameName,
      'achievement.perfect_game.description': l10n.achievementPerfectGameDesc,
      'achievement.streak_3.name': l10n.achievementStreak3Name,
      'achievement.streak_3.description': l10n.achievementStreak3Desc,
      'achievement.streak_5.name': l10n.achievementStreak5Name,
      'achievement.streak_5.description': l10n.achievementStreak5Desc,
      'achievement.spares_20.name': l10n.achievementSpares20Name,
      'achievement.spares_20.description': l10n.achievementSpares20Desc,
      'achievement.spares_100.name': l10n.achievementSpares100Name,
      'achievement.spares_100.description': l10n.achievementSpares100Desc,
    };
    
    return achievementMap[key] ?? key;
  }
}
