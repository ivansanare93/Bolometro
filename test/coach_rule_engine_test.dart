import 'package:bolometro/models/coach_models.dart';
import 'package:bolometro/services/coach_rule_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CoachInputMetrics baseMetrics() {
    return const CoachInputMetrics(
      totalSessions: 4,
      totalGames: 12,
      sparePercentage: 42,
      strikePercentage: 38,
      consistencyStdDev: 20,
      criticalFramesOpenRate: 35,
      recentAverage: 160,
      previousAverage: 150,
      recentSparePercentage: 43,
      previousSparePercentage: 39,
      recentCriticalFramesOpenRate: 30,
      previousCriticalFramesOpenRate: 36,
      consecutiveImprovingSessions: 2,
    );
  }

  CoachRule makeRule({
    required String id,
    required CoachTipPriority priority,
    required int impact,
    required int urgency,
    int cooldownDays = 2,
  }) {
    return CoachRule(
      id: id,
      category: CoachTipCategory.correctivo,
      priority: priority,
      impact: impact,
      urgency: urgency,
      cooldownDays: cooldownDays,
      condition: (_) => true,
      tipBuilder: (_) => CoachTip(
        id: '${id}_tip',
        title: 'Tip $id',
        message: 'Mensaje $id',
        detail: 'Detalle $id',
        actionText: 'Acción $id',
        category: CoachTipCategory.correctivo,
        priority: priority,
        impact: impact,
        urgency: urgency,
      ),
    );
  }

  group('CoachRuleEngine', () {
    test('prioriza reglas por prioridad e impacto', () {
      final engine = CoachRuleEngine(
        rules: [
          makeRule(id: 'low_rule', priority: CoachTipPriority.low, impact: 1, urgency: 1),
          makeRule(id: 'critical_rule', priority: CoachTipPriority.critical, impact: 5, urgency: 5),
        ],
      );

      final advice = engine.generateAdvice(
        metrics: baseMetrics(),
        interactionState: const CoachInteractionState(),
        now: DateTime(2026, 1, 1),
      );

      expect(advice.tips.first.id, equals('critical_rule_tip'));
    });

    test('limita a máximo 3 tips por sesión', () {
      final engine = CoachRuleEngine(
        rules: [
          makeRule(id: 'a', priority: CoachTipPriority.high, impact: 5, urgency: 5),
          makeRule(id: 'b', priority: CoachTipPriority.high, impact: 4, urgency: 5),
          makeRule(id: 'c', priority: CoachTipPriority.medium, impact: 4, urgency: 4),
          makeRule(id: 'd', priority: CoachTipPriority.medium, impact: 3, urgency: 4),
        ],
      );

      final advice = engine.generateAdvice(
        metrics: baseMetrics(),
        interactionState: const CoachInteractionState(),
        now: DateTime(2026, 1, 1),
      );

      expect(advice.tips.length, equals(3));
    });

    test('respeta cooldown y evita repetición inmediata', () {
      final engine = CoachRuleEngine(
        rules: [
          makeRule(id: 'rule_a', priority: CoachTipPriority.high, impact: 5, urgency: 5, cooldownDays: 3),
        ],
      );

      final firstAdvice = engine.generateAdvice(
        metrics: baseMetrics(),
        interactionState: const CoachInteractionState(),
        now: DateTime(2026, 1, 10),
      );
      expect(firstAdvice.tips, isNotEmpty);

      final secondAdvice = engine.generateAdvice(
        metrics: baseMetrics(),
        interactionState: firstAdvice.interactionState,
        now: DateTime(2026, 1, 11),
      );

      expect(secondAdvice.tips, isEmpty);
    });

    test('desempata por id de regla cuando score es igual', () {
      final engine = CoachRuleEngine(
        rules: [
          makeRule(id: 'z_rule', priority: CoachTipPriority.medium, impact: 3, urgency: 3),
          makeRule(id: 'a_rule', priority: CoachTipPriority.medium, impact: 3, urgency: 3),
        ],
      );

      final advice = engine.generateAdvice(
        metrics: baseMetrics(),
        interactionState: const CoachInteractionState(),
        now: DateTime(2026, 1, 1),
      );

      expect(advice.tips.first.id, equals('a_rule_tip'));
      expect(advice.tips[1].id, equals('z_rule_tip'));
    });
  });
}
