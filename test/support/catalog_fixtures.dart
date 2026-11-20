import 'dart:convert';
import 'dart:io';
import 'package:bolometro/repositories/ball_catalog_repository.dart';

String catalogSeed() =>
    File('assets/catalog/catalog_seed.json').readAsStringSync();
String catalogDemo() =>
    File('assets/catalog/catalog_demo.json').readAsStringSync();
Map<String, dynamic> demoObject() =>
    jsonDecode(catalogDemo()) as Map<String, dynamic>;

/// Test-only simulated commercial snapshot; never bundled or published.
String simulatedCatalog(int version) {
  final data = demoObject();
  data['version'] = version;
  data['isTestData'] = false;
  for (final ball in data['balls'] as List) {
    ball['isTestData'] = false;
    ball['sources'][0]['kind'] = 'manual_verified';
    ball['sources'][0]['url'] = 'https://example.invalid/fictional-source';
  }
  return jsonEncode(data);
}

class MemoryCatalogCache implements CatalogCache {
  String? value;
  bool failWrite = false;
  bool failRead = false;
  @override
  Future<String?> read() async {
    if (failRead) throw const FileSystemException('simulated cache read error');
    return value;
  }

  @override
  Future<void> write(String json) async {
    if (failWrite)
      throw const FileSystemException('simulated cache write error');
    value = json;
  }
}

BallCatalogRepository memoryCatalog({
  MemoryCatalogCache? cache,
  bool enabled = true,
}) => BallCatalogRepository(
  commercialCatalogEnabled: enabled,
  cache: cache ?? MemoryCatalogCache(),
  loadSeed: () async => catalogSeed(),
  loadDemo: () async => catalogDemo(),
);
