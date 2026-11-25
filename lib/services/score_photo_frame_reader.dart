import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'score_photo_reader.dart';

class ScorePhotoFrameReading {
  final List<String> throws;
  final String raw;
  final Uint8List crop;
  const ScorePhotoFrameReading(this.throws, this.raw, this.crop);
}

/// Re-reads only the source pixels of one cell; never changes a game or draft.
class ScorePhotoFrameReader {
  final Future<ScorePhotoDocument> Function(Uint8List)? recognize;
  const ScorePhotoFrameReader({this.recognize});

  static List<String> parse(ScorePhotoDocument document, int frame) {
    if (frame < 0 || frame > 9) throw RangeError.range(frame, 0, 9);
    // Place the crop in column ten to preserve all three tenth-frame throws.
    final w = document.size.width;
    final row = ScorePhotoRow.extract(
      tokens: document.symbols,
      row: ui.Rect.fromLTWH(-9 * w, 0, 10 * w, document.size.height),
      dividers: List.generate(11, (i) => i / 10),
    );
    final result = row.frames[9];
    if (frame != 9 && result[2].isNotEmpty) return ['?', '', ''];
    return List.of(result);
  }

  Future<ScorePhotoFrameReading> read(
    ScorePhotoDocument source,
    ui.Rect cell,
    int frame,
  ) async {
    if (frame < 0 || frame > 9) throw RangeError.range(frame, 0, 9);
    final bounds = ui.Offset.zero & source.size;
    if (!cell.isFinite ||
        cell.isEmpty ||
        !bounds.contains(cell.topLeft) ||
        cell.right > bounds.right ||
        cell.bottom > bounds.bottom) {
      throw const ScorePhotoException('image');
    }
    final codec = await ui.instantiateImageCodec(source.image);
    ui.Image? image;
    ui.Image? cropped;
    ui.Picture? picture;
    try {
      image = (await codec.getNextFrame()).image;
      if (image.width != source.size.width ||
          image.height != source.size.height) {
        throw const ScorePhotoException('image');
      }
      // Modest enlargement can help small glyphs; it adds no missing detail.
      final scale = (2.0).clamp(0.0, 4096 / cell.longestSide);
      final width = (cell.width * scale).ceil().clamp(1, 4096);
      final height = (cell.height * scale).ceil().clamp(1, 4096);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xff000000), ui.BlendMode.src);
      canvas.drawImageRect(
        image,
        cell,
        ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      picture = recorder.endRecording();
      cropped = await picture.toImage(width, height);
      final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw const ScorePhotoException('image');
      final png = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final result = await (recognize ?? _recognize)(png);
      final tokens = List<ScorePhotoToken>.of(result.symbols)
        ..sort((a, b) => a.box.left.compareTo(b.box.left));
      return ScorePhotoFrameReading(
        parse(result, frame),
        tokens.map((t) => t.text).join(),
        png,
      );
    } finally {
      cropped?.dispose();
      picture?.dispose();
      image?.dispose();
      codec.dispose();
    }
  }

  static Future<ScorePhotoDocument> _recognize(Uint8List png) async {
    final dir = await Directory(
      (await getTemporaryDirectory()).path,
    ).createTemp('bolometro_frame_');
    try {
      final file = File('${dir.path}/frame.png');
      await file.writeAsBytes(png, flush: true);
      return await ScorePhotoReader().read(file.path);
    } finally {
      await dir.delete(recursive: true);
    }
  }
}
