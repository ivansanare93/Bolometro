import 'package:bolometro/models/bowling_ball.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:bolometro/l10n/app_localizations.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'package:bolometro/screens/estadisticas.dart';
import 'package:bolometro/services/analytics_service.dart';
import 'package:bolometro/utils/estadisticas_cache.dart';
import 'package:bolometro/utils/estadisticas_utils.dart';
import 'package:bolometro/utils/statistics_samples.dart';
import 'package:bolometro/utils/stats_selection.dart';
import 'package:bolometro/widgets/estadisticas/statistics_score_chart.dart';
import 'package:bolometro/widgets/estadisticas/histograma_puntuaciones.dart';
import 'package:bolometro/widgets/estadisticas/kpi_card_dinamico.dart';
import 'support/memory_arsenal_store.dart';
import 'support/test_firestore_service.dart';

Partida game(int n) =>
    Partida(total: n, frames: List.generate(10, (_) => ['9', '/']));
Sesion session(int day, Partida p, {String type = 'Entrenamiento'}) => Sesion(
  fecha: DateTime(2026, 11, day),
  lugar: 'Test lanes',
  tipo: type,
  partidas: [p],
);

class Repository extends DataRepository {
  Repository()
    : super(
        firestoreService: TestFirestoreService(),
        arsenalRemote: MemoryArsenalStore(),
        autoSyncArsenal: false,
      );
  @override
  Future<List<BowlingBall>> listarTodasLasBolas() async => [];
  List<Sesion> sessions = [];
  @override
  Future<List<Sesion>> obtenerSesiones() async => sessions;
}

class Analytics implements AnalyticsService {
  @override
  Future<void> logScreenView(String name) async {}
  @override
  Future<void> logStatisticsViewed(String filter) async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget localized(
  Widget child, {
  bool dark = false,
  String language = 'es',
  double scale = 1,
}) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: dark ? ThemeData.dark() : ThemeData.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(body: child),
);

Future<void> reveal(WidgetTester tester, Finder finder) async {
  final scrollable = find
      .descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
  await tester.pumpAndSettle();
}

void main() {
  test(
    'chart aligns averages with window end and omits duplicated legacy point',
    () {
      final sessions = List.generate(5, (i) => session(i + 1, game(100 + i)));
      final entries = StatsSelection.games(sessions);
      final averages = EstadisticasUtils.promedioMovil(
        entries.map((e) => e.$2).toList(),
        5,
      );
      expect(
        averages.length,
        2,
      ); // Preserve the historical calculation contract.
      final chart = StatisticsScoreChart(
        entries: entries,
        averages: averages,
        window: 5,
      );
      expect(chart.scoreSpots.length, 5);
      expect(chart.averageSpots, [const FlSpot(4, 102)]);
      expect(
        StatisticsScoreChart(
          entries: entries.take(4).toList(),
          averages: [],
          window: 5,
        ).averageSpots,
        isEmpty,
      );
    },
  );
  test('sample counts use actual pin records, including a recorded zero', () {
    final p = game(0);
    p.pinesPorTiro[0][0] = [];
    final sample = StatisticsPinSample.fromGames([p, game(150)]);
    expect(sample.gamesWithPins, 1);
    expect(sample.firstThrows, 1);
    expect(StatisticsPinSample.fromGames([game(150)]).gamesWithPins, 0);
  });
  testWidgets('single game remains visible without invented moving data', (
    tester,
  ) async {
    await tester.pumpWidget(
      localized(
        StatisticsScoreChart(
          entries: StatsSelection.games([session(1, game(150))]),
          averages: [],
          window: 5,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('necesita al menos 5'), findsOneWidget);
    final plot = tester.widget<LineChart>(find.byType(LineChart));
    expect(plot.data.lineBarsData.length, 1);
    expect(plot.data.lineBarsData.single.spots.length, 1);
    expect(find.textContaining('Puntos: 150'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('statistics-previous-game')))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'chart navigation and touch show corresponding date score and session',
    (tester) async {
      final entries = StatsSelection.games([
        session(1, game(120)),
        session(8, game(210)),
      ]);
      await tester.pumpWidget(
        localized(
          StatisticsScoreChart(entries: entries, averages: [], window: 5),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('statistics-previous-game')));
      await tester.pump();
      expect(find.textContaining('01/11/2026'), findsOneWidget);
      expect(find.textContaining('Puntos: 120'), findsOneWidget);
      await tester.tap(find.byKey(const Key('statistics-next-game')));
      await tester.pump();
      expect(find.textContaining('Puntos: 210'), findsOneWidget);
      final data = tester.widget<LineChart>(find.byType(LineChart)).data;
      final spot = TouchLineBarSpot(
        data.lineBarsData.first,
        0,
        const FlSpot(0, 120),
        0,
      );
      data.lineTouchData.touchCallback!(
        FlTapUpEvent(TapUpDetails(kind: PointerDeviceKind.touch)),
        LineTouchResponse([spot]),
      );
      await tester.pump();
      expect(find.textContaining('Puntos: 120'), findsOneWidget);
      expect(
        data.lineTouchData.touchTooltipData
            .getTooltipItems([spot])
            .single!
            .text,
        contains('01/11/2026'),
      );
      expect(find.textContaining('Test lanes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'histogram shows ranges numerically and scrolls without overlapping labels',
    (tester) async {
      await tester.pumpWidget(
        localized(
          Center(
            child: SizedBox(
              width: 260,
              child: HistogramaPuntuaciones(
                histograma: {
                  '100-119': 2,
                  '80-99': 1,
                  '0-19': 3,
                  '300-319': 1,
                  '200-219': 2,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final data = tester.widget<BarChart>(find.byType(BarChart)).data;
      expect(data.barGroups.map((g) => g.barRods.single.toY), [3, 1, 2, 2, 1]);
      expect(
        tester
            .widget<SizedBox>(
              find
                  .ancestor(
                    of: find.byType(BarChart),
                    matching: find.byType(SizedBox),
                  )
                  .first,
            )
            .width,
        320,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('chart selection resets on a filtered dataset update', (
    tester,
  ) async {
    await tester.pumpWidget(
      localized(
        StatisticsScoreChart(
          entries: StatsSelection.games([
            session(1, game(120)),
            session(2, game(130)),
          ]),
          averages: [],
          window: 5,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('statistics-previous-game')));
    await tester.pump();
    expect(find.textContaining('Puntos: 120'), findsOneWidget);
    await tester.pumpWidget(
      localized(
        StatisticsScoreChart(
          entries: StatsSelection.games([session(4, game(240))]),
          averages: [],
          window: 5,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Puntos: 240'), findsOneWidget);
    expect(find.textContaining('Puntos: 120'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('normal statistics screen', () {
    late Repository repo;
    late EstadisticasCache cache;
    setUp(() {
      repo = Repository();
      cache = EstadisticasCache();
    });
    tearDown(() {
      repo.dispose();
      cache.dispose();
    });
    Widget app({bool dark = false, String language = 'es', double scale = 1}) =>
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DataRepository>.value(value: repo),
            ChangeNotifierProvider<EstadisticasCache>.value(value: cache),
            Provider<AnalyticsService>.value(value: Analytics()),
          ],
          child: localized(
            const EstadisticasPantallaCompleta(),
            dark: dark,
            language: language,
            scale: scale,
          ),
        );

    testWidgets(
      'compact filters and summary open first, reset clears hidden constraints',
      (tester) async {
        repo.sessions = [
          session(1, game(100)),
          session(2, game(200), type: 'Competici\u00f3n'),
        ];
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        expect(find.byType(DropdownButton<String>), findsNothing);
        expect(
          tester
              .widget<KpiCardDinamico>(
                find.byKey(const Key('statistics-average')),
              )
              .value,
          '150.0',
        );
        expect(find.text('2 partidas \u00b7 2 sesiones'), findsOneWidget);
        await tester.tap(find.byKey(const Key('statistics-filter-toggle')));
        await tester.pumpAndSettle();
        final type = tester
            .widgetList<DropdownButton<String>>(
              find.byType(DropdownButton<String>),
            )
            .first;
        type.onChanged!('Entrenamiento');
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const Key('statistics-filter-toggle')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('statistics-filter-toggle')));
        await tester.pumpAndSettle();
        expect(find.byType(DropdownButton<String>), findsNothing);
        expect(
          tester
              .widget<Text>(find.byKey(const Key('statistics-filter-summary')))
              .data,
          contains('Entrenamiento'),
        );
        await tester.tap(find.byKey(const Key('statistics-reset-filters')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<KpiCardDinamico>(
                find.byKey(const Key('statistics-average')),
              )
              .value,
          '150.0',
        );
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('empty filtered result provides a working reset', (
      tester,
    ) async {
      repo.sessions = [session(1, game(150))];
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('statistics-filter-toggle')));
      await tester.pumpAndSettle();
      tester
          .widgetList<DropdownButton<String>>(
            find.byType(DropdownButton<String>),
          )
          .first
          .onChanged!('Competici\u00f3n');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No hay partidas con estos filtros'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('statistics-empty-reset')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('statistics-summary')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'missing pin data stays unknown instead of becoming zero percent',
      (tester) async {
        repo.sessions = [session(1, game(150))];
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('statistics-toggle-pins')));
        await tester.tap(find.byKey(const Key('statistics-toggle-pins')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Sin datos de pines.'), findsOneWidget);
        expect(find.text('0.0%'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'partial pin data shows exact sample sizes and converted opportunities',
      (tester) async {
        final p = game(150);
        p.pinesPorTiro[0][0] = List.generate(9, (i) => i + 1);
        p.pinesPorTiro[0][1] = [10];
        p.pinesPorTiro[1][0] = List.generate(8, (i) => i + 1);
        p.pinesPorTiro[1][1] = [];
        repo.sessions = [session(1, p), session(2, game(120))];
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('statistics-toggle-pins')));
        await tester.tap(find.byKey(const Key('statistics-toggle-pins')));
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('statistics-spare-sample')));
        expect(
          find.text('2 primeros tiros con pines registrados.'),
          findsOneWidget,
        );
        expect(
          find.text('1 convertido de 2 oportunidades registradas.'),
          findsOneWidget,
        );
        expect(find.text('50.0%'), findsWidgets);
        expect(find.textContaining('1 de 2 partidas'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'recorded missed spare is a real zero while strike-only is unknown',
      (tester) async {
        final p = game(100);
        p.pinesPorTiro[0][0] = [1, 2, 3];
        p.pinesPorTiro[0][1] = [];
        repo.sessions = [session(1, p)];
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('statistics-toggle-pins')));
        await tester.tap(find.byKey(const Key('statistics-toggle-pins')));
        await tester.pumpAndSettle();
        expect(find.text('0.0%'), findsWidgets);
        expect(
          find.text('0 convertidos de 1 oportunidad registrada.'),
          findsOneWidget,
        );
        final strike = game(300);
        strike.pinesPorTiro[0][0] = List.generate(10, (i) => i + 1);
        repo.sessions = [session(1, strike)];
        await tester.tap(find.byKey(const Key('statistics-refresh')));
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('statistics-toggle-pins')));
        await tester.tap(find.byKey(const Key('statistics-toggle-pins')));
        await tester.pumpAndSettle();
        expect(find.text('Sin datos suficientes'), findsOneWidget);
        expect(find.text('0.0%'), findsNothing);
      },
    );
    for (final dark in [false, true]) {
      testWidgets(
        'phone layout supports expanded details and large text, dark=$dark',
        (tester) async {
          tester.view.physicalSize = const Size(360, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final p = game(150);
          p.pinesPorTiro[0][0] = [1, 2, 3];
          p.pinesPorTiro[0][1] = [];
          repo.sessions = [session(1, p), session(2, game(170))];
          await tester.pumpWidget(app(dark: dark, scale: 1.5));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await reveal(tester, find.byKey(const Key('statistics-toggle-pins')));
          await tester.tap(find.byKey(const Key('statistics-toggle-pins')));
          await tester.pumpAndSettle();
          await reveal(
            tester,
            find.byKey(const Key('statistics-spare-sample')),
          );
          expect(tester.takeException(), isNull);
          // Also cover the old content inside its new collapsible sections.
          for (final id in ['outcomes', 'distribution', 'records']) {
            final toggle = find.byKey(Key('statistics-toggle-$id'));
            // Earlier sections are above the expanded pins: scroll back first.
            final scroll = tester.state<ScrollableState>(
              find
                  .descendant(
                    of: find.byType(CustomScrollView),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            scroll.position.jumpTo(0);
            await tester.pumpAndSettle();
            await reveal(tester, toggle);
            await tester.tap(toggle);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
    testWidgets('English screen uses translated presentation messages', (
      tester,
    ) async {
      repo.sessions = [session(1, game(150))];
      await tester.pumpWidget(app(language: 'en'));
      await tester.pumpAndSettle();
      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Filtered results summary'), findsOneWidget);
      await reveal(tester, find.byType(StatisticsScoreChart));
      expect(find.text('Game progress'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
