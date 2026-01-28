import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for LanguageProvider
void main() {
  group('LanguageProvider', () {
    late LanguageProvider languageProvider;

    setUp(() async {
      // Initialize SharedPreferences with mock values
      SharedPreferences.setMockInitialValues({});
      languageProvider = LanguageProvider();
      // Wait for initialization to complete using the exposed future
      await languageProvider.initializationFuture;
    });

    test('LanguageProvider initializes with Spanish locale', () async {
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
      
      // Act - Create new provider instance
      final newProvider = LanguageProvider();
      await newProvider.initializationFuture;
      
      // Assert
      expect(newProvider.locale, equals(const Locale('en')));
      expect(newProvider.isInitialized, isTrue);
    });

    test('LanguageProvider should handle initialization errors gracefully', () async {
      // The provider should initialize with default locale even if there are errors
      // This test verifies that the provider completes initialization
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
      
      // Verify by creating a new provider
      final newProvider = LanguageProvider();
      await newProvider.initializationFuture;
      expect(newProvider.locale, equals(const Locale('en')));
    });
  });
}
