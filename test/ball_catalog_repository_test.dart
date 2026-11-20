import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/models/catalog_ball.dart';
import 'package:bolometro/repositories/ball_catalog_repository.dart';
import 'support/catalog_fixtures.dart';

class FailedCatalogSource implements CatalogUpdateSource {
  @override
  Future<String> fetchSnapshot() async =>
      throw StateError('simulated network failure');
}

void main() {
  test(
    'demo is separate and never replaces or persists the commercial catalog',
    () async {
      final cache = MemoryCatalogCache();
      final repo = memoryCatalog(cache: cache);
      await repo.load();
      expect((await repo.demonstration()).balls, hasLength(3));
      expect(repo.snapshot!.balls, isEmpty);
      expect(cache.value, isNull);
      await expectLater(repo.install(catalogDemo()), throwsFormatException);
    },
  );
  test(
    'search ignores case and accents and supports aliases and combined filters',
    () {
      final data = CatalogSnapshot.parse(catalogDemo());
      expect(
        BallCatalogRepository.search(data, query: 'ALFA orbita'),
        hasLength(1),
      );
      expect(
        BallCatalogRepository.search(data, query: 'ejemplo'),
        hasLength(1),
      );
      expect(
        BallCatalogRepository.search(
          data,
          status: CommercialStatus.discontinued,
        ),
        hasLength(1),
      );
      expect(
        BallCatalogRepository.search(
          data,
          manufacturer: data.balls[0].manufacturer,
          status: CommercialStatus.discontinued,
        ),
        isEmpty,
      );
    },
  );
  test(
    'valid update survives repository recreation for offline search',
    () async {
      final cache = MemoryCatalogCache();
      final repo = memoryCatalog(cache: cache);
      await repo.install(simulatedCatalog(2));
      final reopened = memoryCatalog(cache: cache);
      final loaded = await reopened.load();
      expect(loaded.version, 2);
      expect(
        BallCatalogRepository.search(loaded, query: 'orbita'),
        hasLength(1),
      );
    },
  );
  test(
    'rejects invalid update and preserves last usable catalog and cache',
    () async {
      final cache = MemoryCatalogCache();
      final repo = memoryCatalog(cache: cache);
      await repo.install(simulatedCatalog(2));
      final saved = cache.value;
      await expectLater(repo.install('{bad-json'), throwsFormatException);
      expect(repo.snapshot!.version, 2);
      expect(cache.value, saved);
    },
  );
  test(
    'downgrades and changed payload under same version are rejected',
    () async {
      final repo = memoryCatalog();
      await repo.install(simulatedCatalog(3));
      await expectLater(
        repo.install(simulatedCatalog(2)),
        throwsFormatException,
      );
      await expectLater(
        repo.install(simulatedCatalog(3).replaceFirst('Órbita', 'Changed')),
        throwsFormatException,
      );
      expect(repo.snapshot!.version, 3);
    },
  );
  test('write failure does not activate new version', () async {
    final cache = MemoryCatalogCache();
    final repo = memoryCatalog(cache: cache);
    await repo.install(simulatedCatalog(2));
    cache.failWrite = true;
    await expectLater(
      repo.install(simulatedCatalog(3)),
      throwsA(isA<Exception>()),
    );
    expect(repo.snapshot!.version, 2);
  });
  test('network error leaves downloaded catalog available', () async {
    final repo = memoryCatalog();
    await repo.install(simulatedCatalog(2));
    await expectLater(repo.refresh(FailedCatalogSource()), throwsStateError);
    expect(repo.snapshot!.version, 2);
  });
  test(
    'corrupt cache falls back to bundled seed without deleting cache',
    () async {
      final cache = MemoryCatalogCache()..value = 'corrupt';
      final repo = memoryCatalog(cache: cache);
      expect((await repo.load()).balls, isEmpty);
      expect(repo.warning, isNotNull);
      expect(cache.value, 'corrupt');
    },
  );
  test(
    'concurrent updates serialize and cannot reactivate an older version',
    () async {
      final repo = memoryCatalog();
      final high = repo.install(simulatedCatalog(3));
      final low = expectLater(
        repo.install(simulatedCatalog(2)),
        throwsFormatException,
      );
      await high;
      await low;
      expect(repo.snapshot!.version, 3);
    },
  );
}
