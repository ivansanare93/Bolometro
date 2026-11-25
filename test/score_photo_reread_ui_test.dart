import 'dart:async';

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bolometro/l10n/app_localizations.dart';
import 'package:bolometro/screens/score_photo_screen.dart';
import 'package:bolometro/services/score_photo_frame_reader.dart';
import 'package:bolometro/services/score_photo_reader.dart';
import 'package:bolometro/services/score_photo_review.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'support/score_photo_proposal_fixture.dart';
import 'support/test_firestore_service.dart';
import 'support/memory_arsenal_store.dart';

class Reader extends ScorePhotoFrameReader {
  List<String> values = ['8', '/', ''];
  bool fails = false;
  Completer<void>? gate;
  int calls = 0;
  @override
  Future<ScorePhotoFrameReading> read(
    ScorePhotoDocument source,
    ui.Rect cell,
    int frame,
  ) async {
    calls++;
    if (gate != null) await gate!.future;
    if (fails) throw StateError('simulated OCR error');
    return ScorePhotoFrameReading(values, values.join(), source.image);
  }
}

class Owner extends DataRepository {
  Owner()
    : super(
        firestoreService: TestFirestoreService(),
        arsenalRemote: MemoryArsenalStore(),
        autoSyncArsenal: false,
      );
  int token = 0;
  @override
  String? get arsenalUserId => 'fake';
  @override
  int get seasonAccountToken => token;
  void change() {
    token++;
    notifyListeners();
  }
}

Future<void> click(WidgetTester t, String key) async {
  final f = find.byKey(ValueKey(key));
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  final frames = List.generate(
    10,
    (f) => f == 9 ? ['X', 'X', 'X'] : ['X', '', ''],
  );
  Future<void> open(
    WidgetTester t,
    Reader reader,
    ValueChanged<Map<String, dynamic>> emit, {
    Owner? owner,
  }) async {
    // Explicitly synthetic OCR fixture; not a native OCR accuracy test.
    final photo = proposalFixture();
    Widget child = MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScorePhotoReviewForm(
            candidate: ScorePhotoCandidate(frames: frames, printedTotal: '300'),
            document: photo,
            selectedRow: const Rect.fromLTWH(0, 0, 100, 30),
            dividers: List.generate(11, (i) => i / 10),
            frameReader: reader,
            initialProgress: {
              'frames': frames,
              'total': '300',
              'reviewed': List.generate(10, (i) => i),
              'totalReviewed': true,
              'activeFrame': 0,
            },
            onProgress: emit,
            onApply: (_) {},
          ),
        ),
      ),
    );
    if (owner != null)
      child = ChangeNotifierProvider<DataRepository>.value(
        value: owner,
        child: child,
      );
    await t.pumpWidget(child);
    await t.pumpAndSettle();
  }

  testWidgets('cancel preserves corrections and emits nothing', (t) async {
    final reader = Reader();
    final changes = <Map<String, dynamic>>[];
    await open(t, reader, changes.add);
    changes.clear();
    await click(t, 'photo-reread-0');
    expect(find.byKey(const ValueKey('photo-reread-accept')), findsOneWidget);
    await click(t, 'photo-reread-cancel');
    expect(changes, isEmpty);
    expect(
      t
          .widget<TextField>(find.byKey(const ValueKey('photo-throw-0-0')))
          .controller!
          .text,
      'X',
    );
  });
  testWidgets(
    'accept replaces only one frame and invalidates its confirmation and total',
    (t) async {
      final changes = <Map<String, dynamic>>[];
      await open(t, Reader(), changes.add);
      changes.clear();
      await click(t, 'photo-reread-0');
      await click(t, 'photo-reread-accept');
      final result = changes.single;
      final updated = result['frames'] as List;
      expect(updated[0], ['8', '/', '']);
      expect(updated.skip(1).toList(), frames.skip(1).toList());
      expect(result['reviewed'], List.generate(9, (i) => i + 1));
      expect(result['totalReviewed'], false);
      expect(result['total'], '300');
    },
  );
  testWidgets('unknown OCR proposal cannot be accepted', (t) async {
    final changes = <Map<String, dynamic>>[];
    await open(t, Reader()..values = ['?', '', ''], changes.add);
    changes.clear();
    await click(t, 'photo-reread-0');
    expect(
      t
          .widget<FilledButton>(
            find.byKey(const ValueKey('photo-reread-accept')),
          )
          .onPressed,
      isNull,
    );
    await click(t, 'photo-reread-cancel');
    expect(changes, isEmpty);
  });
  testWidgets('OCR failure preserves previous data', (t) async {
    final changes = <Map<String, dynamic>>[];
    await open(t, Reader()..fails = true, changes.add);
    changes.clear();
    await click(t, 'photo-reread-0');
    expect(changes, isEmpty);
    expect(find.byKey(const ValueKey('photo-reread-accept')), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets('account generation change hides result and blocks application', (
    t,
  ) async {
    final owner = Owner();
    final changes = <Map<String, dynamic>>[];
    await open(t, Reader(), changes.add, owner: owner);
    changes.clear();
    await click(t, 'photo-reread-0');
    owner.change();
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo-reread-crop')), findsNothing);
    expect(
      t
          .widget<FilledButton>(
            find.byKey(const ValueKey('photo-reread-accept')),
          )
          .onPressed,
      isNull,
    );
    await click(t, 'photo-reread-cancel');
    expect(changes, isEmpty);
    await t.pumpWidget(const SizedBox());
    owner.dispose();
  });

  testWidgets('account changes during OCR discard result without proposal', (
    t,
  ) async {
    final owner = Owner();
    final reader = Reader()..gate = Completer<void>();
    final changes = <Map<String, dynamic>>[];
    await open(t, reader, changes.add, owner: owner);
    changes.clear();
    final target = find.byKey(const ValueKey('photo-reread-0'));
    await t.ensureVisible(target);
    await t.pumpAndSettle();
    await t.tap(target);
    await t.pump();
    owner.change();
    reader.gate!.complete();
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo-reread-accept')), findsNothing);
    expect(changes, isEmpty);
    expect(reader.calls, 1);
    await t.pumpWidget(const SizedBox());
    owner.dispose();
  });
  testWidgets('repeated taps start a single OCR request', (t) async {
    final reader = Reader()..gate = Completer<void>();
    final changes = <Map<String, dynamic>>[];
    await open(t, reader, changes.add);
    changes.clear();
    final target = find.byKey(const ValueKey('photo-reread-0'));
    await t.ensureVisible(target);
    await t.pumpAndSettle();
    await t.tap(target);
    await t.tap(target);
    await t.pump();
    expect(reader.calls, 1);
    reader.gate!.complete();
    await t.pumpAndSettle();
    await click(t, 'photo-reread-cancel');
    expect(changes, isEmpty);
  });
}
