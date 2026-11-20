import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/models/catalog_ball.dart';
import 'package:bolometro/repositories/ball_catalog_repository.dart';
import 'package:bolometro/data/commercial_catalog_data.dart';
import 'package:bolometro/screens/ball_catalog_screen.dart';
import 'package:bolometro/screens/catalog_ball_detail_screen.dart';

import '../tool/catalog/generate_commercial_catalog.dart';
import '../tool/catalog/validate_review_catalog.dart';
import 'support/catalog_fixtures.dart';
import 'support/catalog_weight_reference.dart';

String reviewJson() =>
    File('docs/catalog/c2/catalog_real_v2.review.json').readAsStringSync();

void main() {
  final snapshot = validateReviewCatalog(reviewJson());

  for (final ball in snapshot.balls) {
    test('C3 metric reference for every reviewed weight: ${ball.id}', () {
      final expected = catalogWeightReference[ball.id]!.split(' ');
      expect(ball.weights.length, expected.length);
      for (final row in expected) {
        final values = row.split('/');
        final weight = ball.specFor(int.parse(values[0]))!;
        expect(weight.rgInches, double.parse(values[1]), reason: row);
        expect(weight.differentialInches, double.parse(values[2]), reason: row);
        expect(
          weight.intermediateDifferentialInches,
          values.length == 4 ? double.parse(values[3]) : null,
          reason: row,
        );
      }
    });
  }

  test('disabled build ignores but preserves an enabled build cache', () async {
    final cache = MemoryCatalogCache();
    final enabled = memoryCatalog(cache: cache);
    await enabled.install(reviewJson());
    expect((await enabled.load()).balls.length, 28);
    final saved = cache.value;
    final disabled = memoryCatalog(cache: cache, enabled: false);
    expect((await disabled.load()).balls, isEmpty);
    await expectLater(disabled.install(reviewJson()), throwsUnsupportedError);
    final source = _ObservedSource();
    await expectLater(disabled.refresh(source), throwsUnsupportedError);
    expect(source.called, isFalse);
    expect(cache.value, saved);
    final restored = memoryCatalog(cache: cache);
    expect((await restored.load()).balls.length, 28);
    enabled.dispose();
    disabled.dispose();
    restored.dispose();
  });

  test(
    'all searches and combined manufacturer/status filters match real data',
    () {
      expect(
        catalogWeightReference.keys.toSet(),
        snapshot.balls.map((b) => b.id).toSet(),
      );
      for (final ball in snapshot.balls) {
        final matches = BallCatalogRepository.search(
          snapshot,
          query: '${ball.manufacturer} ${ball.model}'.toUpperCase(),
        );
        expect(matches.map((b) => b.id), contains(ball.id));
      }
      for (final maker in snapshot.balls.map((b) => b.manufacturer).toSet()) {
        for (final status in CommercialStatus.values) {
          expect(
            BallCatalogRepository.search(
              snapshot,
              manufacturer: maker,
              status: status,
            ).map((b) => b.id).toSet(),
            snapshot.balls
                .where((b) => b.manufacturer == maker && b.status == status)
                .map((b) => b.id)
                .toSet(),
          );
        }
      }
      expect(BallCatalogRepository.search(snapshot, query: 'IDOL'), isEmpty);
      expect(
        BallCatalogRepository.search(snapshot, query: 'Sidewinder'),
        isEmpty,
      );
    },
  );

  test(
    'generated commercial data matches source and has no alternate entrypoint',
    () {
      expect(commercialCatalogJson, snapshot.json);
      expect(
        File('lib/data/commercial_catalog_data.dart').readAsStringSync(),
        buildCommercialCatalogData(snapshot.json),
      );
      expect(
        File('pubspec.yaml').readAsStringSync(),
        isNot(contains('docs/catalog')),
      );
      expect(
        File('lib/main.dart').readAsStringSync(),
        isNot(contains('catalogFactory')),
      );
      expect(CatalogSnapshot.parse(catalogSeed()).balls, isEmpty);
    },
  );

  testWidgets(
    'all 28 detail screens show all 134 weights and unknowns honestly',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var rows = 0;
      void field(String label, Object? expected) {
        final tile = tester.widget<ListTile>(
          find.widgetWithText(ListTile, label),
        );
        expect(
          (tile.subtitle as Text).data,
          expected?.toString() ?? 'No disponible',
        );
      }

      for (final ball in snapshot.balls) {
        await tester.pumpWidget(
          MaterialApp(
            home: CatalogBallDetailScreen(key: ValueKey(ball.id), ball: ball),
          ),
        );
        await tester.pumpAndSettle();
        field('Año de lanzamiento', ball.releaseYear);
        field('Tipo de cubierta', ball.coverType);
        field('Acabado de fábrica', ball.factoryFinish);
        field('Estado comercial', ball.status.label);
        field('RG (pulgadas)', null);
        final image = tester.widget<Image>(find.byType(Image));
        expect(image.image, isA<AssetImage>());
        expect(
          (image.image as AssetImage).assetName,
          'assets/logo_bolometro_min.png',
        );
        final selector = find.byType(DropdownButtonFormField<int>);
        expect(
          tester
              .widget<DropdownButton<int>>(
                find.descendant(
                  of: selector,
                  matching: find.byType(DropdownButton<int>),
                ),
              )
              .items!
              .map((i) => i.value)
              .toSet(),
          ball.weights.map((w) => w.weightLbs).toSet(),
        );
        for (final weight in ball.weights) {
          tester.widget<DropdownButtonFormField<int>>(selector).onChanged!(
            weight.weightLbs,
          );
          await tester.pumpAndSettle();
          field('RG (pulgadas)', weight.rgInches);
          field('Diferencial (pulgadas)', weight.differentialInches);
          field(
            'Diferencial intermedio (pulgadas)',
            weight.intermediateDifferentialInches,
          );
          field('Nombre del núcleo', weight.coreName ?? ball.coreName);
          field('Tipo de núcleo', weight.coreType ?? ball.coreType);
          expect(tester.takeException(), isNull);
          rows++;
        }
      }
      expect(rows, 134);
    },
  );

  testWidgets(
    'normal catalog search, filters and weight selection without special UI',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final local = BallCatalogRepository(
        commercialCatalogEnabled: true,
        cache: MemoryCatalogCache(),
        loadSeed: () async => reviewJson(),
      );
      addTearDown(local.dispose);
      await tester.pumpWidget(
        MaterialApp(home: BallCatalogScreen(repository: local)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('CATÁLOGO EN REVISIÓN'), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('MOTIV').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<CommercialStatus>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desconocido').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'hyper');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hyper Venom'));
      await tester.pumpAndSettle();
      final selector = find.byType(DropdownButtonFormField<int>);
      await tester.tap(selector);
      await tester.pumpAndSettle();
      expect(find.text('14 lb'), findsNothing);
      await tester.tap(find.text('15 lb').last);
      await tester.pumpAndSettle();
      expect(find.byType(CatalogBallDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _ObservedSource implements CatalogUpdateSource {
  bool called = false;
  @override
  Future<String> fetchSnapshot() async {
    called = true;
    return reviewJson();
  }
}
