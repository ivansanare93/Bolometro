import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:bolometro/services/score_photo_reader.dart';

/// Positioned OCR simulation, NOT the output of ML Kit on a photograph.
ScorePhotoDocument proposalFixture({
  double scale = 1,
  int players = 1,
  bool headers = true,
  String alignment = 'right',
  bool includeElements = true,
  bool includeName = false,
  List<List<String>>? throws_,
  List<int>? cumulative,
}) {
  final frames =
      throws_ ??
      [
        ['9', '/'],
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
  final scores = cumulative ?? [20, 49, 69, 89, 109, 128, 148, 168, 187, 207];
  final symbols = <ScorePhotoToken>[], elements = <ScorePhotoToken>[];
  Rect rect(double x, double y, double w, double h) =>
      Rect.fromLTWH(x * scale, y * scale, w * scale, h * scale);
  void word(String text, Rect box) {
    elements.add(ScorePhotoToken(text, box));
    final width = box.width / text.length;
    for (var i = 0; i < text.length; i++) {
      symbols.add(
        ScorePhotoToken(
          text[i],
          Rect.fromLTWH(box.left + width * i, box.top, width * .85, box.height),
        ),
      );
    }
  }

  if (headers) {
    for (var f = 0; f < 10; f++) {
      final label = '${f + 1}', width = f == 9 ? 30.0 : 18.0;
      final left = alignment == 'right'
          ? 100 + (f + 1) * 100 - 12 - width
          : alignment == 'center'
          ? 100 + f * 100 + 50 - width / 2
          : 100 + f * 100 + 12.0;
      word(label, rect(left, 50, width, 25));
    }
  }
  for (var player = 0; player < players; player++) {
    final top = 150.0 + player * 180;
    if (includeName) word('PLAYER', rect(0, top, 80, 32));
    for (var f = 0; f < 10; f++) {
      final values = frames[f];
      Rect? bounds;
      for (var t = 0; t < values.length; t++) {
        final x =
            100 +
            f * 100 +
            (f == 9
                    ? 10 + t * 30
                    : values.length == 1
                    ? 72
                    : t == 0
                    ? 12
                    : 72)
                .toDouble();
        final box = rect(x, top, 18, 32);
        symbols.add(ScorePhotoToken(values[t], box));
        bounds = bounds == null ? box : bounds.expandToInclude(box);
      }
      if (bounds != null) elements.add(ScorePhotoToken(values.join(), bounds));
      word('${scores[f]}', rect(100 + f * 100 + 40.0, top + 60, 45, 32));
    }
    // Two totals outside frame 10: their values must not drive parsing.
    word('207', rect(1150, top + 45, 60, 60));
    word('247', rect(1260, top + 45, 60, 60));
  }
  return ScorePhotoDocument(
    image: Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a3ioAAAAASUVORK5CYII=',
      ),
    ),
    size: Size(1400 * scale, (300 + players * 180) * scale),
    symbols: symbols,
    elements: includeElements ? elements : [],
    numberCandidates: const ['207', '247'],
  );
}
