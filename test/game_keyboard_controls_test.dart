import 'package:bolometro/l10n/app_localizations.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/providers/keyboard_provider.dart';
import 'package:bolometro/screens/editar_partida.dart';
import 'package:bolometro/screens/registro_sesion.dart';
import 'package:bolometro/services/draft_service.dart';
import 'package:bolometro/services/analytics_service.dart';
import 'package:bolometro/widgets/keyboard_mode_selector.dart';
import 'package:bolometro/widgets/marcador_bolos.dart';
import 'package:bolometro/widgets/teclado_selector_pins.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SilentAnalytics implements AnalyticsService {
  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget localized(Widget child, {double scale = 1}) => MaterialApp(
  locale: const Locale('es'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: child,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'keyboard choices have visible labels and work on narrow screens',
    (tester) async {
      bool visual = false;
      await tester.pumpWidget(
        localized(
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 288,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return KeyboardModeSelector(
                      modoVisual: visual,
                      onChanged: (value) => setState(() => visual = value),
                    );
                  },
                ),
              ),
            ),
          ),
          scale: 1.6,
        ),
      );
      expect(find.text('Numérico'), findsOneWidget);
      expect(find.text('Pines'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin_rounded), findsNothing);
      await tester.tap(find.text('Pines'));
      await tester.pumpAndSettle();
      expect(visual, isTrue);
      await tester.tap(find.text('Numérico'));
      await tester.pumpAndSettle();
      expect(visual, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('delete cancels a pending automatic strike acceptance', (
    tester,
  ) async {
    var accepted = 0;
    var deleted = 0;
    await tester.pumpWidget(
      localized(
        Scaffold(
          body: SingleChildScrollView(
            child: SelectorpinesWidget(
              pinesIniciales: const [],
              pinesDeshabilitados: const [],
              onAceptar: (_) => accepted++,
              onBorrar: () => deleted++,
              isFrame10: false,
              tiroActual: 0,
              frames: List.generate(10, (_) => List.filled(3, '')),
              frameActual: 0,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.bolt));
    await tester.tap(find.text('Borrar tirada'));
    await tester.pumpAndSettle();
    expect(deleted, 1);
    expect(accepted, 0);
  });

  for (final editing in [false, true]) {
    testWidgets(
      '${editing ? 'editing' : 'registration'}: clear selection differs '
      'from deleting the selected recorded throw',
      (tester) async {
        final keyboard = KeyboardProvider();
        await keyboard.initializationFuture;
        await keyboard.setModoVisual(true);
        addTearDown(keyboard.dispose);
        final original = Partida(
          frames: List.generate(10, (_) => ['', '', '']),
          total: 0,
        );
        await tester.pumpWidget(
          ChangeNotifierProvider<KeyboardProvider>.value(
            value: keyboard,
            child: Provider<AnalyticsService>.value(
              value: _SilentAnalytics(),
              child: localized(
                editing
                    ? EditarPartidaScreen(partida: original, onGuardar: (_) {})
                    : RegistroSesionScreen(onGuardar: (_) {}),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final board = tester.state<MarcadorBolosState>(
          find.byType(MarcadorBolos),
        );
        board.setTiroActivo(0, 0);
        await tester.pumpAndSettle();
        // Record a combination through the real visual keyboard callback.
        tester
            .widget<SelectorpinesWidget>(find.byType(SelectorpinesWidget))
            .onAceptar([1, 2, 3]);
        await tester.pumpAndSettle();
        board.setTiroActivo(0, 1);
        await tester.pumpAndSettle();
        tester
            .widget<SelectorpinesWidget>(find.byType(SelectorpinesWidget))
            .onAceptar([4]);
        await tester.pumpAndSettle();
        // Select the mistaken throw, rather than deleting the next empty cell.
        board.setTiroActivo(0, 1);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Limpiar selección'));
        await tester.tap(find.text('Limpiar selección'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<MarcadorBolos>(find.byType(MarcadorBolos))
              .frames[0]
              .take(2),
          ['3', '1'],
        );
        await tester.ensureVisible(find.text('Borrar tirada'));
        await tester.tap(find.text('Borrar tirada'));
        await tester.pumpAndSettle();
        expect(board.frameActivoGetter, 0);
        expect(board.tiroActivoGetter, 1);
        expect(
          tester
              .widget<MarcadorBolos>(find.byType(MarcadorBolos))
              .frames[0]
              .take(2),
          ['3', ''],
        );
        final selector = tester.widget<SelectorpinesWidget>(
          find.byType(SelectorpinesWidget),
        );
        expect(selector.pinesIniciales, isEmpty);
        expect(selector.pinesDeshabilitados, [1, 2, 3]);
        if (!editing) {
          final draft = await DraftService.loadPartidaDraft();
          expect((draft!['pinesPorTiro'] as List).first, '1,2,3;null;null');
          expect((draft['framesText'] as List).first, '3,,');
        }
        // A corrected combination can be entered immediately in the same cell.
        selector.onAceptar([4, 5]);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<MarcadorBolos>(find.byType(MarcadorBolos))
              .frames[0]
              .take(2),
          ['3', '2'],
        );
        // Editing remains an unsaved form; it must not mutate the input game.
        if (editing) {
          expect(original.frames[0], ['', '', '']);
          expect(original.pinesPorTiro[0], [null, null, null]);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}
