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

      test('trims surrounding whitespace before validating', () {
        expect(UrlUtils.isValidHttpUrl(' https://example.com/photo.jpg '), true);
      });
    });

    group('isLocalFilePath', () {
      test('returns true for absolute local paths', () {
        expect(
          UrlUtils.isLocalFilePath('/data/user/0/com.bolometro/cache/avatar.jpg'),
          true,
        );
      });

      test('returns true for file URIs', () {
        expect(
          UrlUtils.isLocalFilePath('file:///data/user/0/com.bolometro/cache/avatar.jpg'),
          true,
        );
      });

      test('returns false for remote URLs or invalid values', () {
        expect(UrlUtils.isLocalFilePath('https://example.com/avatar.jpg'), false);
        expect(UrlUtils.isLocalFilePath('avatar.jpg'), false);
        expect(UrlUtils.isLocalFilePath(null), false);
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

      test('trims valid HTTPS URLs', () {
        expect(
          UrlUtils.sanitizePhotoUrl(' https://lh3.googleusercontent.com/a/photo.jpg '),
          'https://lh3.googleusercontent.com/a/photo.jpg',
        );
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

    group('sanitizeLocalPhotoPath', () {
      test('returns local absolute paths unchanged', () {
        const path = '/data/user/0/com.bolometro/cache/avatar.jpg';
        expect(UrlUtils.sanitizeLocalPhotoPath(path), path);
      });

      test('returns trimmed file URIs unchanged', () {
        expect(
          UrlUtils.sanitizeLocalPhotoPath(' file:///data/user/0/com.bolometro/cache/avatar.jpg '),
          'file:///data/user/0/com.bolometro/cache/avatar.jpg',
        );
      });

      test('returns null for remote URLs', () {
        expect(
          UrlUtils.sanitizeLocalPhotoPath('https://example.com/avatar.jpg'),
          null,
        );
      });
    });

    group('resolvePreferredPhoto', () {
      test('prioritizes local avatar paths over remote photos', () {
        expect(
          UrlUtils.resolvePreferredPhoto(
            avatarPath: '/data/user/0/com.bolometro/cache/avatar.jpg',
            googlePhotoUrl: 'https://example.com/google.jpg',
          ),
          '/data/user/0/com.bolometro/cache/avatar.jpg',
        );
      });

      test('allows remote avatarPath values', () {
        expect(
          UrlUtils.resolvePreferredPhoto(
            avatarPath: 'https://example.com/custom-avatar.jpg',
            googlePhotoUrl: 'https://example.com/google.jpg',
          ),
          'https://example.com/custom-avatar.jpg',
        );
      });

      test('falls back to Google and auth photos', () {
        expect(
          UrlUtils.resolvePreferredPhoto(
            avatarPath: 'avatar.jpg',
            googlePhotoUrl: 'https://example.com/google.jpg',
            fallbackPhotoUrl: 'https://example.com/auth.jpg',
          ),
          'https://example.com/google.jpg',
        );
      });

      test('returns null when no candidate is usable', () {
        expect(
          UrlUtils.resolvePreferredPhoto(
            avatarPath: 'avatar.jpg',
            googlePhotoUrl: 'ftp://example.com/google.jpg',
          ),
          null,
        );
      });
    });
  });
}
