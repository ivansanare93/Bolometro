/// Utilities for URL validation and sanitization
class UrlUtils {
  /// Validates if a URL is a valid HTTP(S) URL
  /// Returns true if the URL starts with http:// or https://
  static bool isValidHttpUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }
    
    return uri.scheme == 'http' || uri.scheme == 'https';
  }
  
  /// Sanitizes a photo URL to ensure it's a valid HTTP(S) URL
  /// Returns the URL if valid, null otherwise
  /// This prevents file:// URIs from being used with NetworkImage
  static String? sanitizePhotoUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }
    
    // Check if it's a valid HTTP/HTTPS URL
    if (isValidHttpUrl(url)) {
      return url;
    }
    
    // If it's a file:// URI or any other invalid URL, return null
    return null;
  }
}
