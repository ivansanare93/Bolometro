import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'support/score_photo_raster_fixture.dart';
import 'package:bolometro/services/score_photo_reader.dart';
import 'package:bolometro/services/score_photo_perspective.dart';

const full = [
  ui.Offset(0, 0),
  ui.Offset(100, 0),
  ui.Offset(100, 80),
  ui.Offset(0, 80),
];
const quad = [
  ui.Offset(20, 10),
  ui.Offset(90, 15),
  ui.Offset(85, 70),
  ui.Offset(10, 65),
];
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('identity and perspective map all four corners precisely', () {
    for (final points in [full, quad]) {
      final h = ScorePhotoPerspective(const ui.Size(100, 80), points);
      final target = [
        ui.Offset.zero,
        ui.Offset(h.outputSize.width, 0),
        ui.Offset(h.outputSize.width, h.outputSize.height),
        ui.Offset(0, h.outputSize.height),
      ];
      for (var i = 0; i < 4; i++)
        expect((h.transform(points[i]) - target[i]).distance, lessThan(1e-7));
      final p = points[0], m = h.matrix;
      final d = m[3] * p.dx + m[7] * p.dy + m[15];
      expect((m[0] * p.dx + m[4] * p.dy + m[12]) / d, closeTo(0, 1e-7));
    }
  });
  test(
    'rejects crossed, reversed, duplicate, collinear and out-of-bounds corners',
    () {
      for (final points in [
        [full[0], full[2], full[1], full[3]],
        full.reversed.toList(),
        [full[0], full[0], full[2], full[3]],
        [
          const ui.Offset(0, 0),
          const ui.Offset(20, 0),
          const ui.Offset(40, 0),
          const ui.Offset(60, 0),
        ],
        [const ui.Offset(-1, 0), full[1], full[2], full[3]],
        [full[1], full[2], full[3], full[0]],
      ])
        expect(
          () => ScorePhotoPerspective(const ui.Size(100, 80), points),
          throwsFormatException,
        );
    },
  );
  test(
    'geometry is consistent at different source resolutions and output bounded',
    () {
      for (final scale in [1.0, 2.0, 4.0]) {
        final h = ScorePhotoPerspective(
          ui.Size(100 * scale, 80 * scale),
          quad.map((p) => p * scale).toList(),
        );
        expect(h.outputSize.width, lessThanOrEqualTo(4096));
        expect((h.transform(quad[0] * scale)).distance, lessThan(1e-6));
      }
    },
  );
  test(
    'actual raster rectification preserves colors at projected source points',
    () async {
      final source = await imageFixture();
      final original = Uint8List.fromList(source.image);
      for (final points in [full, quad]) {
        final h = ScorePhotoPerspective(source.size, points);
        final result = await h.rectify(source);
        expect(result.symbols, isEmpty);
        expect(result.size, h.outputSize);
        final codec = await ui.instantiateImageCodec(result.image);
        final image = (await codec.getNextFrame()).image;
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        for (final item in [
          (const ui.Offset(30, 25), [255, 0, 0]),
          (const ui.Offset(65, 25), [0, 255, 0]),
          (const ui.Offset(30, 55), [255, 255, 0]),
          (const ui.Offset(65, 55), [0, 0, 255]),
        ]) {
          final p = h.transform(item.$1);
          final offset = (p.dy.floor() * image.width + p.dx.floor()) * 4;
          expect(
            data!.buffer.asUint8List(data.offsetInBytes + offset, 3),
            item.$2,
          );
        }
        image.dispose();
        codec.dispose();
      }
      expect(source.image, original);
    },
  );
  test(
    'image normalization retains PNG dimensions and no OCR is run',
    () async {
      final source = await imageFixture();
      final dir = await Directory.systemTemp.createTemp('photo_geometry_');
      try {
        final file = File('${dir.path}/input.png');
        await file.writeAsBytes(source.image);
        final result = await ScorePhotoReader().loadImage(file.path);
        expect(result.size, source.size);
        expect(result.symbols, isEmpty);
        expect(await file.readAsBytes(), source.image);
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
  test('normalization respects EXIF orientation before selection and OCR',()async{
    final source=await ScorePhotoReader().loadImage('test/fixtures/score_photos/orientation_6_synthetic.jpeg');
    expect(source.size,const ui.Size(80,120));
    final codec=await ui.instantiateImageCodec(source.image);final image=(await codec.getNextFrame()).image;
    final data=await image.toByteData(format:ui.ImageByteFormat.rawRgba);
    final offset=(30*image.width+60)*4;
    final pixel=data!.buffer.asUint8List(data.offsetInBytes+offset,3);
    expect(pixel[0],greaterThan(220));expect(pixel[1],lessThan(30));expect(pixel[2],lessThan(30));
    image.dispose();codec.dispose();
  });
}
