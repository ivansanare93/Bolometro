import '../utils/registro_tiros_utils.dart';

enum ScorePhotoIssueCode {
  frameCount,
  invalidFrame,
  missingPrintedTotal,
  invalidPrintedTotal,
  totalMismatch,
  humanReviewRequired,
}

enum ScorePhotoFrameProblemCode {
  missingThrow,
  unknownSymbol,
  unexpectedThrow,
  invalidSpare,
  pinSum,
  spareExpected,
}

class ScorePhotoFrameProblem {
  final ScorePhotoFrameProblemCode code;
  final int throwIndex;
  const ScorePhotoFrameProblem(this.code, this.throwIndex);
}

/// Review data only: this class neither reads a photograph nor persists a game.
/// Frame positions must come from an explicit layout/row selection, never from
/// a flat sequence of OCR numbers that could include cumulative scores.
class ScorePhotoCandidate {
  final List<List<String>> frames;
  final String? printedTotal;

  ScorePhotoCandidate({
    required List<List<String>> frames,
    required this.printedTotal,
  }) : frames = List.unmodifiable(
         frames.map(
           (frame) => List<String>.unmodifiable(
             frame.map((token) => token.trim().toUpperCase()),
           ),
         ),
       );

  ScorePhotoReview validate({
    Set<int> reviewedFrames = const {},
    bool totalReviewed = false,
  }) {
    if (reviewedFrames.any((i) => i < 0 || i > 9)) {
      throw ArgumentError.value(reviewedFrames, 'reviewedFrames');
    }
    final issues = <ScorePhotoIssue>[];
    if (frames.length != 10) {
      issues.add(const ScorePhotoIssue(ScorePhotoIssueCode.frameCount));
    }
    for (var i = 0; i < frames.length && i < 10; i++) {
      if (!_validFrame(frames[i], last: i == 9)) {
        issues.add(
          ScorePhotoIssue(ScorePhotoIssueCode.invalidFrame, frameIndex: i),
        );
      }
    }
    final throwsValid = issues.isEmpty;
    final calculatedTotal = throwsValid
        ? calcularPuntuacionPartida(interpretarFrames(frames))
        : null;
    final rawTotal = printedTotal?.trim();
    final total = rawTotal != null && RegExp(r'^[0-9]{1,3}$').hasMatch(rawTotal)
        ? int.tryParse(rawTotal)
        : null;
    if (rawTotal == null || rawTotal.isEmpty) {
      issues.add(
        const ScorePhotoIssue(ScorePhotoIssueCode.missingPrintedTotal),
      );
    } else if (total == null || total < 0 || total > 300) {
      issues.add(
        const ScorePhotoIssue(ScorePhotoIssueCode.invalidPrintedTotal),
      );
    } else if (calculatedTotal != null && calculatedTotal != total) {
      issues.add(const ScorePhotoIssue(ScorePhotoIssueCode.totalMismatch));
    }
    if (reviewedFrames.length != 10 || !totalReviewed) {
      issues.add(
        const ScorePhotoIssue(ScorePhotoIssueCode.humanReviewRequired),
      );
    }
    return ScorePhotoReview._(
      frames,
      calculatedTotal,
      total,
      List.unmodifiable(issues),
      List.unmodifiable(
        throwsValid
            ? calcularPuntuacionPorFrame(
                interpretarFrames(frames),
                permitirNulos: true,
              )
            : List<int?>.filled(10, null),
      ),
    );
  }

  /// Explains invalid cells without changing the established acceptance rules.
  static ScorePhotoFrameProblem? frameProblem(
    List<String> raw, {
    required int index,
  }) {
    if (index < 0 || index > 9) throw RangeError.range(index, 0, 9);
    final last = index == 9;
    final values = raw.map((t) => t.trim().toUpperCase()).toList();
    if (_validFrame(values, last: last)) return null;
    final limit = last ? 3 : 2;
    for (var i = limit; i < values.length; i++) {
      if (values[i].isNotEmpty)
        return ScorePhotoFrameProblem(
          ScorePhotoFrameProblemCode.unexpectedThrow,
          i,
        );
    }
    final t = List.generate(limit, (i) => i < values.length ? values[i] : '');
    for (var i = 0; i < t.length; i++) {
      if (t[i].isNotEmpty &&
          t[i] != 'X' &&
          t[i] != '/' &&
          _pins(t[i]) == null) {
        return ScorePhotoFrameProblem(
          ScorePhotoFrameProblemCode.unknownSymbol,
          i,
        );
      }
    }
    if (t[0].isEmpty)
      return const ScorePhotoFrameProblem(
        ScorePhotoFrameProblemCode.missingThrow,
        0,
      );
    if (t[0] == '/')
      return const ScorePhotoFrameProblem(
        ScorePhotoFrameProblemCode.invalidSpare,
        0,
      );
    if (!last && t[0] == 'X')
      return const ScorePhotoFrameProblem(
        ScorePhotoFrameProblemCode.unexpectedThrow,
        1,
      );
    if (t[1].isEmpty)
      return const ScorePhotoFrameProblem(
        ScorePhotoFrameProblemCode.missingThrow,
        1,
      );
    if (t[1] == '/' && t[0] == 'X')
      return const ScorePhotoFrameProblem(
        ScorePhotoFrameProblemCode.invalidSpare,
        1,
      );
    if (t[1] == 'X' && t[0] != 'X')
      return const ScorePhotoFrameProblem(
        ScorePhotoFrameProblemCode.unexpectedThrow,
        1,
      );
    if (last && t[0] != 'X' && t[1] != '/' && t[2].isNotEmpty) {
      return const ScorePhotoFrameProblem(
        ScorePhotoFrameProblemCode.unexpectedThrow,
        2,
      );
    }
    if (last && (t[0] == 'X' || t[1] == '/') && t[2].isEmpty) {
      return const ScorePhotoFrameProblem(
        ScorePhotoFrameProblemCode.missingThrow,
        2,
      );
    }
    if (last && t[2] == '/' && (t[1] == 'X' || t[1] == '/')) {
      return const ScorePhotoFrameProblem(
        ScorePhotoFrameProblemCode.invalidSpare,
        2,
      );
    }
    final a = t[0] == 'X' && last ? t[1] : t[0];
    final b = t[0] == 'X' && last ? t[2] : t[1];
    final position = t[0] == 'X' && last ? 2 : 1;
    if (b == 'X')
      return ScorePhotoFrameProblem(
        ScorePhotoFrameProblemCode.unexpectedThrow,
        position,
      );
    if (_pins(a) != null && _pins(b) != null) {
      return ScorePhotoFrameProblem(
        _pins(a)! + _pins(b)! == 10
            ? ScorePhotoFrameProblemCode.spareExpected
            : ScorePhotoFrameProblemCode.pinSum,
        position,
      );
    }
    return ScorePhotoFrameProblem(
      ScorePhotoFrameProblemCode.unknownSymbol,
      position,
    );
  }

  static int? _pins(String token) {
    if (token == '-') return 0;
    return RegExp(r'^[0-9]$').hasMatch(token) ? int.parse(token) : null;
  }

  static bool _validFrame(List<String> raw, {required bool last}) {
    final limit = last ? 3 : 2;
    // Existing editors pad normal frames to three slots. Empty padding is safe.
    if (raw.skip(limit).any((token) => token.isNotEmpty)) return false;
    final tokens = List.generate(limit, (i) => i < raw.length ? raw[i] : '');
    final first = tokens[0];
    final second = tokens[1];
    if (first != 'X' && _pins(first) == null) return false;
    if (!last) {
      if (first == 'X') return second.isEmpty;
      return second == '/' ||
          (_pins(second) != null && _pins(first)! + _pins(second)! < 10);
    }
    final third = tokens[2];
    if (first != 'X') {
      if (second == '/') return third == 'X' || _pins(third) != null;
      return _pins(second) != null &&
          _pins(first)! + _pins(second)! < 10 &&
          third.isEmpty;
    }
    if (second == 'X') return third == 'X' || _pins(third) != null;
    if (_pins(second) == null) return false;
    return third == '/' ||
        (_pins(third) != null && _pins(second)! + _pins(third)! < 10);
  }
}

class ScorePhotoIssue {
  final ScorePhotoIssueCode code;

  /// Zero-based frame; null means an issue with the whole review.
  final int? frameIndex;

  const ScorePhotoIssue(this.code, {this.frameIndex});
}

class ScorePhotoReview {
  final List<List<String>> frames;
  final int? calculatedTotal;
  final int? printedTotal;
  final List<ScorePhotoIssue> issues;

  /// Calculated only for a complete, strictly valid game; never fills unknown
  /// observations or reconstructs throws from the printed cumulative scores.
  final List<int?> calculatedFrameTotals;

  const ScorePhotoReview._(
    this.frames,
    this.calculatedTotal,
    this.printedTotal,
    this.issues,
    this.calculatedFrameTotals,
  );

  bool get canApply => issues.isEmpty;

  /// Produces only score data. The normal game form must supply personal ball
  /// assignments, date and notes, and still require its normal Save action.
  ReviewedPhotoScore requireReviewedScore() {
    if (!canApply) {
      throw StateError('Photo score requires correction and human review');
    }
    return ReviewedPhotoScore._(frames, calculatedTotal!);
  }
}

class ReviewedPhotoScore {
  final List<List<String>> frames;
  final int total;

  const ReviewedPhotoScore._(this.frames, this.total);
}
