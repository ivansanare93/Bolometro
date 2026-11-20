import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bolometro/l10n/app_localizations.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/models/bowling_ball.dart';
import 'package:bolometro/providers/keyboard_provider.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'package:bolometro/screens/registro_sesion.dart';
import 'package:bolometro/screens/score_photo_screen.dart';
import 'package:bolometro/services/score_photo_reader.dart';
import 'package:bolometro/services/score_photo_review.dart';
import 'package:bolometro/services/draft_service.dart';
import 'package:bolometro/services/analytics_service.dart';
import 'package:bolometro/widgets/marcador_bolos.dart';
import 'support/test_firestore_service.dart';
import 'support/memory_arsenal_store.dart';
import 'support/memory_score_photo_draft_store.dart';
import 'package:bolometro/services/score_photo_draft_store.dart';

late MemoryScorePhotoDraftStore photoStore;

class PhotoAnalytics implements AnalyticsService {
  @override
  Future<void> logScreenView(String name) async {}
  @override
  Future<void> logGameCreated(int score) async {}
  @override
  Future<void> logBallAssignedToGame() async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class PhotoRepository extends DataRepository {
  PhotoRepository()
    : super(
        firestoreService: TestFirestoreService(),
        arsenalRemote: MemoryArsenalStore(),
        autoSyncArsenal: false,
      );
  String? owner = 'photo-test';
  int token = 0;
  @override
  String? get arsenalUserId => owner;
  @override
  int get seasonAccountToken => token;
  @override
  Future<BowlingBall?> obtenerBola(String id) async =>
      BowlingBall(id: id, name: 'Test ball', weightLbs: 15);
}

List<List<String>> perfectFrames() => [
  ...List.generate(9, (_) => <String>['X', '', '']),
  ['X', 'X', 'X'],
];
ReviewedPhotoScore reviewedScore({bool zero = false}) =>
    ScorePhotoCandidate(
          frames: zero
              ? List.generate(10, (_) => ['0', '0', ''])
              : perfectFrames(),
          printedTotal: zero ? '0' : '300',
        )
        .validate(
          reviewedFrames: Set.of(List.generate(10, (i) => i)),
          totalReviewed: true,
        )
        .requireReviewedScore();

Widget localized(Widget child, {double scale = 1}) =>
    Provider<ScorePhotoDraftStore>.value(
      value: photoStore,
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
Future<void> tapVisible(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.byType(Scrollable).last,
    );
  } else {
    await tester.ensureVisible(target);
  }
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> approveAll(WidgetTester tester) async {
  for (var f = 0; f < 10; f++) {
    await tapVisible(tester, 'photo-reviewed-$f');
  }
  await tapVisible(tester, 'photo-total-reviewed');
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    photoStore = MemoryScorePhotoDraftStore();
  });

  testWidgets(
    'Review blocks auto-save, requires all confirmations and returns only score data',
    (tester) async {
      ReviewedPhotoScore? applied;
      await tester.pumpWidget(
        localized(
          Scaffold(
            body: SingleChildScrollView(
              child: ScorePhotoReviewForm(
                candidate: ScorePhotoCandidate(
                  frames: perfectFrames(),
                  printedTotal: '300',
                ),
                onApply: (score) => applied = score,
              ),
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('photo-apply')))
            .onPressed,
        isNull,
      );
      await approveAll(tester);
      await tapVisible(tester, 'photo-apply');
      expect(applied!.total, 300);
      expect(applied!.frames[9], ['X', 'X', 'X']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Changing a reviewed throw invalidates confirmation and mismatched total blocks apply',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        localized(
          Scaffold(
            body: SingleChildScrollView(
              child: ScorePhotoReviewForm(
                candidate: ScorePhotoCandidate(
                  frames: perfectFrames(),
                  printedTotal: '299',
                ),
                onApply: (_) => calls++,
              ),
            ),
          ),
        ),
      );
      await approveAll(tester);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('photo-apply')))
            .onPressed,
        isNull,
      );
      final field = find.byKey(const ValueKey('photo-throw-0-0'));
      await tester.ensureVisible(field);
      await tester.enterText(field, '9');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('photo-reviewed-0')),
            )
            .value,
        false,
      );
      expect(calls, 0);
    },
  );

  testWidgets(
    'Review form fits a phone with large text through tenth-frame bonus',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        localized(
          Scaffold(
            body: SingleChildScrollView(
              child: ScorePhotoReviewForm(
                candidate: ScorePhotoCandidate(
                  frames: perfectFrames(),
                  printedTotal: '300',
                ),
                numberCandidates: const ['300', '30', '300'],
                onApply: (_) {},
              ),
            ),
          ),
          scale: 1.5,
        ),
      );
      await approveAll(tester);
      await tapVisible(tester, 'photo-apply');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Cancelling gallery selection keeps the review empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      localized(ScorePhotoScreen(loadPhoto: () async => null)),
    );
    await tapVisible(tester, 'photo-pick');
    expect(find.byType(ScorePhotoReviewForm), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Photo row selection extracts ten cells and keeps total unassigned',
    (tester) async {
      final tokens = List.generate(
        10,
        (i) => ScorePhotoToken(
          i == 9 ? 'XXX' : 'X',
          Rect.fromLTWH(i * 100 + 20, 110, 30, 20),
        ),
      );
      final document = ScorePhotoDocument(
        image: Uint8List.fromList(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a3ioAAAAASUVORK5CYII=',
          ),
        ),
        size: const Size(1000, 500),
        symbols: tokens,
        numberCandidates: const ['300'],
      );
      var selections = 0;
      await tester.pumpWidget(
        localized(
          ScorePhotoScreen(
            loadPhoto: () async => ++selections == 1 ? document : null,
          ),
        ),
      );
      await tapVisible(tester, 'photo-pick');
      final selector = find.byKey(const ValueKey('photo-row-selector'));
      await tester.ensureVisible(selector);
      await tester.pumpAndSettle();
      final rect = tester.getRect(selector);
      final start = rect.topLeft + Offset(1, rect.height * .2);
      final end = rect.topLeft + Offset(rect.width - 1, rect.height * .3);
      final gesture = await tester.startGesture(start);
      await gesture.moveTo(start + const Offset(0, 20));
      await gesture.moveTo(end);
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('photo-extract')),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('photo-extract')))
            .onPressed,
        isNotNull,
      );
      await tapVisible(tester, 'photo-extract');
      await tapVisible(tester, 'photo-correct-reading');
      await tester.scrollUntilVisible(
        find.byType(ScorePhotoReviewForm),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.byType(ScorePhotoReviewForm), findsOneWidget);
      final form = tester.widget<ScorePhotoReviewForm>(
        find.byType(ScorePhotoReviewForm),
      );
      expect(form.candidate.frames[0][0], 'X');
      expect(form.candidate.frames[9], ['X', 'X', 'X']);
      expect(form.candidate.printedTotal, isNull);
      final firstThrow = find.byKey(const ValueKey('photo-throw-0-0'));
      await tester.ensureVisible(firstThrow);
      await tester.enterText(firstThrow, '9');
      await tester.pumpAndSettle();
      await tapVisible(tester, 'photo-pick');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(firstThrow).controller!.text, '9');
      expect(selections, 2);
      expect(tester.takeException(), isNull);
    },
  );

  for (final zero in [false, true]) {
    testWidgets('Normal form saves reviewed photo score; zero=$zero', (
      tester,
    ) async {
      final repo = PhotoRepository();
      final keyboard = KeyboardProvider();
      addTearDown(repo.dispose);
      addTearDown(keyboard.dispose);
      Partida? saved;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DataRepository>.value(value: repo),
            ChangeNotifierProvider<KeyboardProvider>.value(value: keyboard),
            Provider<AnalyticsService>.value(value: PhotoAnalytics()),
          ],
          child: localized(RegistroSesionScreen(onGuardar: (p) => saved = p)),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, 'import-score-photo');
      Navigator.pop(
        tester.element(find.byType(ScorePhotoScreen)),
        reviewedScore(zero: zero),
      );
      await tester.pumpAndSettle();
      final board = tester.widget<MarcadorBolos>(find.byType(MarcadorBolos));
      expect(board.frames[0][0], zero ? '-' : 'X');
      expect(saved, isNull);
      final draft = await DraftService.loadPartidaDraft(ownerUid: 'photo-test');
      expect(draft, isNotNull);
      final l = AppLocalizations.of(
        tester.element(find.byType(RegistroSesionScreen)),
      )!;
      await tester.tap(find.text(l.saveGame));
      await tester.pumpAndSettle();
      expect(saved!.total, zero ? 0 : 300);
      expect(saved!.pinesPorTiro.every((f) => f.every((t) => t == null)), true);
      expect(saved!.ballIdsByThrow, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Account generation change rejects a photo result even after returning to same UID',
    (tester) async {
      final repo = PhotoRepository();
      final keyboard = KeyboardProvider();
      addTearDown(repo.dispose);
      addTearDown(keyboard.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DataRepository>.value(value: repo),
            ChangeNotifierProvider<KeyboardProvider>.value(value: keyboard),
            Provider<AnalyticsService>.value(value: PhotoAnalytics()),
          ],
          child: localized(RegistroSesionScreen(onGuardar: (_) {})),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, 'import-score-photo');
      repo.token++;
      Navigator.pop(
        tester.element(find.byType(ScorePhotoScreen)),
        reviewedScore(),
      );
      await tester.pumpAndSettle();
      final board = tester.widget<MarcadorBolos>(find.byType(MarcadorBolos));
      expect(board.frames.every((f) => f.every((s) => s.isEmpty)), true);
    },
  );

  testWidgets('Rejecting replacement preserves existing draft throws', (
    tester,
  ) async {
    final repo = PhotoRepository();
    final keyboard = KeyboardProvider();
    addTearDown(repo.dispose);
    addTearDown(keyboard.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DataRepository>.value(value: repo),
          ChangeNotifierProvider<KeyboardProvider>.value(value: keyboard),
          Provider<AnalyticsService>.value(value: PhotoAnalytics()),
        ],
        child: localized(RegistroSesionScreen(onGuardar: (_) {})),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .state<MarcadorBolosState>(find.byType(MarcadorBolos))
        .insertarValor('8');
    await tester.pumpAndSettle();
    await tapVisible(tester, 'import-score-photo');
    Navigator.pop(
      tester.element(find.byType(ScorePhotoScreen)),
      reviewedScore(),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MarcadorBolos>(find.byType(MarcadorBolos)).frames[0][0],
      '8',
    );
  });
  testWidgets('OCR errors stay recoverable and do not return a score', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      localized(
        ScorePhotoScreen(
          loadPhoto: () async {
            calls++;
            throw const ScorePhotoException('size');
          },
        ),
      ),
    );
    await tapVisible(tester, 'photo-pick');
    expect(find.byType(ScorePhotoReviewForm), findsNothing);
    final l = AppLocalizations.of(
      tester.element(find.byType(ScorePhotoScreen)),
    )!;
    expect(find.text(l.photoScoreSize), findsOneWidget);
    await tapVisible(tester, 'photo-pick');
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Accepting replacement retains ball assignments and notes, removes old pin identities',
    (tester) async {
      final repo = PhotoRepository();
      final keyboard = KeyboardProvider();
      addTearDown(repo.dispose);
      addTearDown(keyboard.dispose);
      await DraftService.savePartidaDraft(
        ownerUid: 'photo-test',
        framesText: [
          ['8', '', ''],
          ...List.generate(9, (_) => ['', '', '']),
        ],
        ballId: 'a',
        ballIdsByThrow: const {'4:0': 'b'},
        notas: 'Personal note',
        pinesPorTiro: [
          [
            [1, 2, 3, 4, 5, 6, 7, 8],
            null,
            null,
          ],
          ...List.generate(9, (_) => <List<int>?>[null, null, null]),
        ],
      );
      Partida? saved;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DataRepository>.value(value: repo),
            ChangeNotifierProvider<KeyboardProvider>.value(value: keyboard),
            Provider<AnalyticsService>.value(value: PhotoAnalytics()),
          ],
          child: localized(RegistroSesionScreen(onGuardar: (p) => saved = p)),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, 'import-score-photo');
      Navigator.pop(
        tester.element(find.byType(ScorePhotoScreen)),
        reviewedScore(),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(RegistroSesionScreen)),
      )!;
      await tester.tap(find.text(l.photoScoreReplace));
      await tester.pumpAndSettle();
      final draft = await DraftService.loadPartidaDraft(ownerUid: 'photo-test');
      expect(draft!['ballId'], 'a');
      expect(draft['ballIdsByThrow'], {'4:0': 'b'});
      expect(draft['notas'], 'Personal note');
      await tester.tap(find.text(l.saveGame));
      await tester.pumpAndSettle();
      expect(saved!.ballId, 'a');
      expect(saved!.ballIdsByThrow, {'4:0': 'b'});
      expect(saved!.notas, 'Personal note');
      expect(saved!.pinesPorTiro.every((f) => f.every((t) => t == null)), true);
      expect(tester.takeException(), isNull);
    },
  );
}
