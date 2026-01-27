import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/providers/language_provider.dart';

/// Tests for LanguageProvider
void main() {
  group('LanguageProvider', () {
    late LanguageProvider languageProvider;

    setUp(() {
      languageProvider = LanguageProvider();
    });

    test('LanguageProvider initializes with Spanish locale', () {
      expect(languageProvider.locale, equals(const Locale('es')));
    });

    test('setLocale should update locale', () {
      // Act
      languageProvider.setLocale(const Locale('en'));

      // Assert
      expect(languageProvider.locale, equals(const Locale('en')));
    });

    test('setLocale should notify listeners', () {
      bool listenerCalled = false;
      languageProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      languageProvider.setLocale(const Locale('en'));

      // Assert
      expect(listenerCalled, isTrue);
    });

    test('multiple locale changes should work correctly', () {
      languageProvider.setLocale(const Locale('en'));
      expect(languageProvider.locale, equals(const Locale('en')));

      languageProvider.setLocale(const Locale('es'));
      expect(languageProvider.locale, equals(const Locale('es')));
    });

    test('setLocale with same locale should still notify listeners', () {
      int notificationCount = 0;
      languageProvider.addListener(() {
        notificationCount++;
      });

      // Set to current locale
      languageProvider.setLocale(const Locale('es'));
      
      expect(notificationCount, equals(1));
    });
  });
}
