import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/url_utils.dart';

/// A widget that safely displays network images with error handling
/// Only renders NetworkImage if the URL is a valid HTTP(S) URL
/// Falls back to showing initials or icon if the URL is invalid
class SafeNetworkImage extends StatelessWidget {
  final String? photoUrl;
  final String fallbackText;
  final double? radius;

  const SafeNetworkImage({
    super.key,
    required this.photoUrl,
    required this.fallbackText,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedSource = UrlUtils.sanitizeLocalPhotoPath(photoUrl) ??
        UrlUtils.sanitizePhotoUrl(photoUrl);
    ImageProvider? imageProvider;

    if (normalizedSource != null) {
      if (UrlUtils.isValidHttpUrl(normalizedSource)) {
        imageProvider = NetworkImage(normalizedSource);
      } else if (!kIsWeb) {
        imageProvider = FileImage(
          normalizedSource.startsWith('file://')
            ? File.fromUri(Uri.parse(normalizedSource))
            : File(normalizedSource),
        );
      }
    }

    return CircleAvatar(
      radius: radius,
      foregroundImage: imageProvider,
      child: fallbackText.isNotEmpty
          ? Text(fallbackText[0].toUpperCase())
          : null,
    );
  }
}
