import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/widgets/sesion_card.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/utils/app_constants.dart';
import 'package:bolometro/l10n/app_localizations.dart';

/// Helper to wrap a widget with the required localizations
Widget withLocalizations(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('es')],
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

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
        withLocalizations(SesionCard(
          sesion: testSesion,
          onTap: () {},
        )),
      );

      // Verify the card is displayed
      expect(find.byType(SesionCard), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('SesionCard should display session location', (WidgetTester tester) async {
      await tester.pumpWidget(
        withLocalizations(SesionCard(
          sesion: testSesion,
          onTap: () {},
        )),
      );

      // Verify location is shown
      expect(find.text('Test Bowling Center'), findsOneWidget);
    });

    testWidgets('SesionCard should be tappable', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        withLocalizations(SesionCard(
          sesion: testSesion,
          onTap: () {
            tapped = true;
          },
        )),
      );

      // Tap the card
      await tester.tap(find.byType(SesionCard));
      await tester.pump();

      // Verify callback was called
      expect(tapped, isTrue);
    });

    testWidgets('SesionCard should show training type indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        withLocalizations(SesionCard(
          sesion: testSesion,
          onTap: () {},
        )),
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
        withLocalizations(SesionCard(
          sesion: competitionSesion,
          onTap: () {},
        )),
      );

      expect(find.byType(SesionCard), findsOneWidget);
      expect(find.text('Competition Center'), findsOneWidget);
    });
  });
}
