import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bolometro/l10n/app_localizations.dart';
import 'package:bolometro/models/bowling_ball.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/providers/keyboard_provider.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'package:bolometro/screens/registro_sesion.dart';
import 'package:bolometro/screens/editar_partida.dart';
import 'package:bolometro/services/analytics_service.dart';
import 'package:bolometro/services/draft_service.dart';
import 'package:bolometro/widgets/game_ball_assignments.dart';
import 'package:bolometro/widgets/marcador_bolos.dart';
import 'package:bolometro/widgets/seleccionar_bola_field.dart';
import 'support/test_firestore_service.dart';
import 'support/memory_arsenal_store.dart';

class Repository extends DataRepository {
  Repository()
    : super(
        firestoreService: TestFirestoreService(),
        arsenalRemote: MemoryArsenalStore(),
        autoSyncArsenal: false,
      );
  final balls = [
    BowlingBall(id: 'a', name: 'Ball A', weightLbs: 15),
    BowlingBall(id: 'b', name: 'Ball B', weightLbs: 14),
  ];
  String? owner = 'account-a';
  void switchOwner(String? value) {
    owner = value;
    generation++;
    notifyListeners();
  }

  int generation = 0;
  @override
  String? get arsenalUserId => owner;
  @override
  int get seasonAccountToken => generation;
  @override
  Future<List<BowlingBall>> listarTodasLasBolas() async => balls;
  @override
  Future<List<BowlingBall>> listarBolasActivas() async =>
      balls.where((b) => b.isActive).toList();
  @override
  Future<BowlingBall?> obtenerBola(String id) async {
    final found = balls.where((b) => b.id == id);
    return found.isEmpty ? null : found.first;
  }
}

class Analytics implements AnalyticsService {
  @override
  Future<void> logScreenView(String name) async {}
  @override
  Future<void> logGameCreated(int score) async {}
  @override
  Future<void> logGameEdited() async {}
  @override
  Future<void> logBallAssignedToGame() async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Future<void> choose(WidgetTester tester, String? id) async {
  await tester.tap(
    id == null
        ? find.text('Sin especificar').last
        : find.byKey(ValueKey('ball-choice-$id')),
  );
  await tester.pumpAndSettle();
}

Future<void> cell(WidgetTester tester, int f, int t) async {
  final target = find.byKey(Key('ball-throw-$f-$t'));
  await tester.scrollUntilVisible(
    target,
    150,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> saveAssignments(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('ball-save-overrides')));
  await tester.pumpAndSettle();
}

void main() {
  late Repository repo;
  late KeyboardProvider keyboard;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = Repository();
    keyboard = KeyboardProvider();
  });
  tearDown(() {
    repo.dispose();
    keyboard.dispose();
  });
  Widget app(Widget child, {double scale = 1}) => MultiProvider(
    providers: [
      ChangeNotifierProvider<DataRepository>.value(value: repo),
      ChangeNotifierProvider<KeyboardProvider>.value(value: keyboard),
      Provider<AnalyticsService>.value(value: Analytics()),
    ],
    child: MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: child,
    ),
  );

  testWidgets(
    'range frame five through ten saves staged assignments only after confirmation',
    (tester) async {
      Map<String, String?> assignments = {};
      var changes = 0;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => GameBallAssignments(
                ballId: 'a',
                assignments: assignments,
                onChanged: (_, map) {
                  changes++;
                  setState(() => assignments = map);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ball-throw-editor')));
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byKey(const Key('ball-range-start')),
          )
          .onChanged!(4);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Asignar bola al intervalo'));
      await tester.pumpAndSettle();
      await choose(tester, 'b');
      expect(changes, 0);
      expect(assignments, isEmpty);
      await saveAssignments(tester);
      expect(changes, 1);
      expect(assignments.length, 13);
      expect(assignments['4:0'], 'b');
      expect(assignments['9:2'], 'b');
      expect(assignments.containsKey('3:0'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'cancel picker and cancel editor preserve the only stored assignments',
    (tester) async {
      final original = <String, String?>{'0:1': 'b'};
      var changes = 0;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: GameBallAssignments(
              ballId: 'a',
              assignments: original,
              onChanged: (_, m) => changes++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ball-throw-editor')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Asignar bola al intervalo'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await saveAssignments(tester);
      expect(original, {'0:1': 'b'});
      expect(
        changes,
        1,
      ); // Confirmed unchanged map, no extra range assignments.
      await tester.tap(find.byKey(const Key('ball-throw-editor')));
      await tester.pumpAndSettle();
      await cell(tester, 0, 0);
      await choose(tester, 'b');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(changes, 1);
      expect(original, {'0:1': 'b'});
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'explicit unknown overrides default instead of being mistaken for cancellation',
    (tester) async {
      Map<String, String?>? saved;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: GameBallAssignments(
              ballId: 'a',
              assignments: const {},
              onChanged: (_, m) => saved = m,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ball-throw-editor')));
      await tester.pumpAndSettle();
      await cell(tester, 0, 0);
      await choose(tester, null);
      await saveAssignments(tester);
      expect(saved, {'0:0': null});
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'only second throws can be assigned to the spare ball across all frames',
    (tester) async {
      Map<String, String?>? saved;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: GameBallAssignments(
              ballId: 'a',
              assignments: const {},
              onChanged: (_, m) => saved = m,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ball-throw-editor')));
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byKey(const Key('ball-range-kind')),
          )
          .onChanged!(1);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Asignar bola al intervalo'));
      await tester.pumpAndSettle();
      await choose(tester, 'b');
      await saveAssignments(tester);
      expect(saved!.length, 10);
      expect(saved!.keys.every((k) => k.endsWith(':1')), isTrue);
      expect(saved!['9:1'], 'b');
    },
  );
  testWidgets(
    'archived referenced ball remains available for correcting historical assignments',
    (tester) async {
      repo.balls[1].isActive = false;
      Map<String, String?>? saved;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: GameBallAssignments(
              ballId: 'a',
              assignments: const {'0:1': 'b'},
              onChanged: (_, m) => saved = m,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ball-throw-editor')));
      await tester.pumpAndSettle();
      await cell(tester, 0, 0);
      await choose(tester, 'b');
      await saveAssignments(tester);
      expect(saved!['0:0'], 'b');
    },
  );
  testWidgets(
    'changing default keeps overrides; reset is explicit and staged',
    (tester) async {
      String? defaultId = 'a';
      Map<String, String?> map = {'0:1': 'b'};
      await tester.pumpWidget(
        app(
          Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => GameBallAssignments(
                ballId: defaultId,
                assignments: map,
                onChanged: (id, m) => setState(() {
                  defaultId = id;
                  map = m;
                }),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SeleccionarBolaField));
      await tester.pumpAndSettle();
      await choose(tester, 'b');
      expect(defaultId, 'b');
      expect(map, {'0:1': 'b'});
      await tester.tap(find.byKey(const Key('ball-throw-editor')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ball-clear-overrides')));
      await tester.pumpAndSettle();
      expect(map, isNotEmpty);
      await saveAssignments(tester);
      expect(map, isEmpty);
      expect(defaultId, 'b');
    },
  );
  testWidgets(
    'account change while editor is open prevents assigning to a different owner',
    (tester) async {
      var changes = 0;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: GameBallAssignments(
              ballId: 'a',
              assignments: const {},
              onChanged: (_, m) => changes++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ball-throw-editor')));
      await tester.pumpAndSettle();
      await cell(tester, 0, 1);
      await choose(tester, 'b');
      repo.owner = 'account-b';
      repo.generation++;
      await saveAssignments(tester);
      expect(changes, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'editor fits phone with large text and scrolls to tenth-frame bonus',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: GameBallAssignments(
                ballId: 'a',
                assignments: const {},
                onChanged: (_, m) {},
              ),
            ),
          ),
          scale: 1.5,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ball-throw-editor')));
      await tester.pumpAndSettle();
      await cell(tester, 9, 2);
      await choose(tester, 'b');
      await saveAssignments(tester);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'registration saves both balls and owner-scoped draft through the real game form',
    (tester) async {
      Partida? saved;
      await tester.pumpWidget(
        app(RegistroSesionScreen(onGuardar: (p) => saved = p)),
      );
      await tester.pumpAndSettle();
      final board = tester.state<MarcadorBolosState>(
        find.byType(MarcadorBolos),
      );
      for (var i = 0; i < 12; i++) {
        board.insertarValor('X');
        await tester.pumpAndSettle();
      }
      final field = find.byType(GameBallAssignments);
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SeleccionarBolaField));
      await tester.pumpAndSettle();
      await choose(tester, 'a');
      await tester.ensureVisible(find.byKey(const Key('ball-throw-editor')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ball-throw-editor')));
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byKey(const Key('ball-range-start')),
          )
          .onChanged!(4);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Asignar bola al intervalo'));
      await tester.pumpAndSettle();
      await choose(tester, 'b');
      await saveAssignments(tester);
      final draft = await DraftService.loadPartidaDraft(ownerUid: 'account-a');
      expect(draft!['ballIdsByThrow'], isNotEmpty);
      final l = AppLocalizations.of(
        tester.element(find.byType(RegistroSesionScreen)),
      )!;
      await tester.tap(find.text(l.saveGame));
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      expect(saved!.total, 300);
      expect(saved!.ballForThrow(0, 0), 'a');
      expect(saved!.ballForThrow(4, 0), 'b');
      expect(saved!.ballForThrow(9, 2), 'b');
      expect(
        await DraftService.loadPartidaDraft(ownerUid: 'account-a'),
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'editing hides another account game without overwriting its original assignments',
    (tester) async {
      final original = Partida(
        total: 300,
        ballId: 'a',
        frames: List.generate(10, (i) => i < 9 ? ['X'] : ['X', 'X', 'X']),
        ballIdsByThrow: {'9:2': 'b'},
      );
      await tester.pumpWidget(
        app(EditarPartidaScreen(partida: original, onGuardar: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MarcadorBolos), findsOneWidget);
      repo.switchOwner('account-b');
      await tester.pumpAndSettle();
      expect(find.byType(MarcadorBolos), findsNothing);
      expect(find.byType(GameBallAssignments), findsNothing);
      expect(find.textContaining('La cuenta ha cambiado.'), findsOneWidget);
      repo.switchOwner('account-a');
      await tester.pumpAndSettle();
      expect(find.byType(MarcadorBolos), findsOneWidget);
      expect(original.ballIdsByThrow, {'9:2': 'b'});
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'editing without changing ball assignments preserves sparse overrides and input game',
    (tester) async {
      final original = Partida(
        total: 300,
        ballId: 'a',
        frames: List.generate(10, (i) => i < 9 ? ['X'] : ['X', 'X', 'X']),
        ballIdsByThrow: {'9:2': 'b'},
      );
      Partida? saved;
      await tester.pumpWidget(
        app(
          EditarPartidaScreen(partida: original, onGuardar: (p) => saved = p),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(EditarPartidaScreen)),
      )!;
      await tester.tap(find.text(l.saveChanges));
      await tester.pumpAndSettle();
      expect(saved!.ballIdsByThrow, {'9:2': 'b'});
      expect(saved!.ballId, 'a');
      expect(original.ballIdsByThrow, {'9:2': 'b'});
      expect(original.total, 300);
      expect(tester.takeException(), isNull);
    },
  );
}
