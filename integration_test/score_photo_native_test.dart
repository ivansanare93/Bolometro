import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'support/score_photo_private_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bolometro/services/score_photo_reader.dart';
import 'package:bolometro/services/score_photo_review.dart';

/// Run only on an isolated emulator, never on a user's physical device.
/// Image bytes are compiled only into the integration-test APK and removed
/// from its test-only fixture afterwards. Normal lib/main.dart never imports it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const layout = String.fromEnvironment('SCORE_PHOTO_REVIEW_REGION');
  const expected = String.fromEnvironment('SCORE_PHOTO_EXPECTED_FRAMES');
  testWidgets(
    'native OCR of a privately supplied score photo',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();
      final directory = await (await getTemporaryDirectory()).createTemp(
        'score_native_',
      );
      try {
        final file = File('${directory.path}/input.jpeg');
        final bytes = base64Decode(scorePhotoTestBase64);
        await file.writeAsBytes(bytes, flush: true);
        expect(await file.length(), bytes.length);
        // ignore: avoid_print
        print(
          'PHOTO_OCR_INPUT_READY:${bytes.length};${Platform.operatingSystem}',
        );
        final document = await ScorePhotoReader().read(
          file.path,
          // ignore: avoid_print
          onStage: (stage) => print('PHOTO_OCR_STAGE:$stage'),
        );
        expect(document.symbols, isNotEmpty);
        final config = jsonDecode(layout) as Map<String, dynamic>;
        final row = Rect.fromLTRB(
          (config['left'] as num) * document.size.width,
          (config['top'] as num) * document.size.height,
          (config['right'] as num) * document.size.width,
          (config['bottom'] as num) * document.size.height,
        );
        final dividers = (config['dividers'] as List)
            .map((v) => (v as num).toDouble())
            .toList();
        final extracted = ScorePhotoRow.extract(
          tokens: document.symbols,
          row: row,
          dividers: dividers,
        );
        final review = ScorePhotoCandidate(
          frames: extracted.frames,
          printedTotal: null,
        ).validate();
        final expectedFrames = expected.isEmpty
            ? null
            : jsonDecode(expected) as List;
        final report = {
          'source': 'ML Kit native Android execution',
          'width': document.size.width,
          'height': document.size.height,
          'number_candidates': document.numberCandidates,
          'region_pixels': [row.left, row.top, row.right, row.bottom],
          'dividers': dividers,
          'row_tokens': document.symbols
              .where((s) => row.contains(s.box.center))
              .map(
                (s) => {
                  'text': s.text,
                  'box': [s.box.left, s.box.top, s.box.right, s.box.bottom],
                  'confidence': s.confidence,
                },
              )
              .toList(),
          'raw_cells': extracted.rawCells,
          'frames': extracted.frames,
          'calculated_total': review.calculatedTotal,
          'calculated_cumulative_scores': review.calculatedFrameTotals,
          'can_apply_without_human_review': review.canApply,
          'expected_frames_source': 'separate manual transcription',
          'matches_expected_frames': expectedFrames == null
              ? null
              : List.generate(
                  10,
                  (i) =>
                      jsonEncode(
                        extracted.frames[i].where((t) => t.isNotEmpty).toList(),
                      ) ==
                      jsonEncode(expectedFrames[i]),
                ),
        };
        // No player name, full OCR text or image bytes in this report.
        // ignore: avoid_print
        print('PHOTO_OCR_REPORT:${jsonEncode(report)}');
      } finally {
        await directory.delete(recursive: true);
      }
    },
    skip: scorePhotoTestBase64.isEmpty || layout.isEmpty,
  );
}
