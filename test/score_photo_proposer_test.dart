import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/services/score_photo_proposer.dart';
import 'package:bolometro/services/score_photo_review.dart';
import 'package:bolometro/services/score_photo_reader.dart';
import 'support/score_photo_proposal_fixture.dart';

void main() {
  for (final alignment in ['left', 'center', 'right']) {
    for (final scale in [.5, 1.0, 2.0]) {
      test(
        'Header alignment $alignment at scale $scale proposes observed throws and total',
        () {
          final proposals = ScorePhotoProposer().propose(
            proposalFixture(alignment: alignment, scale: scale),
          );
          expect(proposals.length, 1);
          final p = proposals.single;
          expect(
            p.frames.map((f) => f.where((v) => v.isNotEmpty).join()).toList(),
            ['9/', 'X', 'X', '9/', 'X', '9/', '9/', 'X', '6/', '9/X'],
          );
          expect(p.printedTotal, '207');
          expect(p.observedCumulative, [
            20,
            49,
            69,
            89,
            109,
            128,
            148,
            168,
            187,
            207,
          ]);
          expect(p.ambiguousColumns, false);
        },
      );
    }
  }
  test(
    'Multiple players produce separate proposals, never a score-based winner',
    () {
      final proposals = ScorePhotoProposer().propose(
        proposalFixture(players: 2),
      );
      expect(proposals.length, 2);
      expect(proposals.first.row.top, lessThan(proposals.last.row.top));
    },
  );
  test('Missing headers do not manufacture a complete game from totals', () {
    expect(
      ScorePhotoProposer().propose(proposalFixture(headers: false)),
      isEmpty,
    );
  });
  test('Old OCR documents without elements use positioned symbols', () {
    final p = ScorePhotoProposer()
        .propose(proposalFixture(includeElements: false))
        .single;
    expect(p.printedTotal, '207');
    expect(p.ambiguousColumns, false);
  });
  test(
    'Wrong printed total is kept as observed, not replaced with matching external 207',
    () {
      final p = ScorePhotoProposer()
          .propose(
            proposalFixture(
              cumulative: [20, 49, 69, 89, 109, 128, 148, 168, 187, 247],
            ),
          )
          .single;
      expect(p.printedTotal, '247');
      final review = ScorePhotoCandidate(
        frames: p.frames,
        printedTotal: p.printedTotal,
      ).validate();
      expect(review.calculatedTotal, 207);
      expect(
        review.issues.map((e) => e.code),
        contains(ScorePhotoIssueCode.totalMismatch),
      );
    },
  );
  test(
    'Intermediate cumulative error remains visible even when final total matches',
    () {
      final p = ScorePhotoProposer()
          .propose(
            proposalFixture(
              cumulative: [20, 49, 69, 89, 109, 129, 148, 168, 187, 207],
            ),
          )
          .single;
      final review = ScorePhotoCandidate(
        frames: p.frames,
        printedTotal: p.printedTotal,
      ).validate();
      expect(review.calculatedTotal, 207);
      expect(
        ScorePhotoProposer.cumulativeMismatch(p.observedCumulative, review),
        true,
      );
    },
  );
  test(
    'All open frames can be proposed without inventing strikes or spares',
    () {
      final p = ScorePhotoProposer()
          .propose(
            proposalFixture(
              throws_: List.generate(10, (_) => ['4', '5']),
              cumulative: List.generate(10, (i) => (i + 1) * 9),
            ),
          )
          .single;
      expect(p.printedTotal, '90');
      expect(p.frames.every((f) => f[0] == '4' && f[1] == '5'), true);
    },
  );
  test(
    'Unknown glyphs remain unknown instead of being changed to match a total',
    () {
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
      final p = ScorePhotoProposer()
          .propose(proposalFixture(throws_: values))
          .first;
      expect(p.frames[0][0], '?');
      expect(
        ScorePhotoCandidate(
          frames: p.frames,
          printedTotal: p.printedTotal,
        ).validate().calculatedTotal,
        isNull,
      );
    },
  );

  test('Player name to the left of frame one is not included as throws', () {
    final p = ScorePhotoProposer()
        .propose(proposalFixture(includeName: true))
        .single;
    expect(p.frames[0].where((v) => v.isNotEmpty).join(), '9/');
    expect(p.printedTotal, '207');
  });
  test(
    'A global matching number cannot replace a missing positioned cumulative row',
    () {
      final original = proposalFixture();
      final doc = ScorePhotoDocument(
        image: original.image,
        size: original.size,
        symbols: original.symbols.where((s) => s.box.center.dy < 200).toList(),
        elements: original.elements
            .where((s) => s.box.center.dy < 200)
            .toList(),
        numberCandidates: const ['207', '247'],
      );
      final p = ScorePhotoProposer().propose(doc).single;
      expect(p.printedTotal, isNull);
      expect(p.frames[0].where((v) => v.isNotEmpty).join(), '9/');
    },
  );
  test(
    'A zero game remains zero rather than being considered an empty game',
    () {
      final p = ScorePhotoProposer()
          .propose(
            proposalFixture(
              throws_: List.generate(10, (_) => ['0', '0']),
              cumulative: List.filled(10, 0),
            ),
          )
          .single;
      expect(p.printedTotal, '0');
      expect(
        ScorePhotoCandidate(
          frames: p.frames,
          printedTotal: p.printedTotal,
        ).validate().calculatedTotal,
        0,
      );
    },
  );
}
