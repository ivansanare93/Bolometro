import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('es');
  bool _isInitialized = false;
  late Future<void> _initializationFuture;

  /// Language codes supported by the app.
  static const List<String> _supportedLanguages = ['en', 'es'];

  /// Optional resolver used to obtain the device's system locale. Defaults to
  /// [ui.PlatformDispatcher.instance.locale]. Exposed so tests can inject a
  /// deterministic locale without depending on the host machine's settings.
  final Locale Function() _systemLocaleResolver;

  static Locale _defaultSystemLocaleResolver() =>
      ui.PlatformDispatcher.instance.locale;

  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;
  Future<void> get initializationFuture => _initializationFuture;

  LanguageProvider({Locale Function()? systemLocaleResolver})
      : _systemLocaleResolver =
            systemLocaleResolver ?? _defaultSystemLocaleResolver {
    _initializationFuture = _loadLanguagePreference();
  }

  /// Returns the language code to use when no user preference is saved.
  /// Uses the device's system locale if it is a supported language; otherwise
  /// falls back to Spanish.
  String _getDefaultLanguageCode() {
    final systemLanguage = _systemLocaleResolver().languageCode;
    return _supportedLanguages.contains(systemLanguage) ? systemLanguage : 'es';
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString('language_code');
      final languageCode = savedLanguageCode ?? _getDefaultLanguageCode();
      _locale = Locale(languageCode);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // Fall back to system/default locale on error
      _locale = Locale(_getDefaultLanguageCode());
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
      // Only update state after successful persistence
      _locale = locale;
      notifyListeners();
    } catch (e) {
      // Log error and don't change the locale if persistence fails
      debugPrint('Error saving language preference: $e');
      // Optionally, you could still update the locale for the current session:
      // _locale = locale;
      // notifyListeners();
    }
  }
}