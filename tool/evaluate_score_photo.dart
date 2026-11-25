import 'dart:convert';
import 'dart:io';
import '../lib/services/score_photo_evaluation.dart';

/// Offline report evaluator. No images, Firebase or network access.
void main(List<String> args) {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/evaluate_score_photo.dart reference.json prediction.json report.json',
    );
    exitCode = 64;
    return;
  }
  try {
    final reference =
        jsonDecode(File(args[0]).readAsStringSync()) as Map<String, dynamic>;
    final prediction =
        jsonDecode(File(args[1]).readAsStringSync()) as Map<String, dynamic>;
    final report = ScorePhotoEvaluation.compare(
      reference: reference,
      prediction: prediction,
    );
    File(
      args[2],
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
    stdout.writeln(
      'Report written. Evidence: ${report['evidence']}; eligible: ${report['eligible_for_accuracy_claim']}',
    );
  } catch (_) {
    stderr.writeln(
      'Cannot evaluate: check reference, prediction and image identity.',
    );
    exitCode = 1;
  }
}
