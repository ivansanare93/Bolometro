import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/utils/url_utils.dart';

void main() {
  group('UrlUtils', () {
    group('isValidHttpUrl', () {
      test('returns true for valid HTTP URLs', () {
        expect(UrlUtils.isValidHttpUrl('http://example.com/image.jpg'), true);
        expect(UrlUtils.isValidHttpUrl('http://www.example.com'), true);
      });

      test('returns true for valid HTTPS URLs', () {
        expect(UrlUtils.isValidHttpUrl('https://example.com/image.jpg'), true);
        expect(UrlUtils.isValidHttpUrl('https://www.example.com'), true);
        expect(
          UrlUtils.isValidHttpUrl('https://lh3.googleusercontent.com/a/photo.jpg'),
          true,
        );
      });

      test('returns false for file:// URLs', () {
        expect(
          UrlUtils.isValidHttpUrl('file:///data/user/0/com.bolometro/cache/scaled_1000162952.jpg'),
          false,
        );
        expect(UrlUtils.isValidHttpUrl('file:///path/to/image.jpg'), false);
      });

      test('returns false for null or empty strings', () {
        expect(UrlUtils.isValidHttpUrl(null), false);
        expect(UrlUtils.isValidHttpUrl(''), false);
      });

      test('returns false for invalid URLs', () {
        expect(UrlUtils.isValidHttpUrl('not a url'), false);
        expect(UrlUtils.isValidHttpUrl('ftp://example.com'), false);
        expect(UrlUtils.isValidHttpUrl('data:image/png;base64,abc123'), false);
      });
    });

    group('sanitizePhotoUrl', () {
      test('returns valid HTTP URLs unchanged', () {
        const url = 'http://example.com/image.jpg';
        expect(UrlUtils.sanitizePhotoUrl(url), url);
      });

      test('returns valid HTTPS URLs unchanged', () {
        const url = 'https://lh3.googleusercontent.com/a/photo.jpg';
        expect(UrlUtils.sanitizePhotoUrl(url), url);
      });

      test('returns null for file:// URLs', () {
        expect(
          UrlUtils.sanitizePhotoUrl('file:///data/user/0/com.bolometro/cache/scaled_1000162952.jpg'),
          null,
        );
      });

      test('returns null for null or empty strings', () {
        expect(UrlUtils.sanitizePhotoUrl(null), null);
        expect(UrlUtils.sanitizePhotoUrl(''), null);
      });

      test('returns null for invalid URLs', () {
        expect(UrlUtils.sanitizePhotoUrl('not a url'), null);
        expect(UrlUtils.sanitizePhotoUrl('ftp://example.com'), null);
      });
    });
  });
}
