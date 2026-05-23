import 'package:bolometro/l10n/app_localizations.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/utils/app_constants.dart';
import 'package:bolometro/utils/compartir_sesion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppLocalizations> loadL10n(
  WidgetTester tester, {
  Locale locale = const Locale('es'),
}) async {
  late AppLocalizations l10n;

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('es')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context)!;
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  await tester.pump();
  return l10n;
}

void main() {
  group('compartir_sesion helpers', () {
    test('buildSessionShareSummary calculates average best and worst', () {
      final sesion = Sesion(
        fecha: DateTime(2026, 5, 23),
        lugar: 'Bowling Center',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [
          Partida(total: 156, frames: List.generate(AppConstants.totalFrames, (_) => ['7', '2'])),
          Partida(total: 172, frames: List.generate(AppConstants.totalFrames, (_) => ['8', '1'])),
          Partida(total: 180, frames: List.generate(AppConstants.totalFrames, (_) => ['9', AppConstants.simboloSpare])),
        ],
      );

      final summary = buildSessionShareSummary(sesion);

      expect(summary.scores, [156, 172, 180]);
      expect(summary.gamesCount, 3);
      expect(summary.average, closeTo(169.333, 0.001));
      expect(summary.best, 180);
      expect(summary.worst, 156);
    });

    test('buildGameShareSummary counts strikes spares and misses per frame', () {
      final partida = Partida(
        total: 178,
        frames: [
          ['X'],
          ['9', AppConstants.simboloSpare],
          ['8', '1'],
          ['X'],
          ['7', '2'],
          ['8', AppConstants.simboloSpare],
          ['X'],
          ['9', '0'],
          ['6', '2'],
          ['X', '9', AppConstants.simboloSpare],
        ],
      );

      final summary = buildGameShareSummary(partida);

      expect(summary.strikes, 4);
      expect(summary.spares, 3);
      expect(summary.misses, 3);
    });

    testWidgets('buildSessionShareText creates a readable localized summary', (
      WidgetTester tester,
    ) async {
      final l10n = await loadL10n(tester);
      final sesion = Sesion(
        fecha: DateTime(2026, 5, 23),
        lugar: 'Bowling Chamartín',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [
          Partida(total: 156, frames: List.generate(AppConstants.totalFrames, (_) => ['7', '2'])),
          Partida(total: 172, frames: List.generate(AppConstants.totalFrames, (_) => ['8', '1'])),
        ],
        notas: 'Muy buenas sensaciones hoy.',
      );

      final text = buildSessionShareText(
        l10n: l10n,
        sesion: sesion,
        localeName: 'es',
      );

      expect(text, contains('🎳 Sesión de bolos'));
      expect(text, contains('Ubicación: Bowling Chamartín'));
      expect(text, contains('Promedio: 164,0'));
      expect(text, contains('- Partida 1: 156'));
      expect(text, contains('Generado con Bolómetro'));
    });

    testWidgets('buildGameShareText falls back to session context when needed', (
      WidgetTester tester,
    ) async {
      final l10n = await loadL10n(tester, locale: const Locale('en'));
      final sesion = Sesion(
        fecha: DateTime(2026, 5, 23),
        lugar: 'Downtown Bowling',
        tipo: AppConstants.tipoCompeticion,
        partidas: const [],
      );
      final partida = Partida(
        total: 178,
        frames: [
          ['X'],
          ['9', AppConstants.simboloSpare],
          ['8', '1'],
          ['X'],
          ['7', '2'],
          ['8', AppConstants.simboloSpare],
          ['X'],
          ['9', '0'],
          ['6', '2'],
          ['X', '9', AppConstants.simboloSpare],
        ],
      );

      final text = buildGameShareText(
        l10n: l10n,
        sesion: sesion,
        partida: partida,
        gameNumber: 2,
        localeName: 'en',
      );

      expect(text, contains('🎳 Bowling game'));
      expect(text, contains('🎳 Game 2'));
      expect(text, contains('Location: Downtown Bowling'));
      expect(text, contains('Session type: Competition'));
      expect(text, contains('Strikes: 4'));
      expect(text, contains('Misses: 3'));
    });
  });
}
