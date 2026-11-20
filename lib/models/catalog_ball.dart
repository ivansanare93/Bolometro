import 'dart:convert';

enum CommercialStatus { current, discontinued, unknown }

extension CommercialStatusLabel on CommercialStatus {
  String get label => switch (this) {
    CommercialStatus.current => 'Actual',
    CommercialStatus.discontinued => 'Descatalogada',
    CommercialStatus.unknown => 'Desconocido',
  };
}

String _text(Object? value, String field) {
  if (value is! String || value.trim().isEmpty)
    throw FormatException('Invalid $field');
  return value.trim();
}

String? _optional(Object? value, String field) =>
    value == null ? null : _text(value, field);

DateTime _date(Object? value, String field) {
  final text = _text(value, field);
  final parsed = DateTime.tryParse(text);
  final validShape = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|\+00:00)$',
  ).hasMatch(text);
  if (!validShape ||
      parsed == null ||
      !parsed.isUtc ||
      parsed.toIso8601String().substring(0, 19) != text.substring(0, 19)) {
    throw FormatException('Invalid UTC $field');
  }
  return parsed;
}

Uri? _url(Object? value, String field) {
  if (value == null) return null;
  final uri = Uri.tryParse(_text(value, field));
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    throw FormatException('Invalid HTTPS $field');
  }
  return uri;
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) throw const FormatException('Expected object');
  return Map<String, dynamic>.from(value);
}

List<dynamic> _list(Object? value) {
  if (value is! List) throw const FormatException('Expected array');
  return value;
}

class CatalogSource {
  final String id;
  final String kind;
  final Uri? url;
  final DateTime checkedAt;
  CatalogSource.fromJson(Map<String, dynamic> json)
    : id = _text(json['id'], 'source.id'),
      kind = _text(json['kind'], 'source.kind'),
      url = _url(json['url'], 'source.url'),
      checkedAt = _date(json['checkedAt'], 'source.checkedAt') {
    if (![
      'fixture',
      'manufacturer',
      'licensed_partner',
      'manual_verified',
    ].contains(kind)) {
      throw const FormatException('Unknown source kind');
    }
    if (kind != 'fixture' && url == null)
      throw const FormatException('Source URL missing');
  }
}

class CatalogPhoto {
  final Uri? url;
  final Uri? sourceUrl;
  final String? rightsHolder;
  final String? license;
  final Uri? licenseUrl;
  final String? permissionReference;
  final DateTime? verifiedAt;
  final bool displayAuthorized;
  final bool cacheAuthorized;
  CatalogPhoto.fromJson(Map<String, dynamic> json)
    : url = _url(json['url'], 'photo.url'),
      sourceUrl = _url(json['sourceUrl'], 'photo.sourceUrl'),
      rightsHolder = _optional(json['rightsHolder'], 'photo.rightsHolder'),
      license = _optional(json['license'], 'photo.license'),
      licenseUrl = _url(json['licenseUrl'], 'photo.licenseUrl'),
      permissionReference = _optional(
        json['permissionReference'],
        'photo.permissionReference',
      ),
      verifiedAt = json['verifiedAt'] == null
          ? null
          : _date(json['verifiedAt'], 'photo.verifiedAt'),
      displayAuthorized = json['displayAuthorized'] == true,
      cacheAuthorized = json['cacheAuthorized'] == true;

  /// Editorial attestation, not automatic legal verification of a website.
  bool get canDisplay =>
      displayAuthorized &&
      url != null &&
      sourceUrl != null &&
      rightsHolder != null &&
      license != null &&
      verifiedAt != null &&
      (licenseUrl != null || permissionReference != null);
}

class CatalogWeightSpec {
  final int weightLbs;
  final double? rgInches;
  final double? differentialInches;
  final double? intermediateDifferentialInches;
  final String? coreName;
  final String? coreType;
  CatalogWeightSpec.fromJson(Map<String, dynamic> json)
    : weightLbs = json['weightLbs'] is int
          ? json['weightLbs'] as int
          : throw const FormatException('Invalid nominal weight'),
      rgInches = _number(json['rgInches'], strictlyPositive: true),
      differentialInches = _number(json['differentialInches']),
      intermediateDifferentialInches = _number(
        json['intermediateDifferentialInches'],
      ),
      coreName = _optional(json['coreName'], 'weight.coreName'),
      coreType = _optional(json['coreType'], 'weight.coreType') {
    if (weightLbs < 1 || weightLbs > 20)
      throw const FormatException('Unsupported weight');
  }
  static double? _number(Object? value, {bool strictlyPositive = false}) {
    if (value == null) return null;
    if (value is! num ||
        !value.isFinite ||
        value < 0 ||
        (strictlyPositive && value == 0)) {
      throw const FormatException('Invalid technical value');
    }
    return value.toDouble();
  }
}

class CatalogBall {
  final String id;
  final String manufacturer;
  final String model;
  final List<String> aliases;
  final int? releaseYear;
  final CommercialStatus status;
  final String? coverType;
  final String? coverMaterial;
  final String? coreName;
  final String? coreType;
  final String? factoryFinish;
  final List<CatalogWeightSpec> weights;
  final Uri? officialUrl;
  final CatalogPhoto? photo;
  final DateTime updatedAt;
  final List<CatalogSource> sources;
  final Map<String, List<String>> fieldSources;
  final bool isTestData;

  CatalogBall.fromJson(Map<String, dynamic> json)
    : id = _text(json['id'], 'id'),
      manufacturer = _text(json['manufacturer'], 'manufacturer'),
      model = _text(json['model'], 'model'),
      aliases = List.unmodifiable(
        _list(json['aliases']).map((v) => _text(v, 'alias')),
      ),
      releaseYear = json['releaseYear'] == null
          ? null
          : json['releaseYear'] is int
          ? json['releaseYear'] as int
          : throw const FormatException('Invalid release year'),
      status = CommercialStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => throw const FormatException('Invalid commercial status'),
      ),
      coverType = _optional(json['coverType'], 'coverType'),
      coverMaterial = _optional(json['coverMaterial'], 'coverMaterial'),
      coreName = _optional(json['coreName'], 'coreName'),
      coreType = _optional(json['coreType'], 'coreType'),
      factoryFinish = _optional(json['factoryFinish'], 'factoryFinish'),
      weights = List.unmodifiable(
        _list(json['weights']).map((v) => CatalogWeightSpec.fromJson(_map(v))),
      ),
      officialUrl = _url(json['officialUrl'], 'officialUrl'),
      photo = json['photo'] == null
          ? null
          : CatalogPhoto.fromJson(_map(json['photo'])),
      updatedAt = _date(json['updatedAt'], 'updatedAt'),
      sources = List.unmodifiable(
        _list(json['sources']).map((v) => CatalogSource.fromJson(_map(v))),
      ),
      fieldSources = Map.unmodifiable(
        _map(json['fieldSources']).map(
          (key, value) => MapEntry(
            key,
            List<String>.unmodifiable(
              _list(value).map((v) => _text(v, 'source reference')),
            ),
          ),
        ),
      ),
      isTestData = json['isTestData'] is bool
          ? json['isTestData'] as bool
          : throw const FormatException('Missing data classification') {
    if (!RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(id))
      throw const FormatException('Invalid catalog ID');
    if (releaseYear != null && (releaseYear! < 1800 || releaseYear! > 2200))
      throw const FormatException('Invalid year');
    if (weights.map((w) => w.weightLbs).toSet().length != weights.length)
      throw const FormatException('Duplicate weight');
    final sourceIds = sources.map((s) => s.id).toSet();
    if (sourceIds.length != sources.length || sources.isEmpty)
      throw const FormatException('Missing or duplicate sources');
    if (!isTestData && sources.any((s) => s.kind == 'fixture'))
      throw const FormatException('Fixture in commercial catalog');
    for (final refs in fieldSources.values) {
      if (refs.isEmpty || refs.any((ref) => !sourceIds.contains(ref)))
        throw const FormatException('Unknown provenance');
    }
    if (!isTestData &&
        releaseYear != null &&
        !fieldSources.containsKey('releaseYear')) {
      throw const FormatException('Release year needs verified provenance');
    }
    if (photo?.displayAuthorized == true && !photo!.canDisplay)
      throw const FormatException('Incomplete photo permission');
  }

  CatalogWeightSpec? specFor(int weight) {
    for (final spec in weights) {
      if (spec.weightLbs == weight) return spec;
    }
    return null;
  }
}

class CatalogSnapshot {
  static const schemaVersion = 1;
  final int version;
  final DateTime updatedAt;
  final bool isTestData;
  final List<CatalogBall> balls;
  final String json;
  CatalogSnapshot._(
    this.version,
    this.updatedAt,
    this.isTestData,
    this.balls,
    this.json,
  );

  factory CatalogSnapshot.parse(String text) {
    if (utf8.encode(text).length > 5 * 1024 * 1024)
      throw const FormatException('Catalog too large');
    final data = _map(jsonDecode(text));
    if (data['schemaVersion'] != schemaVersion)
      throw const FormatException('Unsupported catalog schema');
    if (data['version'] is! int ||
        (data['version'] as int) < 1 ||
        data['isTestData'] is! bool) {
      throw const FormatException('Invalid catalog header');
    }
    final balls = _list(
      data['balls'],
    ).map((v) => CatalogBall.fromJson(_map(v))).toList();
    if (balls.length > 10000 ||
        balls.map((b) => b.id).toSet().length != balls.length)
      throw const FormatException('Invalid or duplicate products');
    if (balls.any((b) => b.isTestData != data['isTestData']))
      throw const FormatException('Mixed real and test data');
    return CatalogSnapshot._(
      data['version'] as int,
      _date(data['updatedAt'], 'snapshot.updatedAt'),
      data['isTestData'] as bool,
      List.unmodifiable(balls),
      jsonEncode(data),
    );
  }
}
