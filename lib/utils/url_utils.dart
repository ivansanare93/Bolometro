/// Utilities for URL validation and sanitization
class UrlUtils {
  static String? _normalizeValue(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  /// Validates if a URL is a valid HTTP(S) URL
  /// Returns true if the URL starts with http:// or https://
  static bool isValidHttpUrl(String? url) {
    final normalizedUrl = _normalizeValue(url);
    if (normalizedUrl == null) {
      return false;
    }

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) {
      return false;
    }

    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  /// Returns true when the source points to a local file path.
  static bool isLocalFilePath(String? path) {
    final normalizedPath = _normalizeValue(path);
    if (normalizedPath == null) {
      return false;
    }

    return normalizedPath.startsWith('/') ||
        normalizedPath.startsWith('file://');
  }

  /// Sanitizes a photo URL to ensure it's a valid HTTP(S) URL
  /// Returns the URL if valid, null otherwise
  static String? sanitizePhotoUrl(String? url) {
    final normalizedUrl = _normalizeValue(url);
    if (normalizedUrl == null) {
      return null;
    }

    if (isValidHttpUrl(normalizedUrl)) {
      return normalizedUrl;
    }

    return null;
  }

  /// Sanitizes a local avatar path.
  static String? sanitizeLocalPhotoPath(String? path) {
    final normalizedPath = _normalizeValue(path);
    if (normalizedPath == null) {
      return null;
    }

    if (isLocalFilePath(normalizedPath)) {
      return normalizedPath;
    }

    return null;
  }

  /// Resolves the preferred photo source for a profile.
  static String? resolvePreferredPhoto({
    String? avatarPath,
    String? googlePhotoUrl,
    String? fallbackPhotoUrl,
  }) {
    return sanitizeLocalPhotoPath(avatarPath) ??
        sanitizePhotoUrl(avatarPath) ??
        sanitizePhotoUrl(googlePhotoUrl) ??
        sanitizePhotoUrl(fallbackPhotoUrl);
  }

  /// Resolves the preferred photo source for remote users.
  /// Local file paths are ignored, but remote HTTP(S) URLs are accepted.
  static String? resolveRemotePhoto({
    String? avatarPath,
    String? googlePhotoUrl,
    String? fallbackPhotoUrl,
  }) {
    return sanitizePhotoUrl(avatarPath) ??
        sanitizePhotoUrl(googlePhotoUrl) ??
        sanitizePhotoUrl(fallbackPhotoUrl);
  }
}
