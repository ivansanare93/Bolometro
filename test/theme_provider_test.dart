import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/providers/theme_provider.dart';

/// Tests for ThemeProvider
void main() {
  group('ThemeProvider', () {
    late ThemeProvider themeProvider;

    setUp(() {
      themeProvider = ThemeProvider();
    });

    test('ThemeProvider initializes with system theme mode', () {
      expect(themeProvider.themeMode, equals(ThemeMode.system));
    });

    test('setThemeMode should update theme mode', () {
      // Act
      themeProvider.setThemeMode(ThemeMode.dark);

      // Assert
      expect(themeProvider.themeMode, equals(ThemeMode.dark));
    });

    test('setThemeMode should notify listeners', () {
      bool listenerCalled = false;
      themeProvider.addListener(() {
        listenerCalled = true;
      });

      // Act
      themeProvider.setThemeMode(ThemeMode.light);

      // Assert
      expect(listenerCalled, isTrue);
    });

    test('multiple theme mode changes should work correctly', () {
      themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.themeMode, equals(ThemeMode.dark));

      themeProvider.setThemeMode(ThemeMode.light);
      expect(themeProvider.themeMode, equals(ThemeMode.light));

      themeProvider.setThemeMode(ThemeMode.system);
      expect(themeProvider.themeMode, equals(ThemeMode.system));
    });
  });
}
