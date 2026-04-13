import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Información sobre una actualización disponible
class UpdateInfo {
  final String latestVersion;
  final String updateUrl;
  final String changelog;
  final bool forceUpdate;

  const UpdateInfo({
    required this.latestVersion,
    required this.updateUrl,
    required this.changelog,
    required this.forceUpdate,
  });
}

/// Servicio para comprobar si hay actualizaciones disponibles.
///
/// Lee el documento `app_config/version` de Firestore y compara la versión
/// remota con la instalada. Devuelve un [UpdateInfo] si hay una versión más
/// reciente, o `null` si la app está al día o si no se puede comprobar.
class UpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// Comprueba si hay una actualización disponible.
  ///
  /// Devuelve [UpdateInfo] si la versión remota es superior a la instalada,
  /// o `null` si no hay actualización o se produce cualquier error.
  Future<UpdateInfo?> checkForUpdate({String languageCode = 'es'}) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final doc = await _firestore
          .collection('app_config')
          .doc('version')
          .get(const GetOptions(source: Source.serverAndCache));

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      final latestVersion = data['latestVersion'] as String?;
      final updateUrl = data['updateUrl'] as String?;
      final forceUpdate = (data['forceUpdate'] as bool?) ?? false;
      final changelogEs = (data['changelogEs'] as String?) ?? '';
      final changelogEn = (data['changelogEn'] as String?) ?? '';

      if (latestVersion == null || updateUrl == null) return null;

      if (!_isNewerVersion(latestVersion, currentVersion)) return null;

      final changelog = languageCode == 'es' ? changelogEs : changelogEn;

      return UpdateInfo(
        latestVersion: latestVersion,
        updateUrl: updateUrl,
        changelog: changelog,
        forceUpdate: forceUpdate,
      );
    } catch (e) {
      debugPrint('UpdateService: error al comprobar actualización: $e');
      return null;
    }
  }

  /// Devuelve `true` si [remote] es estrictamente mayor que [current].
  ///
  /// Compara versiones semánticas (major.minor.patch).
  bool _isNewerVersion(String remote, String current) {
    final remoteParts = _parseParts(remote);
    final currentParts = _parseParts(current);

    final maxLen = remoteParts.length > currentParts.length
        ? remoteParts.length
        : currentParts.length;

    for (int i = 0; i < maxLen; i++) {
      final r = i < remoteParts.length ? remoteParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }

  List<int> _parseParts(String version) {
    // Remove build metadata (e.g. "1.2.3+4" → "1.2.3")
    final versionOnly = version.split('+').first;
    return versionOnly
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
  }
}
