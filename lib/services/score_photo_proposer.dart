import 'dart:math' as math;
import 'dart:ui';
import 'score_photo_reader.dart';
import 'score_photo_review.dart';

class ScorePhotoProposal {
  final Rect row;
  final List<double> dividers;
  final List<List<String>> frames;
  final List<String> rawCells;
  final List<int?> observedCumulative;
  final bool ambiguousColumns;
  const ScorePhotoProposal({
    required this.row,
    required this.dividers,
    required this.frames,
    required this.rawCells,
    required this.observedCumulative,
    required this.ambiguousColumns,
  });
  String? get printedTotal => observedCumulative[9]?.toString();
}

/// Conservative layout interpretation of positioned OCR, never of a flat list
/// of score numbers. Supported first layout: headers 1..10, throws below them,
/// cumulative scores under the throws. Unsupported layouts remain manual.
class ScorePhotoProposer {
  List<ScorePhotoProposal> propose(ScorePhotoDocument document) {
    if (!document.size.width.isFinite ||
        !document.size.height.isFinite ||
        document.size.width <= 0 ||
        document.size.height <= 0 ||
        document.symbols.length > 6000 ||
        document.elements.length > 3000)
      return [];
    final wordSets = [
      if (document.elements.isNotEmpty) document.elements,
      _joinSymbols(document.symbols),
    ];
    final headers = <List<ScorePhotoToken>>[];
    for (final words in wordSets) {
      for (final band in _bands(words)) {
        final numbers =
            band
                .where((t) => RegExp(r'^([1-9]|10)$').hasMatch(t.text.trim()))
                .toList()
              ..sort((a, b) => a.box.center.dx.compareTo(b.box.center.dx));
        for (var start = 0; start + 10 <= numbers.length; start++) {
          final sequence = numbers.sublist(start, start + 10);
          if (List.generate(
                10,
                (i) => sequence[i].text.trim() == '${i + 1}',
              ).every((v) => v) &&
              !headers.any(
                (old) =>
                    (old.first.box.center - sequence.first.box.center)
                        .distance <
                    sequence.first.box.height * .2,
              ))
            headers.add(sequence);
        }
      }
    }
    final shotBands = _bands(document.symbols);
    final groups = <List<_Layout>>[];
    for (final header in headers.take(8)) {
      for (final band in shotBands) {
        final y = _median(band.map((t) => t.box.center.dy));
        final bottom = header.map((t) => t.box.bottom).reduce(math.max);
        if (y <= bottom + header.first.box.height * .2) continue;
        final variants = <_Layout>[];
        // Compare text alignments, not the resulting score. There is no
        // correction of O/0, I/slash, inferred strike, or total-driven search.
        for (final anchor in [2, 1, 0]) {
          final points = header
              .map(
                (t) => anchor == 2
                    ? t.box.right
                    : anchor == 1
                    ? t.box.center.dx
                    : t.box.left,
              )
              .toList();
          final pitch = _median(
            List.generate(8, (i) => points[i + 1] - points[i]),
          );
          if (pitch <= 0 ||
              List.generate(
                9,
                (i) =>
                    ((points[i + 1] - points[i]) - pitch).abs() > pitch * .35,
              ).any((v) => v))
            continue;
          final labels = wordSets
              .expand((set) => set)
              .where(
                (t) =>
                    t.box.right < header.first.box.left &&
                    RegExp(r'[A-Za-z]').allMatches(t.text).length >= 2 &&
                    !RegExp(r'^[0-9Xx/-]+$').hasMatch(t.text),
              );
          final nearby = band
              .where(
                (t) =>
                    t.box.center.dx >= points.first - pitch * 1.3 &&
                    t.box.center.dx <= points.last + pitch * .4 &&
                    !labels.any((label) => label.box.contains(t.box.center)),
              )
              .toList();
          if (nearby.length < 8) continue;
          for (final offset in [
            .15,
            .25,
            .35,
            .5,
            .6,
            .65,
            .7,
            .75,
            .8,
            .85,
            .9,
            .95,
          ]) {
            final edges = [
              ...points.map((p) => p - offset * pitch),
              points.last + (1 - offset) * pitch,
            ];
            if (edges.first < 0 ||
                edges.last > document.size.width ||
                List.generate(
                  10,
                  (i) => edges[i] >= edges[i + 1],
                ).any((v) => v))
              continue;
            final top = nearby.map((t) => t.box.top).reduce(math.min);
            final low = nearby.map((t) => t.box.bottom).reduce(math.max);
            if (top >= document.size.height || low <= 0) continue;
            final padding = (low - top) * .08;
            final row = Rect.fromLTRB(
              edges.first,
              math.max(0, top - padding),
              edges.last,
              math.min(document.size.height, low + padding),
            );
            final dividers = edges
                .map((x) => (x - edges.first) / row.width)
                .toList();
            dividers[0] = 0;
            dividers[10] = 1;
            final parsed = ScorePhotoRow.extract(
              tokens: nearby,
              row: row,
              dividers: dividers,
            );
            final occupied = parsed.frames
                .where((f) => f.any((v) => v.isNotEmpty))
                .length;
            final valid = List.generate(
              10,
              (i) =>
                  ScorePhotoCandidate.frameProblem(
                    parsed.frames[i],
                    index: i,
                  ) ==
                  null,
            ).where((v) => v).length;
            if (occupied < 8 || valid < 6) continue;
            final covered = nearby
                .where(
                  (t) => List.generate(
                    10,
                    (i) =>
                        t.box.left >= edges[i] && t.box.right <= edges[i + 1],
                  ).any((v) => v),
                )
                .length;
            variants.add(_Layout(row, dividers, parsed, valid, covered));
          }
        }
        for (final variant in variants) {
          final same = groups.where(
            (g) =>
                (g.first.row.center.dy - variant.row.center.dy).abs() <
                    math.min(g.first.row.height, variant.row.height) * .4 &&
                g.first.row.intersect(variant.row).width >
                    math.min(g.first.row.width, variant.row.width) * .8,
          );
          if (same.isEmpty) {
            groups.add([variant]);
          } else {
            same.first.add(variant);
          }
        }
      }
    }
    final proposals = <ScorePhotoProposal>[];
    for (final group in groups) {
      group.sort(
        (a, b) => a.covered == b.covered
            ? b.valid.compareTo(a.valid)
            : b.covered.compareTo(a.covered),
      );
      final best = group.first;
      final tied = group.where(
        (g) => g.covered == best.covered && g.valid == best.valid,
      );
      final interpretations = tied
          .map((g) => g.parsed.frames.map((f) => f.join('|')).join(';'))
          .toSet();
      proposals.add(
        ScorePhotoProposal(
          row: best.row,
          dividers: List.unmodifiable(best.dividers),
          frames: best.parsed.frames,
          rawCells: best.parsed.rawCells,
          observedCumulative: readCumulative(document, best.row, best.dividers),
          ambiguousColumns: interpretations.length > 1,
        ),
      );
    }
    proposals.sort(
      (a, b) => a.row.top == b.row.top
          ? a.row.left.compareTo(b.row.left)
          : a.row.top.compareTo(b.row.top),
    );
    // A printed cumulative row may itself look like numeric throws (18,27,...).
    // Exclude it only when its literal cells match an independently coherent
    // cumulative row of a complete proposal above. Never modify either reading.
    return proposals
        .where(
          (lower) => !proposals.any((upper) {
            if (identical(lower, upper) ||
                lower.row.center.dy <= upper.row.bottom ||
                lower.row.center.dy >
                    upper.row.bottom + upper.row.height * 2.5 ||
                lower.row.intersect(upper.row).width <
                    math.min(lower.row.width, upper.row.width) * .8)
              return false;
            final review = ScorePhotoCandidate(
              frames: upper.frames,
              printedTotal: upper.printedTotal,
            ).validate();
            if (review.calculatedTotal == null ||
                cumulativeMismatch(upper.observedCumulative, review))
              return false;
            var count = 0;
            for (var i = 0; i < 10; i++) {
              final value = upper.observedCumulative[i];
              if (value == null) continue;
              count++;
              if (lower.rawCells[i] != value.toString()) return false;
            }
            return count >= 5;
          }),
        )
        .take(16)
        .toList();
  }

  /// Reads the closest plausible cumulative row, independently of calculated
  /// scores. Never searches the entire photo for a number matching the total.
  static List<int?> readCumulative(
    ScorePhotoDocument document,
    Rect row,
    List<double> dividers,
  ) {
    final candidates = <(double, List<int?>)>[];
    final wordSets = [
      if (document.elements.isNotEmpty) document.elements,
      _joinSymbols(document.symbols),
    ];
    for (final words in wordSets) {
      for (final band in _bands(words)) {
        final y = _median(band.map((t) => t.box.center.dy));
        if (y <= row.bottom || y > row.bottom + row.height * 2.5) continue;
        final inLane = band
            .where(
              (t) =>
                  t.box.center.dx >= row.left && t.box.center.dx <= row.right,
            )
            .toList();
        if (inLane.any((t) => t.text.contains('X') || t.text.contains('/')))
          continue;
        final values = List<int?>.filled(10, null);
        for (var f = 0; f < 10; f++) {
          final left = row.left + dividers[f] * row.width;
          final right = row.left + dividers[f + 1] * row.width;
          final tokens = inLane
              .where(
                (t) =>
                    t.box.left >= left &&
                    t.box.right <= right &&
                    RegExp(r'^[0-9]{1,3}$').hasMatch(t.text.trim()),
              )
              .toList();
          if (tokens.length == 1) {
            final n = int.tryParse(tokens.single.text.trim());
            if (n != null && n <= 300) values[f] = n;
          }
        }
        if (values.whereType<int>().length >= 5 && values.last != null)
          candidates.add((y, values));
      }
    }
    if (candidates.isEmpty) return List<int?>.filled(10, null);
    candidates.sort((a, b) => a.$1.compareTo(b.$1));
    final first = candidates.first;
    // Conflicting word/symbol readings at the same height remain unknown.
    if (candidates.any(
      (c) =>
          (c.$1 - first.$1).abs() < row.height * .25 &&
          List.generate(
            10,
            (i) =>
                c.$2[i] != null &&
                first.$2[i] != null &&
                c.$2[i] != first.$2[i],
          ).any((v) => v),
    ))
      return List<int?>.filled(10, null);
    return List.unmodifiable(first.$2);
  }

  static bool cumulativeMismatch(
    List<int?> observed,
    ScorePhotoReview review,
  ) =>
      review.calculatedTotal != null &&
      List.generate(
        10,
        (i) =>
            observed[i] != null &&
            observed[i] != review.calculatedFrameTotals[i],
      ).any((v) => v);

  static double _median(Iterable<double> values) {
    final sorted = values.toList()..sort();
    return sorted[sorted.length ~/ 2];
  }

  static List<List<ScorePhotoToken>> _bands(List<ScorePhotoToken> items) {
    final sorted =
        items
            .where((t) => t.box.isFinite && t.box.width > 0 && t.box.height > 0)
            .toList()
          ..sort((a, b) => a.box.center.dy.compareTo(b.box.center.dy));
    final bands = <List<ScorePhotoToken>>[];
    for (final token in sorted) {
      final match = bands.reversed
          .take(8)
          .where(
            (band) =>
                (token.box.center.dy -
                        _median(band.map((v) => v.box.center.dy)))
                    .abs() <=
                math.min(
                      token.box.height,
                      _median(band.map((v) => v.box.height)),
                    ) *
                    .55,
          );
      if (match.isEmpty) {
        bands.add([token]);
      } else {
        match.first.add(token);
      }
    }
    return bands;
  }

  static List<ScorePhotoToken> _joinSymbols(List<ScorePhotoToken> symbols) {
    final result = <ScorePhotoToken>[];
    for (final band in _bands(symbols)) {
      band.sort((a, b) => a.box.left.compareTo(b.box.left));
      String? text;
      Rect? box;
      void flush() {
        if (text != null) result.add(ScorePhotoToken(text!, box!));
        text = null;
        box = null;
      }

      for (final token in band) {
        if (box != null &&
            token.box.left - box!.right >
                math.min(token.box.height, box!.height) * .3)
          flush();
        text = (text ?? '') + token.text;
        box = box == null ? token.box : box!.expandToInclude(token.box);
      }
      flush();
    }
    return result;
  }
}

class _Layout {
  final Rect row;
  final List<double> dividers;
  final ScorePhotoRow parsed;
  final int valid, covered;
  const _Layout(this.row, this.dividers, this.parsed, this.valid, this.covered);
}
