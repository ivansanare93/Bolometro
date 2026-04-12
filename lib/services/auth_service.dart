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

  /// Iniciar sesión con correo electrónico y contraseña
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      _user = userCredential.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _emailAuthErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      debugPrint('FirebaseAuthException en signInWithEmail: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado al iniciar sesión.\n'
          'Por favor, intenta nuevamente.';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error inesperado en signInWithEmail: $e');
      return false;
    }
  }

  /// Registrar una nueva cuenta con correo electrónico y contraseña
  Future<bool> registerWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      _user = userCredential.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _emailAuthErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      debugPrint('FirebaseAuthException en registerWithEmail: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado al crear la cuenta.\n'
          'Por favor, intenta nuevamente.';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error inesperado en registerWithEmail: $e');
      return false;
    }
  }

  /// Enviar correo de restablecimiento de contraseña
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _emailAuthErrorMessage(e);
      notifyListeners();
      debugPrint('FirebaseAuthException en resetPassword: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado. Por favor, intenta nuevamente.';
      notifyListeners();
      debugPrint('Error inesperado en resetPassword: $e');
      return false;
    }
  }

  /// Traduce los códigos de error de Firebase Auth para email/contraseña
  String _emailAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe ninguna cuenta con este correo electrónico.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.\n'
            'Por favor, verifica tus datos e intenta nuevamente.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.\n'
            'Contacta al soporte para más información.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico.\n'
            'Intenta iniciar sesión o usa otro correo.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.\n'
            'Debe tener al menos 6 caracteres.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos.\n'
            'Intenta nuevamente más tarde.';
      case 'network-request-failed':
        return 'Error de red.\n'
            'Verifica tu conexión a Internet e intenta nuevamente.';
      case 'operation-not-allowed':
        return 'El inicio de sesión con correo no está habilitado.\n'
            'Contacta al administrador de la aplicación.';
      default:
        return 'Error de autenticación: ${e.message ?? e.code}';
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
