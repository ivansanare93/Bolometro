import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/services/score_photo_reader.dart';
import 'package:bolometro/services/score_photo_perspective.dart';

/// Local geometric demonstration only. These corners are manually estimated,
/// not detected automatically or confirmed by the user. Never runs ML Kit.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const path = String.fromEnvironment('SCORE_PHOTO_GEOMETRY_SOURCE');
  test(
    'real reference photo rectification without OCR accuracy claims',
    () async {
      final source = await ScorePhotoReader().loadImage(path);
      expect(source.size, const ui.Size(1599, 337));
      const points = [
        ui.Offset(184, 104),
        ui.Offset(1290, 112),
        ui.Offset(1290, 334),
        ui.Offset(180, 332),
      ];
      final geometry = ScorePhotoPerspective(source.size, points);
      final rectified = await geometry.rectify(source);
      final directory = Directory('build/score_photo_perspective');
      await directory.create(recursive: true);
      await File(
        '${directory.path}/puntosBolos_rectified.png',
      ).writeAsBytes(rectified.image);
      final codec = await ui.instantiateImageCodec(source.image);
      final image = (await codec.getNextFrame()).image;
      final recorder = ui.PictureRecorder();
      final c = ui.Canvas(recorder);
      c.drawImage(image, ui.Offset.zero, ui.Paint());
      c.drawPath(
        ui.Path()..addPolygon(points, true),
        ui.Paint()
          ..color = const ui.Color(0xff00ffff)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      for (var i = 0; i < 4; i++) {
        final text = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
            style: const TextStyle(fontSize: 24, color: ui.Color(0xff00ffff)),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        text.paint(c, points[i] + ui.Offset(3, i > 1 ? -30 : 3));
        text.dispose();
      }
      final picture = recorder.endRecording();
      final marked = await picture.toImage(1599, 337);
      final data = await marked.toByteData(format: ui.ImageByteFormat.png);
      await File('${directory.path}/puntosBolos_corners.png').writeAsBytes(
        data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      marked.dispose();
      picture.dispose();
      image.dispose();
      codec.dispose();
      expect(await File(path).length(), 66418);
    },
    skip: path.isEmpty,
  );
}
