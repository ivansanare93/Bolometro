import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting user-defined statistics goals locally.
///
/// Uses [SharedPreferences] — the same persistence layer used by [DraftService]
/// and the theme/locale settings — so no new dependency is required.
class GoalService {
  GoalService._();

  static const String _keyAverageGoal = 'stats_goal_average';

  /// Default goal shown the first time the user opens the goal section.
  static const double defaultAverageGoal = 150.0;

  /// Minimum allowed average goal.
  static const double minAverageGoal = 1.0;

  /// Maximum allowed average goal (perfect game in bowling is 300).
  static const double maxAverageGoal = 300.0;

  /// Loads the stored average goal, or [null] if the user has never set one.
  static Future<double?> loadAverageGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyAverageGoal);
  }

  /// Persists [goal] locally. Throws [ArgumentError] if [goal] is not within
  /// [[minAverageGoal], [maxAverageGoal]].
  static Future<void> saveAverageGoal(double goal) async {
    if (goal < minAverageGoal || goal > maxAverageGoal) {
      throw ArgumentError.value(
        goal,
        'goal',
        'Must be between $minAverageGoal and $maxAverageGoal',
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyAverageGoal, goal);
  }

  /// Removes the stored goal so the section reverts to its default state.
  static Future<void> clearAverageGoal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAverageGoal);
  }
}
