import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bolometro/l10n/app_localizations.dart';
import 'package:bolometro/services/score_photo_draft_store.dart';
import 'package:bolometro/services/score_photo_reader.dart';
import 'package:bolometro/services/score_photo_review.dart';
import 'package:bolometro/screens/score_photo_screen.dart';
import 'package:bolometro/widgets/score_photo_region_selector.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'support/memory_score_photo_draft_store.dart';
import 'support/memory_arsenal_store.dart';
import 'support/test_firestore_service.dart';

class PhotoOwner extends DataRepository {
  PhotoOwner()
    : super(
        firestoreService: TestFirestoreService(),
        arsenalRemote: MemoryArsenalStore(),
        autoSyncArsenal: false,
      );
  String? uid = 'a';
  int generation = 0;
  @override
  String? get arsenalUserId => uid;
  @override
  int get seasonAccountToken => generation;
  void switchTo(String? next) {
    uid = next;
    generation++;
    notifyListeners();
  }
}

ScorePhotoDocument photo() => ScorePhotoDocument(
  image: Uint8List.fromList(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a3ioAAAAASUVORK5CYII=',
    ),
  ),
  size: const Size(1000, 500),
  symbols: const [ScorePhotoToken('X', Rect.fromLTWH(10, 10, 10, 20))],
  numberCandidates: const ['299', '300'],
);
List<List<String>> perfect() =>
    List.generate(10, (f) => f == 9 ? ['X', 'X', 'X'] : ['X', '', '']);
Map<String, dynamic> draft({String total = '299', int active = 4}) => {
  'row': [0, 0, 1000, 50],
  'dividers': List.generate(11, (i) => i / 10),
  'candidate': perfect(),
  'rawCells': List.filled(10, 'X'),
  'progress': {
    'frames': perfect(),
    'total': total,
    'reviewed': [0, 1, 2],
    'totalReviewed': false,
    'activeFrame': active,
  },
};
Widget app(
  Widget child, {
  ScorePhotoDraftStore? store,
  PhotoOwner? owner,
  double scale = 1,
}) => MultiProvider(
  providers: [
    Provider<ScorePhotoDraftStore>.value(
      value: store ?? MemoryScorePhotoDraftStore(),
    ),
    if (owner != null)
      ChangeNotifierProvider<DataRepository>.value(value: owner),
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
Future<void> click(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Zoomed selection maps back to original image pixels; pan and reset preserve it',
    (tester) async {
      Rect? selected;
      var changes = 0;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: ScorePhotoRegionSelector(
                document: photo(),
                onChanged: (row, _) {
                  selected = row;
                  changes++;
                },
              ),
            ),
          ),
        ),
      );
      await click(tester, 'photo-zoom-in');
      final viewer = tester.widget<InteractiveViewer>(
        find.byKey(const ValueKey('photo-image-viewer')),
      );
      expect(
        viewer.transformationController!.value.getMaxScaleOnAxis(),
        closeTo(1.5, .001),
      );
      final target = find.byKey(const ValueKey('photo-row-selector'));
      final box = tester.renderObject<RenderBox>(target);
      final begin = box.localToGlobal(
        Offset(box.size.width * .4, box.size.height * .4),
      );
      final end = box.localToGlobal(
        Offset(box.size.width * .6, box.size.height * .6),
      );
      final gesture = await tester.startGesture(begin);
      await gesture.moveTo(begin + const Offset(20, 0));
      await gesture.moveTo(end);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(selected!.left, closeTo(400, .01));
      expect(selected!.top, closeTo(200, .01));
      expect(selected!.right, closeTo(600, .01));
      expect(selected!.bottom, closeTo(300, .01));
      final count = changes;
      await click(tester, 'photo-move-mode');
      await tester.drag(target, const Offset(-25, -10));
      await tester.pumpAndSettle();
      await click(tester, 'photo-reset-view');
      expect(changes, count);
      expect(selected!.left, closeTo(400, .01));
      expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Divider edit requires permission and commits only when finished',
    (tester) async {
      var allowed = false;
      List<double>? result;
      Rect? resultRow;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: ScorePhotoRegionSelector(
                document: photo(),
                initialRow: const Rect.fromLTWH(100, 100, 800, 80),
                onEditRequested: () async => allowed,
                onChanged: (row, dividers) {
                  result = dividers;
                  resultRow = row;
                },
              ),
            ),
          ),
        ),
      );
      await click(tester, 'photo-edit-region');
      expect(
        tester
            .widget<Slider>(find.byKey(const ValueKey('photo-divider-slider')))
            .onChanged,
        isNull,
      );
      allowed = true;
      await click(tester, 'photo-edit-region');
      var slider = tester.widget<Slider>(
        find.byKey(const ValueKey('photo-divider-slider')),
      );
      slider.onChanged!(.12);
      await tester.pumpAndSettle();
      expect(result, isNull);
      slider = tester.widget<Slider>(
        find.byKey(const ValueKey('photo-divider-slider')),
      );
      slider.onChangeEnd!(.12);
      await tester.pumpAndSettle();
      expect(result![1], closeTo(.12, .001));
      expect(resultRow, const Rect.fromLTWH(100, 100, 800, 80));
    },
  );

  testWidgets(
    'Confirm and next navigates without saving a game; field errors are actionable',
    (tester) async {
      Map<String, dynamic>? progress;
      var applied = 0;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: ScorePhotoReviewForm(
                candidate: ScorePhotoCandidate(
                  frames: perfect(),
                  printedTotal: '300',
                ),
                onProgress: (value) => progress = value,
                onApply: (_) => applied++,
              ),
            ),
          ),
        ),
      );
      await click(tester, 'photo-confirm-next-0');
      expect(progress!['reviewed'], [0]);
      expect(progress!['activeFrame'], 1);
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('photo-frame-tab-1')))
            .selected,
        true,
      );
      await click(tester, 'photo-previous-1');
      expect(progress!['activeFrame'], 0);
      final first = find.byKey(const ValueKey('photo-throw-0-0'));
      await tester.ensureVisible(first);
      await tester.enterText(first, '9');
      await tester.pumpAndSettle();
      expect(progress!['reviewed'], isEmpty);
      expect(progress!['totalReviewed'], false);
      final l = AppLocalizations.of(
        tester.element(find.byType(ScorePhotoReviewForm)),
      )!;
      expect(find.text('Tiro 2: ${l.photoScoreMissingThrow}'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('photo-confirm-next-0')),
            )
            .onPressed,
        isNull,
      );
      expect(applied, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Closing and reopening preserves corrections and requires explicit resume without rerunning OCR',
    (tester) async {
      final store = MemoryScorePhotoDraftStore();
      final image = photo();
      await store.save(ownerUid: null, document: image, state: draft());
      var reads = 0;
      Widget screen() => app(
        ScorePhotoScreen(
          loadPhoto: () async {
            reads++;
            return image;
          },
        ),
        store: store,
      );
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.byType(ScorePhotoReviewForm), findsNothing);
      await click(tester, 'photo-resume');
      final f = find.byKey(const ValueKey('photo-throw-4-0'));
      await tester.ensureVisible(f);
      await tester.enterText(f, '9');
      await tester.enterText(
        find.byKey(const ValueKey('photo-throw-4-1')),
        '/',
      );
      await tester.pumpAndSettle();
      expect(store.drafts[null]!.state['progress']['frames'][4], [
        '9',
        '/',
        '',
      ]);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.byType(ScorePhotoReviewForm), findsNothing);
      await click(tester, 'photo-resume');
      expect(tester.widget<TextField>(f).controller!.text, '9');
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('photo-total')))
            .controller!
            .text,
        '299',
      );
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('photo-frame-tab-4')))
            .selected,
        true,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('photo-reviewed-4')),
            )
            .value,
        false,
      );
      expect(reads, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Storage failure warns and retry preserves the corrected copy', (
    tester,
  ) async {
    final store = MemoryScorePhotoDraftStore();
    await store.save(ownerUid: null, document: photo(), state: draft());
    store.failSave = true;
    await tester.pumpWidget(app(const ScorePhotoScreen(), store: store));
    await tester.pumpAndSettle();
    await click(tester, 'photo-resume');
    final first = find.byKey(const ValueKey('photo-throw-4-0'));
    await tester.ensureVisible(first);
    await tester.enterText(first, '9');
    await tester.pumpAndSettle();
    expect(store.drafts[null]!.state['progress']['frames'][4][0], 'X');
    final l = AppLocalizations.of(
      tester.element(find.byType(ScorePhotoScreen)),
    )!;
    expect(find.text(l.photoScoreDraftError), findsOneWidget);
    expect(find.text(l.photoScoreDraftSaved), findsNothing);
    store.failSave = false;
    await click(tester, 'photo-draft-retry');
    expect(store.drafts[null]!.state['progress']['frames'][4][0], '9');
    expect(find.text(l.photoScoreDraftError), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Account switch blocks the open review and does not copy it to the next account',
    (tester) async {
      final store = MemoryScorePhotoDraftStore();
      final owner = PhotoOwner();
      addTearDown(owner.dispose);
      await store.save(
        ownerUid: 'a',
        document: photo(),
        state: draft(total: '111'),
      );
      await store.save(
        ownerUid: 'b',
        document: photo(),
        state: draft(total: '222'),
      );
      await tester.pumpWidget(
        app(const ScorePhotoScreen(), store: store, owner: owner),
      );
      await tester.pumpAndSettle();
      await click(tester, 'photo-resume');
      owner.switchTo('b');
      await tester.pumpAndSettle();
      expect(find.byType(ScorePhotoReviewForm), findsNothing);
      expect(store.drafts['a']!.state['progress']['total'], '111');
      expect(store.drafts['b']!.state['progress']['total'], '222');
      expect(store.drafts[null], isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Explicit discard can be cancelled and does not remove another account review',
    (tester) async {
      final store = MemoryScorePhotoDraftStore();
      await store.save(ownerUid: null, document: photo(), state: draft());
      await store.save(
        ownerUid: 'b',
        document: photo(),
        state: draft(total: '200'),
      );
      await tester.pumpWidget(app(const ScorePhotoScreen(), store: store));
      await tester.pumpAndSettle();
      await click(tester, 'photo-discard');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(store.drafts[null], isNotNull);
      await click(tester, 'photo-discard');
      await tester.tap(find.text('Borrar revisi\u00f3n guardada').last);
      await tester.pumpAndSettle();
      expect(store.drafts[null], isNull);
      expect(store.drafts['b']!.state['progress']['total'], '200');
      expect(find.byType(ScorePhotoReviewForm), findsNothing);
    },
  );

  testWidgets('Restore and navigation fit a 360px phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryScorePhotoDraftStore();
    await store.save(ownerUid: null, document: photo(), state: draft());
    await tester.pumpWidget(
      app(const ScorePhotoScreen(), store: store, scale: 1.5),
    );
    await tester.pumpAndSettle();
    await click(tester, 'photo-resume');
    await click(tester, 'photo-frame-tab-9');
    await click(tester, 'photo-previous-9');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Entering edit mode or touching a divider without moving preserves corrections',
    (tester) async {
      final store = MemoryScorePhotoDraftStore();
      await store.save(ownerUid: null, document: photo(), state: draft());
      await tester.pumpWidget(app(const ScorePhotoScreen(), store: store));
      await tester.pumpAndSettle();
      await click(tester, 'photo-resume');
      await click(tester, 'photo-edit-region');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(ScorePhotoReviewForm), findsOneWidget);
      await click(tester, 'photo-edit-region');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      final image = find.byKey(const ValueKey('photo-row-selector'));
      await tester.ensureVisible(image);
      await tester.pumpAndSettle();
      final box = tester.renderObject<RenderBox>(image);
      await tester.tapAt(
        box.localToGlobal(Offset(box.size.width * .1, box.size.height * .05)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ScorePhotoReviewForm), findsOneWidget);
      expect(store.drafts[null]!.state['progress']['total'], '299');
      expect(store.drafts[null]!.state['progress']['reviewed'], [0, 1, 2]);
    },
  );
}
