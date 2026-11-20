import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/services/score_photo_draft_store.dart';
import 'package:bolometro/services/score_photo_reader.dart';
import 'package:bolometro/services/score_photo_review.dart';

Uint8List png() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a3ioAAAAASUVORK5CYII=',
);
ScorePhotoDocument document() => ScorePhotoDocument(
  image: png(),
  size: const Size(1000, 500),
  symbols: const [
    ScorePhotoToken('X', Rect.fromLTWH(20, 20, 10, 20), confidence: .9),
  ],
  numberCandidates: const ['207', '247'],
);
Map<String, dynamic> state({String total = '207'}) => {
  'row': [0, 0, 1000, 50],
  'dividers': List.generate(11, (i) => i / 10),
  'candidate': List.generate(10, (_) => ['X', '', '']),
  'rawCells': List.filled(10, 'X'),
  'progress': {
    'frames': List.generate(
      10,
      (i) => i == 9 ? ['X', 'X', 'X'] : ['X', '', ''],
    ),
    'total': total,
    'reviewed': [0, 1, 2],
    'totalReviewed': false,
    'activeFrame': 3,
  },
};

void main() {
  late Directory root;
  late ScorePhotoDraftStore store;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('score_photo_store_test_');
    store = ScorePhotoDraftStore(directory: root);
  });
  tearDown(() async {
    final tempRoot = await Directory.systemTemp.resolveSymbolicLinks();
    final resolved = await root.resolveSymbolicLinks();
    expect(resolved.startsWith('$tempRoot${Platform.pathSeparator}'), true);
    expect(
      root.uri.pathSegments
          .where((p) => p.isNotEmpty)
          .last
          .startsWith('score_photo_store_test_'),
      true,
    );
    await root.delete(recursive: true);
  });

  test(
    'Reopen preserves photo, OCR, selection, corrections and confirmations',
    () async {
      final original = document();
      await store.save(ownerUid: 'a', document: original, state: state());
      final recovered = await ScorePhotoDraftStore(
        directory: root,
      ).load(ownerUid: 'a');
      expect(recovered!.document.image, original.image);
      expect(recovered.document.symbols.single.text, 'X');
      expect(recovered.document.symbols.single.confidence, .9);
      expect(recovered.state, state());
    },
  );

  test(
    'Guest and accounts including hostile-looking UIDs remain isolated',
    () async {
      for (final uid in [null, 'a', 'b', '../guest']) {
        await store.save(
          ownerUid: uid,
          document: document(),
          state: state(total: '$uid'),
        );
      }
      final reopened = ScorePhotoDraftStore(directory: root);
      for (final uid in [null, 'a', 'b', '../guest']) {
        expect(
          (await reopened.load(ownerUid: uid))!.state['progress']['total'],
          '$uid',
        );
      }
      expect(await reopened.load(ownerUid: 'new-account'), isNull);
    },
  );

  test(
    'Queued writes commit the last edit and reuse the immutable image bundle',
    () async {
      final photo = document();
      await Future.wait(
        List.generate(
          12,
          (i) => store.save(
            ownerUid: 'a',
            document: photo,
            state: state(total: '$i'),
          ),
        ),
      );
      final recovered = await ScorePhotoDraftStore(
        directory: root,
      ).load(ownerUid: 'a');
      expect(recovered!.state['progress']['total'], '11');
      final files = await root
          .list(recursive: true)
          .where((f) => f is File)
          .toList();
      expect(files.where((f) => f.path.endsWith('.png')).length, 1);
      expect(files.where((f) => f.path.endsWith('.tmp')), isEmpty);
    },
  );

  test(
    'Failed new document leaves the last committed copy recoverable',
    () async {
      await store.save(
        ownerUid: 'a',
        document: document(),
        state: state(total: '207'),
      );
      final broken = ScorePhotoDocument(
        image: png(),
        size: const Size(double.nan, 1),
        symbols: const [],
        numberCandidates: const [],
      );
      await expectLater(
        store.save(ownerUid: 'a', document: broken, state: state()),
        throwsFormatException,
      );
      final recovered = await ScorePhotoDraftStore(
        directory: root,
      ).load(ownerUid: 'a');
      expect(recovered!.state['progress']['total'], '207');
      await store.save(
        ownerUid: 'a',
        document: document(),
        state: state(total: '208'),
      );
      expect(
        (await store.load(ownerUid: 'a'))!.state['progress']['total'],
        '208',
      );
    },
  );

  test(
    'Replacing a photo commits the new document and then removes obsolete copies',
    () async {
      await store.save(ownerUid: 'a', document: document(), state: state());
      await store.save(
        ownerUid: 'a',
        document: document(),
        state: state(total: '300'),
      );
      expect(
        (await store.load(ownerUid: 'a'))!.state['progress']['total'],
        '300',
      );
      final images = await root
          .list(recursive: true)
          .where((f) => f.path.endsWith('.png'))
          .toList();
      expect(images.length, 1);
    },
  );

  test(
    'Discard removes only this account review; unrelated files stay intact',
    () async {
      await store.save(ownerUid: 'a', document: document(), state: state());
      await store.save(
        ownerUid: 'b',
        document: document(),
        state: state(total: '200'),
      );
      final folder = await root.list().where((f) => f is Directory).first;
      final unrelated = File('${folder.path}/keep.txt');
      await unrelated.writeAsString('unrelated');
      await store.clear(ownerUid: 'a');
      expect(await store.load(ownerUid: 'a'), isNull);
      expect(
        (await store.load(ownerUid: 'b'))!.state['progress']['total'],
        '200',
      );
      expect(await unrelated.readAsString(), 'unrelated');
    },
  );

  test(
    'Corrupt or escaping pointers are rejected without deleting files',
    () async {
      await store.save(ownerUid: 'a', document: document(), state: state());
      final pointer =
          await root
                  .list(recursive: true)
                  .where((f) => f.path.endsWith('current.json'))
                  .first
              as File;
      final content = jsonDecode(await pointer.readAsString()) as Map;
      content['bundle'] = '../../secret';
      await pointer.writeAsString(jsonEncode(content));
      await expectLater(
        ScorePhotoDraftStore(directory: root).load(ownerUid: 'a'),
        throwsFormatException,
      );
      expect(await pointer.exists(), true);
    },
  );

  test('Owner mismatch and incomplete progress are rejected', () async {
    await store.save(ownerUid: 'a', document: document(), state: state());
    final pointer =
        await root
                .list(recursive: true)
                .where((f) => f.path.endsWith('current.json'))
                .first
            as File;
    final content = jsonDecode(await pointer.readAsString()) as Map;
    content['ownerUid'] = 'b';
    await pointer.writeAsString(jsonEncode(content));
    await expectLater(
      ScorePhotoDraftStore(directory: root).load(ownerUid: 'a'),
      throwsFormatException,
    );
    final invalid = state()..['candidate'] = null;
    await expectLater(
      store.save(ownerUid: 'b', document: document(), state: invalid),
      throwsFormatException,
    );
  });

  test('Readable error reasons preserve the original strict validation', () {
    final cases = <(List<String>, int, ScorePhotoFrameProblemCode, int)>[
      (['', ''], 0, ScorePhotoFrameProblemCode.missingThrow, 0),
      (['9', ''], 0, ScorePhotoFrameProblemCode.missingThrow, 1),
      (['9', 'I'], 0, ScorePhotoFrameProblemCode.unknownSymbol, 1),
      (['9', '4'], 0, ScorePhotoFrameProblemCode.pinSum, 1),
      (['8', '2'], 0, ScorePhotoFrameProblemCode.spareExpected, 1),
      (['/', '9'], 0, ScorePhotoFrameProblemCode.invalidSpare, 0),
      (['X', '4'], 0, ScorePhotoFrameProblemCode.unexpectedThrow, 1),
      (['X', '7', ''], 9, ScorePhotoFrameProblemCode.missingThrow, 2),
      (['X', 'X', '/'], 9, ScorePhotoFrameProblemCode.invalidSpare, 2),
      (['7', '2', 'X'], 9, ScorePhotoFrameProblemCode.unexpectedThrow, 2),
    ];
    for (final c in cases) {
      final problem = ScorePhotoCandidate.frameProblem(c.$1, index: c.$2)!;
      expect(problem.code, c.$3, reason: '${c.$1}');
      expect(problem.throwIndex, c.$4, reason: '${c.$1}');
    }
    expect(ScorePhotoCandidate.frameProblem(['X', '', ''], index: 0), isNull);
    expect(ScorePhotoCandidate.frameProblem(['X', '7', '/'], index: 9), isNull);
  });
  test(
    'Failure after writing new image cannot replace the committed pointer',
    () async {
      await store.save(
        ownerUid: 'a',
        document: document(),
        state: state(total: '207'),
      );
      final broken = ScorePhotoDocument(
        image: png(),
        size: const Size(1000, 500),
        symbols: const [
          ScorePhotoToken(
            'X',
            Rect.fromLTWH(0, 0, 10, 10),
            confidence: double.nan,
          ),
        ],
        numberCandidates: const [],
      );
      await expectLater(
        store.save(
          ownerUid: 'a',
          document: broken,
          state: state(total: '999'),
        ),
        throwsA(isA<JsonUnsupportedObjectError>()),
      );
      final recovered = await ScorePhotoDraftStore(
        directory: root,
      ).load(ownerUid: 'a');
      expect(recovered!.state['progress']['total'], '207');
      await store.save(
        ownerUid: 'a',
        document: document(),
        state: state(total: '208'),
      );
      final images = await root
          .list(recursive: true)
          .where((f) => f.path.endsWith('.png'))
          .toList();
      expect(images.length, 1);
    },
  );
  test(
    'Positioned words round-trip and old bundles without words remain readable',
    () async {
      final original = document();
      final withWords = ScorePhotoDocument(
        image: original.image,
        size: original.size,
        symbols: original.symbols,
        numberCandidates: original.numberCandidates,
        elements: const [
          ScorePhotoToken(
            '207',
            Rect.fromLTWH(800, 60, 40, 30),
            confidence: .8,
          ),
        ],
      );
      final snapshot = state()
        ..['simpleSummary'] = true
        ..['showSelection'] = false
        ..['ambiguousColumns'] = false
        ..['observedCumulative'] = List<int?>.filled(10, null);
      await store.save(ownerUid: 'a', document: withWords, state: snapshot);
      final restored = await ScorePhotoDraftStore(
        directory: root,
      ).load(ownerUid: 'a');
      expect(restored!.document.elements.single.text, '207');
      expect(
        restored.document.elements.single.box,
        const Rect.fromLTWH(800, 60, 40, 30),
      );
      final metadata =
          await root
                  .list(recursive: true)
                  .where(
                    (f) =>
                        f is File &&
                        f.path.endsWith('.json') &&
                        !f.path.endsWith('current.json'),
                  )
                  .first
              as File;
      final old = jsonDecode(await metadata.readAsString()) as Map;
      old.remove('elements');
      await metadata.writeAsString(jsonEncode(old));
      final legacy = await ScorePhotoDraftStore(
        directory: root,
      ).load(ownerUid: 'a');
      expect(legacy!.document.elements, isEmpty);
      expect(legacy.state, snapshot);
    },
  );
}
