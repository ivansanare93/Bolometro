import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/models/catalog_ball.dart';
import 'package:bolometro/models/catalog_selection.dart';
import 'support/catalog_fixtures.dart';

void main() {
  test('bundled seed has no unverified commercial products', () {
    final snapshot = CatalogSnapshot.parse(catalogSeed());
    expect(snapshot.isTestData, isFalse);
    expect(snapshot.balls, isEmpty);
  });
  test('fixtures explicitly identify fictitious models and unknown values', () {
    final snapshot = CatalogSnapshot.parse(catalogDemo());
    expect(snapshot.isTestData, isTrue);
    expect(snapshot.balls.every((b) => b.isTestData), isTrue);
    expect(snapshot.balls[1].weights.single.rgInches, isNull);
    expect(snapshot.balls[1].releaseYear, isNull);
    expect(snapshot.balls.every((b) => b.photo == null), isTrue);
  });
  test('technical values are selected by weight without extrapolation', () {
    final ball = CatalogSnapshot.parse(catalogDemo()).balls.first;
    expect(ball.specFor(14)!.rgInches, 2.54);
    expect(ball.specFor(15)!.rgInches, 2.5);
    expect(ball.specFor(16), isNull);
    expect(() => CatalogSelection(ball, 16), throwsArgumentError);
  });
  test(
    'personal prefill is marked as test and does not choose a default weight',
    () {
      final ball = CatalogSnapshot.parse(catalogDemo()).balls.first;
      final selection = CatalogSelection(ball, 15);
      expect(selection.name, startsWith('[PRUEBA]'));
      expect(selection.coverstock, 'Material de prueba Alfa');
      expect(() => CatalogSelection(ball, double.nan), throwsArgumentError);
    },
  );
  test(
    'unknown commercial weights accept personal input without inventing specs',
    () {
      final ball = CatalogSnapshot.parse(catalogDemo()).balls.last;
      expect(CatalogSelection(ball, 14.5).weightLbs, 14.5);
      expect(ball.specFor(14), isNull);
    },
  );
  final mutations = <String, void Function(Map<String, dynamic>)>{
    'schema': (data) => data['schemaVersion'] = 2,
    'duplicate model': (data) => data['balls'].add(data['balls'][0]),
    'duplicate weight': (data) =>
        data['balls'][0]['weights'].add(data['balls'][0]['weights'][0]),
    'negative RG': (data) => data['balls'][0]['weights'][0]['rgInches'] = -1,
    'text measurement': (data) =>
        data['balls'][0]['weights'][0]['rgInches'] = 'unknown',
    'mixed fixtures': (data) => data['balls'][0]['isTestData'] = false,
    'unknown source reference': (data) => data['balls'][0]['fieldSources'] = {
      'releaseYear': ['missing'],
    },
    'invalid date': (data) => data['updatedAt'] = 'yesterday',
    'overflowing date': (data) => data['updatedAt'] = '2026-13-40T00:00:00Z',
    'unknown status': (data) => data['balls'][0]['status'] = 'probably-current',
    'unsafe official URL': (data) =>
        data['balls'][0]['officialUrl'] = 'file:///private',
  };
  for (final mutation in mutations.entries) {
    test('rejects invalid catalog: ${mutation.key}', () {
      final data = demoObject();
      mutation.value(data);
      expect(
        () => CatalogSnapshot.parse(jsonEncode(data)),
        throwsFormatException,
      );
    });
  }
  test('non-fixture release year needs an identified source', () {
    final data = jsonDecode(simulatedCatalog(2)) as Map<String, dynamic>;
    data['balls'][0]['releaseYear'] = 2020;
    expect(
      () => CatalogSnapshot.parse(jsonEncode(data)),
      throwsFormatException,
    );
    data['balls'][0]['fieldSources'] = {
      'releaseYear': ['synthetic'],
    };
    expect(
      CatalogSnapshot.parse(jsonEncode(data)).balls.first.releaseYear,
      2020,
    );
  });
  test(
    'photo requires editorial rights evidence before it can be displayed',
    () {
      final unknown = CatalogPhoto.fromJson({
        'url': 'https://example.invalid/image.png',
      });
      expect(unknown.canDisplay, isFalse);
      final verified = CatalogPhoto.fromJson({
        'url': 'https://example.invalid/image.png',
        'sourceUrl': 'https://example.invalid/product',
        'rightsHolder': 'Fictional owner in unit test',
        'license': 'Test-only attestation',
        'permissionReference': 'TEST-NOT-A-REAL-LICENSE',
        'verifiedAt': '2026-10-28T00:00:00Z',
        'displayAuthorized': true,
        'cacheAuthorized': false,
      });
      expect(verified.canDisplay, isTrue);
      expect(verified.cacheAuthorized, isFalse);
    },
  );
}
