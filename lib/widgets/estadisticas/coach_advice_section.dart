import 'package:flutter/material.dart';

import '../../models/coach_models.dart';

class CoachAdviceSection extends StatelessWidget {
  const CoachAdviceSection({
    super.key,
    required this.advice,
    required this.onPrimaryTipTap,
    required this.onQuickFocusTap,
    required this.onQuickExplainTap,
    required this.onQuickWeeklyGoalTap,
    required this.onQuickProgressTap,
    required this.onWeeklyGoalCompletedTap,
  });

  final CoachSessionAdvice advice;
  final VoidCallback onPrimaryTipTap;
  final VoidCallback onQuickFocusTap;
  final VoidCallback onQuickExplainTap;
  final VoidCallback onQuickWeeklyGoalTap;
  final VoidCallback onQuickProgressTap;
  final VoidCallback onWeeklyGoalCompletedTap;

  @override
  Widget build(BuildContext context) {
    final primary = advice.primaryTip;
    final secondary = advice.tips.length > 1
        ? advice.tips.sublist(1, advice.tips.length > 3 ? 3 : advice.tips.length)
        : <CoachTip>[];
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sports_rounded, color: Colors.indigo[400]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Bolo Entrenador',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Tips accionables para esta sesión',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 10),
        if (primary == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                advice.fallbackMessage ??
                    'Registra más partidas para recibir recomendaciones personalizadas.',
              ),
            ),
          )
        else ...[
          InkWell(
            onTap: onPrimaryTipTap,
            borderRadius: BorderRadius.circular(14),
            child: Card(
              elevation: 1.5,
              color: colorScheme.primaryContainer.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TIP PRINCIPAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      primary.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(primary.message),
                    if (advice.interactionState.showTipExplanation) ...[
                      const SizedBox(height: 8),
                      Text(
                        primary.detail,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...secondary.map(
            (tip) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                dense: true,
                leading: Icon(Icons.check_circle_outline, color: Colors.indigo[300]),
                title: Text(tip.title),
                subtitle: Text(tip.message),
              ),
            ),
          ),
          if (advice.interactionState.weeklyGoal != null)
            Card(
              margin: const EdgeInsets.only(top: 4),
              color: Colors.teal.withOpacity(0.08),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reto semanal activo',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(advice.interactionState.weeklyGoal!),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onWeeklyGoalCompletedTap,
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Marcar completado'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: onQuickFocusTap,
              child: const Text('¿En qué me enfoco hoy?'),
            ),
            OutlinedButton(
              onPressed: onQuickExplainTap,
              child: const Text('Explícame este tip'),
            ),
            OutlinedButton(
              onPressed: onQuickWeeklyGoalTap,
              child: const Text('Dame un reto semanal'),
            ),
            OutlinedButton(
              onPressed: onQuickProgressTap,
              child: const Text('¿Voy mejorando?'),
            ),
          ],
        ),
      ],
    );
  }
}
