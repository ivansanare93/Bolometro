import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/config/catalog_config.dart';
import 'package:bolometro/repositories/ball_catalog_repository.dart';

import 'support/catalog_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'main repository respects the actual compile-time catalog gate',
    () async {
      final cache = MemoryCatalogCache()..value = simulatedCatalog(999);
      final repo = BallCatalogRepository(cache: cache);
      expect(repo.commercialCatalogEnabled, CatalogConfig.commercialEnabled);
      if (!const bool.hasEnvironment('COMMERCIAL_CATALOG_ENABLED')) {
        expect(CatalogConfig.commercialEnabled, isFalse);
      }
      if (CatalogConfig.commercialEnabled) {
        // No cached fixture: exercise the normal enabled build, through the
        // ordinary constructor and the ordinary seed loader.
        cache.value = null;
        final snapshot = await repo.load();
        expect(snapshot.balls.length, 28);
        expect(
          snapshot.balls.fold<int>(0, (n, b) => n + b.weights.length),
          134,
        );
        expect(snapshot.isTestData, isFalse);
      } else {
        expect((await repo.load()).balls, isEmpty);
        expect(cache.value, isNotNull); // Ignored, not deleted.
        await expectLater(
          repo.install(simulatedCatalog(1000)),
          throwsUnsupportedError,
        );
      }
      repo.dispose();
    },
  );
}
