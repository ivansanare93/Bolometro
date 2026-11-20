import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../data/authorized_catalog_photos.dart';
import '../models/catalog_ball.dart';
import '../services/ball_image_service.dart';

class BallMediaRepository extends ChangeNotifier {
  final BallImageService images;
  final Future<Directory> Function() documentsDirectory;
  final Map<String, CatalogPhoto> approved;
  final Map<String, Future<Map<String, dynamic>>> _indexes = {};
  Future<void> _tail = Future.value();
  int revision = 0;
  bool _disposed = false;

  BallMediaRepository({
    BallImageService? images,
    Future<Directory> Function()? documentsDirectory,
    Map<String, CatalogPhoto>? approved,
  }) : images = images ?? BallImageService(),
       documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory,
       approved = Map.unmodifiable(
         approved ??
             {
               for (final entry
                   in (jsonDecode(authorizedCatalogPhotosJson)
                           as Map<String, dynamic>)
                       .entries)
                 entry.key: CatalogPhoto.fromJson(
                   Map<String, dynamic>.from(entry.value as Map),
                 ),
             },
       );

  String _owner(String? uid) => uid == null
      ? 'guest'
      : 'uid-${base64Url.encode(utf8.encode(uid)).replaceAll('=', '')}';
  Future<Directory> _directory(String? uid) async => Directory(
    '${(await documentsDirectory()).path}/ball_media_v1/${_owner(uid)}',
  );

  Future<Map<String, dynamic>> _index(String? uid) => _indexes.putIfAbsent(
    _owner(uid),
    () async {
      final file = File('${(await _directory(uid)).path}/index.json');
      if (!await file.exists()) return <String, dynamic>{};
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map)
        throw const FormatException('Invalid photo index; original retained');
      for (final item in decoded.entries) {
        final value = item.value;
        if (item.key is! String ||
            (item.key as String).isEmpty ||
            value is! Map ||
            value.keys.any(
              (key) => key != 'catalogId' && key != 'personalFile',
            ) ||
            (value.containsKey('catalogId') &&
                (value['catalogId'] is! String ||
                    (value['catalogId'] as String).isEmpty)) ||
            (value.containsKey('personalFile') &&
                (value['personalFile'] is! String ||
                    !RegExp(
                      r'^[A-Za-z0-9_-]+\.bin$',
                    ).hasMatch(value['personalFile'] as String)))) {
          throw const FormatException('Invalid photo entry; original retained');
        }
      }
      return Map<String, dynamic>.from(decoded);
    },
  );

  Future<Map<String, dynamic>> metadata(String? uid, String ballId) async {
    final index = await _index(uid);
    final item = index[ballId];
    return item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
  }

  Future<void> save({
    required String? uid,
    required String ballId,
    String? catalogId,
    String? personalPath,
  }) {
    final result = _tail.then((_) async {
      final index = await _index(uid);
      final next = Map<String, dynamic>.from(index);
      final entry = Map<String, dynamic>.from(await metadata(uid, ballId));
      final directory = await _directory(uid);
      await directory.create(recursive: true);
      if (personalPath != null) {
        final bytes = await images.personal(personalPath);
        final random = Random.secure();
        final name =
            '${base64Url.encode(List.generate(24, (_) => random.nextInt(256))).replaceAll('=', '')}.bin';
        await File('${directory.path}/$name').writeAsBytes(bytes, flush: true);
        // Keep original files, including an earlier personal photo. Never
        // overwrite one merely because a commercial model was linked.
        entry['personalFile'] = name;
      }
      if (catalogId != null) entry['catalogId'] = catalogId;
      next[ballId] = entry;
      final file = File('${directory.path}/index.json');
      if (await file.exists()) await file.copy('${file.path}.previous');
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(jsonEncode(next), flush: true);
      await temporary.rename(file.path);
      _indexes[_owner(uid)] = Future.value(next);
      revision++;
      if (!_disposed) notifyListeners();
    });
    _tail = result.catchError((Object _) {});
    return result;
  }

  Future<Uint8List?> resolve({
    String? uid,
    String? ballId,
    String? catalogId,
    String? draftPersonalPath,
  }) async {
    Map<String, dynamic> entry = {};
    if (ballId != null) {
      try {
        entry = await metadata(uid, ballId);
      } catch (_) {
        /* Never rewrite a damaged index. */
      }
    }
    if (draftPersonalPath != null) {
      try {
        return await images.personal(draftPersonalPath);
      } catch (_) {
        /* Keep the existing personal photo if the draft is invalid. */
      }
    }
    final stored = entry['personalFile'];
    if (stored is String && RegExp(r'^[A-Za-z0-9_-]+\.bin$').hasMatch(stored)) {
      try {
        return await images.personal('${(await _directory(uid)).path}/$stored');
      } catch (_) {
        /* Try an authorised commercial image. */
      }
    }
    final id = catalogId ?? entry['catalogId'];
    final photo = id is String ? approved[id] : null;
    if (photo?.canDisplay == true) {
      try {
        return await images.commercial(photo!);
      } catch (_) {
        /* Generic fallback. */
      }
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
