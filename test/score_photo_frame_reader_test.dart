import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/services/score_photo_reader.dart';
import 'package:bolometro/services/score_photo_frame_reader.dart';

ScorePhotoDocument doc(List<String> values) => ScorePhotoDocument(
  image: Uint8List(0),
  size: const ui.Size(100, 40),
  symbols: [
    for (var i = 0; i < values.length; i++)
      ScorePhotoToken(values[i], ui.Rect.fromLTWH(5 + i * 20, 5, 10, 20)),
  ],
  numberCandidates: const [],
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('preserves symbols without guessing ambiguous OCR', () {
    expect(ScorePhotoFrameReader.parse(doc(['9', '/']), 0), ['9', '/', '']);
    expect(ScorePhotoFrameReader.parse(doc(['I']), 0), ['?', '', '']);
    expect(ScorePhotoFrameReader.parse(doc([]), 0), ['', '', '']);
  });
  test('three throws only belong to tenth frame', () {
    expect(ScorePhotoFrameReader.parse(doc(['9', '/', 'X']), 9), [
      '9',
      '/',
      'X',
    ]);
    expect(ScorePhotoFrameReader.parse(doc(['9', '/', 'X']), 2), ['?', '', '']);
  });
  test('rejects invalid frame indices', () {
    expect(() => ScorePhotoFrameReader.parse(doc([]), 10), throwsRangeError);
    expect(() => ScorePhotoFrameReader.parse(doc([]), -1), throwsRangeError);
  });
  test(
    're-recognizes only bounded crop, source image remains unchanged',
    () async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(
        recorder,
      ).drawColor(const ui.Color(0xffffffff), ui.BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(8, 8);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final png = bytes!.buffer.asUint8List(
        bytes.offsetInBytes,
        bytes.lengthInBytes,
      );
      final original = Uint8List.fromList(png);
      final source = ScorePhotoDocument(
        image: png,
        size: const ui.Size(8, 8),
        symbols: const [],
        numberCandidates: const [],
      );
      var calls = 0;
      final reader = ScorePhotoFrameReader(
        recognize: (crop) async {
          calls++;
          final codec = await ui.instantiateImageCodec(crop);
          final frame = await codec.getNextFrame();
          expect(frame.image.width, 4);
          expect(frame.image.height, 6);
          frame.image.dispose();
          codec.dispose();
          return doc(['X']);
        },
      );
      final result = await reader.read(
        source,
        const ui.Rect.fromLTWH(2, 1, 2, 3),
        0,
      );
      expect(result.throws, ['X', '', '']);
      expect(calls, 1);
      expect(source.image, original);
      await expectLater(
        reader.read(source, const ui.Rect.fromLTWH(-1, 0, 2, 2), 0),
        throwsA(isA<ScorePhotoException>()),
      );
      expect(calls, 1);
      final failed = ScorePhotoFrameReader(
        recognize: (_) async => throw StateError('simulated native failure'),
      );
      await expectLater(
        failed.read(source, const ui.Rect.fromLTWH(2, 1, 2, 3), 0),
        throwsStateError,
      );
      image.dispose();
      picture.dispose();
    },
  );
  test('symbols crossing crop boundary remain unknown', () {
    final source = ScorePhotoDocument(
      image: Uint8List(0),
      size: const ui.Size(100, 40),
      symbols: const [ScorePhotoToken('9', ui.Rect.fromLTWH(90, 5, 15, 20))],
      numberCandidates: const [],
    );
    expect(ScorePhotoFrameReader.parse(source, 0), ['?', '', '']);
  });
}
