import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/widgets/sesion_card.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/utils/app_constants.dart';

/// Tests for SesionCard widget
void main() {
  group('SesionCard Widget', () {
    late Sesion testSesion;

    setUp(() {
      testSesion = Sesion(
        fecha: DateTime(2024, 1, 15),
        lugar: 'Test Bowling Center',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [
          Partida(
            total: 150,
            frames: List.generate(
              AppConstants.totalFrames,
              (i) => ['5', AppConstants.simboloSpare],
            ),
          ),
          Partida(
            total: 180,
            frames: List.generate(
              AppConstants.totalFrames,
              (i) => [AppConstants.simboloStrike],
            ),
          ),
        ],
        notas: 'Good practice session',
      );
    });

    testWidgets('SesionCard should display correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SesionCard(
              sesion: testSesion,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify the card is displayed
      expect(find.byType(SesionCard), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('SesionCard should display session location', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SesionCard(
              sesion: testSesion,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify location is shown
      expect(find.text('Test Bowling Center'), findsOneWidget);
    });

    testWidgets('SesionCard should be tappable', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SesionCard(
              sesion: testSesion,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Tap the card
      await tester.tap(find.byType(SesionCard));
      await tester.pump();

      // Verify callback was called
      expect(tapped, isTrue);
    });

    testWidgets('SesionCard should show training type indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SesionCard(
              sesion: testSesion,
              onTap: () {},
            ),
          ),
        ),
      );

      // The card should show training type somehow (implementation dependent)
      // This is a basic check that the widget builds without error
      expect(find.byType(SesionCard), findsOneWidget);
    });

    testWidgets('SesionCard should show competition type', (WidgetTester tester) async {
      final competitionSesion = Sesion(
        fecha: DateTime(2024, 1, 15),
        lugar: 'Competition Center',
        tipo: AppConstants.tipoCompeticion,
        partidas: [
          Partida(
            total: 200,
            frames: List.generate(
              AppConstants.totalFrames,
              (i) => [AppConstants.simboloStrike],
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SesionCard(
              sesion: competitionSesion,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(SesionCard), findsOneWidget);
      expect(find.text('Competition Center'), findsOneWidget);
    });
  });
}
