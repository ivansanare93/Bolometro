import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bolometro/models/catalog_ball.dart';
import 'package:bolometro/repositories/ball_media_repository.dart';
import 'package:bolometro/services/ball_image_service.dart';
import 'package:bolometro/widgets/ball_photo.dart';
import '../tool/catalog/generate_authorized_photos.dart' as generator;
import 'package:bolometro/data/authorized_catalog_photos.dart';

// Synthetic 1-pixel PNG, not manufacturer artwork.
final png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aV1cAAAAASUVORK5CYII=',
);
Map<String, dynamic> photoJson({bool authorised = true, bool cache = true}) => {
  'url': 'https://example.invalid/synthetic.png',
  'sourceUrl': 'https://example.invalid/synthetic',
  'rightsHolder': 'Synthetic test fixture',
  'license': 'TEST ONLY',
  'permissionReference': 'Synthetic pixels created for tests',
  'verifiedAt': '2026-10-28T00:00:00Z',
  'displayAuthorized': authorised,
  'cacheAuthorized': cache,
};

void mediaTest(String name, FutureOr<void> Function() body) {
  testWidgets(name, (tester) async {
    await tester.runAsync(() async {
      await body();
    });
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late int downloads;
  late BallImageService images;
  late BallMediaRepository repository;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('bolometro_c4_');
    downloads = 0;
    images = BallImageService(
      cacheDirectory: () async => Directory('${temp.path}/cache'),
      download: (_) async {
        downloads++;
        return png;
      },
    );
    repository = BallMediaRepository(
      images: images,
      documentsDirectory: () async => temp,
      approved: {'synthetic.model': CatalogPhoto.fromJson(photoJson())},
    );
  });
  tearDown(() async {
    repository.dispose();
    await temp.delete(recursive: true);
  });

  mediaTest(
    'permission is checked before cache/network, including revoked permissions',
    () async {
      await images.commercial(CatalogPhoto.fromJson(photoJson()));
      expect(downloads, 1);
      await expectLater(
        images.commercial(CatalogPhoto.fromJson(photoJson(authorised: false))),
        throwsStateError,
      );
      expect(downloads, 1);
    },
  );
  mediaTest(
    'authorised disk cache is reusable offline and damaged bytes are refetched',
    () async {
      final photo = CatalogPhoto.fromJson(photoJson());
      expect(await images.commercial(photo), png);
      final offline = BallImageService(
        cacheDirectory: images.cacheDirectory,
        download: (_) async => throw const SocketException('offline'),
      );
      expect(await offline.commercial(photo), png);
      final files = await (await images.cacheDirectory()).list().toList();
      await (files.whereType<File>().singleWhere(
        (f) => f.path.endsWith('.bin'),
      )).writeAsString('broken');
      expect(await images.commercial(photo), png);
      expect(downloads, 2);
    },
  );
  mediaTest(
    'without cache permission no persistent image files are created',
    () async {
      final photo = CatalogPhoto.fromJson(photoJson(cache: false));
      await images.commercial(photo);
      await images.commercial(photo);
      expect(downloads, 2);
      expect(await (await images.cacheDirectory()).exists(), isFalse);
    },
  );
  mediaTest(
    'concurrent requests share a download and failed requests can be retried',
    () async {
      final gate = Completer<Uint8List>();
      var calls = 0;
      final service = BallImageService(
        download: (_) {
          calls++;
          return gate.future;
        },
      );
      final photo = CatalogPhoto.fromJson(photoJson(cache: false));
      final a = service.commercial(photo), b = service.commercial(photo);
      gate.complete(png);
      await Future.wait([a, b]);
      expect(calls, 1);
      var failing = true;
      final retry = BallImageService(
        download: (_) async {
          if (failing) throw const SocketException('offline');
          return png;
        },
      );
      await expectLater(
        retry.commercial(photo),
        throwsA(isA<SocketException>()),
      );
      failing = false;
      expect(await retry.commercial(photo), png);
    },
  );
  mediaTest(
    'invalid, oversized and missing personal files fail safely',
    () async {
      await expectLater(
        BallImageService.validateImage(Uint8List(0)),
        throwsFormatException,
      );
      await expectLater(
        BallImageService.validateImage(
          Uint8List(BallImageService.maxImageBytes + 1),
        ),
        throwsFormatException,
      );
      await expectLater(
        BallImageService.validateImage(Uint8List.fromList([1, 2, 3])),
        throwsA(anything),
      );
      expect(
        await repository.resolve(
          uid: 'a',
          ballId: 'missing',
          draftPersonalPath: '${temp.path}/missing',
        ),
        isNull,
      );
    },
  );
  mediaTest(
    'personal pictures win, persist, and catalog linking never overwrites them',
    () async {
      final original = File('${temp.path}/user.png');
      await original.writeAsBytes(png);
      await repository.save(
        uid: 'a',
        ballId: 'unchanged-id',
        personalPath: original.path,
      );
      final first = await repository.metadata('a', 'unchanged-id');
      await repository.save(
        uid: 'a',
        ballId: 'unchanged-id',
        catalogId: 'synthetic.model',
      );
      expect(
        (await repository.metadata('a', 'unchanged-id'))['personalFile'],
        first['personalFile'],
      );
      await original.delete();
      expect(await repository.resolve(uid: 'a', ballId: 'unchanged-id'), png);
      expect(downloads, 0);
      final reopened = BallMediaRepository(
        images: images,
        documentsDirectory: () async => temp,
      );
      expect(await reopened.resolve(uid: 'a', ballId: 'unchanged-id'), png);
      reopened.dispose();
    },
  );
  mediaTest(
    'same ball ID in other accounts and guest remains isolated',
    () async {
      await repository.save(
        uid: 'a',
        ballId: 'same-id',
        catalogId: 'synthetic.model',
      );
      expect(await repository.resolve(uid: 'b', ballId: 'same-id'), isNull);
      expect(await repository.resolve(ballId: 'same-id'), isNull);
      expect(await repository.metadata('b', 'same-id'), isEmpty);
      expect(await repository.resolve(uid: 'a', ballId: 'same-id'), png);
    },
  );
  mediaTest(
    'two units of the same commercial model keep independent metadata',
    () async {
      await Future.wait([
        repository.save(
          uid: 'a',
          ballId: 'unit-1',
          catalogId: 'synthetic.model',
        ),
        repository.save(
          uid: 'a',
          ballId: 'unit-2',
          catalogId: 'synthetic.model',
        ),
      ]);
      expect(
        (await repository.metadata('a', 'unit-1'))['catalogId'],
        'synthetic.model',
      );
      expect(
        (await repository.metadata('a', 'unit-2'))['catalogId'],
        'synthetic.model',
      );
    },
  );
  mediaTest(
    'failed photo replacement preserves the previous metadata and file',
    () async {
      final file = File('${temp.path}/user.png');
      await file.writeAsBytes(png);
      await repository.save(uid: 'a', ballId: 'one', personalPath: file.path);
      final before = await repository.metadata('a', 'one');
      await expectLater(
        repository.save(
          uid: 'a',
          ballId: 'one',
          personalPath: '${temp.path}/absent',
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(await repository.metadata('a', 'one'), before);
      expect(await repository.resolve(uid: 'a', ballId: 'one'), png);
      await repository.save(
        uid: 'a',
        ballId: 'one',
        catalogId: 'synthetic.model',
      );
      expect(await repository.resolve(uid: 'a', ballId: 'one'), png);
    },
  );
  mediaTest('corrupt metadata fails closed and is not rewritten', () async {
    final folder = Directory('${temp.path}/ball_media_v1/guest');
    await folder.create(recursive: true);
    final file = File('${folder.path}/index.json');
    await file.writeAsString('{broken');
    expect(await repository.resolve(ballId: 'one'), isNull);
    await expectLater(
      repository.save(uid: null, ballId: 'one', catalogId: 'synthetic.model'),
      throwsFormatException,
    );
    expect(await file.readAsString(), '{broken');
  });
  mediaTest(
    'pending research is complete, separate and never compiled as authorised',
    () {
      final ledger =
          jsonDecode(
                File('docs/catalog/c4/photo_research.json').readAsStringSync(),
              )
              as Map;
      final models = ledger['models'] as List;
      final catalog =
          jsonDecode(
                File(
                  'docs/catalog/c2/catalog_real_v2.review.json',
                ).readAsStringSync(),
              )
              as Map;
      expect(
        models.map((m) => m['id']).toSet(),
        (catalog['balls'] as List).map((b) => b['id']).toSet(),
      );
      expect(models, hasLength(28));
      expect(
        models.where((m) => m['status'] == 'pending_authorization'),
        hasLength(20),
      );
      expect(models.where((m) => m['status'] == 'not_usable'), hasLength(8));
      expect(
        models.every(
          (m) =>
              m['publicDistributionAuthorized'] == false &&
              m['privateUseAuthorized'] == false,
        ),
        isTrue,
      );
      expect(jsonDecode(authorizedCatalogPhotosJson), isEmpty);
      expect(
        jsonDecode(
          File('docs/catalog/c4/authorized_photos.json').readAsStringSync(),
        ),
        isEmpty,
      );
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('docs/catalog/c4'), isFalse);
      expect(
        (catalog['balls'] as List).every((b) => b['photo'] == null),
        isTrue,
      );
    },
  );
  mediaTest(
    'approval preparation rejects unknown models, missing app approval and missing distribution permission',
    () {
      final entry = {
        'photo': photoJson(),
        'appApprovalReference': 'TEST APPROVAL',
        'permissionEvidence': 'TEST EVIDENCE',
        'publicDistributionAuthorized': true,
      };
      expect(
        generator.validateApprovedPhotos(
          {'synthetic.model': entry},
          {'synthetic.model'},
        ),
        hasLength(1),
      );
      expect(
        () => generator.validateApprovedPhotos(
          {'unknown': entry},
          {'synthetic.model'},
        ),
        throwsFormatException,
      );
      expect(
        () => generator.validateApprovedPhotos(
          {
            'synthetic.model': {...entry, 'appApprovalReference': null},
          },
          {'synthetic.model'},
        ),
        throwsFormatException,
      );
      expect(
        () => generator.validateApprovedPhotos(
          {
            'synthetic.model': {
              ...entry,
              'publicDistributionAuthorized': false,
            },
          },
          {'synthetic.model'},
        ),
        throwsFormatException,
      );
      expect(
        () => generator.validateApprovedPhotos(
          {
            'synthetic.model': {
              ...entry,
              'photo': photoJson(authorised: false),
            },
          },
          {'synthetic.model'},
        ),
        throwsFormatException,
      );
    },
  );
  mediaTest(
    'a remote photo attestation cannot bypass the release registry',
    () async {
      final empty = BallMediaRepository(
        images: images,
        documentsDirectory: () async => temp,
        approved: {},
      );
      expect(await empty.resolve(catalogId: 'synthetic.model'), isNull);
      expect(downloads, 0);
      empty.dispose();
    },
  );
  mediaTest(
    'a missing personal photo falls back to an authorised model and revocation blocks cached bytes',
    () async {
      await repository.save(
        uid: 'a',
        ballId: 'one',
        catalogId: 'synthetic.model',
      );
      expect(
        await repository.resolve(
          uid: 'a',
          ballId: 'one',
          draftPersonalPath: '${temp.path}/missing',
        ),
        png,
      );
      expect(downloads, 1);
      final revoked = BallMediaRepository(
        images: images,
        documentsDirectory: () async => temp,
        approved: {},
      );
      expect(await revoked.resolve(uid: 'a', ballId: 'one'), isNull);
      expect(downloads, 1);
      revoked.dispose();
    },
  );
  mediaTest(
    'persistent cache stays bounded and preserves unrelated files',
    () async {
      final directory = await images.cacheDirectory();
      await directory.create(recursive: true);
      final keep = File('${directory.path}/keep.txt');
      await keep.writeAsString('keep');
      for (var i = 0; i < BallImageService.maxCacheEntries + 1; i++) {
        await images.commercial(
          CatalogPhoto.fromJson({
            ...photoJson(),
            'url': 'https://example.invalid/synthetic-$i.png',
          }),
        );
      }
      final entries = await directory.list().toList();
      expect(
        entries.whereType<File>().where((f) => f.path.endsWith('.bin')),
        hasLength(BallImageService.maxCacheEntries),
      );
      expect(await keep.readAsString(), 'keep');
    },
  );

  mediaTest(
    'malformed entries and path traversal cannot rewrite the photo index',
    () async {
      final directory = Directory('${temp.path}/ball_media_v1/guest');
      await directory.create(recursive: true);
      final file = File('${directory.path}/index.json');
      final bad = jsonEncode({
        'one': {'personalFile': '../outside.bin'},
      });
      await file.writeAsString(bad);
      expect(await repository.resolve(ballId: 'one'), isNull);
      await expectLater(
        repository.save(uid: null, ballId: 'one', catalogId: 'synthetic.model'),
        throwsFormatException,
      );
      expect(await file.readAsString(), bad);
    },
  );
  mediaTest(
    'an invalid draft still prefers the saved personal image over commercial artwork',
    () async {
      final file = File('${temp.path}/own.png');
      await file.writeAsBytes(png);
      await repository.save(
        uid: 'a',
        ballId: 'one',
        catalogId: 'synthetic.model',
        personalPath: file.path,
      );
      expect(
        await repository.resolve(
          uid: 'a',
          ballId: 'one',
          draftPersonalPath: '${temp.path}/missing',
        ),
        png,
      );
      expect(downloads, 0);
    },
  );
  testWidgets('loading and failure use owned fallback without distortion', (
    tester,
  ) async {
    final gate = Completer<Uint8List>();
    final service = BallImageService(download: (_) => gate.future);
    final repo = BallMediaRepository(
      images: service,
      approved: {
        'synthetic.model': CatalogPhoto.fromJson(photoJson(cache: false)),
      },
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repo,
        child: const MaterialApp(home: BallPhoto(catalogId: 'synthetic.model')),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.completeError(const SocketException('offline'));
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect(image.fit, BoxFit.contain);
    repo.dispose();
  });
  testWidgets(
    'switching account never retains previous picture during loading',
    (tester) async {
      final gated = GatedMedia();
      Widget screen(String uid) =>
          ChangeNotifierProvider<BallMediaRepository>.value(
            value: gated,
            child: MaterialApp(
              home: BallPhoto(ownerUid: uid, ballId: 'same-id'),
            ),
          );
      await tester.pumpWidget(screen('a'));
      gated.a.complete(png);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<ResizeImage>(),
      );
      await tester.pumpWidget(screen('b'));
      await tester.pump();
      expect(tester.widget<Image>(find.byType(Image)).image, isA<AssetImage>());
      gated.b.complete(null);
      await tester.pumpAndSettle();
      gated.dispose();
    },
  );
}

class GatedMedia extends BallMediaRepository {
  final a = Completer<Uint8List?>(), b = Completer<Uint8List?>();
  @override
  Future<Uint8List?> resolve({
    String? uid,
    String? ballId,
    String? catalogId,
    String? draftPersonalPath,
  }) => uid == 'a' ? a.future : b.future;
}
