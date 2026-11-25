import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/services/score_photo_evaluation.dart';

void main() {
  late Map<String, dynamic> ref, pred;
  setUp(() {
    ref = jsonDecode(
      File(
        'test/fixtures/score_photos/scoreboard_207_reference.json',
      ).readAsStringSync(),
    );
    pred = jsonDecode(
      File(
        'test/fixtures/score_photos/scoreboard_207_evaluation_demo.json',
      ).readAsStringSync(),
    );
  });
  test('perfect synthetic proposal is not native measured accuracy', () {
    final r = ScorePhotoEvaluation.compare(reference: ref, prediction: pred);
    expect(r['exact_game'], true);
    expect(r['exact_frames'], 10);
    expect(r['eligible_for_accuracy_claim'], false);
  });
  test('incorrect coherent game is explicitly detected', () {
    pred['frames'] = List.generate(10, (_) => ['9', '-']);
    pred['printed_total'] = '90';
    final r = ScorePhotoEvaluation.compare(reference: ref, prediction: pred);
    expect(r['structurally_coherent'], true);
    expect(r['coherent_but_wrong'], true);
    expect(r['exact_game'], false);
  });
  test('missing proposal counts lost throws without claiming success', () {
    pred['frames'] = null;
    pred['printed_total'] = null;
    final r = ScorePhotoEvaluation.compare(reference: ref, prediction: pred);
    expect(r['correct_throws'], 0);
    expect(r['extra_throws'], 0);
    expect(r['exact_frames'], 0);
    expect(r['structurally_coherent'], false);
  });
  test('extra throws and handicap total count as errors', () {
    (pred['frames'] as List)[1] = ['X', '8'];
    pred['printed_total'] = '247';
    final r = ScorePhotoEvaluation.compare(reference: ref, prediction: pred);
    expect(r['extra_throws'], 1);
    expect(r['total_matches'], false);
    expect(r['exact_game'], false);
  });
  test('wrong image hash or invalid reference is rejected', () {
    pred['image_sha256'] = '0' * 64;
    expect(
      () => ScorePhotoEvaluation.compare(reference: ref, prediction: pred),
      throwsFormatException,
    );
    pred['image_sha256'] = ref['image_sha256'];
    ref['scratch_total'] = 247;
    expect(
      () => ScorePhotoEvaluation.compare(reference: ref, prediction: pred),
      throwsFormatException,
    );
  });
  test(
    'native evidence still requires independently human confirmed reference',
    () {
      pred['evidence'] = 'native_ocr';
      expect(
        ScorePhotoEvaluation.compare(
          reference: ref,
          prediction: pred,
        )['eligible_for_accuracy_claim'],
        false,
      );
      ref['review_status'] = 'human_confirmed';
      expect(
        ScorePhotoEvaluation.compare(
          reference: ref,
          prediction: pred,
        )['eligible_for_accuracy_claim'],
        true,
      );
    },
  );
}
