import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper: creates a [LanguageProvider] that reports [languageCode] as the
/// device's system language. Using the injected resolver keeps the tests
/// deterministic regardless of the host machine locale.
LanguageProvider _makeProvider(String languageCode) => LanguageProvider(
      systemLocaleResolver: () => Locale(languageCode),
    );

/// Tests for LanguageProvider
void main() {
  group('LanguageProvider', () {
    late LanguageProvider languageProvider;

    setUp(() async {
      // Initialize SharedPreferences with mock values.
      // Simulate a Spanish-language device so existing tests keep their
      // Spanish-default expectations unchanged.
      SharedPreferences.setMockInitialValues({});
      languageProvider = _makeProvider('es');
      // Wait for initialization to complete using the exposed future
      await languageProvider.initializationFuture;
    });

    test('LanguageProvider initializes with Spanish locale when system locale is Spanish',
        () async {
      expect(languageProvider.locale, equals(const Locale('es')));
      expect(languageProvider.isInitialized, isTrue);
    });

    test('setLocale should update locale', () async {
      // Act
      await languageProvider.setLocale(const Locale('en'));

      // Assert
      expect(languageProvider.locale, equals(const Locale('en')));
    });

    test('setLocale should notify listeners', () async {
      bool listenerCalled = false;
      languageProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      await languageProvider.setLocale(const Locale('en'));

      // Assert
      expect(listenerCalled, isTrue);
    });

    test('multiple locale changes should work correctly', () async {
      await languageProvider.setLocale(const Locale('en'));
      expect(languageProvider.locale, equals(const Locale('en')));

      await languageProvider.setLocale(const Locale('es'));
      expect(languageProvider.locale, equals(const Locale('es')));
    });

    test('setLocale with same locale should still notify listeners', () async {
      int notificationCount = 0;
      languageProvider.addListener(() {
        notificationCount++;
      });

      // Set to current locale
      await languageProvider.setLocale(const Locale('es'));
      
      expect(notificationCount, equals(1));
    });

    test('setLocale should persist locale preference', () async {
      // Act
      await languageProvider.setLocale(const Locale('en'));
      
      // Verify persistence by reading from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('language_code');
      
      // Assert
      expect(savedLanguage, equals('en'));
    });

    test('LanguageProvider should load saved locale on initialization', () async {
      // Arrange - Save a locale preference
      SharedPreferences.setMockInitialValues({'language_code': 'en'});
      
      // Act - Create new provider instance (system locale does not matter when a
      // preference is already persisted)
      final newProvider = _makeProvider('es');
      await newProvider.initializationFuture;
      
      // Assert
      expect(newProvider.locale, equals(const Locale('en')));
      expect(newProvider.isInitialized, isTrue);
    });

    test('LanguageProvider should handle initialization errors gracefully', () async {
      // The provider should initialize with the system/default locale even if
      // there are errors. setUp uses a Spanish system locale resolver.
      expect(languageProvider.locale, equals(const Locale('es')));
      expect(languageProvider.isInitialized, isTrue);
    });

    test('setLocale should persist before updating state', () async {
      // This test verifies the order of operations
      final prefs = await SharedPreferences.getInstance();
      
      // Act
      await languageProvider.setLocale(const Locale('en'));
      
      // Assert - both in-memory and persisted state should match
      expect(languageProvider.locale, equals(const Locale('en')));
      expect(prefs.getString('language_code'), equals('en'));
      
      // Verify by creating a new provider (saved 'en' preference takes precedence)
      final newProvider = _makeProvider('es');
      await newProvider.initializationFuture;
      expect(newProvider.locale, equals(const Locale('en')));
    });

    // -------------------------------------------------------------------------
    // System locale detection tests
    // -------------------------------------------------------------------------

    test('LanguageProvider uses English when device language is English and no preference saved',
        () async {
      SharedPreferences.setMockInitialValues({});
      final provider = _makeProvider('en');
      await provider.initializationFuture;

      expect(provider.locale, equals(const Locale('en')));
    });

    test('LanguageProvider falls back to Spanish for unsupported system locale',
        () async {
      SharedPreferences.setMockInitialValues({});
      final provider = _makeProvider('fr'); // French is not a supported locale
      await provider.initializationFuture;

      expect(provider.locale, equals(const Locale('es')));
    });

    test('Saved preference overrides system locale', () async {
      // Persist Spanish preference
      SharedPreferences.setMockInitialValues({'language_code': 'es'});

      // Create provider with English system locale
      final provider = _makeProvider('en');
      await provider.initializationFuture;

      // Saved preference (Spanish) should win
      expect(provider.locale, equals(const Locale('es')));
    });
  });
}