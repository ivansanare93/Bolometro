import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'score_photo_reader.dart';

/// Pure image geometry, unrelated to lane/metric calibration.
class ScorePhotoPerspective {
  final ui.Size sourceSize;
  final List<ui.Offset> corners;
  final ui.Size outputSize;
  final List<double> _h;
  ScorePhotoPerspective._(
    this.sourceSize,
    this.corners,
    this.outputSize,
    this._h,
  );

  /// Clockwise: top-left, top-right, bottom-right, bottom-left. No auto sorting.
  factory ScorePhotoPerspective(ui.Size size, List<ui.Offset> points) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.isEmpty ||
        size.width * size.height > 16000000 ||
        points.length != 4) {
      throw const FormatException('Invalid source or corner count');
    }
    for (var i = 0; i < 4; i++) {
      final p = points[i];
      final q = points[(i + 1) % 4];
      final r = points[(i + 2) % 4];
      if (!p.dx.isFinite ||
          !p.dy.isFinite ||
          p.dx < 0 ||
          p.dy < 0 ||
          p.dx > size.width ||
          p.dy > size.height ||
          (q - p).distance < 8 ||
          (q.dx - p.dx) * (r.dy - q.dy) - (q.dy - p.dy) * (r.dx - q.dx) <= 1) {
        throw const FormatException(
          'Corners must form a convex clockwise quadrilateral',
        );
      }
    }
    if (points[0].dy + points[1].dy >= points[2].dy + points[3].dy ||
        points[0].dx + points[3].dx >= points[1].dx + points[2].dx) {
      throw const FormatException('Corner order must begin at top left');
    }
    final w = math.max(
      (points[1] - points[0]).distance,
      (points[2] - points[3]).distance,
    );
    final h = math.max(
      (points[3] - points[0]).distance,
      (points[2] - points[1]).distance,
    );
    var scale = math.min(1.0, 4096 / math.max(w, h));
    if (w * h * scale * scale > 16000000) scale = math.sqrt(16000000 / (w * h));
    final output = ui.Size(
      (w * scale).floorToDouble(),
      (h * scale).floorToDouble(),
    );
    final rows = <List<double>>[];
    const dest = [
      ui.Offset(0, 0),
      ui.Offset(1, 0),
      ui.Offset(1, 1),
      ui.Offset(0, 1),
    ];
    for (var i = 0; i < 4; i++) {
      final x = points[i].dx / size.width, y = points[i].dy / size.height;
      final u = dest[i].dx, v = dest[i].dy;
      rows.add([x, y, 1, 0, 0, 0, -u * x, -u * y, u]);
      rows.add([0, 0, 0, x, y, 1, -v * x, -v * y, v]);
    }
    for (var col = 0; col < 8; col++) {
      var pivot = col;
      for (var row = col + 1; row < 8; row++) {
        if (rows[row][col].abs() > rows[pivot][col].abs()) pivot = row;
      }
      if (rows[pivot][col].abs() < 1e-10)
        throw const FormatException('Unstable perspective');
      final swap = rows[col];
      rows[col] = rows[pivot];
      rows[pivot] = swap;
      final d = rows[col][col];
      for (var k = col; k < 9; k++) {
        rows[col][k] /= d;
      }
      for (var row = 0; row < 8; row++) {
        if (row == col) continue;
        final f = rows[row][col];
        for (var k = col; k < 9; k++) {
          rows[row][k] -= f * rows[col][k];
        }
      }
    }
    final hmat = [for (var i = 0; i < 8; i++) rows[i][8], 1.0];
    final denominators = [
      for (final p in points)
        hmat[6] * p.dx / size.width + hmat[7] * p.dy / size.height + 1,
    ];
    if (hmat.any((v) => !v.isFinite) ||
        denominators.any(
          (v) => v.abs() < 1e-7 || v.sign != denominators.first.sign,
        )) {
      throw const FormatException('Unstable perspective denominator');
    }
    return ScorePhotoPerspective._(
      size,
      List.unmodifiable(points),
      output,
      hmat,
    );
  }

  ui.Offset transform(ui.Offset p) {
    final x = p.dx / sourceSize.width, y = p.dy / sourceSize.height;
    final d = _h[6] * x + _h[7] * y + 1;
    return ui.Offset(
      (_h[0] * x + _h[1] * y + _h[2]) / d * outputSize.width,
      (_h[3] * x + _h[4] * y + _h[5]) / d * outputSize.height,
    );
  }

  Float64List get matrix => Float64List.fromList([
    _h[0] * outputSize.width / sourceSize.width,
    _h[3] * outputSize.height / sourceSize.width,
    0,
    _h[6] / sourceSize.width,
    _h[1] * outputSize.width / sourceSize.height,
    _h[4] * outputSize.height / sourceSize.height,
    0,
    _h[7] / sourceSize.height,
    0,
    0,
    1,
    0,
    _h[2] * outputSize.width,
    _h[5] * outputSize.height,
    0,
    1,
  ]);

  Future<ScorePhotoDocument> rectify(ScorePhotoDocument source) async {
    if (source.size != sourceSize)
      throw const FormatException('Source size mismatch');
    final codec = await ui.instantiateImageCodec(source.image);
    ui.Image? image, output;
    ui.Picture? picture;
    try {
      image = (await codec.getNextFrame()).image;
      if (image.width != sourceSize.width || image.height != sourceSize.height)
        throw const FormatException('Pixel size mismatch');
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.clipRect(ui.Offset.zero & outputSize);
      canvas.drawColor(const ui.Color(0xff000000), ui.BlendMode.src);
      canvas.transform(matrix);
      canvas.drawImage(
        image,
        ui.Offset.zero,
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      picture = recorder.endRecording();
      output = await picture.toImage(
        outputSize.width.toInt(),
        outputSize.height.toInt(),
      );
      final bytes = await output.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null)
        throw const FormatException('Cannot encode rectified image');
      return ScorePhotoDocument(
        image: bytes.buffer.asUint8List(
          bytes.offsetInBytes,
          bytes.lengthInBytes,
        ),
        size: outputSize,
        symbols: const [],
        numberCandidates: const [],
      );
    } finally {
      output?.dispose();
      picture?.dispose();
      image?.dispose();
      codec.dispose();
    }
  }
}
