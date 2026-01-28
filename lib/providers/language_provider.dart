import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('es');
  bool _isInitialized = false;
  late Future<void> _initializationFuture;

  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;
  Future<void> get initializationFuture => _initializationFuture;

  LanguageProvider() {
    _initializationFuture = _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'es';
      _locale = Locale(languageCode);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // Fall back to default locale on error
      _locale = const Locale('es');
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