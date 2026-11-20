import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'score_photo_reader.dart';

class ScorePhotoDraft {
  final ScorePhotoDocument document;
  final Map<String, dynamic> state;
  const ScorePhotoDraft(this.document, this.state);
}

/// Device-only, account-scoped photo review. No Hive or Firebase writes.
/// Immutable image/OCR bundles are committed before the small current pointer.
class ScorePhotoDraftStore {
  static final shared = ScorePhotoDraftStore();
  final Directory? directory;
  Future<void> _tail = Future.value();
  final Map<String, (ScorePhotoDocument, String)> _bundles = {};
  int _sequence = 0;
  ScorePhotoDraftStore({this.directory});

  String _ownerKey(String? uid) => uid == null
      ? 'guest'
      : 'user_${base64Url.encode(utf8.encode(uid)).replaceAll("=", "")}';

  Future<Directory> _folder(String? uid) async {
    final root =
        directory ??
        Directory(
          '${(await getApplicationSupportDirectory()).path}/score_photo_reviews_v1',
        );
    return Directory('${root.path}/${_ownerKey(uid)}');
  }

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _atomic(File target, List<int> bytes) async {
    final pending = File('${target.path}.tmp');
    await pending.writeAsBytes(bytes, flush: true);
    // Never remove the last committed file before replacing it.
    await pending.rename(target.path);
  }

  Future<void> save({
    required String? ownerUid,
    required ScorePhotoDocument document,
    required Map<String, dynamic> state,
  }) async {
    final captured = jsonDecode(jsonEncode(state)) as Map<String, dynamic>;
    validateState(captured);
    _validateDocument(document, captured);
    return _serial(() async {
      final folder = await _folder(ownerUid);
      await folder.create(recursive: true);
      final key = _ownerKey(ownerUid);
      final cached = _bundles[key];
      final id = cached != null && identical(cached.$1, document)
          ? cached.$2
          : 'photo_${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';
      if (cached == null || cached.$2 != id) {
        await _atomic(File('${folder.path}/$id.png'), document.image);
        final metadata = {
          'width': document.size.width,
          'height': document.size.height,
          'numbers': document.numberCandidates,
          'elements': document.elements
              .map(
                (s) => {
                  'text': s.text,
                  'box': [s.box.left, s.box.top, s.box.right, s.box.bottom],
                  'confidence': s.confidence,
                },
              )
              .toList(),
          'symbols': document.symbols
              .map(
                (s) => {
                  'text': s.text,
                  'box': [s.box.left, s.box.top, s.box.right, s.box.bottom],
                  'confidence': s.confidence,
                },
              )
              .toList(),
        };
        await _atomic(
          File('${folder.path}/$id.json'),
          utf8.encode(jsonEncode(metadata)),
        );
      }
      await _atomic(
        File('${folder.path}/current.json'),
        utf8.encode(
          jsonEncode({
            'version': 1,
            'ownerUid': ownerUid,
            'bundle': id,
            'state': captured,
          }),
        ),
      );
      if (!_bundles.containsKey(key)) _bundles.clear();
      _bundles[key] = (document, id);
      // Once the new pointer is committed, obsolete private copies are safe to
      // remove. Unrelated files or symlinks are never traversed.
      await for (final file in folder.list(followLinks: false)) {
        final name = file.uri.pathSegments.last;
        if (file is File &&
            RegExp(
              r'^photo_[0-9]+_[0-9]+\.(png|json)(\.tmp)?$',
            ).hasMatch(name) &&
            !name.startsWith('$id.')) {
          try {
            await file.delete();
          } on FileSystemException {
            /* Retry later. */
          }
        }
      }
    });
  }

  Future<ScorePhotoDraft?> load({required String? ownerUid}) =>
      _serial(() async {
        final folder = await _folder(ownerUid);
        final pointer = File('${folder.path}/current.json');
        if (!await pointer.exists()) return null;
        final data =
            jsonDecode(await pointer.readAsString()) as Map<String, dynamic>;
        if (data['version'] != 1 ||
            !data.containsKey('ownerUid') ||
            data['ownerUid'] != ownerUid) {
          throw const FormatException('Invalid photo review owner or version');
        }
        final id = data['bundle'];
        if (id is! String || !RegExp(r'^photo_[0-9]+_[0-9]+$').hasMatch(id)) {
          throw const FormatException('Invalid photo review bundle');
        }
        final state = Map<String, dynamic>.from(data['state'] as Map);
        validateState(state);
        final metadata =
            jsonDecode(await File('${folder.path}/$id.json').readAsString())
                as Map<String, dynamic>;
        final width = (metadata['width'] as num).toDouble();
        final height = (metadata['height'] as num).toDouble();
        if (!width.isFinite ||
            !height.isFinite ||
            width <= 0 ||
            height <= 0 ||
            width * height > 16000000) {
          throw const FormatException('Invalid photo review dimensions');
        }
        final document = ScorePhotoDocument(
          image: await File('${folder.path}/$id.png').readAsBytes(),
          size: Size(width, height),
          symbols: (metadata['symbols'] as List).map((raw) {
            final item = raw as Map;
            final box = (item['box'] as List)
                .map((v) => (v as num).toDouble())
                .toList();
            if (box.length != 4 || box.any((v) => !v.isFinite)) {
              throw const FormatException('Invalid OCR bounds');
            }
            return ScorePhotoToken(
              item['text'] as String,
              Rect.fromLTRB(box[0], box[1], box[2], box[3]),
              confidence: (item['confidence'] as num?)?.toDouble(),
            );
          }).toList(),
          numberCandidates: List<String>.from(metadata['numbers'] as List),
          elements: ((metadata['elements'] as List?) ?? []).map((raw) {
            final item = raw as Map;
            final box = (item['box'] as List)
                .map((v) => (v as num).toDouble())
                .toList();
            if (box.length != 4 || box.any((v) => !v.isFinite)) {
              throw const FormatException('Invalid OCR element bounds');
            }
            return ScorePhotoToken(
              item['text'] as String,
              Rect.fromLTRB(box[0], box[1], box[2], box[3]),
              confidence: (item['confidence'] as num?)?.toDouble(),
            );
          }).toList(),
        );
        _bundles.clear();
        _bundles[_ownerKey(ownerUid)] = (document, id);
        return ScorePhotoDraft(document, state);
      });

  Future<void> clear({required String? ownerUid}) => _serial(() async {
    final folder = await _folder(ownerUid);
    if (!await folder.exists()) return;
    // Remove pointer first only on an explicit user discard, never on sign-out.
    final pointer = File('${folder.path}/current.json');
    if (await pointer.exists()) await pointer.delete();
    await for (final file in folder.list(followLinks: false)) {
      final name = file.uri.pathSegments.last;
      if (file is File &&
          (RegExp(
                r'^photo_[0-9]+_[0-9]+\.(png|json)(\.tmp)?$',
              ).hasMatch(name) ||
              name == 'current.json.tmp')) {
        await file.delete();
      }
    }
    _bundles.remove(_ownerKey(ownerUid));
  });

  static void _validateDocument(
    ScorePhotoDocument document,
    Map<String, dynamic> state,
  ) {
    final size = document.size;
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0 ||
        size.width * size.height > 16000000 ||
        document.image.length > 70 * 1024 * 1024 ||
        document.image.length < 8 ||
        !List.generate(
          8,
          (i) => document.image[i] == [137, 80, 78, 71, 13, 10, 26, 10][i],
        ).every((v) => v)) {
      throw const FormatException('Invalid review image');
    }
    final row = state['row'] as List?;
    if (row != null &&
        ((row[0] as num) < 0 ||
            (row[1] as num) < 0 ||
            (row[2] as num) > size.width + .001 ||
            (row[3] as num) > size.height + .001)) {
      throw const FormatException('Review region outside image');
    }
  }

  static void validateState(Map<String, dynamic> state) {
    final row = state['row'];
    if (row != null &&
        (row is! List ||
            row.length != 4 ||
            row.any((v) => v is! num || !v.toDouble().isFinite) ||
            row[2] <= row[0] ||
            row[3] <= row[1])) {
      throw const FormatException('Invalid review region');
    }
    final dividers = state['dividers'];
    if (dividers is! List ||
        dividers.length != 11 ||
        dividers.any((v) => v is! num || !v.toDouble().isFinite) ||
        dividers.first != 0 ||
        dividers.last != 1 ||
        List.generate(
          10,
          (i) => dividers[i] >= dividers[i + 1],
        ).any((v) => v)) {
      throw const FormatException('Invalid review dividers');
    }
    for (final key in ['simpleSummary', 'showSelection', 'ambiguousColumns']) {
      if (state.containsKey(key) && state[key] is! bool) {
        throw const FormatException('Invalid review mode');
      }
    }
    final observed = state['observedCumulative'];
    if (observed != null &&
        (observed is! List ||
            observed.length != 10 ||
            observed.any(
              (v) => v != null && (v is! int || v < 0 || v > 300),
            ))) {
      throw const FormatException('Invalid observed cumulative scores');
    }
    final progress = state['progress'];
    if (progress != null) {
      if (progress is! Map)
        throw const FormatException('Invalid review progress');
      final frames = progress['frames'];
      final reviewed = progress['reviewed'];
      if (frames is! List ||
          frames.length != 10 ||
          frames.any(
            (f) => f is! List || f.length != 3 || f.any((v) => v is! String),
          ) ||
          progress['total'] is! String ||
          progress['totalReviewed'] is! bool ||
          progress['activeFrame'] is! int ||
          progress['activeFrame'] < 0 ||
          progress['activeFrame'] > 9 ||
          reviewed is! List ||
          reviewed.any((v) => v is! int || v < 0 || v > 9)) {
        throw const FormatException('Invalid review progress');
      }
    }
    final candidate = state['candidate'];
    if (candidate != null &&
        (candidate is! List ||
            candidate.length != 10 ||
            candidate.any(
              (f) => f is! List || f.length != 3 || f.any((v) => v is! String),
            ))) {
      throw const FormatException('Invalid review candidate');
    }
    if ((progress != null && candidate == null) ||
        (candidate != null && row == null)) {
      throw const FormatException('Incomplete review context');
    }
    if (state['rawCells'] is! List ||
        (state['rawCells'] as List).any((v) => v is! String)) {
      throw const FormatException('Invalid raw cells');
    }
  }
}
