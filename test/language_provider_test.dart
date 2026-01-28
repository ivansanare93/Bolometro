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
      // Give some time for async initialization
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('LanguageProvider initializes with Spanish locale', () async {
      expect(languageProvider.locale, equals(const Locale('es')));
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
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Assert
      expect(newProvider.locale, equals(const Locale('en')));
    });
  });
}
