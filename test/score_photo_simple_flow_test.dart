import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'package:bolometro/services/score_photo_draft_store.dart';
import 'package:bolometro/services/score_photo_reader.dart';
import 'package:bolometro/services/score_photo_review.dart';
import 'package:bolometro/services/score_photo_proposer.dart';
import 'package:bolometro/screens/score_photo_screen.dart';
import 'package:bolometro/widgets/score_photo_summary.dart';
import 'package:bolometro/l10n/app_localizations.dart';
import 'support/score_photo_proposal_fixture.dart';
import 'support/memory_score_photo_draft_store.dart';
import 'support/test_firestore_service.dart';
import 'support/memory_arsenal_store.dart';

class Owner extends DataRepository {
  Owner()
    : super(
        firestoreService: TestFirestoreService(),
        arsenalRemote: MemoryArsenalStore(),
        autoSyncArsenal: false,
      );
  String? uid = 'a';
  int token = 0;
  @override
  String? get arsenalUserId => uid;
  @override
  int get seasonAccountToken => token;
  void switchAccount() {
    uid = 'b';
    token++;
    notifyListeners();
  }
}

class DelayedStore extends MemoryScorePhotoDraftStore {
  Completer<void>? gate;
  int waiting = 0;
  @override
  Future<void> save({
    required String? ownerUid,
    required ScorePhotoDocument document,
    required Map<String, dynamic> state,
  }) async {
    if (gate != null) {
      waiting++;
      await gate!.future;
    }
    await super.save(ownerUid: ownerUid, document: document, state: state);
  }
}

Future<void> click(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Widget app({
  required ScorePhotoDocument document,
  required MemoryScorePhotoDraftStore store,
  ValueChanged<ReviewedPhotoScore>? onResult,
  Owner? owner,
  double scale = 1,
  VoidCallback? onRead,
}) => MultiProvider(
  providers: [
    Provider<ScorePhotoDraftStore>.value(value: store),
    if (owner != null)
      ChangeNotifierProvider<DataRepository>.value(value: owner),
  ],
  child: MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (c, child) => MediaQuery(
      data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Builder(
      builder: (c) => Scaffold(
        body: TextButton(
          key: const ValueKey('open-photo'),
          onPressed: () async {
            final result = await Navigator.push<ReviewedPhotoScore>(
              c,
              MaterialPageRoute(
                builder: (_) => ScorePhotoScreen(
                  loadPhoto: () async {
                    onRead?.call();
                    return document;
                  },
                ),
              ),
            );
            if (result != null) onResult?.call(result);
          },
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'Single row opens the whole-game proposal; one explicit confirmation returns the score',
    (tester) async {
      final store = MemoryScorePhotoDraftStore();
      ReviewedPhotoScore? returned;
      await tester.pumpWidget(
        app(
          document: proposalFixture(),
          store: store,
          onResult: (v) => returned = v,
        ),
      );
      await click(tester, 'open-photo');
      await click(tester, 'photo-pick');
      expect(find.byType(ScorePhotoSummary), findsOneWidget);
      expect(find.byType(ScorePhotoReviewForm), findsNothing);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('photo-summary-total')),
            )
            .controller!
            .text,
        '207',
      );
      expect(returned, isNull);
      await click(tester, 'photo-summary-apply');
      expect(returned!.total, 207);
      expect(returned!.frames[9].where((v) => v.isNotEmpty).join(), '9/X');
      expect(
        store.drafts[null]!.state['progress']['reviewed'],
        List.generate(10, (i) => i),
      );
    },
  );

  testWidgets(
    'Several player rows require a choice before any proposal can be applied',
    (tester) async {
      final store = MemoryScorePhotoDraftStore();
      await tester.pumpWidget(
        app(document: proposalFixture(players: 2), store: store),
      );
      await click(tester, 'open-photo');
      await click(tester, 'photo-pick');
      expect(find.byType(ScorePhotoSummary), findsNothing);
      expect(find.byKey(const ValueKey('photo-summary-apply')), findsNothing);
      await click(tester, 'photo-row-1');
      expect(find.byType(ScorePhotoSummary), findsOneWidget);
      expect((store.drafts[null]!.state['row'] as List)[1], greaterThan(300));
    },
  );

  testWidgets(
    'Unknown throws block quick confirmation and can be corrected through the same editor',
    (tester) async {
      final values = [
        ['9', 'I'],
        ['X'],
        ['X'],
        ['9', '/'],
        ['X'],
        ['9', '/'],
        ['9', '/'],
        ['X'],
        ['6', '/'],
        ['9', '/', 'X'],
      ];
      final store = MemoryScorePhotoDraftStore();
      ReviewedPhotoScore? returned;
      await tester.pumpWidget(
        app(
          document: proposalFixture(throws_: values),
          store: store,
          onResult: (v) => returned = v,
        ),
      );
      await click(tester, 'open-photo');
      await click(tester, 'photo-pick');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('photo-summary-apply')),
            )
            .onPressed,
        isNull,
      );
      await click(tester, 'photo-correct-reading');
      expect(find.byType(ScorePhotoReviewForm), findsOneWidget);
      final first = find.byKey(const ValueKey('photo-throw-0-0'));
      await tester.ensureVisible(first);
      await tester.enterText(first, '9');
      await tester.enterText(
        find.byKey(const ValueKey('photo-throw-0-1')),
        '/',
      );
      await tester.pumpAndSettle();
      await click(tester, 'photo-return-summary');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('photo-summary-apply')),
            )
            .onPressed,
        isNotNull,
      );
      expect(returned, isNull);
      await click(tester, 'photo-summary-apply');
      expect(returned!.total, 207);
    },
  );

  testWidgets(
    'Printed 247 is not replaced by a matching number; user may correct the total explicitly',
    (tester) async {
      final store = MemoryScorePhotoDraftStore();
      ReviewedPhotoScore? returned;
      await tester.pumpWidget(
        app(
          document: proposalFixture(
            cumulative: [20, 49, 69, 89, 109, 128, 148, 168, 187, 247],
          ),
          store: store,
          onResult: (v) => returned = v,
        ),
      );
      await click(tester, 'open-photo');
      await click(tester, 'photo-pick');
      final total = find.byKey(const ValueKey('photo-summary-total'));
      expect(tester.widget<TextField>(total).controller!.text, '247');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('photo-summary-apply')),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(total);
      await tester.enterText(total, '207');
      await tester.pumpAndSettle();
      expect(returned, isNull);
      await click(tester, 'photo-summary-apply');
      expect(returned!.total, 207);
      expect(store.drafts[null]!.state['observedCumulative'][9], 247);
    },
  );

  testWidgets(
    'Disagreeing intermediate accumulated score blocks quick confirmation despite matching final total',
    (tester) async {
      final store = MemoryScorePhotoDraftStore();
      await tester.pumpWidget(
        app(
          document: proposalFixture(
            cumulative: [20, 49, 69, 89, 109, 129, 148, 168, 187, 207],
          ),
          store: store,
        ),
      );
      await click(tester, 'open-photo');
      await click(tester, 'photo-pick');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('photo-summary-apply')),
            )
            .onPressed,
        isNull,
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(ScorePhotoSummary)),
      )!;
      expect(find.text(l.photoScoreProposalCumulativeMismatch), findsOneWidget);
      await click(tester, 'photo-correct-reading');
      expect(find.byType(ScorePhotoReviewForm), findsOneWidget);
    },
  );

  testWidgets('A proposal resumes without OCR or automatic confirmation', (
    tester,
  ) async {
    final store = MemoryScorePhotoDraftStore();
    var reads = 0;
    ReviewedPhotoScore? returned;
    Widget build() => app(
      document: proposalFixture(),
      store: store,
      onResult: (v) => returned = v,
      onRead: () => reads++,
    );
    await tester.pumpWidget(build());
    await click(tester, 'open-photo');
    await click(tester, 'photo-pick');
    expect(reads, 1);
    expect(returned, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(build());
    await click(tester, 'open-photo');
    await click(tester, 'photo-resume');
    expect(find.byType(ScorePhotoSummary), findsOneWidget);
    expect(reads, 1);
    expect(returned, isNull);
    expect(store.drafts[null]!.state['progress']['reviewed'], isEmpty);
  });

  testWidgets(
    'Unsupported layout keeps the existing manual selector available',
    (tester) async {
      final store = MemoryScorePhotoDraftStore();
      await tester.pumpWidget(
        app(document: proposalFixture(headers: false), store: store),
      );
      await click(tester, 'open-photo');
      await click(tester, 'photo-pick');
      expect(find.byType(ScorePhotoSummary), findsNothing);
      expect(find.byKey(const ValueKey('photo-row-selector')), findsOneWidget);
      final l = AppLocalizations.of(
        tester.element(find.byType(ScorePhotoScreen)),
      )!;
      expect(find.text(l.photoScoreNoProposals), findsOneWidget);
    },
  );

  testWidgets(
    'Changing account during final local save prevents transferring the old account result',
    (tester) async {
      final store = DelayedStore();
      final owner = Owner();
      addTearDown(owner.dispose);
      ReviewedPhotoScore? returned;
      await tester.pumpWidget(
        app(
          document: proposalFixture(),
          store: store,
          owner: owner,
          onResult: (v) => returned = v,
        ),
      );
      await click(tester, 'open-photo');
      await click(tester, 'photo-pick');
      store.gate = Completer<void>();
      await click(tester, 'photo-summary-apply');
      owner.switchAccount();
      await tester.pumpAndSettle();
      store.gate!.complete();
      await tester.pumpAndSettle();
      expect(returned, isNull);
      expect(store.drafts['b'], isNull);
      expect(find.byType(ScorePhotoSummary), findsNothing);
    },
  );

  testWidgets('Whole-game summary fits phone and large text', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryScorePhotoDraftStore();
    await tester.pumpWidget(
      app(document: proposalFixture(), store: store, scale: 1.5),
    );
    await click(tester, 'open-photo');
    await click(tester, 'photo-pick');
    await tester.ensureVisible(
      find.byKey(const ValueKey('photo-summary-frame-9')),
    );
    await tester.pumpAndSettle();
    await click(tester, 'photo-full-image');
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await click(tester, 'photo-summary-apply');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Repeated confirmation while saving returns a single result', (
    tester,
  ) async {
    final store = DelayedStore();
    var returns = 0;
    await tester.pumpWidget(
      app(
        document: proposalFixture(),
        store: store,
        onResult: (_) => returns++,
      ),
    );
    await click(tester, 'open-photo');
    await click(tester, 'photo-pick');
    final button = find.byKey(const ValueKey('photo-summary-apply'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    store.gate = Completer<void>();
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();
    expect(store.waiting, 1);
    store.gate!.complete();
    await tester.pumpAndSettle();
    expect(returns, 1);
  });
  testWidgets(
    'Ambiguous columns cannot be accepted just because the score matches',
    (tester) async {
      final doc = proposalFixture();
      final proposal = ScorePhotoProposer().propose(doc).single;
      final store = MemoryScorePhotoDraftStore();
      await store.save(
        ownerUid: null,
        document: doc,
        state: {
          'row': [
            proposal.row.left,
            proposal.row.top,
            proposal.row.right,
            proposal.row.bottom,
          ],
          'dividers': proposal.dividers,
          'candidate': proposal.frames,
          'rawCells': proposal.rawCells,
          'simpleSummary': true,
          'showSelection': false,
          'ambiguousColumns': true,
          'observedCumulative': proposal.observedCumulative,
          'progress': {
            'frames': proposal.frames,
            'total': '207',
            'reviewed': <int>[],
            'totalReviewed': false,
            'activeFrame': 0,
          },
        },
      );
      await tester.pumpWidget(app(document: doc, store: store));
      await click(tester, 'open-photo');
      await click(tester, 'photo-resume');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('photo-summary-apply')),
            )
            .onPressed,
        isNull,
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(ScorePhotoSummary)),
      )!;
      expect(find.text(l.photoScoreProposalAmbiguous), findsOneWidget);
      await click(tester, 'photo-correct-reading');
      expect(find.byType(ScorePhotoReviewForm), findsOneWidget);
    },
  );
  testWidgets('An enlarged photo is hidden immediately on account change', (
    tester,
  ) async {
    final store = MemoryScorePhotoDraftStore();
    final owner = Owner();
    addTearDown(owner.dispose);
    await tester.pumpWidget(
      app(document: proposalFixture(), store: store, owner: owner),
    );
    await click(tester, 'open-photo');
    await click(tester, 'photo-pick');
    await click(tester, 'photo-full-image');
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(ScorePhotoProposalImage),
      ),
      findsOneWidget,
    );
    owner.switchAccount();
    await tester.pumpAndSettle();
    expect(find.byType(ScorePhotoProposalImage), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(ScorePhotoSummary), findsNothing);
  });
}
