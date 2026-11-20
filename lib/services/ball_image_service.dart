import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';
import '../models/catalog_ball.dart';

typedef ImageDownload = Future<Uint8List> Function(Uri uri);

class BallImageService {
  static const maxImageBytes = 5 * 1024 * 1024;
  static const maxCacheBytes = 24 * 1024 * 1024;
  static const maxCacheEntries = 64;
  final Future<Directory> Function() cacheDirectory;
  final ImageDownload download;
  final Map<String, Future<Uint8List>> _inflight = {};
  Future<void> _cacheTail = Future.value();

  BallImageService({
    Future<Directory> Function()? cacheDirectory,
    ImageDownload? download,
  }) : cacheDirectory =
           cacheDirectory ??
           (() async => Directory(
             '${(await getTemporaryDirectory()).path}/ball_image_cache_v1',
           )),
       download = download ?? _download;

  static Future<void> validateImage(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > maxImageBytes)
      throw const FormatException('Image size exceeds limit');
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width > 8192 ||
          descriptor.height > 8192 ||
          descriptor.width * descriptor.height > 16000000) {
        throw const FormatException('Image dimensions exceed limit');
      }
    } finally {
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  static Future<Uint8List> _download(Uri initial) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      var uri = initial;
      for (var redirect = 0; redirect <= 3; redirect++) {
        if (uri.scheme != 'https' || uri.userInfo.isNotEmpty)
          throw const FormatException('HTTPS image required');
        final request = await client
            .getUrl(uri)
            .timeout(const Duration(seconds: 10));
        request.followRedirects = false;
        final response = await request.close().timeout(
          const Duration(seconds: 10),
        );
        if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location == null) throw const FormatException('Invalid redirect');
          uri = uri.resolve(location);
          continue;
        }
        if (response.statusCode != 200 ||
            !{
              'image/png',
              'image/jpeg',
              'image/webp',
            }.contains(response.headers.contentType?.mimeType) ||
            response.contentLength > maxImageBytes) {
          throw const FormatException('Unsupported image response');
        }
        final bytes = BytesBuilder(copy: false);
        await (() async {
          await for (final chunk in response) {
            if (bytes.length + chunk.length > maxImageBytes)
              throw const FormatException('Image too large');
            bytes.add(chunk);
          }
        })().timeout(const Duration(seconds: 15));
        return bytes.takeBytes();
      }
      throw const FormatException('Too many redirects');
    } finally {
      client.close(force: true);
    }
  }

  static String _fingerprint(CatalogPhoto photo) => jsonEncode([
    photo.url.toString(),
    photo.sourceUrl.toString(),
    photo.rightsHolder,
    photo.license,
    photo.licenseUrl?.toString(),
    photo.permissionReference,
    photo.verifiedAt?.toIso8601String(),
    photo.cacheAuthorized,
  ]);

  // The complete fingerprint in the companion metadata prevents a hash
  // collision from ever returning bytes belonging to another URL or licence.
  static String _key(String value) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(value)) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16);
  }

  Future<Uint8List> commercial(CatalogPhoto photo) {
    if (!photo.canDisplay)
      return Future.error(StateError('No documented image permission'));
    final fingerprint = _fingerprint(photo);
    return _inflight.putIfAbsent(
      fingerprint,
      () => _commercial(photo, fingerprint).whenComplete(() {
        _inflight.remove(fingerprint);
      }),
    );
  }

  Future<Uint8List> personal(String path) async {
    final file = File(path);
    if (await file.length() > maxImageBytes)
      throw const FormatException('Image too large');
    final bytes = await file.readAsBytes();
    await validateImage(bytes);
    return bytes;
  }

  Future<Uint8List> _commercial(CatalogPhoto photo, String fingerprint) async {
    if (photo.cacheAuthorized) {
      try {
        final directory = await cacheDirectory();
        final file = File('${directory.path}/${_key(fingerprint)}.bin');
        final metadata = File('${file.path}.json');
        if (await metadata.exists() &&
            await metadata.readAsString() == fingerprint) {
          final bytes = await personal(file.path);
          await file.setLastModified(DateTime.now());
          return bytes;
        }
      } catch (_) {
        /* A damaged/unavailable cache never blocks a fresh load. */
      }
    }
    final bytes = await download(
      photo.url!,
    ).timeout(const Duration(seconds: 25));
    await validateImage(bytes);
    if (photo.cacheAuthorized) {
      final write = _cacheTail.then((_) => _store(bytes, fingerprint));
      _cacheTail = write.catchError((Object _) {});
      try {
        await write;
      } catch (_) {
        /* Display may succeed without disk cache. */
      }
    }
    return bytes;
  }

  Future<void> _store(Uint8List bytes, String fingerprint) async {
    final directory = await cacheDirectory();
    await directory.create(recursive: true);
    final file = File('${directory.path}/${_key(fingerprint)}.bin');
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsBytes(bytes, flush: true);
    await temporary.rename(file.path);
    await File('${file.path}.json').writeAsString(fingerprint, flush: true);
    final entries = await directory
        .list()
        .where((e) => e is File && e.path.endsWith('.bin'))
        .cast<File>()
        .toList();
    final dated = <MapEntry<File, FileStat>>[];
    for (final entry in entries) {
      dated.add(MapEntry(entry, await entry.stat()));
    }
    dated.sort((a, b) => a.value.modified.compareTo(b.value.modified));
    var count = dated.length;
    var size = dated.fold<int>(0, (n, e) => n + e.value.size);
    for (final entry in dated) {
      if (count <= maxCacheEntries && size <= maxCacheBytes) break;
      // Only generated files under this service's own cache directory.
      await entry.key.delete();
      final metadata = File('${entry.key.path}.json');
      if (await metadata.exists()) await metadata.delete();
      count--;
      size -= entry.value.size;
    }
  }
}
