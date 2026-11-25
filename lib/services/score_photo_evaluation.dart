import 'score_photo_review.dart';

/// Compares uncorrected OCR proposals with separately reviewed transcription.
/// Does not interpret images or pick a proposal using the expected score.
class ScorePhotoEvaluation {
  static List<List<String>> frames(dynamic raw) {
    if (raw is! List || raw.length != 10)
      throw const FormatException('Expected ten frames');
    return raw.map<List<String>>((f) {
      if (f is! List || f.length > 3 || f.any((v) => v is! String))
        throw const FormatException('Invalid throws');
      final result = f
          .cast<String>()
          .map((v) => v.trim().toUpperCase())
          .toList();
      while (result.isNotEmpty && result.last.isEmpty) {
        result.removeLast();
      }
      return result;
    }).toList();
  }

  static Map<String, dynamic> compare({
    required Map<String, dynamic> reference,
    required Map<String, dynamic> prediction,
  }) {
    final expected = frames(reference['frames']);
    final total = reference['scratch_total'];
    if (total is! int ||
        total < 0 ||
        total > 300 ||
        !ScorePhotoCandidate(frames: expected, printedTotal: '$total')
            .validate(
              reviewedFrames: Set.from(List.generate(10, (i) => i)),
              totalReviewed: true,
            )
            .canApply) {
      throw const FormatException(
        'Reference must contain coherent complete throws and scratch total',
      );
    }
    if (prediction['evidence'] != 'native_ocr' &&
        prediction['evidence'] != 'synthetic') {
      throw const FormatException(
        'Prediction evidence must identify native or synthetic OCR',
      );
    }
    if (reference['id'] != prediction['reference_id'] ||
        prediction['image_sha256'] != reference['image_sha256'] ||
        reference['image_sha256'] is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(reference['image_sha256'])) {
      throw const FormatException('Reference/image mismatch');
    }
    final output = prediction['frames'] == null
        ? null
        : frames(prediction['frames']);
    final rawTotal = prediction['printed_total'];
    if (rawTotal != null && rawTotal is! String)
      throw const FormatException('Printed total must retain OCR text');
    var observed = 0,
        correct = 0,
        expectedCount = 0,
        extra = 0,
        exactFrames = 0;
    for (var f = 0; f < 10; f++) {
      final actual = output?[f] ?? <String>[];
      expectedCount += expected[f].length;
      if (actual.length == expected[f].length &&
          List.generate(
            actual.length,
            (i) => actual[i] == expected[f][i],
          ).every((v) => v))
        exactFrames++;
      for (var t = 0; t < expected[f].length; t++) {
        final value = t < actual.length ? actual[t] : '';
        if (value.isNotEmpty) observed++;
        if (value == expected[f][t]) correct++;
      }
      for (var t = expected[f].length; t < actual.length; t++) {
        if (actual[t].isNotEmpty) extra++;
      }
    }
    final coherent =
        output != null &&
        ScorePhotoCandidate(frames: output, printedTotal: rawTotal as String?)
            .validate(
              reviewedFrames: Set.from(List.generate(10, (i) => i)),
              totalReviewed: true,
            )
            .canApply;
    final exact =
        exactFrames == 10 &&
        rawTotal != null &&
        int.tryParse(rawTotal as String) == total;
    return {
      'reference_id': reference['id'],
      'evidence': prediction['evidence'],
      'reference_review_status': reference['review_status'] ?? 'pending',
      'eligible_for_accuracy_claim':
          reference['review_status'] == 'human_confirmed' &&
          prediction['evidence'] == 'native_ocr',
      'proposal_present': output != null,
      'expected_throws': expectedCount,
      'observed_expected_slots': observed,
      'correct_throws': correct,
      'incorrect_or_missing_throws': expectedCount - correct,
      'extra_throws': extra,
      'exact_frames': exactFrames,
      'total_matches':
          rawTotal != null && int.tryParse(rawTotal as String) == total,
      'exact_game': exact,
      'structurally_coherent': coherent,
      'coherent_but_wrong': coherent && !exact,
      'note':
          'Coherence is not OCR accuracy. No photo names or full OCR text are included.',
    };
  }
}
