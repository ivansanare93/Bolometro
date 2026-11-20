import 'dart:convert';
import 'dart:io';
import '../../lib/models/catalog_ball.dart';

/// Offline preparation. Does not download or package image bytes.
Map<String, dynamic> validateApprovedPhotos(
  Map<String, dynamic> entries,
  Set<String> catalogIds,
) {
  final result = <String, dynamic>{};
  for (final item in entries.entries) {
    if (!catalogIds.contains(item.key))
      throw const FormatException('Unknown model');
    final record = Map<String, dynamic>.from(item.value as Map);
    for (final field in ['appApprovalReference', 'permissionEvidence']) {
      if (record[field] is! String ||
          (record[field] as String).trim().isEmpty) {
        throw const FormatException('Missing human approval/evidence');
      }
    }
    if (record['publicDistributionAuthorized'] != true) {
      throw const FormatException('No public distribution permission');
    }
    final photo = Map<String, dynamic>.from(record['photo'] as Map);
    if (!CatalogPhoto.fromJson(photo).canDisplay) {
      throw const FormatException('Incomplete licence or display permission');
    }
    result[item.key] = photo;
  }
  return result;
}

void main(List<String> args) {
  if (args.isNotEmpty)
    throw const FormatException('Run from repository root without arguments');
  final entries =
      jsonDecode(
            File('docs/catalog/c4/authorized_photos.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final catalog =
      jsonDecode(
            File(
              'docs/catalog/c2/catalog_real_v2.review.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final ids = (catalog['balls'] as List).map((b) => b['id'] as String).toSet();
  final approved = validateApprovedPhotos(entries, ids);
  final json = jsonEncode(approved);
  final literal =
      "'${json.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$')}'";
  File('lib/data/authorized_catalog_photos.dart').writeAsStringSync(
    '// Generated offline by tool/catalog/generate_authorized_photos.dart.\n'
    '// Only rights-reviewed photos approved for the application belong here.\n'
    'const String authorizedCatalogPhotosJson = $literal;\n',
  );
  stdout.writeln(
    'Approved commercial photographs: ${approved.length}. No images downloaded.',
  );
}
