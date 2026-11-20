import 'dart:convert';
import 'dart:io';

import 'package:bolometro/models/catalog_ball.dart';

/// Editorial checks for the C2 artifact. Does not change the v1 runtime parser,
/// connect to a service, update a cache, or enable the catalog in the app.
CatalogSnapshot validateReviewCatalog(
  String text, {
  Map<String, dynamic>? review,
}) {
  final snapshot = CatalogSnapshot.parse(text);
  final raw = jsonDecode(text) as Map<String, dynamic>;
  if (snapshot.isTestData || snapshot.balls.isEmpty) {
    throw const FormatException('Expected nonempty real review catalog');
  }
  const hosts = {
    'Storm': {'www.stormbowling.com', 'stormbowling.com'},
    'Roto Grip': {'www.stormbowling.com', 'stormbowling.com'},
    'Hammer': {'hammerbowling.com'},
    'Brunswick': {'brunswickbowling.com'},
    'MOTIV': {'www.motivbowling.com', 'motivbowling.com'},
  };
  const explicitFields = [
    'releaseYear',
    'coverType',
    'coverMaterial',
    'coreName',
    'coreType',
    'factoryFinish',
    'officialUrl',
    'photo',
  ];
  final productNames = <String>{};
  for (var i = 0; i < snapshot.balls.length; i++) {
    final ball = snapshot.balls[i];
    final data = raw['balls'][i] as Map<String, dynamic>;
    final productKey = '${ball.manufacturer}|${ball.model}'
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
    if (!productNames.add(productKey)) {
      throw FormatException(
        '${ball.id}: duplicate manufacturer/model in pilot',
      );
    }
    if (explicitFields.any((key) => !data.containsKey(key))) {
      throw FormatException('${ball.id}: unknown fields must be explicit null');
    }
    if (ball.photo != null ||
        ball.officialUrl == null ||
        !(hosts[ball.manufacturer]?.contains(ball.officialUrl!.host) ??
            false) ||
        ball.sources.any(
          (s) =>
              s.kind != 'manufacturer' ||
              !(hosts[ball.manufacturer]?.contains(s.url?.host) ?? false) &&
                  !({'Storm', 'Roto Grip'}.contains(ball.manufacturer) &&
                      s.url?.host ==
                          'stormproducts.nyc3.cdn.digitaloceanspaces.com'),
        )) {
      throw FormatException('${ball.id}: unverified photo or official source');
    }
    if (ball.updatedAt.isAfter(snapshot.updatedAt) ||
        ball.sources.any((s) => s.checkedAt.isAfter(ball.updatedAt)) ||
        (ball.releaseYear != null && ball.releaseYear! > ball.updatedAt.year)) {
      throw FormatException('${ball.id}: inconsistent editorial dates');
    }
    void provenance(String field) {
      if (!ball.fieldSources.containsKey(field)) {
        throw FormatException('${ball.id}: missing provenance for $field');
      }
    }

    for (final field in [
      'manufacturer',
      'model',
      'officialUrl',
      ...explicitFields.where((f) => f != 'photo' && f != 'officialUrl'),
    ]) {
      if (data[field] != null) provenance(field);
    }
    if (ball.status != CommercialStatus.unknown) provenance('status');
    final validPaths = <String>{};
    for (final weight in ball.weights) {
      final prefix = 'weights.${weight.weightLbs}';
      final metrics = {
        'rgInches': weight.rgInches,
        'differentialInches': weight.differentialInches,
        'intermediateDifferentialInches': weight.intermediateDifferentialInches,
        'coreName': weight.coreName,
        'coreType': weight.coreType,
      };
      if (weight.weightLbs < 10 || weight.weightLbs > 16) {
        throw FormatException(
          '${ball.id}: weight outside reviewed pilot range',
        );
      }
      // Broad editorial sanity bounds, not a declaration of USBC compliance.
      if ((weight.rgInches != null &&
              (weight.rgInches! < 2 || weight.rgInches! > 3.5)) ||
          (weight.differentialInches != null &&
              weight.differentialInches! > .1) ||
          (weight.intermediateDifferentialInches != null &&
              (weight.intermediateDifferentialInches! > .1 ||
                  (weight.differentialInches != null &&
                      weight.intermediateDifferentialInches! >
                          weight.differentialInches!)))) {
        throw FormatException('${ball.id}: suspicious measurement at $prefix');
      }
      validPaths.add('$prefix.weightLbs');
      provenance('$prefix.weightLbs');
      for (final metric in metrics.entries) {
        validPaths.add('$prefix.${metric.key}');
        if (metric.value != null) provenance('$prefix.${metric.key}');
      }
    }
    for (final key in ball.fieldSources.keys.where(
      (key) => key.startsWith('weights.'),
    )) {
      if (!validPaths.contains(key)) {
        throw FormatException('${ball.id}: provenance for nonexistent weight');
      }
    }
  }
  if (review != null) _validateReview(snapshot, review);
  return snapshot;
}

void _validateReview(CatalogSnapshot snapshot, Map<String, dynamic> review) {
  if (review['activationApproved'] != false ||
      review['distributionRightsVerified'] != false ||
      review['photoCount'] != 0) {
    throw const FormatException(
      'C2 approval and rights gates must remain closed',
    );
  }
  final candidates = (review['candidates'] as List)
      .cast<Map<String, dynamic>>();
  final ids = candidates.map((c) => c['id']).toSet();
  if (ids.length != candidates.length) {
    throw const FormatException('Duplicate review IDs');
  }
  final counts = review['counts'] as Map<String, dynamic>;
  const classes = {'ready', 'incomplete', 'blocked'};
  if (candidates.any((c) => !classes.contains(c['classification']))) {
    throw const FormatException('Unknown review classification');
  }
  for (final classification in classes) {
    if (counts[classification] !=
        candidates.where((c) => c['classification'] == classification).length) {
      throw const FormatException('Incorrect review counts');
    }
  }
  final included = candidates.where((c) => c['included'] == true).toList();
  if (included.length != snapshot.balls.length ||
      candidates.any(
        (c) => (c['classification'] == 'blocked') != (c['included'] == false),
      )) {
    throw const FormatException('Blocked or missing review model');
  }
  for (final ball in snapshot.balls) {
    final matching = included.where((c) => c['id'] == ball.id).toList();
    if (matching.length != 1 ||
        matching.single['officialUrl'] != ball.officialUrl.toString()) {
      throw FormatException('${ball.id}: review identity mismatch');
    }
    final declared = (matching.single['verifiedWeightsLbs'] as List).toSet();
    if (declared.length != ball.weights.length ||
        !declared.containsAll(ball.weights.map((w) => w.weightLbs))) {
      throw FormatException('${ball.id}: weight coverage differs from review');
    }
    if (matching.single['classification'] == 'ready' &&
        (ball.releaseYear == null ||
            ball.status == CommercialStatus.unknown ||
            ball.coverType == null ||
            ball.coverMaterial == null ||
            ball.factoryFinish == null ||
            ball.weights.isEmpty ||
            ball.weights.any(
              (w) =>
                  w.rgInches == null ||
                  w.differentialInches == null ||
                  (w.coreName ?? ball.coreName) == null ||
                  (w.coreType ?? ball.coreType) == null,
            ))) {
      throw FormatException('${ball.id}: incomplete model marked ready');
    }
  }
}

void main(List<String> arguments) {
  final path = arguments.isEmpty
      ? 'docs/catalog/c2/catalog_real_v2.review.json'
      : arguments.first;
  final reviewPath = arguments.length < 2
      ? 'docs/catalog/c2/catalog_c2_review.json'
      : arguments[1];
  try {
    final snapshot = validateReviewCatalog(
      File(path).readAsStringSync(),
      review:
          jsonDecode(File(reviewPath).readAsStringSync())
              as Map<String, dynamic>,
    );
    stdout.writeln(
      jsonEncode({
        'valid': true,
        'models': snapshot.balls.length,
        'weightRows': snapshot.balls.fold<int>(
          0,
          (n, b) => n + b.weights.length,
        ),
        'activated': false,
      }),
    );
  } on Object catch (error) {
    stderr.writeln('Review validation failed: $error');
    exitCode = 1;
  }
}
