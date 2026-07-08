import 'package:bolometro/models/coach_models.dart';
import 'package:bolometro/widgets/estadisticas/coach_advice_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza card principal y secundarias del entrenador', (
    WidgetTester tester,
  ) async {
    final advice = CoachSessionAdvice(
      tips: const [
        CoachTip(
          id: 'tip_main',
          title: 'Tip principal',
          message: 'Mensaje principal',
          detail: 'Detalle principal',
          actionText: 'Acción principal',
          category: CoachTipCategory.correctivo,
          priority: CoachTipPriority.high,
          impact: 5,
          urgency: 5,
        ),
        CoachTip(
          id: 'tip_secondary_1',
          title: 'Tip secundario 1',
          message: 'Mensaje secundario 1',
          detail: 'Detalle secundario 1',
          actionText: 'Acción secundaria 1',
          category: CoachTipCategory.objetivo,
          priority: CoachTipPriority.medium,
          impact: 3,
          urgency: 3,
        ),
        CoachTip(
          id: 'tip_secondary_2',
          title: 'Tip secundario 2',
          message: 'Mensaje secundario 2',
          detail: 'Detalle secundario 2',
          actionText: 'Acción secundaria 2',
          category: CoachTipCategory.refuerzo,
          priority: CoachTipPriority.low,
          impact: 2,
          urgency: 2,
        ),
      ],
      interactionState: const CoachInteractionState(),
      hasEnoughData: true,
      generatedAt: DateTime(2026, 1, 1),
      focusMessage: 'Foco',
      progressMessage: 'Progreso',
      weeklyGoalSuggestion: 'Reto',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CoachAdviceSection(
            advice: advice,
            onPrimaryTipTap: () {},
            onQuickFocusTap: () {},
            onQuickExplainTap: () {},
            onQuickWeeklyGoalTap: () {},
            onQuickProgressTap: () {},
            onWeeklyGoalCompletedTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Bolo Entrenador'), findsOneWidget);
    expect(find.text('TIP PRINCIPAL'), findsOneWidget);
    expect(find.text('Tip principal'), findsOneWidget);
    expect(find.text('Tip secundario 1'), findsOneWidget);
    expect(find.text('Tip secundario 2'), findsOneWidget);
    expect(find.text('¿En qué me enfoco hoy?'), findsOneWidget);
    expect(find.text('Explícame este tip'), findsOneWidget);
    expect(find.text('Dame un reto semanal'), findsOneWidget);
    expect(find.text('¿Voy mejorando?'), findsOneWidget);
  });
}
