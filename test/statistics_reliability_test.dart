import 'package:bolometro/models/bowling_ball.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bolometro/l10n/app_localizations.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'package:bolometro/screens/estadisticas.dart';
import 'package:bolometro/services/analytics_service.dart';
import 'package:bolometro/utils/estadisticas_cache.dart';
import 'package:bolometro/utils/stats_filter.dart';
import 'package:bolometro/utils/stats_selection.dart';
import 'package:bolometro/widgets/estadisticas/kpi_card_dinamico.dart';
import 'support/memory_arsenal_store.dart';
import 'support/test_firestore_service.dart';

Partida game(int score, {DateTime? date}) => Partida(
  total: score,
  fecha: date,
  frames: List.generate(10, (_) => ['9', '/']),
);
Sesion session(int day, List<Partida> games, {String? season}) => Sesion(
  fecha: DateTime(2026, 11, day),
  lugar: 'Test',
  tipo: 'Entrenamiento',
  temporada: season,
  partidas: games,
);

class _Repository extends DataRepository {
  _Repository()
    : super(
        firestoreService: TestFirestoreService(),
        arsenalRemote: MemoryArsenalStore(),
        autoSyncArsenal: false,
      );
  @override
  Future<List<BowlingBall>> listarTodasLasBolas() async => [];
  String? owner = 'account-a';
  int calls = 0;
  Future<List<Sesion>> Function() load = () async => [];
  @override
  String? get arsenalUserId => owner;
  @override
  Future<List<Sesion>> obtenerSesiones() {
    calls++;
    return load();
  }

  void changed({String? uid}) {
    if (uid != null) owner = uid;
    notifyListeners();
  }
}

class _Analytics implements AnalyticsService {
  @override
  Future<void> logScreenView(String name) async {}
  @override
  Future<void> logStatisticsViewed(String filter) async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget app(_Repository repo, EstadisticasCache cache) => MultiProvider(
  providers: [
    ChangeNotifierProvider<DataRepository>.value(value: repo),
    ChangeNotifierProvider<EstadisticasCache>.value(value: cache),
    Provider<AnalyticsService>.value(value: _Analytics()),
  ],
  child: const MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const EstadisticasPantallaCompleta(),
  ),
);

void main() {
  test(
    'same count score edits and nested pin edits invalidate both cache paths',
    () {
      for (final key in ['', 'same-filter']) {
        final cache = EstadisticasCache();
        final s = session(1, [game(100)]);
        final before = cache.getEstadisticas([s], filterKey: key);
        s.partidas[0] = game(200);
        final after = cache.getEstadisticas([s], filterKey: key);
        expect(before['promedioGeneral'], 100);
        expect(after['promedioGeneral'], 200);
        expect(identical(before, after), isFalse);
        s.partidas[0].pinesPorTiro[0][0] = [1, 2, 3];
        expect(
          cache.getEstadisticas([s], filterKey: key)['promedioPrimerTiro'],
          3,
        );
        cache.dispose();
      }
    },
  );
  test(
    'account and guest transitions do not reuse any previous account entry',
    () {
      final cache = EstadisticasCache();
      final a = [
        session(1, [game(100)]),
      ];
      final old = cache.getEstadisticas(a, accountId: 'a', filterKey: 'same');
      expect(
        cache.getEstadisticas(
          [
            session(1, [game(250)]),
          ],
          accountId: 'b',
          filterKey: 'same',
        )['promedioGeneral'],
        250,
      );
      expect(
        identical(
          cache.getEstadisticas(a, accountId: 'a', filterKey: 'same'),
          old,
        ),
        isFalse,
      );
      expect(cache.getEstadisticas([], filterKey: 'same')['totalPartidas'], 0);
      cache.dispose();
    },
  );
  test(
    'canonical chronology produces same recent means and chart from reverse input',
    () {
      final sessions = List.generate(
        12,
        (i) => session(i + 1, [game((i + 1) * 10)]),
      );
      final before = sessions.map((s) => s.fecha).toList();
      final cache = EstadisticasCache();
      final a = cache.getEstadisticas(sessions, filterKey: 'a');
      final b = cache.getEstadisticas(
        sessions.reversed.toList(),
        filterKey: 'b',
      );
      expect(a['promedioUltimas5'], 100);
      expect(a['promedioUltimas10'], 75);
      expect(a['promedioMovil'], b['promedioMovil']);
      expect(a['promedioUltimas5'], b['promedioUltimas5']);
      expect(sessions.map((s) => s.fecha), before);
      final last = StatsSelection.apply(
        sessions.reversed.toList(),
        const StatsFilter(lastN: LastNGames.last10),
      );
      expect(
        StatsSelection.games(last).map((e) => e.$2.total),
        List.generate(10, (i) => (i + 3) * 10),
      );
      expect(sessions.length, 12);
      cache.dispose();
    },
  );
  test(
    'effective game date and stored tie order are shared by last N and metrics',
    () {
      final s = session(1, [
        game(100, date: DateTime(2026, 11, 3)),
        game(200),
        game(150),
      ]);
      expect(StatsSelection.games([s]).map((e) => e.$2.total), [200, 150, 100]);
      expect(s.partidas.map((p) => p.total), [100, 200, 150]);
    },
  );
  test(
    'seven days include today and six previous dates, exclude future and eighth day',
    () {
      final values = [
        session(1, []),
        session(2, []),
        session(8, []),
        session(9, []),
      ];
      expect(
        StatsSelection.apply(
          values,
          const StatsFilter(datePreset: DateRangePreset.last7Days),
          now: DateTime(2026, 11, 8, 20),
        ).map((s) => s.fecha.day),
        [2, 8],
      );
    },
  );
  test(
    'custom dates include entire final day and combine season type and limit',
    () {
      final s = session(4, [game(140)], season: 'Current')
        ..fecha = DateTime(2026, 11, 4, 23, 59);
      final f = StatsFilter(
        temporada: 'Current',
        tipo: 'Entrenamiento',
        datePreset: DateRangePreset.custom,
        customRange: DateTimeRange(
          start: DateTime(2026, 11, 4),
          end: DateTime(2026, 11, 4),
        ),
        lastN: LastNGames.last10,
      );
      expect(
        StatsSelection.apply([
          s,
          session(5, [game(200)], season: 'Current'),
          session(4, [game(100)], season: 'Other'),
        ], f).single.partidas.single.total,
        140,
      );
    },
  );
  test(
    'removed session and season clear real filters instead of displaying all with hidden restriction',
    () {
      final f = StatsSelection.availableFilter(
        [session(1, [])],
        const StatsFilter(
          temporada: 'Removed',
          sessionKey: 'missing',
          lastN: LastNGames.last10,
        ),
      );
      expect(f.temporada, isNull);
      expect(f.sessionKey, isNull);
      expect(f.lastN, LastNGames.last10);
    },
  );
  test('empty sessions are counted but cannot become worst played session', () {
    final cache = EstadisticasCache();
    final empty = session(1, []);
    expect(cache.getEstadisticas([empty])['totalSesiones'], 1);
    final played = session(2, [game(100)]);
    final stats = cache.getEstadisticas([empty, played]);
    expect(stats['totalSesiones'], 2);
    expect(stats['sesionPeor'], same(played));
    cache.dispose();
  });

  group('statistics screen reliability', () {
    late _Repository repo;
    late EstadisticasCache cache;
    setUp(() {
      repo = _Repository();
      cache = EstadisticasCache();
    });
    tearDown(() {
      repo.dispose();
      cache.dispose();
    });
    testWidgets('failed load offers retry and manual refresh reloads data', (
      tester,
    ) async {
      repo.load = () async => throw StateError('test network failure');
      await tester.pumpWidget(app(repo, cache));
      await tester.pumpAndSettle();
      expect(find.text('Reintentar'), findsOneWidget);
      repo.load = () async => [];
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Reintentar'), findsNothing);
      final calls = repo.calls;
      await tester.tap(find.byKey(const Key('statistics-refresh')));
      await tester.pumpAndSettle();
      expect(repo.calls, calls + 1);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'late old-account response cannot replace a new account result',
      (tester) async {
        final old = Completer<List<Sesion>>();
        repo.load = () => old.future;
        await tester.pumpWidget(app(repo, cache));
        await tester.pump();
        repo.load = () async => [
          session(1, [game(211)]),
        ];
        repo.changed(uid: 'account-b');
        await tester.pumpAndSettle();
        old.complete([
          session(1, [game(99)]),
        ]);
        await tester.pumpAndSettle();
        final values = tester
            .widgetList<KpiCardDinamico>(find.byType(KpiCardDinamico))
            .map((w) => w.value);
        expect(values, contains('211.0'));
        expect(values, isNot(contains('99.0')));
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'repository edit refreshes same-count results and loading hides prior account values',
      (tester) async {
        repo.load = () async => [
          session(1, [game(111)]),
        ];
        await tester.pumpWidget(app(repo, cache));
        await tester.pumpAndSettle();
        final pending = Completer<List<Sesion>>();
        repo.load = () => pending.future;
        repo.changed(uid: 'account-b');
        await tester.pump();
        await tester.pump();
        expect(find.byType(KpiCardDinamico), findsNothing);
        pending.complete([
          session(1, [game(222)]),
        ]);
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<KpiCardDinamico>(find.byType(KpiCardDinamico))
              .map((w) => w.value),
          contains('222.0'),
        );
        repo.load = () async => [
          session(1, [game(233)]),
        ];
        repo.changed();
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<KpiCardDinamico>(find.byType(KpiCardDinamico))
              .map((w) => w.value),
          contains('233.0'),
        );
        expect(find.byIcon(Icons.arrow_upward), findsNothing);
        expect(find.byIcon(Icons.arrow_downward), findsNothing);
      },
    );
    testWidgets(
      'full season scope is explicit and independent of last N filter',
      (tester) async {
        repo.load = () async => List.generate(
          12,
          (i) => session(i + 1, [game(100 + i)], season: 'Current'),
        );
        await tester.pumpWidget(app(repo, cache));
        await tester.pumpAndSettle();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('statistics-filter-toggle')));
        await tester.pumpAndSettle();
        final seasonDropdown = tester
            .widgetList<DropdownButton<String>>(
              find.byType(DropdownButton<String>),
            )
            .firstWhere((w) => w.items!.any((i) => i.value == 'Current'));
        seasonDropdown.onChanged!('Current');
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('\u00dalt. 10'));
        await tester.tap(find.text('\u00dalt. 10'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const Key('statistics-filter-toggle')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('statistics-filter-toggle')));
        await tester.pumpAndSettle();
        final scrollable = find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.byKey(const Key('statistics-average')),
          200,
          scrollable: scrollable,
        );
        expect(
          tester
              .widget<KpiCardDinamico>(
                find.byKey(const Key('statistics-average')),
              )
              .value,
          '106.5',
        );
        await tester.scrollUntilVisible(
          find.byKey(const Key('statistics-toggle-season')),
          250,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('statistics-toggle-season')));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const Key('statistics-season-scope')),
          200,
          scrollable: scrollable,
        );
        expect(
          find.textContaining('Resumen de temporadas completas'),
          findsOneWidget,
        );
        expect(
          tester
              .widgetList<KpiCardDinamico>(find.byType(KpiCardDinamico))
              .map((w) => w.value),
          contains('105.5'),
        );
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('loaded statistics remain usable on a phone-sized screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 873);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      repo.load = () async =>
          List.generate(12, (i) => session(i + 1, [game(100 + i)]));
      await tester.pumpWidget(app(repo, cache));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
    testWidgets('resume and dispose during a pending refresh are safe', (
      tester,
    ) async {
      await tester.pumpWidget(app(repo, cache));
      await tester.pumpAndSettle();
      final calls = repo.calls;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(repo.calls, calls + 1);
      final pending = Completer<List<Sesion>>();
      repo.load = () => pending.future;
      await tester.tap(find.byKey(const Key('statistics-refresh')));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      pending.complete([]);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
