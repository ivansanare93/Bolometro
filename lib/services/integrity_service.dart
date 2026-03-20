import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Servicio que gestiona la verificación de integridad de la aplicación
/// mediante Google Play Integrity API a través de Firebase App Check.
///
/// Firebase App Check verifica automáticamente que las solicitudes provienen
/// de una instancia auténtica de la app, usando Play Integrity en Android.
class IntegrityService {
  static final IntegrityService _instance = IntegrityService._internal();
  factory IntegrityService() => _instance;
  IntegrityService._internal();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Activa Firebase App Check con el proveedor adecuado según el entorno.
  ///
  /// - En modo **debug**: usa el proveedor de depuración (no requiere Play Store).
  /// - En modo **release**: usa Google Play Integrity API.
  ///
  /// Debe llamarse después de `Firebase.initializeApp()` y antes de
  /// cualquier operación de Firebase.
  Future<void> activate() async {
    try {
      await FirebaseAppCheck.instance.activate(
        // En producción se usa Play Integrity; en debug se usa el proveedor
        // de depuración para facilitar las pruebas sin pasar por Play Store.
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        // En iOS/macOS se usa DeviceCheck; en web se usa reCAPTCHA.
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.deviceCheck,
      );
      _initialized = true;
      debugPrint('Firebase App Check (Play Integrity) activado correctamente.');
    } catch (e) {
      // App Check no está disponible en todos los entornos (emuladores, tests).
      // Se registra el error pero no se bloquea el inicio de la app.
      debugPrint('Advertencia: Firebase App Check no pudo activarse: $e');
    }
  }

  /// Obtiene el token de App Check actual.
  ///
  /// Puede usarse para depuración, para registrar el token en los logs de
  /// desarrollo, o para adjuntarlo manualmente a solicitudes HTTP propias
  /// (no gestionadas por el SDK de Firebase).
  ///
  /// Devuelve `null` si App Check no está disponible en el entorno actual.
  Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      return await FirebaseAppCheck.instance.getToken(forceRefresh);
    } catch (e) {
      debugPrint('Error al obtener token de App Check: $e');
      return null;
    }
  }
}
