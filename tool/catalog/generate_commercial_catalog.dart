import 'dart:convert';
import 'dart:io';

import 'validate_review_catalog.dart';

/// Generate app data from the unchanged, reviewed source of truth. Generation
/// does not enable the compile-time gate and does not grant distribution rights.
String buildCommercialCatalogData(String json) {
  final literal = jsonEncode(json).replaceAll(r'$', r'\$');
  return '// Generated from docs/catalog/c2/catalog_real_v2.review.json.\n'
      '// No photographs. Do not edit manually; use the generator.\n'
      '// ignore_for_file: prefer_single_quotes\n'
      'const String commercialCatalogJson = $literal;\n';
}

void main() {
  final snapshot = validateReviewCatalog(
    File('docs/catalog/c2/catalog_real_v2.review.json').readAsStringSync(),
    review:
        jsonDecode(
              File('docs/catalog/c2/catalog_c2_review.json').readAsStringSync(),
            )
            as Map<String, dynamic>,
  );
  final output = File('lib/data/commercial_catalog_data.dart');
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(buildCommercialCatalogData(snapshot.json));
  stdout.writeln('Generated ${snapshot.balls.length} models; gate unchanged.');
}
