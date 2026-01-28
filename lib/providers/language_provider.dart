import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('es');
  bool _isInitialized = false;

  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  LanguageProvider() {
    _loadLanguagePreference();
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
    _locale = locale;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
    } catch (e) {
      // Log error but don't crash - the locale change is already applied in memory
      debugPrint('Error saving language preference: $e');
    }
  }
}