import 'dart:math' show sqrt;

import '../models/coach_models.dart';
import '../models/partida.dart';
import '../models/sesion.dart';
import '../utils/app_constants.dart';

class CoachRuleEngine {
  CoachRuleEngine({List<CoachRule>? rules}) : _rules = rules ?? _defaultRules;

  final List<CoachRule> _rules;

  CoachSessionAdvice generateAdvice({
    required CoachInputMetrics metrics,
    required CoachInteractionState interactionState,
    int maxTips = 3,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    if (!metrics.hasEnoughData) {
      return CoachSessionAdvice(
        tips: const [],
        interactionState: interactionState,
        hasEnoughData: false,
        generatedAt: timestamp,
        focusMessage:
            'Aún necesito más sesiones para personalizar mejor tu enfoque.',
        progressMessage:
            'Registra al menos 2 sesiones con 6 partidas totales para ver tendencias.',
        weeklyGoalSuggestion:
            'Meta sugerida: completa 2 sesiones esta semana y mantén una rutina estable.',
        fallbackMessage:
            'Todavía no hay datos suficientes para recomendaciones avanzadas.',
      );
    }

    final candidates = <_RuleScore>[];
    for (final rule in _rules) {
      if (!rule.condition(metrics)) continue;
      if (_isRuleInCooldown(rule, interactionState, timestamp)) continue;
      candidates.add(
        _RuleScore(
          rule: rule,
          totalScore: (rule.priority.weight * 100) + (rule.impact * 10) + rule.urgency,
        ),
      );
    }

    candidates.sort((a, b) {
      final byScore = b.totalScore.compareTo(a.totalScore);
      if (byScore != 0) return byScore;
      return a.rule.id.compareTo(b.rule.id);
    });

    final selected = candidates.take(maxTips).toList();
    final tips = selected.map((s) => s.rule.tipBuilder(metrics)).toList();

    final updatedLastShown = Map<String, DateTime>.from(interactionState.lastShownRuleAt);
    for (final rule in selected.map((s) => s.rule)) {
      updatedLastShown[rule.id] = timestamp;
    }

    return CoachSessionAdvice(
      tips: tips,
      interactionState: interactionState.copyWith(lastShownRuleAt: updatedLastShown),
      hasEnoughData: true,
      generatedAt: timestamp,
      focusMessage: _buildFocusMessage(tips),
      progressMessage: _buildProgressMessage(metrics),
      weeklyGoalSuggestion: _buildWeeklyGoal(metrics),
    );
  }

  bool _isRuleInCooldown(
    CoachRule rule,
    CoachInteractionState interactionState,
    DateTime now,
  ) {
    final lastShown = interactionState.lastShownRuleAt[rule.id];
    if (lastShown == null) return false;
    return now.difference(lastShown).inDays < rule.cooldownDays;
  }

  String _buildFocusMessage(List<CoachTip> tips) {
    if (tips.isEmpty) {
      return 'Hoy el foco es mantener tu rutina y registrar una sesión completa.';
    }
    return 'Enfócate primero en: ${tips.first.actionText}';
  }

  String _buildProgressMessage(CoachInputMetrics metrics) {
    final delta = metrics.recentAverage - metrics.previousAverage;
    if (delta >= 6) {
      return 'Vas mejorando: subiste ${delta.toStringAsFixed(1)} puntos de promedio.';
    }
    if (delta <= -6) {
      return 'Hay una caída reciente de ${delta.abs().toStringAsFixed(1)} puntos: ajusta el enfoque.';
    }
    return 'Tu tendencia está estable. Pequeños ajustes pueden marcar diferencia.';
  }

  String _buildWeeklyGoal(CoachInputMetrics metrics) {
    if (metrics.sparePercentage < 40) {
      return 'Meta semanal: subir tu spare en +5 puntos (ejemplo: de ${metrics.sparePercentage.toStringAsFixed(1)}% a ${(metrics.sparePercentage + 5).toStringAsFixed(1)}%).';
    }
    if (metrics.criticalFramesOpenRate > 45) {
      return 'Meta semanal: reducir errores en frames 8/9/10 por debajo de 40%.';
    }
    return 'Meta semanal: mantener 3 sesiones con promedio >= ${metrics.recentAverage.toStringAsFixed(0)}.';
  }

  static CoachInputMetrics buildInputMetrics(
    List<Sesion> sesiones,
    Map<String, dynamic> stats,
  ) {
    final sorted = List<Sesion>.from(sesiones)
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    final allGames = sorted.expand((s) => s.partidas).toList();
    final sessionAverages = sorted.map(_sessionAverage).toList();
    final split = sessionAverages.length >= 6 ? 3 : (sessionAverages.length ~/ 2);
    final safeSplit = split > 0 ? split : 1;

    final recentAverages = sessionAverages.length > safeSplit
        ? sessionAverages.sublist(sessionAverages.length - safeSplit)
        : sessionAverages;
    final previousAverages = sessionAverages.length > safeSplit
        ? sessionAverages.sublist(0, sessionAverages.length - safeSplit)
        : sessionAverages;

    final recentSessions = sorted.length > safeSplit
        ? sorted.sublist(sorted.length - safeSplit)
        : sorted;
    final previousSessions = sorted.length > safeSplit
        ? sorted.sublist(0, sorted.length - safeSplit)
        : sorted;

    final sparePercentage = (stats['porcentajes'] as Map<String, double>)['spares'] ?? 0.0;
    final strikePercentage = (stats['porcentajes'] as Map<String, double>)['strikes'] ?? 0.0;

    return CoachInputMetrics(
      totalSessions: sesiones.length,
      totalGames: allGames.length,
      sparePercentage: sparePercentage,
      strikePercentage: strikePercentage,
      consistencyStdDev: _stdDev(allGames.map((g) => g.total.toDouble()).toList()),
      criticalFramesOpenRate: _criticalFramesOpenRate(allGames),
      recentAverage: _avg(recentAverages),
      previousAverage: _avg(previousAverages),
      recentSparePercentage: _sparePercentage(recentSessions),
      previousSparePercentage: _sparePercentage(previousSessions),
      recentCriticalFramesOpenRate: _criticalFramesOpenRate(
        recentSessions.expand((s) => s.partidas).toList(),
      ),
      previousCriticalFramesOpenRate: _criticalFramesOpenRate(
        previousSessions.expand((s) => s.partidas).toList(),
      ),
      consecutiveImprovingSessions: _consecutiveImprovingSessions(sessionAverages),
    );
  }

  static double _sessionAverage(Sesion sesion) {
    if (sesion.partidas.isEmpty) return 0;
    final total = sesion.partidas.fold<int>(0, (sum, p) => sum + p.total);
    return total / sesion.partidas.length;
  }

  static double _avg(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double _stdDev(List<double> values) {
    if (values.length <= 1) return 0;
    final mean = _avg(values);
    final sum = values.fold<double>(
      0,
      (acc, value) => acc + ((value - mean) * (value - mean)),
    );
    return sqrt(sum / values.length);
  }

  static double _sparePercentage(List<Sesion> sesiones) {
    final partidasFrames = sesiones
        .expand((s) => s.partidas)
        .map((p) => p.frames)
        .toList();
    if (partidasFrames.isEmpty) return 0;

    int totalFrames = 0;
    int spareFrames = 0;
    for (final game in partidasFrames) {
      for (final frame in game) {
        if (frame.isEmpty) continue;
        totalFrames++;
        if (frame.contains(AppConstants.simboloSpare)) {
          spareFrames++;
        }
      }
    }
    if (totalFrames == 0) return 0;
    return (spareFrames / totalFrames) * 100;
  }

  static double _criticalFramesOpenRate(List<Partida> games) {
    int criticalFrames = 0;
    int openCriticalFrames = 0;

    for (final game in games) {
      for (int index = 7; index <= 9; index++) {
        if (index >= game.frames.length) continue;
        final frame = game.frames[index];
        if (frame.isEmpty) continue;
        criticalFrames++;
        if (_isOpenFrame(frame)) {
          openCriticalFrames++;
        }
      }
    }

    if (criticalFrames == 0) return 0;
    return (openCriticalFrames / criticalFrames) * 100;
  }

  static bool _isOpenFrame(List<String> frame) {
    if (frame.isEmpty) return false;
    final isStrike = frame.first == AppConstants.simboloStrike;
    final isSpare = frame.contains(AppConstants.simboloSpare);
    return !isStrike && !isSpare;
  }

  static int _consecutiveImprovingSessions(List<double> sessionAverages) {
    if (sessionAverages.length < 2) return 0;
    int streak = 0;
    for (int i = sessionAverages.length - 1; i > 0; i--) {
      if (sessionAverages[i] > sessionAverages[i - 1]) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static List<CoachRule> get _defaultRules => [
        CoachRule(
          id: 'spare_very_low',
          category: CoachTipCategory.correctivo,
          priority: CoachTipPriority.critical,
          impact: 5,
          urgency: 5,
          cooldownDays: 3,
          condition: (m) => m.sparePercentage < 35,
          tipBuilder: (m) => CoachTip(
            id: 'spare_very_low_tip',
            title: 'Tu spare necesita atención urgente',
            message: 'Tu spare está en ${m.sparePercentage.toStringAsFixed(1)}%.',
            detail:
                'Practica 15 tiros de remate por sesión en dejes simples y registra si conviertes o no.',
            actionText: 'dedicar 15 remates por sesión',
            category: CoachTipCategory.correctivo,
            priority: CoachTipPriority.critical,
            impact: 5,
            urgency: 5,
          ),
        ),
        CoachRule(
          id: 'spare_low',
          category: CoachTipCategory.correctivo,
          priority: CoachTipPriority.high,
          impact: 4,
          urgency: 4,
          cooldownDays: 2,
          condition: (m) => m.sparePercentage >= 35 && m.sparePercentage < 45,
          tipBuilder: (m) => CoachTip(
            id: 'spare_low_tip',
            title: 'Sube tu cierre de frames',
            message: 'Tu spare está cerca del objetivo, pero aún mejorable.',
            detail:
                'Enfoca tu próxima sesión en precisión del segundo tiro para ganar estabilidad de puntuación.',
            actionText: 'mejorar precisión del segundo tiro',
            category: CoachTipCategory.correctivo,
            priority: CoachTipPriority.high,
            impact: 4,
            urgency: 4,
          ),
        ),
        CoachRule(
          id: 'consistency_high_variance',
          category: CoachTipCategory.correctivo,
          priority: CoachTipPriority.high,
          impact: 4,
          urgency: 4,
          cooldownDays: 3,
          condition: (m) => m.consistencyStdDev > 30,
          tipBuilder: (m) => CoachTip(
            id: 'consistency_high_variance_tip',
            title: 'Trabaja la consistencia',
            message:
                'Tu variación de resultados es alta (σ ${m.consistencyStdDev.toStringAsFixed(1)}).',
            detail:
                'Define una rutina fija previa al tiro y repítela durante toda la sesión para reducir oscilaciones.',
            actionText: 'aplicar rutina fija antes de cada tiro',
            category: CoachTipCategory.correctivo,
            priority: CoachTipPriority.high,
            impact: 4,
            urgency: 4,
          ),
        ),
        CoachRule(
          id: 'consistency_medium_variance',
          category: CoachTipCategory.objetivo,
          priority: CoachTipPriority.medium,
          impact: 3,
          urgency: 3,
          cooldownDays: 2,
          condition: (m) => m.consistencyStdDev > 22 && m.consistencyStdDev <= 30,
          tipBuilder: (m) => CoachTip(
            id: 'consistency_medium_variance_tip',
            title: 'Puedes estabilizar tu promedio',
            message:
                'Hay margen para bajar la variabilidad y sostener mejores rachas.',
            detail:
                'Apunta a cerrar cada bloque de 3 frames con una ejecución controlada, sin forzar potencia.',
            actionText: 'cerrar bloques de 3 frames con control',
            category: CoachTipCategory.objetivo,
            priority: CoachTipPriority.medium,
            impact: 3,
            urgency: 3,
          ),
        ),
        CoachRule(
          id: 'critical_frames_alert',
          category: CoachTipCategory.correctivo,
          priority: CoachTipPriority.critical,
          impact: 5,
          urgency: 5,
          cooldownDays: 3,
          condition: (m) => m.criticalFramesOpenRate > 55,
          tipBuilder: (m) => CoachTip(
            id: 'critical_frames_alert_tip',
            title: 'Alerta en frames 8/9/10',
            message:
                'En frames críticos tienes ${m.criticalFramesOpenRate.toStringAsFixed(1)}% abiertos.',
            detail:
                'Simula cierres de partida: juega 5 bloques empezando en frame 8 y prioriza no dejar abierto el 10.',
            actionText: 'simular cierres desde frame 8',
            category: CoachTipCategory.correctivo,
            priority: CoachTipPriority.critical,
            impact: 5,
            urgency: 5,
          ),
        ),
        CoachRule(
          id: 'critical_frames_warning',
          category: CoachTipCategory.proximaSesion,
          priority: CoachTipPriority.high,
          impact: 4,
          urgency: 4,
          cooldownDays: 2,
          condition: (m) =>
              m.criticalFramesOpenRate > 40 && m.criticalFramesOpenRate <= 55,
          tipBuilder: (m) => CoachTip(
            id: 'critical_frames_warning_tip',
            title: 'Refuerza tu cierre final',
            message:
                'Tus últimos frames aún pierden puntos clave en momentos de presión.',
            detail:
                'Antes de terminar cada sesión, ejecuta 10 tiros de remate en situaciones de frame 10.',
            actionText: 'hacer 10 remates de frame 10 al final',
            category: CoachTipCategory.proximaSesion,
            priority: CoachTipPriority.high,
            impact: 4,
            urgency: 4,
          ),
        ),
        CoachRule(
          id: 'average_drop',
          category: CoachTipCategory.correctivo,
          priority: CoachTipPriority.high,
          impact: 5,
          urgency: 4,
          cooldownDays: 2,
          condition: (m) => (m.recentAverage - m.previousAverage) <= -10,
          tipBuilder: (m) => CoachTip(
            id: 'average_drop_tip',
            title: 'Tu promedio cayó recientemente',
            message:
                'Bajaste ${m.previousAverage - m.recentAverage >= 0 ? (m.previousAverage - m.recentAverage).toStringAsFixed(1) : '0'} puntos.',
            detail:
                'Vuelve a una configuración simple (línea y velocidad estable) para recuperar base técnica.',
            actionText: 'volver a una línea estable en la próxima sesión',
            category: CoachTipCategory.correctivo,
            priority: CoachTipPriority.high,
            impact: 5,
            urgency: 4,
          ),
        ),
        CoachRule(
          id: 'spare_drop_recent',
          category: CoachTipCategory.correctivo,
          priority: CoachTipPriority.high,
          impact: 4,
          urgency: 4,
          cooldownDays: 2,
          condition: (m) => (m.recentSparePercentage - m.previousSparePercentage) <= -8,
          tipBuilder: (m) => CoachTip(
            id: 'spare_drop_recent_tip',
            title: 'Cayó tu conversión de spare',
            message:
                'Tu spare reciente bajó frente al bloque anterior.',
            detail:
                'En la próxima sesión, registra cada deje fallado y repítelo dos veces hasta convertirlo.',
            actionText: 'repetir dejes fallados hasta convertirlos',
            category: CoachTipCategory.correctivo,
            priority: CoachTipPriority.high,
            impact: 4,
            urgency: 4,
          ),
        ),
        CoachRule(
          id: 'critical_drop_recent',
          category: CoachTipCategory.correctivo,
          priority: CoachTipPriority.high,
          impact: 4,
          urgency: 5,
          cooldownDays: 2,
          condition: (m) =>
              (m.recentCriticalFramesOpenRate - m.previousCriticalFramesOpenRate) >= 10,
          tipBuilder: (m) => CoachTip(
            id: 'critical_drop_recent_tip',
            title: 'Perdiste solidez al final',
            message: 'Subieron los errores recientes en frames 8/9/10.',
            detail:
                'Haz un bloque específico de cierre con objetivo: máximo 1 frame abierto por serie.',
            actionText: 'bloque de cierre con máximo 1 abierto',
            category: CoachTipCategory.correctivo,
            priority: CoachTipPriority.high,
            impact: 4,
            urgency: 5,
          ),
        ),
        CoachRule(
          id: 'improving_streak',
          category: CoachTipCategory.refuerzo,
          priority: CoachTipPriority.medium,
          impact: 3,
          urgency: 2,
          cooldownDays: 2,
          condition: (m) => m.consecutiveImprovingSessions >= 3,
          tipBuilder: (m) => const CoachTip(
            id: 'improving_streak_tip',
            title: '¡Gran progreso sostenido!',
            message: 'Llevas 3 o más sesiones mejorando.',
            detail:
                'Mantén tu proceso actual y documenta qué ajustes te están funcionando para repetirlos.',
            actionText: 'mantener el plan que te está funcionando',
            category: CoachTipCategory.refuerzo,
            priority: CoachTipPriority.medium,
            impact: 3,
            urgency: 2,
          ),
        ),
        CoachRule(
          id: 'average_up',
          category: CoachTipCategory.refuerzo,
          priority: CoachTipPriority.high,
          impact: 3,
          urgency: 2,
          cooldownDays: 2,
          condition: (m) => (m.recentAverage - m.previousAverage) >= 8,
          tipBuilder: (m) => CoachTip(
            id: 'average_up_tip',
            title: 'Tu promedio va en alza',
            message:
                'Subiste ${ (m.recentAverage - m.previousAverage).toStringAsFixed(1)} puntos.',
            detail:
                'Buen trabajo: ahora consolida este salto con una meta de regularidad para no retroceder.',
            actionText: 'consolidar este nuevo promedio',
            category: CoachTipCategory.refuerzo,
            priority: CoachTipPriority.high,
            impact: 3,
            urgency: 2,
          ),
        ),
        CoachRule(
          id: 'strike_good',
          category: CoachTipCategory.refuerzo,
          priority: CoachTipPriority.medium,
          impact: 2,
          urgency: 1,
          cooldownDays: 3,
          condition: (m) => m.strikePercentage >= 45,
          tipBuilder: (m) => CoachTip(
            id: 'strike_good_tip',
            title: 'Buen ritmo de strikes',
            message:
                'Tu tasa de strike está en ${m.strikePercentage.toStringAsFixed(1)}%.',
            detail:
                'Con ese ritmo, el mayor salto vendrá de cerrar más spares en frames de ajuste.',
            actionText: 'convertir más spares de ajuste',
            category: CoachTipCategory.refuerzo,
            priority: CoachTipPriority.medium,
            impact: 2,
            urgency: 1,
          ),
        ),
        CoachRule(
          id: 'next_session_focus',
          category: CoachTipCategory.proximaSesion,
          priority: CoachTipPriority.low,
          impact: 2,
          urgency: 1,
          cooldownDays: 1,
          condition: (m) =>
              m.sparePercentage >= 45 && m.criticalFramesOpenRate <= 40,
          tipBuilder: (m) => const CoachTip(
            id: 'next_session_focus_tip',
            title: 'Próxima sesión: objetivo de calidad',
            message:
                'Estás en una base sólida; toca elevar el estándar de ejecución.',
            detail:
                'Define una meta SMART para la próxima sesión: por ejemplo, mínimo 2 partidas con spare >= 50%.',
            actionText: 'fijar una meta SMART para la próxima sesión',
            category: CoachTipCategory.proximaSesion,
            priority: CoachTipPriority.low,
            impact: 2,
            urgency: 1,
          ),
        ),
      ];
}

class _RuleScore {
  const _RuleScore({
    required this.rule,
    required this.totalScore,
  });

  final CoachRule rule;
  final int totalScore;
}
