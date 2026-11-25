import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

class ScorePhotoToken {
  final String text;
  final ui.Rect box;
  final double? confidence;
  const ScorePhotoToken(this.text, this.box, {this.confidence});
}

class ScorePhotoDocument {
  final Uint8List image;
  final ui.Size size;
  final List<ScorePhotoToken> symbols;
  final List<String> numberCandidates;
  final List<ScorePhotoToken> elements;
  ScorePhotoDocument({
    required this.image,
    required this.size,
    required List<ScorePhotoToken> symbols,
    required List<String> numberCandidates,
    List<ScorePhotoToken> elements = const [],
  }) : elements = List.unmodifiable(elements),
       symbols = List.unmodifiable(symbols),
       numberCandidates = List.unmodifiable(numberCandidates);
}

class ScorePhotoException implements Exception {
  final String code;
  const ScorePhotoException(this.code);
}

/// Local, bundled Latin OCR. Neither images nor OCR text are uploaded or logged.
/// Android is the first supported platform; iOS configuration is not changed.
class ScorePhotoReader {
  Future<ScorePhotoDocument> read(
    String path, {
    void Function(String)? onStage,
  }) async {
    onStage?.call('start');
    if (!Platform.isAndroid) throw const ScorePhotoException('platform');
    final source = await loadImage(path, onStage: onStage);
    return readPrepared(source, onStage: onStage);
  }

  /// Decode once; preview and OCR share this exact oriented PNG.
  Future<ScorePhotoDocument> loadImage(
    String path, {
    void Function(String)? onStage,
  }) async {
    final file = File(path);
    if (await file.length() > 20 * 1024 * 1024)
      throw const ScorePhotoException('size');
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      await file.readAsBytes(),
    );
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      onStage?.call('metadata_decoded');
      if (descriptor.width * descriptor.height > 16000000)
        throw const ScorePhotoException('size');
      codec = await descriptor.instantiateCodec();
      image = (await codec.getNextFrame()).image;
      onStage?.call('image_decoded');
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw const ScorePhotoException('image');
      return ScorePhotoDocument(
        image: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        size: ui.Size(image.width.toDouble(), image.height.toDouble()),
        symbols: const [],
        numberCandidates: const [],
      );
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  Future<ScorePhotoDocument> readPrepared(
    ScorePhotoDocument source, {
    void Function(String)? onStage,
  }) async {
    if (!Platform.isAndroid) throw const ScorePhotoException('platform');
    Directory? temporary;
    TextRecognizer? recognizer;
    try {
      temporary = await Directory(
        (await getTemporaryDirectory()).path,
      ).createTemp('bolometro_score_');
      final normalized = File('${temporary.path}/score.png');
      await normalized.writeAsBytes(source.image);
      onStage?.call('png_written');
      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final text = await recognizer.processImage(
        InputImage.fromFilePath(normalized.path),
      );
      onStage?.call('ocr_finished');
      final symbols = <ScorePhotoToken>[];
      final elements = <ScorePhotoToken>[];
      final numbers = <String>{};
      for (final block in text.blocks) {
        for (final line in block.lines) {
          for (final element in line.elements) {
            final value = element.text.trim();
            elements.add(
              ScorePhotoToken(
                value,
                element.boundingBox,
                confidence: element.confidence,
              ),
            );
            final number = int.tryParse(value);
            if (RegExp(r'^[0-9]{1,3}$').hasMatch(value) &&
                number != null &&
                number <= 300) {
              numbers.add(value);
            }
            if (element.symbols.isEmpty) {
              symbols.add(
                ScorePhotoToken(
                  value,
                  element.boundingBox,
                  confidence: element.confidence,
                ),
              );
            } else {
              symbols.addAll(
                element.symbols.map(
                  (s) => ScorePhotoToken(
                    s.text,
                    s.boundingBox,
                    confidence: s.confidence,
                  ),
                ),
              );
            }
          }
        }
      }
      return ScorePhotoDocument(
        image: source.image,
        size: source.size,
        symbols: symbols,
        elements: elements,
        numberCandidates: numbers.toList(),
      );
    } finally {
      try {
        await recognizer?.close();
      } finally {
        if (temporary != null) await temporary.delete(recursive: true);
      }
    }
  }
}

/// Extracts only an explicitly selected row of throw symbols. Cumulative scores
/// and player names must be outside this rectangle. No layout is inferred.
class ScorePhotoRow {
  final List<List<String>> frames;
  final List<String> rawCells;
  const ScorePhotoRow._(this.frames, this.rawCells);

  static ScorePhotoRow extract({
    required List<ScorePhotoToken> tokens,
    required ui.Rect row,
    required List<double> dividers,
  }) {
    if (!row.isFinite ||
        row.width <= 0 ||
        row.height <= 0 ||
        dividers.length != 11 ||
        dividers.first != 0 ||
        dividers.last != 1 ||
        dividers.any((v) => !v.isFinite || v < 0 || v > 1) ||
        List.generate(
          10,
          (i) => dividers[i + 1] <= dividers[i],
        ).any((v) => v)) {
      throw ArgumentError('Invalid score row or dividers');
    }
    final cells = List.generate(10, (_) => <ScorePhotoToken>[]);
    final ambiguous = <int>{};
    for (final token in tokens) {
      if (!row.contains(token.box.center)) continue;
      for (var i = 0; i < 10; i++) {
        final left = row.left + row.width * dividers[i];
        final right = row.left + row.width * dividers[i + 1];
        if (token.box.right <= left || token.box.left >= right) continue;
        // Do not split an OCR element across frames by guessed character widths.
        if (token.box.left < left ||
            token.box.right > right ||
            token.box.top < row.top ||
            token.box.bottom > row.bottom) {
          ambiguous.add(i);
        } else {
          cells[i].add(token);
        }
      }
    }
    final raw = cells.map((cell) {
      cell.sort((a, b) => a.box.left.compareTo(b.box.left));
      return cell.map((t) => t.text).join().toUpperCase().replaceAll(' ', '');
    }).toList();
    final frames = List.generate(10, (i) {
      final value = raw[i];
      final limit = i == 9 ? 3 : 2;
      if (ambiguous.contains(i) ||
          value.length > limit ||
          !RegExp(r'^[0-9X/\-]*$').hasMatch(value)) {
        return <String>['?', '', ''];
      }
      return List.generate(3, (j) => j < value.length ? value[j] : '');
    });
    return ScorePhotoRow._(frames, raw);
  }
}
