import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // For PlatformException (platform-specific errors including Google Sign-In)

/// Servicio de autenticación que maneja el login con Google
/// y la gestión de sesiones de usuario
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Constantes para códigos de error
  static const String _googleSignInConfigErrorCode = '10:';
  static const String _googleSignInConfigErrorMessage = '''Error de configuración de Google Sign-In.

Por favor, verifica:
1. El SHA-1 está registrado en Firebase Console
2. El archivo google-services.json está actualizado
3. El applicationId coincide con el de Firebase

Consulta AUTENTICACION.md para más detalles.''';

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  String? get userId => _user?.uid;

  AuthService() {
    // Escuchar cambios en el estado de autenticación
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  /// Iniciar sesión con Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Iniciar el flujo de autenticación de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // El usuario canceló el inicio de sesión
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Obtener los detalles de autenticación
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Crear credenciales para Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase con las credenciales de Google
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      
      _user = userCredential.user;
      _isLoading = false;
      notifyListeners();
      
      return true;
    } on PlatformException catch (e) {
      // Manejo específico de errores de plataforma
      String errorMsg = 'Error al iniciar sesión con Google';
      
      if (e.code == 'sign_in_failed') {
        // Error específico de Google Sign-In
        final String? message = e.message;
        if (message != null && message.contains(_googleSignInConfigErrorCode)) {
          // ApiException: 10 - Error de configuración
          errorMsg = _googleSignInConfigErrorMessage;
        } else {
          errorMsg = 'Error al iniciar sesión con Google.\n'
              'Por favor, intenta nuevamente o verifica tu configuración.';
        }
      } else if (e.code == 'network_error') {
        errorMsg = 'Error de conexión.\n'
            'Verifica tu conexión a Internet e intenta nuevamente.';
      } else {
        errorMsg = 'Error al iniciar sesión: ${e.message ?? e.code}';
      }
      
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      debugPrint('PlatformException en signInWithGoogle: ${e.code} - ${e.message}');
      return false;
    } on FirebaseAuthException catch (e) {
      // Manejo específico de errores de Firebase Auth
      String errorMsg = 'Error de autenticación';
      
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMsg = 'Ya existe una cuenta con este correo electrónico.\n'
              'Intenta iniciar sesión con otro método.';
          break;
        case 'invalid-credential':
          errorMsg = 'Las credenciales proporcionadas no son válidas.\n'
              'Por favor, intenta nuevamente.';
          break;
        case 'operation-not-allowed':
          errorMsg = 'La autenticación con Google no está habilitada.\n'
              'Contacta al administrador de la aplicación.';
          break;
        case 'user-disabled':
          errorMsg = 'Esta cuenta ha sido deshabilitada.\n'
              'Contacta al soporte para más información.';
          break;
        case 'user-not-found':
          errorMsg = 'No se encontró ninguna cuenta con estas credenciales.';
          break;
        case 'network-request-failed':
          errorMsg = 'Error de red.\n'
              'Verifica tu conexión a Internet e intenta nuevamente.';
          break;
        default:
          errorMsg = 'Error de autenticación: ${e.message ?? e.code}';
      }
      
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      debugPrint('FirebaseAuthException en signInWithGoogle: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      // Cualquier otro error no esperado
      _errorMessage = 'Error inesperado al iniciar sesión.\n'
          'Por favor, intenta nuevamente.';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error inesperado en signInWithGoogle: $e');
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      try {
        await _googleSignIn.disconnect();
      } catch (_) {
        // Disconnect can fail if already disconnected; continue with sign-out
      }

      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);

      _user = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cerrar sesión: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error en signOut: $e');
    }
  }

  /// Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
