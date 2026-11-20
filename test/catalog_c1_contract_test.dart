import 'dart:convert';

import 'package:bolometro/models/catalog_ball.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/catalog_fixtures.dart';

// All records in these tests are synthetic. No manufacturer facts or licences.
Map<String, dynamic> syntheticSnapshot() =>
    jsonDecode(simulatedCatalog(2)) as Map<String, dynamic>;

void main() {
  test('unknown technical fields survive JSON normalization without zeros', () {
    final data = syntheticSnapshot();
    final raw = data['balls'][1] as Map<String, dynamic>;
    raw['status'] = 'unknown';
    final parsed = CatalogSnapshot.parse(jsonEncode(data));
    final ball = parsed.balls[1];
    expect(ball.status, CommercialStatus.unknown);
    expect(ball.releaseYear, isNull);
    expect(ball.factoryFinish, isNull);
    expect(ball.photo, isNull);
    final again = CatalogSnapshot.parse(parsed.json).balls[1].specFor(15)!;
    expect(again.rgInches, isNull);
    expect(again.differentialInches, isNull);
    expect(again.intermediateDifferentialInches, isNull);
  });

  test('weight-specific core and measurements are not extrapolated', () {
    final data = syntheticSnapshot();
    data['balls'][0]['weights'] = [
      {
        'weightLbs': 12,
        'rgInches': null,
        'differentialInches': null,
        'intermediateDifferentialInches': null,
        'coreName': 'Synthetic low-weight core',
        'coreType': null,
      },
      {
        'weightLbs': 16,
        'rgInches': 2.56,
        'differentialInches': .023,
        'intermediateDifferentialInches': null,
        'coreName': 'Synthetic main core',
        'coreType': 'Synthetic symmetric',
      },
    ];
    final ball = CatalogSnapshot.parse(jsonEncode(data)).balls.first;
    expect(ball.specFor(12)!.rgInches, isNull);
    expect(ball.specFor(12)!.coreName, 'Synthetic low-weight core');
    expect(ball.specFor(16)!.coreName, 'Synthetic main core');
    expect(ball.specFor(16)!.rgInches, 2.56);
    expect(ball.specFor(15), isNull);
  });

  test('per-weight provenance remains independent of array ordering', () {
    final data = syntheticSnapshot();
    final raw = data['balls'][0];
    raw['sources'].add({
      'id': 'synthetic-correction',
      'kind': 'manufacturer',
      'url': 'https://example.invalid/synthetic-correction',
      'checkedAt': '2026-10-28T00:00:00Z',
    });
    raw['fieldSources'] = {
      'weights.14.rgInches': ['synthetic'],
      'weights.15.rgInches': ['synthetic-correction'],
    };
    raw['weights'] = (raw['weights'] as List).reversed.toList();
    final ball = CatalogSnapshot.parse(jsonEncode(data)).balls.first;
    expect(ball.fieldSources['weights.15.rgInches'], ['synthetic-correction']);
    expect(ball.specFor(15)!.rgInches, 2.5);
    raw['fieldSources']['weights.15.rgInches'] = ['missing'];
    expect(
      () => CatalogSnapshot.parse(jsonEncode(data)),
      throwsFormatException,
    );
  });

  test(
    'changing official URL or commercial status does not change identity',
    () {
      final data = syntheticSnapshot();
      final first = CatalogSnapshot.parse(jsonEncode(data)).balls.first;
      data['balls'][0]['officialUrl'] =
          'https://example.invalid/new-archive-path';
      data['balls'][0]['status'] = 'discontinued';
      final revised = CatalogSnapshot.parse(jsonEncode(data)).balls.first;
      expect(revised.id, first.id);
      expect(revised.status, CommercialStatus.discontinued);
      expect(revised.specFor(15)!.rgInches, first.specFor(15)!.rgInches);
    },
  );

  test(
    'same commercial name can identify distinct products with distinct IDs',
    () {
      final data = syntheticSnapshot();
      data['balls'][1]['model'] = data['balls'][0]['model'];
      final snapshot = CatalogSnapshot.parse(jsonEncode(data));
      expect(snapshot.balls[0].model, snapshot.balls[1].model);
      expect(snapshot.balls[0].id, isNot(snapshot.balls[1].id));
      data['balls'][1]['id'] = data['balls'][0]['id'];
      expect(
        () => CatalogSnapshot.parse(jsonEncode(data)),
        throwsFormatException,
      );
    },
  );

  test('public product and image URLs alone do not authorize a photograph', () {
    final data = syntheticSnapshot();
    data['balls'][0]['officialUrl'] = 'https://example.invalid/public-product';
    data['balls'][0]['photo'] = {
      'url': 'https://example.invalid/public-photo.png',
      'sourceUrl': 'https://example.invalid/public-product',
      'displayAuthorized': true,
    };
    expect(
      () => CatalogSnapshot.parse(jsonEncode(data)),
      throwsFormatException,
    );
    data['balls'][0]['photo'] = null;
    expect(CatalogSnapshot.parse(jsonEncode(data)).balls.first.photo, isNull);
  });
}
