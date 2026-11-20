import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bolometro/l10n/app_localizations.dart';
import 'package:bolometro/models/bowling_ball.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'package:bolometro/screens/estadisticas.dart';
import 'package:bolometro/services/analytics_service.dart';
import 'package:bolometro/utils/estadisticas_cache.dart';
import 'package:bolometro/widgets/estadisticas/kpi_card_dinamico.dart';
import 'support/memory_arsenal_store.dart';
import 'support/test_firestore_service.dart';

Partida game(int total, {String? ball}) => Partida(
  total: total,
  ballId: ball,
  frames: List.generate(10, (_) => ['9', '/']),
);
Sesion session(int day, List<Partida> games, {String venue = 'North'}) =>
    Sesion(
      fecha: DateTime(2026, 11, day),
      lugar: venue,
      tipo: 'Entrenamiento',
      partidas: games,
    );

class Repository extends DataRepository {
  Repository()
    : super(
        firestoreService: TestFirestoreService(),
        arsenalRemote: MemoryArsenalStore(),
        autoSyncArsenal: false,
      );
  String? owner = 'a';
  int generation = 0;
  List<Sesion> sessions = [];
  Future<List<BowlingBall>> Function() metadata = () async => [];
  @override
  String? get arsenalUserId => owner;
  @override
  int get seasonAccountToken => generation;
  @override
  Future<List<Sesion>> obtenerSesiones() async => sessions;
  @override
  Future<List<BowlingBall>> listarTodasLasBolas() => metadata();
  void change(String? uid, List<Sesion> data) {
    owner = uid;
    generation++;
    sessions = data;
    notifyListeners();
  }
}

class Analytics implements AnalyticsService {
  final logs = <String>[];
  @override
  Future<void> logScreenView(String name) async {}
  @override
  Future<void> logStatisticsViewed(String filter) async {
    logs.add(filter);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Future<void> reveal(WidgetTester tester, Finder target) async {
  final scrollable = find
      .descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(target, 200, scrollable: scrollable);
  await tester.pumpAndSettle();
}

Future<void> top(WidgetTester tester) async {
  tester
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position
      .jumpTo(0);
  await tester.pumpAndSettle();
}

Future<void> open(WidgetTester tester, String id) async {
  final target = find.byKey(Key('statistics-toggle-$id'));
  await reveal(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

List<String> ballLabels(WidgetTester tester) => tester
    .widget<DropdownButton<String>>(
      find.descendant(
        of: find.byKey(const Key('statistics-ball-filter')),
        matching: find.byType(DropdownButton<String>),
      ),
    )
    .items!
    .map((i) => (i.child as Tooltip).message!)
    .toList();
Future<String> average(WidgetTester tester) async {
  await reveal(tester, find.byKey(const Key('statistics-average')));
  return tester
      .widget<KpiCardDinamico>(find.byKey(const Key('statistics-average')))
      .value;
}

void main() {
  late Repository repo;
  late EstadisticasCache cache;
  late Analytics analytics;
  setUp(() {
    repo = Repository();
    cache = EstadisticasCache();
    analytics = Analytics();
  });
  tearDown(() {
    repo.dispose();
    cache.dispose();
  });
  Widget app({bool dark = false, double scale = 1, String language = 'es'}) =>
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DataRepository>.value(value: repo),
          ChangeNotifierProvider<EstadisticasCache>.value(value: cache),
          Provider<AnalyticsService>.value(value: analytics),
        ],
        child: MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: dark ? ThemeData.dark() : ThemeData.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const EstadisticasPantallaCompleta(),
        ),
      );

  testWidgets(
    'ten games require two full blocks; choosing five produces the exact difference',
    (tester) async {
      repo.sessions = List.generate(
        10,
        (i) => session(i + 1, [game(i < 5 ? 100 : 200)]),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await open(tester, 'progress');
      expect(find.byKey(const Key('statistics-mean-change')), findsNothing);
      expect(
        find.textContaining('Se necesitan 20 partidas filtradas; hay 10.'),
        findsOneWidget,
      );
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byKey(const Key('statistics-comparison-window')),
          )
          .onChanged!(5);
      await tester.pumpAndSettle();
      expect(
        find.text('Variaci\u00f3n del promedio: +100.0 puntos'),
        findsOneWidget,
      );
      expect(find.text('\u00daltimas 5 partidas'), findsOneWidget);
      expect(find.text('Las 5 partidas anteriores'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'one game has unknown deviation; two identical games have a real zero',
    (tester) async {
      repo.sessions = [
        session(1, [game(150)]),
      ];
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await open(tester, 'progress');
      expect(
        tester.widget<Text>(find.byKey(const Key('statistics-deviation'))).data,
        'Sin datos suficientes',
      );
      repo.change('a', [
        session(1, [game(150), game(150)]),
      ]);
      await tester.pumpAndSettle();
      await top(tester);
      await open(tester, 'progress');
      expect(
        tester.widget<Text>(find.byKey(const Key('statistics-deviation'))).data,
        '0.0 puntos',
      );
      expect(find.byKey(const Key('statistics-mean-change')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'ball and venue filters combine per game and reset leaves the arsenal untouched',
    (tester) async {
      final a = BowlingBall(
        id: 'unit-a',
        name: 'Same model',
        weightLbs: 14,
        isActive: false,
      );
      final b = BowlingBall(id: 'unit-b', name: 'Same model', weightLbs: 14);
      repo.metadata = () async => [a, b];
      repo.sessions = [
        session(1, [game(100, ball: a.id), game(200, ball: b.id)]),
        session(2, [game(180, ball: a.id)], venue: 'South'),
      ];
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('statistics-filter-toggle')));
      await tester.pumpAndSettle();
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const Key('statistics-ball-filter')),
      );
      expect(
        tester
            .widget<DropdownButton<String>>(
              find.descendant(
                of: find.byKey(const Key('statistics-ball-filter')),
                matching: find.byType(DropdownButton<String>),
              ),
            )
            .items!
            .map((i) => i.value),
        containsAll(['ball:unit-a', 'ball:unit-b']),
      );
      expect(
        ballLabels(tester).where((s) => s.contains('Same model')).length,
        2,
      );
      dropdown.onChanged!('ball:unit-a');
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const Key('statistics-venue-filter')),
          )
          .onChanged!('venue:north');
      await tester.pumpAndSettle();
      expect(await average(tester), '100.0');
      await top(tester);
      await tester.ensureVisible(
        find.byKey(const Key('statistics-reset-filters')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('statistics-reset-filters')));
      await tester.pumpAndSettle();
      expect(await average(tester), '160.0');
      expect(repo.sessions.first.partidas.length, 2);
      expect(a.id, 'unit-a');
      expect(a.isActive, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'unknown ball and venue remain distinct from all; empty result can be reset',
    (tester) async {
      repo.sessions = [
        session(1, [game(100, ball: 'known'), game(180)]),
        session(2, [game(50)], venue: ''),
      ];
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('statistics-filter-toggle')));
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const Key('statistics-ball-filter')),
          )
          .onChanged!('none');
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const Key('statistics-venue-filter')),
          )
          .onChanged!('none');
      await tester.pumpAndSettle();
      expect(await average(tester), '50.0');
      await top(tester);
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const Key('statistics-ball-filter')),
          )
          .onChanged!('ball:known');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('statistics-empty-reset')), findsOneWidget);
      await tester.tap(find.byKey(const Key('statistics-empty-reset')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('statistics-summary')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('metadata failure leaves IDs selectable and analysis available', (
    tester,
  ) async {
    repo.metadata = () async => throw StateError('metadata unavailable');
    repo.sessions = [
      session(1, [game(150, ball: 'orphan-id')]),
    ];
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('statistics-filter-toggle')));
    await tester.pumpAndSettle();
    expect(ballLabels(tester), contains('Bola con ID orphan-id'));
    tester
        .widget<DropdownButtonFormField<String>>(
          find.byKey(const Key('statistics-ball-filter')),
        )
        .onChanged!('ball:orphan-id');
    await tester.pumpAndSettle();
    expect(await average(tester), '150.0');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'late old-account metadata cannot replace names after switching accounts',
    (tester) async {
      final pending = Completer<List<BowlingBall>>();
      repo.sessions = [
        session(1, [game(100, ball: 'same-id')]),
      ];
      repo.metadata = () => pending.future;
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('statistics-filter-toggle')));
      await tester.pumpAndSettle();
      repo.metadata = () async => [
        BowlingBall(id: 'same-id', name: 'Account B ball', weightLbs: 14),
      ];
      repo.change('b', [
        session(1, [game(200, ball: 'same-id')]),
      ]);
      await tester.pumpAndSettle();
      await top(tester);
      await tester.tap(find.byKey(const Key('statistics-filter-toggle')));
      await tester.pumpAndSettle();
      pending.complete([
        BowlingBall(
          id: 'same-id',
          name: 'Private account A ball',
          weightLbs: 15,
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.textContaining('Private account A ball'), findsNothing);
      expect(
        ballLabels(tester).any((s) => s.contains('Account B ball')),
        isTrue,
      );
      expect(
        ballLabels(tester).any((s) => s.contains('Private account A ball')),
        isFalse,
      );
      expect(await average(tester), '200.0');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'account change resets personal ball and venue filters even with shared IDs',
    (tester) async {
      repo.sessions = [
        session(1, [game(100, ball: 'same-id'), game(200)], venue: 'North'),
      ];
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('statistics-filter-toggle')));
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const Key('statistics-ball-filter')),
          )
          .onChanged!('ball:same-id');
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const Key('statistics-venue-filter')),
          )
          .onChanged!('venue:north');
      await tester.pumpAndSettle();
      expect(await average(tester), '100.0');
      repo.change('b', [
        session(1, [game(200, ball: 'same-id')], venue: 'North'),
        session(2, [game(100)], venue: 'South'),
      ]);
      await tester.pumpAndSettle();
      await top(tester);
      expect(await average(tester), '150.0');
      expect(find.byKey(const Key('statistics-reset-filters')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shared-game filter retains game context but does not attribute total score to spare ball',
    (tester) async {
      final mixed = game(200, ball: 'a').copyWith(ballIdsByThrow: {'0:1': 'b'});
      repo.sessions = [
        session(1, [mixed]),
      ];
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('statistics-filter-toggle')));
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const Key('statistics-ball-filter')),
          )
          .onChanged!('ball:b');
      await tester.pumpAndSettle();
      await top(tester);
      await tester.tap(find.byKey(const Key('statistics-filter-toggle')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('ball-score-filter-scope')));
      expect(
        find.textContaining(
          'Las puntuaciones corresponden a partidas completas',
        ),
        findsOneWidget,
      );
      await open(tester, 'balls');
      expect(
        find.text(
          'Sin partidas exclusivas para calcular puntuaciones por bola.',
        ),
        findsOneWidget,
      );
      expect(find.text('Promedio: 200.0 \u00b7 Mejor: 200'), findsNothing);
      final labels = tester
          .widgetList<SelectableText>(find.byType(SelectableText))
          .map((w) => w.data);
      expect(labels, contains('Bola con ID b'));
      expect(labels, isNot(contains('Bola con ID a')));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'grouped views show samples and warnings without ranking a winner',
    (tester) async {
      repo.sessions = [
        session(1, [
          game(100, ball: 'a'),
          game(200, ball: 'b'),
          game(120, ball: 'a'),
          game(50),
        ]),
      ];
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await open(tester, 'balls');
      expect(find.text('2 partidas con uso; 2 exclusivas'), findsOneWidget);
      expect(
        find.textContaining('no es una clasificaci\u00f3n'),
        findsOneWidget,
      );
      expect(find.textContaining('Promedio: 110.0'), findsOneWidget);
      await open(tester, 'venues');
      expect(find.text('4 partidas analizadas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'new controls and complete comparison fit phone with large text dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        repo.sessions = List.generate(
          20,
          (i) => session(i + 1, [
            game(i < 10 ? 130 : 150, ball: i.isEven ? 'a' : null),
          ], venue: i.isEven ? 'North' : 'South'),
        );
        await tester.pumpWidget(app(dark: dark, scale: 1.5));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('statistics-filter-toggle')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await top(tester);
        await tester.tap(find.byKey(const Key('statistics-filter-toggle')));
        await tester.pumpAndSettle();
        await open(tester, 'progress');
        await reveal(tester, find.byKey(const Key('statistics-mean-change')));
        expect(
          find.text('Variaci\u00f3n del promedio: +20.0 puntos'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'English messages and existing analytics avoid personal filter values',
    (tester) async {
      repo.sessions = [
        session(1, [game(150, ball: 'secret-id')], venue: 'Private Venue'),
      ];
      await tester.pumpWidget(app(language: 'en'));
      await tester.pumpAndSettle();
      await open(tester, 'progress');
      expect(find.text('Consistency and recent comparison'), findsOneWidget);
      expect(find.textContaining('filtered games are needed'), findsOneWidget);
      expect(analytics.logs, isNotEmpty);
      expect(analytics.logs.join(), isNot(contains('Private Venue')));
      expect(analytics.logs.join(), isNot(contains('secret-id')));
      expect(tester.takeException(), isNull);
    },
  );
}
