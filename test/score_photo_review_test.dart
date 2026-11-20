import 'dart:math';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/services/score_photo_review.dart';
import 'package:bolometro/services/score_photo_reader.dart';

final allReviewed = Set.of(List.generate(10, (i) => i));
List<List<String>> perfect() => [
  ...List.generate(9, (_) => <String>['X']),
  ['X', 'X', 'X'],
];
ScorePhotoReview checked(List<List<String>> frames, String? total) =>
    ScorePhotoCandidate(
      frames: frames,
      printedTotal: total,
    ).validate(reviewedFrames: allReviewed, totalReviewed: true);

void main() {
  test('A perfect game is not applicable without explicit human review', () {
    final review = ScorePhotoCandidate(
      frames: perfect(),
      printedTotal: '300',
    ).validate();
    expect(review.calculatedTotal, 300);
    expect(review.canApply, false);
    expect(() => review.requireReviewedScore(), throwsStateError);
    expect(checked(perfect(), '300').requireReviewedScore().total, 300);
  });

  test('Missing or inconsistent printed totals block application', () {
    for (final value in [
      null,
      '',
      '301',
      '-1',
      '3OO',
      '299',
      '300 HC',
      '30.0',
    ]) {
      expect(checked(perfect(), value).canApply, false, reason: '$value');
    }
    expect(checked(perfect(), ' 300 ').canApply, true);
  });

  test('Zero is a valid complete gutter game, not a missing observation', () {
    final frames = List.generate(10, (_) => ['-', '-']);
    expect(checked(frames, '0').calculatedTotal, 0);
    expect(checked(frames, '0').canApply, true);
    frames[2] = ['', ''];
    expect(checked(frames, '0').calculatedTotal, isNull);
  });

  test(
    'No reconstruction from cumulative scores, ambiguous OCR or missing throws',
    () {
      for (final tokens in [
        ['30'],
        ['O', '/'],
        ['8', '2'],
        ['X', '3'],
        ['/', '5'],
        ['8', '?'],
        ['', '5'],
        ['8'],
        ['9', '9'],
        ['F', '/'],
      ]) {
        final frames = perfect()..[0] = tokens;
        expect(
          checked(frames, '300').calculatedTotal,
          isNull,
          reason: '$tokens',
        );
      }
      expect(checked([], '300').canApply, false);
      expect(
        checked([
          ...perfect(),
          ['X'],
        ], '300').canApply,
        false,
      );
    },
  );

  test('Tenth frame validates rack reset and bonus throws', () {
    for (final tokens in [
      ['X', '/', 'X'],
      ['X', 'X', '/'],
      ['X', '7', 'X'],
      ['X', '7', '3'],
      ['7', '2', 'X'],
      ['7', '/', '/'],
      ['X', 'X'],
      ['7', '/'],
    ]) {
      expect(
        checked(perfect()..[9] = tokens, '300').calculatedTotal,
        isNull,
        reason: '$tokens',
      );
    }
    for (final entry in <List<String>, int>{
      ['X', '7', '/']: 20,
      ['X', '-', '/']: 20,
      ['7', '/', 'X']: 20,
      ['X', 'X', 'X']: 30,
      ['7', '2', '']: 9,
      ['X', '7', '2']: 19,
    }.entries) {
      final frames = [
        ...List.generate(9, (_) => ['0', '0']),
        entry.key,
      ];
      expect(
        checked(frames, entry.value.toString()).canApply,
        true,
        reason: entry.key.toString(),
      );
    }
  });

  test(
    'Input is copied, normalized and immutable without guessing characters',
    () {
      final original = perfect()..[0] = [' x ', '', ''];
      final candidate = ScorePhotoCandidate(
        frames: original,
        printedTotal: '300',
      );
      original[0][0] = '?';
      expect(candidate.frames[0][0], 'X');
      expect(() => candidate.frames[0].add('3'), throwsUnsupportedError);
      expect(
        () => candidate.validate(reviewedFrames: {10}),
        throwsArgumentError,
      );
    },
  );

  test(
    '500 synthetic valid games match an independent flat-roll scoring oracle',
    () {
      final random = Random(312);
      for (var trial = 0; trial < 500; trial++) {
        final frames = <List<String>>[];
        final rolls = <int>[];
        for (var f = 0; f < 10; f++) {
          final first = random.nextInt(11);
          final row = <String>[first == 10 ? 'X' : '$first'];
          rolls.add(first);
          if (f < 9) {
            if (first != 10) {
              final second = random.nextInt(11 - first);
              rolls.add(second);
              row.add(first + second == 10 ? '/' : '$second');
            }
          } else if (first == 10) {
            final second = random.nextInt(11);
            final third = random.nextInt(second == 10 ? 11 : 11 - second);
            rolls.addAll([second, third]);
            row.add(second == 10 ? 'X' : '$second');
            row.add(
              second == 10
                  ? (third == 10 ? 'X' : '$third')
                  : second + third == 10
                  ? '/'
                  : '$third',
            );
          } else {
            final second = random.nextInt(11 - first);
            rolls.add(second);
            row.add(first + second == 10 ? '/' : '$second');
            if (first + second == 10) {
              final third = random.nextInt(11);
              rolls.add(third);
              row.add(third == 10 ? 'X' : '$third');
            }
          }
          frames.add(row);
        }
        var total = 0;
        var index = 0;
        for (var f = 0; f < 10; f++) {
          if (rolls[index] == 10) {
            total += 10 + rolls[index + 1] + rolls[index + 2];
            index++;
          } else if (rolls[index] + rolls[index + 1] == 10) {
            total += 10 + rolls[index + 2];
            index += 2;
          } else {
            total += rolls[index] + rolls[index + 1];
            index += 2;
          }
        }
        final review = checked(frames, '$total');
        expect(review.calculatedTotal, total, reason: '$frames');
      expect(review.calculatedFrameTotals.last, total, reason: '$frames');
        expect(review.canApply, true, reason: '$frames');
      }
    },
  );

  test('Spatial extraction excludes cumulative totals and other players', () {
    final tokens = <ScorePhotoToken>[];
    for (var i = 0; i < 10; i++) {
      tokens.add(
        ScorePhotoToken(
          i == 9 ? 'XXX' : 'X',
          Rect.fromLTWH(i * 100 + 20, 110, 30, 20),
        ),
      );
      tokens.add(
        ScorePhotoToken('300', Rect.fromLTWH(i * 100 + 20, 160, 30, 20)),
      );
      tokens.add(ScorePhotoToken('9', Rect.fromLTWH(i * 100 + 20, 20, 20, 20)));
    }
    final row = ScorePhotoRow.extract(
      tokens: tokens,
      row: const Rect.fromLTWH(0, 100, 1000, 40),
      dividers: List.generate(11, (i) => i / 10),
    );
    expect(checked(row.frames, '300').canApply, true);
  });

  test(
    'Cross-frame OCR elements are ambiguous rather than split by guesswork',
    () {
      final row = ScorePhotoRow.extract(
        tokens: [const ScorePhotoToken('XX', Rect.fromLTWH(90, 10, 30, 20))],
        row: const Rect.fromLTWH(0, 0, 1000, 50),
        dividers: List.generate(11, (i) => i / 10),
      );
      expect(row.frames[0][0], '?');
      expect(row.frames[1][0], '?');
      expect(checked(row.frames, '300').canApply, false);
    },
  );

  test(
    'Dividers can be adjusted and invalid/non-finite regions are rejected',
    () {
      expect(
        () => ScorePhotoRow.extract(
          tokens: [],
          row: Rect.zero,
          dividers: List.generate(11, (i) => i / 10),
        ),
        throwsArgumentError,
      );
      final dividers = List.generate(11, (i) => i / 10)..[1] = double.nan;
      expect(
        () => ScorePhotoRow.extract(
          tokens: [],
          row: const Rect.fromLTWH(0, 0, 1000, 50),
          dividers: dividers,
        ),
        throwsArgumentError,
      );
      final row = ScorePhotoRow.extract(
        tokens: [const ScorePhotoToken('X', Rect.fromLTWH(105, 10, 10, 20))],
        row: const Rect.fromLTWH(0, 0, 1000, 50),
        dividers: List.generate(11, (i) => i / 10)..[1] = .12,
      );
      expect(row.frames[0][0], 'X');
    },
  );
}
