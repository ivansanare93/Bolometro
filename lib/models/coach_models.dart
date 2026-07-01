enum CoachTipPriority {
  critical(4),
  high(3),
  medium(2),
  low(1);

  const CoachTipPriority(this.weight);
  final int weight;
}

enum CoachTipCategory {
  correctivo,
  objetivo,
  refuerzo,
  proximaSesion,
}

class CoachInputMetrics {
  const CoachInputMetrics({
    required this.totalSessions,
    required this.totalGames,
    required this.sparePercentage,
    required this.strikePercentage,
    required this.consistencyStdDev,
    required this.criticalFramesOpenRate,
    required this.recentAverage,
    required this.previousAverage,
    required this.recentSparePercentage,
    required this.previousSparePercentage,
    required this.recentCriticalFramesOpenRate,
    required this.previousCriticalFramesOpenRate,
    required this.consecutiveImprovingSessions,
  });

  final int totalSessions;
  final int totalGames;
  final double sparePercentage;
  final double strikePercentage;
  final double consistencyStdDev;
  final double criticalFramesOpenRate;
  final double recentAverage;
  final double previousAverage;
  final double recentSparePercentage;
  final double previousSparePercentage;
  final double recentCriticalFramesOpenRate;
  final double previousCriticalFramesOpenRate;
  final int consecutiveImprovingSessions;

  bool get hasEnoughData => totalSessions >= 2 && totalGames >= 6;
}

typedef CoachRuleCondition = bool Function(CoachInputMetrics metrics);
typedef CoachRuleTipBuilder = CoachTip Function(CoachInputMetrics metrics);

class CoachRule {
  const CoachRule({
    required this.id,
    required this.category,
    required this.priority,
    required this.impact,
    required this.urgency,
    required this.cooldownDays,
    required this.condition,
    required this.tipBuilder,
  });

  final String id;
  final CoachTipCategory category;
  final CoachTipPriority priority;
  final int impact;
  final int urgency;
  final int cooldownDays;
  final CoachRuleCondition condition;
  final CoachRuleTipBuilder tipBuilder;
}

class CoachTip {
  const CoachTip({
    required this.id,
    required this.title,
    required this.message,
    required this.detail,
    required this.actionText,
    required this.category,
    required this.priority,
    required this.impact,
    required this.urgency,
  });

  final String id;
  final String title;
  final String message;
  final String detail;
  final String actionText;
  final CoachTipCategory category;
  final CoachTipPriority priority;
  final int impact;
  final int urgency;
}

class CoachInteractionState {
  const CoachInteractionState({
    this.lastShownRuleAt = const <String, DateTime>{},
    this.weeklyGoal,
    this.weeklyGoalCompleted = false,
    this.weeklyGoalSetAt,
    this.showTipExplanation = false,
  });

  final Map<String, DateTime> lastShownRuleAt;
  final String? weeklyGoal;
  final bool weeklyGoalCompleted;
  final DateTime? weeklyGoalSetAt;
  final bool showTipExplanation;

  CoachInteractionState copyWith({
    Map<String, DateTime>? lastShownRuleAt,
    String? weeklyGoal,
    bool clearWeeklyGoal = false,
    bool? weeklyGoalCompleted,
    DateTime? weeklyGoalSetAt,
    bool clearWeeklyGoalSetAt = false,
    bool? showTipExplanation,
  }) {
    return CoachInteractionState(
      lastShownRuleAt: lastShownRuleAt ?? this.lastShownRuleAt,
      weeklyGoal: clearWeeklyGoal ? null : (weeklyGoal ?? this.weeklyGoal),
      weeklyGoalCompleted: weeklyGoalCompleted ?? this.weeklyGoalCompleted,
      weeklyGoalSetAt: clearWeeklyGoalSetAt
          ? null
          : (weeklyGoalSetAt ?? this.weeklyGoalSetAt),
      showTipExplanation: showTipExplanation ?? this.showTipExplanation,
    );
  }
}

class CoachSessionAdvice {
  const CoachSessionAdvice({
    required this.tips,
    required this.interactionState,
    required this.hasEnoughData,
    required this.generatedAt,
    required this.focusMessage,
    required this.progressMessage,
    required this.weeklyGoalSuggestion,
    this.fallbackMessage,
  });

  final List<CoachTip> tips;
  final CoachInteractionState interactionState;
  final bool hasEnoughData;
  final DateTime generatedAt;
  final String focusMessage;
  final String progressMessage;
  final String weeklyGoalSuggestion;
  final String? fallbackMessage;

  CoachTip? get primaryTip => tips.isEmpty ? null : tips.first;
}
