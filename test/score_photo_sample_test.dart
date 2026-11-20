import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/l10n/app_localizations.dart';
import 'package:bolometro/services/score_photo_reader.dart';
import 'package:bolometro/services/score_photo_review.dart';
import 'package:bolometro/screens/score_photo_screen.dart';

Map<String, dynamic> sample() =>
    jsonDecode(
          File(
            'test/fixtures/score_photos/scoreboard_207_manual.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;
List<List<String>> frames(Map<String, dynamic> data) =>
    (data['frames'] as List).map((f) => List<String>.from(f as List)).toList();
final approved = Set.of(List.generate(10, (i) => i));
ScorePhotoReview validate(List<List<String>> throws_, String total) =>
    ScorePhotoCandidate(
      frames: throws_,
      printedTotal: total,
    ).validate(reviewedFrames: approved, totalReviewed: true);

Future<void> click(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Widget app(Widget body) => MaterialApp(
  locale: const Locale('es'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(body: SingleChildScrollView(child: body)),
);

void main() {
  test('Source is a manual transcription, never an actual OCR benchmark', () {
    expect(sample()['source']['kind'], 'manual_transcription_from_chat_image');
    expect(sample()['source']['native_ocr_executed'], false);
  });

  test(
    'Ten frames reproduce every displayed cumulative score and scratch total',
    () {
      final data = sample();
      final result = validate(frames(data), data['scratch_total'].toString());
      expect(result.canApply, true);
      expect(result.calculatedTotal, 207);
      expect(result.calculatedFrameTotals, data['cumulative_scores']);
      expect(result.requireReviewedScore().frames[9], ['9', '/', 'X']);
      expect(
        () => result.calculatedFrameTotals.add(247),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'Handicap total 247 is in range but rejected for the observed throws',
    () {
      final data = sample();
      final result = validate(
        frames(data),
        data['displayed_handicap_total'].toString(),
      );
      expect(result.calculatedTotal, 207);
      expect(result.canApply, false);
      expect(
        result.issues.map((i) => i.code),
        contains(ScorePhotoIssueCode.totalMismatch),
      );
      expect(
        result.issues.map((i) => i.code),
        isNot(contains(ScorePhotoIssueCode.invalidPrintedTotal)),
      );
      expect(() => result.requireReviewedScore(), throwsStateError);
    },
  );

  test(
    'Changing one legal frame does not manufacture matching throws from total',
    () {
      final data = sample();
      final altered = frames(data)..[2] = ['9', '/'];
      final result = validate(altered, '207');
      expect(result.calculatedTotal, isNot(207));
      expect(result.canApply, false);
      expect(result.frames[2], ['9', '/']);
    },
  );

  test(
    'Missing slash leaves cumulative values unknown instead of zero-filled',
    () {
      final altered = frames(sample())..[8] = ['6', ''];
      final result = validate(altered, '207');
      expect(result.calculatedTotal, isNull);
      expect(result.calculatedFrameTotals, List.filled(10, null));
      expect(result.canApply, false);
    },
  );

  for (final scale in [.5, 1.0, 2.0]) {
    test(
      'Synthetic OCR layout for the transcription excludes headers and cumulative row; scale=$scale',
      () {
        final data = sample();
        final tokens = <ScorePhotoToken>[];
        for (var f = 0; f < 10; f++) {
          final row = frames(data)[f];
          for (var t = 0; t < row.length; t++) {
            tokens.add(
              ScorePhotoToken(
                row[t],
                Rect.fromLTWH(
                  (f * 100 + t * 20 + 10) * scale,
                  85 * scale,
                  12 * scale,
                  15 * scale,
                ),
              ),
            );
          }
          tokens.add(
            ScorePhotoToken(
              (f + 1).toString(),
              Rect.fromLTWH(
                (f * 100 + 10) * scale,
                20 * scale,
                30 * scale,
                20 * scale,
              ),
            ),
          );
          tokens.add(
            ScorePhotoToken(
              (data['cumulative_scores'] as List)[f].toString(),
              Rect.fromLTWH(
                (f * 100 + 10) * scale,
                140 * scale,
                40 * scale,
                20 * scale,
              ),
            ),
          );
        }
        tokens.add(
          ScorePhotoToken(
            '247',
            Rect.fromLTWH(1100 * scale, 80 * scale, 60 * scale, 40 * scale),
          ),
        );
        final extracted = ScorePhotoRow.extract(
          tokens: tokens.reversed.toList(),
          row: Rect.fromLTWH(0, 80 * scale, 1000 * scale, 25 * scale),
          dividers: List.generate(11, (i) => i / 10),
        );
        expect(validate(extracted.frames, '207').canApply, true);
        expect(
          validate(extracted.frames, '207').calculatedFrameTotals,
          data['cumulative_scores'],
        );
      },
    );
  }

  test(
    'Selecting cumulative numbers as if they were throws does not import a valid game',
    () {
      final data = sample();
      final tokens = List.generate(
        10,
        (f) => ScorePhotoToken(
          (data['cumulative_scores'] as List)[f].toString(),
          Rect.fromLTWH(f * 100 + 10, 140, 45, 20),
        ),
      );
      final row = ScorePhotoRow.extract(
        tokens: tokens,
        row: const Rect.fromLTWH(0, 135, 1000, 30),
        dividers: List.generate(11, (i) => i / 10),
      );
      expect(validate(row.frames, '207').canApply, false);
      expect(validate(row.frames, '207').calculatedTotal, isNull);
    },
  );

  testWidgets(
    '207 is highlighted as matching, but not selected or confirmed automatically',
    (tester) async {
      final data = sample();
      await tester.pumpWidget(
        app(
          ScorePhotoReviewForm(
            candidate: ScorePhotoCandidate(
              frames: frames(data),
              printedTotal: null,
            ),
            numberCandidates: const ['247', '20', '207', '207'],
            onApply: (_) => fail('Cannot apply an unreviewed score'),
          ),
        ),
      );
      final dropdown = tester.widget<DropdownButton<String>>(
        find.descendant(
          of: find.byKey(const ValueKey('photo-total-candidates')),
          matching: find.byType(DropdownButton<String>),
        ),
      );
      expect(dropdown.items!.map((i) => i.value).toList(), [
        '207',
        '247',
        '20',
      ]);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('photo-total')))
            .controller!
            .text,
        '',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('photo-cumulative-0')))
            .data,
        'Acumulado calculado: 20',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('photo-cumulative-9')))
            .data,
        'Acumulado calculado: 207',
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('photo-apply')))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    '247 blocks a reviewed game; choosing 207 still needs fresh total confirmation',
    (tester) async {
      final data = sample();
      ReviewedPhotoScore? applied;
      await tester.pumpWidget(
        app(
          ScorePhotoReviewForm(
            candidate: ScorePhotoCandidate(
              frames: frames(data),
              printedTotal: '247',
            ),
            numberCandidates: const ['247', '207'],
            onApply: (score) => applied = score,
          ),
        ),
      );
      for (var f = 0; f < 10; f++) {
        await click(tester, 'photo-reviewed-$f');
      }
      await click(tester, 'photo-total-reviewed');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('photo-apply')))
            .onPressed,
        isNull,
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(ScorePhotoReviewForm)),
      )!;
      expect(find.text(l.photoScoreMismatch), findsOneWidget);
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const ValueKey('photo-total-candidates')),
          )
          .onChanged!('207');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('photo-total-reviewed')),
            )
            .value,
        false,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('photo-apply')))
            .onPressed,
        isNull,
      );
      await click(tester, 'photo-total-reviewed');
      await click(tester, 'photo-apply');
      expect(applied!.total, 207);
      expect(
        applied!.frames
            .map((f) => f.where((t) => t.isNotEmpty).toList())
            .toList(),
        frames(data),
      );
    },
  );
}
