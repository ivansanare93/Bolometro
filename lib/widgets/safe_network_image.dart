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
    final sanitizedUrl = UrlUtils.sanitizePhotoUrl(photoUrl);
    
    return CircleAvatar(
      radius: radius,
      backgroundImage: sanitizedUrl != null 
          ? NetworkImage(sanitizedUrl) as ImageProvider
          : null,
      child: sanitizedUrl == null && fallbackText.isNotEmpty
          ? Text(fallbackText[0].toUpperCase())
          : null,
    );
  }
}
