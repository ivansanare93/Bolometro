import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../models/catalog_ball.dart';
import '../config/catalog_config.dart';
import '../data/commercial_catalog_data.dart';

Future<String> _configuredSeed() async {
  // This const branch allows release tree shaking to omit the real dataset
  // entirely from explicitly disabled builds. It is not a separate asset.
  if (CatalogConfig.commercialEnabled) return commercialCatalogJson;
  return rootBundle.loadString('assets/catalog/catalog_seed.json');
}

abstract class CatalogCache {
  Future<String?> read();
  Future<void> write(String json);
}

class HiveCatalogCache implements CatalogCache {
  static const boxName = 'ball_catalog_cache_v1';
  Future<Box<String>> _box() => Hive.openBox<String>(boxName);
  @override
  Future<String?> read() async => (await _box()).get('snapshot');
  @override
  Future<void> write(String json) async {
    final box = await _box();
    await box.put('snapshot', json);
    await box.flush();
  }
}

/// Only the interface is provided: no external host is configured in phase B.
abstract class CatalogUpdateSource {
  Future<String> fetchSnapshot();
}

class BallCatalogRepository extends ChangeNotifier {
  final bool commercialCatalogEnabled;
  final CatalogCache cache;
  final Future<String> Function() loadSeed;
  final Future<String> Function() loadDemo;
  CatalogSnapshot? _snapshot;
  Future<CatalogSnapshot>? _loading;
  Future<void> _updateTail = Future.value();
  String? warning;
  bool _disposed = false;

  BallCatalogRepository({
    this.commercialCatalogEnabled = CatalogConfig.commercialEnabled,
    CatalogCache? cache,
    Future<String> Function()? loadSeed,
    Future<String> Function()? loadDemo,
  }) : cache = cache ?? HiveCatalogCache(),
       loadSeed = loadSeed ?? _configuredSeed,
       loadDemo =
           loadDemo ??
           (() => rootBundle.loadString('assets/catalog/catalog_demo.json'));

  CatalogSnapshot? get snapshot => _snapshot;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<CatalogSnapshot> load() => _snapshot != null
      ? Future.value(_snapshot!)
      : _loading ??= _load().whenComplete(() => _loading = null);

  Future<CatalogSnapshot> _load() async {
    final seed = CatalogSnapshot.parse(await loadSeed());
    if (seed.isTestData)
      throw const FormatException('A demo cannot be the commercial seed');
    var selected = seed;
    if (!commercialCatalogEnabled) {
      if (seed.balls.isNotEmpty) {
        throw const FormatException('Commercial catalog is disabled');
      }
      // Do not read, clear or rewrite the shared cache. A public build must not
      // reactivate private models left there by a previous enabled build.
      _snapshot = seed;
      _changed();
      return seed;
    }
    try {
      final saved = await cache.read();
      if (saved != null) {
        final candidate = CatalogSnapshot.parse(saved);
        if (candidate.isTestData)
          throw const FormatException('Test catalog in production cache');
        if (candidate.version > seed.version) selected = candidate;
        if (candidate.version == seed.version && candidate.json != seed.json) {
          throw const FormatException(
            'Same catalog version has different content',
          );
        }
      }
    } catch (_) {
      warning =
          'No se pudo recuperar el catálogo guardado. Se muestra la versión incluida en la app.';
    }
    _snapshot = selected;
    _changed();
    return selected;
  }

  Future<CatalogSnapshot> demonstration() async {
    final demo = CatalogSnapshot.parse(await loadDemo());
    if (!demo.isTestData)
      throw const FormatException('Demo must identify test data');
    return demo; // Never replaces the shared commercial snapshot or its cache.
  }

  Future<void> refresh(CatalogUpdateSource source) async {
    if (!commercialCatalogEnabled) {
      throw UnsupportedError('Commercial catalog is disabled');
    }
    await install(await source.fetchSnapshot());
  }

  Future<void> install(String json) {
    if (!commercialCatalogEnabled) {
      return Future.error(UnsupportedError('Commercial catalog is disabled'));
    }
    final result = _updateTail.then((_) async {
      final current = await load();
      final next = CatalogSnapshot.parse(json);
      if (next.isTestData)
        throw const FormatException(
          'Cannot publish demo data into commercial cache',
        );
      if (next.version < current.version)
        throw const FormatException('Catalog downgrade rejected');
      if (next.version == current.version) {
        if (next.json != current.json)
          throw const FormatException('Version collision');
        return;
      }
      await cache.write(
        next.json,
      ); // Keep active snapshot unchanged on failure.
      _snapshot = next;
      warning = null;
      _changed();
    });
    _updateTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  static String normalize(String text) {
    var result = text.toLowerCase();
    const groups = {
      'a': 'áàäâãå',
      'e': 'éèëê',
      'i': 'íìïî',
      'o': 'óòöôõ',
      'u': 'úùüû',
      'n': 'ñ',
      'c': 'ç',
    };
    for (final group in groups.entries) {
      for (final character in group.value.split('')) {
        result = result.replaceAll(character, group.key);
      }
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static List<CatalogBall> search(
    CatalogSnapshot snapshot, {
    String query = '',
    String? manufacturer,
    CommercialStatus? status,
  }) {
    final terms = normalize(
      query,
    ).split(' ').where((word) => word.isNotEmpty).toList();
    final result = snapshot.balls.where((ball) {
      if (manufacturer != null && ball.manufacturer != manufacturer)
        return false;
      if (status != null && ball.status != status) return false;
      final text = normalize(
        '${ball.manufacturer} ${ball.model} ${ball.aliases.join(' ')}',
      );
      return terms.every(text.contains);
    }).toList();
    result.sort(
      (a, b) => normalize(
        '${a.manufacturer} ${a.model}',
      ).compareTo(normalize('${b.manufacturer} ${b.model}')),
    );
    return result;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
