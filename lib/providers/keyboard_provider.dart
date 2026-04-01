import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KeyboardProvider extends ChangeNotifier {
  bool _modoVisual = false;
  late final Future<void> initializationFuture;

  bool get modoVisual => _modoVisual;

  KeyboardProvider() {
    initializationFuture = _loadPreference();
  }

  /// Carga la preferencia guardada de SharedPreferences.
  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _modoVisual = prefs.getBool('keyboard_modo_visual') ?? false;
    notifyListeners();
  }

  /// Actualiza el modo de teclado y guarda la preferencia.
  Future<void> setModoVisual(bool value) async {
    _modoVisual = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keyboard_modo_visual', value);
  }
}
