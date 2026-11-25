import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:bolometro/services/score_photo_reader.dart';

Future<ScorePhotoDocument> imageFixture() async {
  final recorder = ui.PictureRecorder();
  final c = ui.Canvas(recorder);
  c.drawRect(
    const ui.Rect.fromLTWH(0, 0, 100, 80),
    ui.Paint()..color = const ui.Color(0xff0000ff),
  );
  c.drawRect(
    const ui.Rect.fromLTWH(0, 0, 50, 40),
    ui.Paint()..color = const ui.Color(0xffff0000),
  );
  c.drawRect(
    const ui.Rect.fromLTWH(50, 0, 50, 40),
    ui.Paint()..color = const ui.Color(0xff00ff00),
  );
  c.drawRect(
    const ui.Rect.fromLTWH(0, 40, 50, 40),
    ui.Paint()..color = const ui.Color(0xffffff00),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(100, 80);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = Uint8List.fromList(
    data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
  image.dispose();
  picture.dispose();
  return ScorePhotoDocument(
    image: bytes,
    size: const ui.Size(100, 80),
    symbols: const [],
    numberCandidates: const [],
  );
}
