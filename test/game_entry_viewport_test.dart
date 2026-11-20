import 'package:bolometro/l10n/app_localizations.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/providers/keyboard_provider.dart';
import 'package:bolometro/screens/editar_partida.dart';
import 'package:bolometro/screens/registro_sesion.dart';
import 'package:bolometro/services/analytics_service.dart';
import 'package:bolometro/widgets/game_entry_viewport.dart';
import 'package:bolometro/widgets/marcador_bolos.dart';
import 'package:bolometro/widgets/teclado_selector_pins.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Analytics implements AnalyticsService {
  @override
  Future<void> logScreenView(String name) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> mount(
  WidgetTester tester, {
  required bool editing,
  required Size size,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetPadding);
  SharedPreferences.setMockInitialValues({'keyboard_modo_visual': true});
  final keyboard = KeyboardProvider();
  await keyboard.initializationFuture;
  addTearDown(keyboard.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<KeyboardProvider>.value(
      value: keyboard,
      child: Provider<AnalyticsService>.value(
        value: _Analytics(),
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: editing
              ? EditarPartidaScreen(
                  partida: Partida(
                    frames: List.generate(10, (_) => ['', '', '']),
                    total: 0,
                  ),
                  onGuardar: (_) {},
                )
              : RegistroSesionScreen(onGuardar: (_) {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void expectScoreVisible(WidgetTester tester) {
  final viewport = tester.getRect(find.byType(GameEntryViewport));
  final score = tester.getRect(find.byType(MarcadorBolos));
  expect(score.top, greaterThanOrEqualTo(viewport.top));
  expect(score.bottom, lessThanOrEqualTo(viewport.bottom));
}

void expectPanelStartsBelowScore(WidgetTester tester) {
  expectScoreVisible(tester);
  final score = tester.getRect(find.byType(MarcadorBolos));
  final panel = tester.getRect(find.byType(SelectorpinesWidget));
  expect(panel.top, greaterThanOrEqualTo(score.bottom));
  expect(panel.top - score.bottom, lessThan(16));
}

void main() {
  for (final editing in [false, true]) {
    final screen = editing ? 'editing' : 'registration';
    testWidgets('$screen keeps score and entire pin keyboard visible on phone', (
      tester,
    ) async {
      await mount(tester, editing: editing, size: const Size(393, 873));
      final fields = find.descendant(
        of: find.byType(MarcadorBolos),
        matching: find.byType(TextField),
      );
      await tester.tap(fields.first);
      await tester.pumpAndSettle();
      expectPanelStartsBelowScore(tester);
      final viewport = tester.getRect(find.byType(GameEntryViewport));
      expect(
        tester.getRect(find.byType(SelectorpinesWidget)).bottom,
        lessThanOrEqualTo(viewport.bottom + 1),
      );
      final top = tester.getTopLeft(find.byType(MarcadorBolos)).dy;
      final pinOne = find.descendant(
        of: find.byType(SelectorpinesWidget),
        matching: find.text('1'),
      );
      await tester.tap(pinOne);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();
      expectPanelStartsBelowScore(tester);
      expect(
        tester.getTopLeft(find.byType(MarcadorBolos)).dy,
        closeTo(top, 0.5),
      );
      final board = tester.state<MarcadorBolosState>(
        find.byType(MarcadorBolos),
      );
      expect(board.tiroActivoGetter, 1);
      expect(
        tester
            .widget<SelectorpinesWidget>(find.byType(SelectorpinesWidget))
            .pinesDeshabilitados,
        [1],
      );
      // Finish a frame; automatic advance should keep the same useful view.
      await tester.tap(
        find.descendant(
          of: find.byType(SelectorpinesWidget),
          matching: find.text('2'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();
      expect(board.frameActivoGetter, 1);
      expect(board.tiroActivoGetter, 0);
      expectPanelStartsBelowScore(tester);
      expect(
        tester.getRect(find.byType(SelectorpinesWidget)).bottom,
        lessThanOrEqualTo(viewport.bottom + 1),
      );
      // Reparenting the shared scoresheet on mode changes must preserve state.
      await tester.tap(find.text('Num\u00e9rico'));
      await tester.pumpAndSettle();
      expect(
        tester.state<MarcadorBolosState>(find.byType(MarcadorBolos)),
        same(board),
      );
      expect(
        tester
            .widget<MarcadorBolos>(find.byType(MarcadorBolos))
            .frames[0]
            .take(2),
        ['1', '1'],
      );
      await tester.tap(find.text('Pines'));
      await tester.pumpAndSettle();
      expectPanelStartsBelowScore(tester);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('$screen preserves score while short-screen keyboard scrolls', (
      tester,
    ) async {
      await mount(
        tester,
        editing: editing,
        size: const Size(360, 640),
        textScale: 1.15,
      );
      final board = tester.state<MarcadorBolosState>(
        find.byType(MarcadorBolos),
      );
      board.setTiroActivo(7, 0);
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(MarcadorBolos),
        matching: find.byType(TextField),
      );
      // Tap an actual cell in a horizontally scrolled distant frame.
      await tester.tap(fields.at(14));
      await tester.pumpAndSettle();
      expectPanelStartsBelowScore(tester);
      await tester.ensureVisible(find.text('Aceptar'));
      await tester.pumpAndSettle();
      expectScoreVisible(tester);
      final viewport = tester.getRect(find.byType(GameEntryViewport));
      expect(
        tester.getRect(find.text('Aceptar')).bottom,
        lessThanOrEqualTo(viewport.bottom),
      );
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();
      expect(board.frameActivoGetter, 7);
      expect(board.tiroActivoGetter, 1);
      expectPanelStartsBelowScore(tester);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets('$screen can close with a focus request pending', (
      tester,
    ) async {
      await mount(tester, editing: editing, size: const Size(393, 873));
      final fields = find.descendant(
        of: find.byType(MarcadorBolos),
        matching: find.byType(TextField),
      );
      await tester.tap(fields.first);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
