import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bolometro/l10n/app_localizations.dart';
import 'package:bolometro/screens/score_photo_prepare_screen.dart';
import 'package:bolometro/screens/score_photo_screen.dart';
import 'package:bolometro/services/score_photo_draft_store.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'support/memory_score_photo_draft_store.dart';
import 'support/score_photo_proposal_fixture.dart';
import 'support/score_photo_raster_fixture.dart';
import 'support/test_firestore_service.dart';
import 'support/memory_arsenal_store.dart';

class Owner extends DataRepository {
  Owner()
    : super(
        firestoreService: TestFirestoreService(),
        arsenalRemote: MemoryArsenalStore(),
        autoSyncArsenal: false,
      );
  int token = 0;
  @override
  String? get arsenalUserId => 'test-photo';
  @override
  int get seasonAccountToken => token;
  void change() {
    token++;
    notifyListeners();
  }
}

Widget app(Widget screen, {Owner? owner, double textScale = 1}) {
  Widget child = MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (c, child) => MediaQuery(
      data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: screen,
  );
  if (owner != null)
    child = ChangeNotifierProvider<DataRepository>.value(
      value: owner,
      child: child,
    );
  return child;
}

Future<void> click(WidgetTester t, String key) async {
  final f = find.byKey(ValueKey(key));
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'four corner edit requires preview; reset enables original reading',
    (t) async {
      await t.binding.setSurfaceSize(const Size(600, 1100));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final source = await t.runAsync(imageFixture);
      await t.pumpWidget(app(ScorePhotoPrepareScreen(source: source!)));
      await t.pumpAndSettle();
      final image = find.byKey(const ValueKey('photo-corner-image'));
      final rect = t.getRect(image);
      for (final p in [
        const Offset(.1, .1),
        const Offset(.9, .1),
        const Offset(.9, .9),
        const Offset(.1, .9),
      ]) {
        await t.tapAt(
          rect.topLeft + Offset(rect.width * p.dx, rect.height * p.dy),
        );
        await t.pump();
      }
      expect(
        t
            .widget<FilledButton>(
              find.byKey(const ValueKey('photo-read-prepared')),
            )
            .onPressed,
        isNull,
      );
      // Render tasks are asynchronous engine operations, not fake clock timers.
      final button = find.byKey(const ValueKey('photo-corners-preview'));
      await t.ensureVisible(button);
      await t.pumpAndSettle();
      await t.runAsync(() async {
        await t.tap(button);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('photo-prepared-preview')),
        findsOneWidget,
      );
      expect(
        t
            .widget<FilledButton>(
              find.byKey(const ValueKey('photo-read-prepared')),
            )
            .onPressed,
        isNotNull,
      );
      await click(t, 'photo-corners-reset');
      expect(
        find.byKey(const ValueKey('photo-prepared-preview')),
        findsNothing,
      );
      expect(
        t
            .widget<FilledButton>(
              find.byKey(const ValueKey('photo-read-prepared')),
            )
            .onPressed,
        isNotNull,
      );
    },
  );
  testWidgets('crossed corner ordering blocks correction', (t) async {
    await t.binding.setSurfaceSize(const Size(600, 1100));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final source = await t.runAsync(imageFixture);
    await t.pumpWidget(app(ScorePhotoPrepareScreen(source: source!)));
    await t.pumpAndSettle();
    final rect = t.getRect(find.byKey(const ValueKey('photo-corner-image')));
    for (final p in [
      const Offset(.1, .1),
      const Offset(.9, .9),
      const Offset(.9, .1),
      const Offset(.1, .9),
    ]) {
      await t.tapAt(
        rect.topLeft + Offset(rect.width * p.dx, rect.height * p.dy),
      );
      await t.pump();
    }
    expect(
      t
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('photo-corners-preview')),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets('account change hides preparation image', (t) async {
    final owner = Owner();
    final source = await t.runAsync(imageFixture);
    await t.pumpWidget(
      app(ScorePhotoPrepareScreen(source: source!), owner: owner),
    );
    await t.pumpAndSettle();
    owner.change();
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo-corner-image')), findsNothing);
    await t.pumpWidget(const SizedBox());
    owner.dispose();
  });
  testWidgets('small screen and large text retain controls without overflow', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final source = await t.runAsync(imageFixture);
    await t.pumpWidget(
      app(ScorePhotoPrepareScreen(source: source!), textScale: 1.5),
    );
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const ValueKey('photo-read-prepared')));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'normal screen defers OCR until preparation is explicitly accepted',
    (t) async {
      final source = await t.runAsync(imageFixture);
      var reads = 0;
      final store = MemoryScorePhotoDraftStore();
      Widget screen = ScorePhotoScreen(
        draftStore: store,
        loadSource: () async => source,
        recognizePrepared: (image) async {
          reads++;
          expect(identical(image, source), true);
          return proposalFixture();
        },
      );
      screen = Provider<ScorePhotoDraftStore>.value(
        value: store,
        child: screen,
      );
      await t.pumpWidget(app(screen));
      await t.pumpAndSettle();
      await click(t, 'photo-pick');
      expect(find.byType(ScorePhotoPrepareScreen), findsOneWidget);
      expect(reads, 0);
      await click(t, 'photo-read-prepared');
      expect(reads, 1);
      expect(find.byKey(const ValueKey('photo-summary-apply')), findsOneWidget);
    },
  );

  testWidgets('cancel preparation does not run OCR or save a replacement draft',(t)async{
    final source=await t.runAsync(imageFixture);var reads=0;
    final store=MemoryScorePhotoDraftStore();
    await t.pumpWidget(app(ScorePhotoScreen(draftStore:store,loadSource:()async=>source,
      recognizePrepared:(_)async{reads++;return proposalFixture();})));
    await t.pumpAndSettle();await click(t,'photo-pick');
    await t.tap(find.byType(BackButton).last);await t.pumpAndSettle();
    expect(reads,0);expect(store.saves,0);expect(find.byKey(const ValueKey('photo-summary-apply')),findsNothing);
  });
  testWidgets('confirmed rectified image is the one sent to OCR',(t)async{
    await t.binding.setSurfaceSize(const Size(600,1100));addTearDown(()=>t.binding.setSurfaceSize(null));
    final source=await t.runAsync(imageFixture);var reads=0;
    final store=MemoryScorePhotoDraftStore();
    await t.pumpWidget(app(ScorePhotoScreen(draftStore:store,loadSource:()async=>source,
      recognizePrepared:(image)async{
        reads++;expect(image.size.width,lessThan(source!.size.width));
        expect(image.size.height,lessThan(source.size.height));
        expect(image.symbols,isEmpty);return proposalFixture();})));
    await t.pumpAndSettle();await click(t,'photo-pick');
    final rect=t.getRect(find.byKey(const ValueKey('photo-corner-image')));
    for(final p in [const Offset(.1,.1),const Offset(.9,.1),const Offset(.9,.9),const Offset(.1,.9)]){
      await t.tapAt(rect.topLeft+Offset(rect.width*p.dx,rect.height*p.dy));await t.pump();}
    final button=find.byKey(const ValueKey('photo-corners-preview'));
    await t.ensureVisible(button);await t.pumpAndSettle();
    await t.runAsync(()async{await t.tap(button);await Future<void>.delayed(const Duration(milliseconds:100));});
    await t.pumpAndSettle();expect(reads,0);
    await click(t,'photo-read-prepared');expect(reads,1);
    expect(find.byKey(const ValueKey('photo-summary-apply')),findsOneWidget);
  });
}
