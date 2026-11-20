import 'dart:convert';
import 'dart:io';

import 'package:bolometro/models/catalog_ball.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/catalog/validate_review_catalog.dart';

const snapshotPath = 'docs/catalog/c2/catalog_real_v2.review.json';
const reviewPath = 'docs/catalog/c2/catalog_c2_review.json';
Map<String, dynamic> rawCatalog() =>
    jsonDecode(File(snapshotPath).readAsStringSync()) as Map<String, dynamic>;
Map<String, dynamic> rawReview() =>
    jsonDecode(File(reviewPath).readAsStringSync()) as Map<String, dynamic>;

void main() {
  test(
    'all C1 candidates are reviewed and blocked models stay out of JSON',
    () {
      final review = rawReview();
      final snapshot = validateReviewCatalog(
        File(snapshotPath).readAsStringSync(),
        review: review,
      );
      final c1 = File(
        'docs/mds/BALL_CATALOG_PHASE_C1_RESEARCH.md',
      ).readAsStringSync();
      final expectedIds = RegExp(
        r'\| \[`([^`]+)`\]',
      ).allMatches(c1).map((m) => m.group(1)).toSet();
      expect(expectedIds.length, 30);
      final reviewedIds = (review['candidates'] as List)
          .map((c) => c['id'])
          .toSet();
      expect(reviewedIds, expectedIds);
      expect(snapshot.balls.length, 28);
      expect(review['counts'], {'ready': 3, 'incomplete': 25, 'blocked': 2});
      expect(snapshot.balls.any((b) => b.id == 'roto-grip.idol'), isFalse);
      expect(
        snapshot.balls.any((b) => b.id == 'brunswick.bvp-sidewinder'),
        isFalse,
      );
    },
  );

  test('real data is not bundled, activated, cached or mixed with demo', () {
    final seedText = File(
      'assets/catalog/catalog_seed.json',
    ).readAsStringSync();
    final demoText = File(
      'assets/catalog/catalog_demo.json',
    ).readAsStringSync();
    expect(CatalogSnapshot.parse(seedText).balls, isEmpty);
    expect(CatalogSnapshot.parse(demoText).isTestData, isTrue);
    expect(
      CatalogSnapshot.parse(File(snapshotPath).readAsStringSync()).isTestData,
      isFalse,
    );
    expect(
      File('pubspec.yaml').readAsStringSync(),
      isNot(contains('docs/catalog')),
    );
    expect(rawReview()['activationApproved'], isFalse);
  });

  test('known per-weight differences and conservative nulls are preserved', () {
    final snapshot = validateReviewCatalog(
      File(snapshotPath).readAsStringSync(),
    );
    CatalogBall ball(String id) =>
        snapshot.balls.singleWhere((b) => b.id == id);
    expect(ball('storm.iq-tour-edition').specFor(15)!.differentialInches, .029);
    expect(ball('storm.iq-tour-edition').specFor(16)!.differentialInches, .035);
    expect(ball('motiv.black-venom').specFor(15)!.rgInches, 2.47);
    expect(
      ball('motiv.venom-shock-pearl').specFor(15)!.differentialInches,
      .035,
    );
    expect(ball('motiv.hyper-venom').weights.map((w) => w.weightLbs), [15]);
    expect(ball('storm.phaze-v').factoryFinish, isNull);
    expect(ball('storm.hy-road').factoryFinish, 'Power Edge');
    expect(ball('storm.phaze-ii').coreName, isNull);
    expect(ball('storm.phaze-ii').specFor(12)!.coreName, isNull);
    expect(ball('storm.phaze-ii').specFor(14)!.coreName, 'Velocity');
    expect(ball('hammer.arctic-vibe').weights.length, 7);
    expect(snapshot.balls.every((b) => b.photo == null), isTrue);
  });

  final mutations = <String, void Function(Map<String, dynamic>)>{
    'duplicate commercial ID': (d) => d['balls'].add(d['balls'][0]),
    'duplicate manufacturer and model under another ID': (d) {
      final copy = jsonDecode(jsonEncode(d['balls'][0]));
      copy['id'] = 'duplicate.product';
      d['balls'].add(copy);
    },
    'duplicate nominal weight': (d) =>
        d['balls'][0]['weights'].add(d['balls'][0]['weights'][0]),
    'fractional nominal weight': (d) =>
        d['balls'][0]['weights'][0]['weightLbs'] = 14.5,
    'unreviewed weight': (d) => d['balls'][0]['weights'][0]['weightLbs'] = 20,
    'negative RG': (d) => d['balls'][0]['weights'][0]['rgInches'] = -1,
    'likely decimal transcription error': (d) =>
        d['balls'][0]['weights'][0]['rgInches'] = .247,
    'text instead of measurement': (d) =>
        d['balls'][0]['weights'][0]['rgInches'] = '2.50',
    'negative differential': (d) =>
        d['balls'][0]['weights'][0]['differentialInches'] = -.01,
    'excessive differential': (d) =>
        d['balls'][0]['weights'][0]['differentialInches'] = 1,
    'intermediate above total differential': (d) =>
        d['balls'][0]['weights'][0]['intermediateDifferentialInches'] = .09,
    'missing manufacturer': (d) => d['balls'][0].remove('manufacturer'),
    'missing model': (d) => d['balls'][0].remove('model'),
    'missing weights': (d) => d['balls'][0].remove('weights'),
    'missing sources': (d) => d['balls'][0].remove('sources'),
    'missing explicit unknown': (d) => d['balls'][0].remove('releaseYear'),
    'untraced measurement': (d) => d['balls'][0]['fieldSources'] = {},
    'provenance for absent weight': (d) =>
        d['balls'][0]['fieldSources']['weights.10.rgInches'] = [
          'official-product',
        ],
    'nonofficial source kind': (d) =>
        d['balls'][0]['sources'][0]['kind'] = 'manual_verified',
    'nonofficial source URL': (d) => d['balls'][0]['sources'][0]['url'] =
        'https://example.invalid/not-a-manufacturer',
    'fixture mixed into real snapshot': (d) =>
        d['balls'][0]['isTestData'] = true,
    'photo without permission': (d) => d['balls'][0]['photo'] = {
      'url': 'https://example.invalid/photo.png',
      'displayAuthorized': true,
    },
  };
  for (final entry in mutations.entries) {
    test('C2 rejects ${entry.key}', () {
      final raw = rawCatalog();
      entry.value(raw);
      expect(
        () => validateReviewCatalog(jsonEncode(raw)),
        throwsFormatException,
      );
    });
  }

  test(
    'review rejects changed coverage, duplicated IDs and open approval gate',
    () {
      final text = File(snapshotPath).readAsStringSync();
      for (final change in <void Function(Map<String, dynamic>)>[
        (r) => r['candidates'][0]['verifiedWeightsLbs'] = [15],
        (r) => r['candidates'].add(r['candidates'][0]),
        (r) => r['activationApproved'] = true,
        (r) => r['counts']['ready'] = 30,
      ]) {
        final review = rawReview();
        change(review);
        expect(
          () => validateReviewCatalog(text, review: review),
          throwsFormatException,
        );
      }
    },
  );
}
