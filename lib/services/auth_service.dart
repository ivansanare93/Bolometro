import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Servicio de autenticación que maneja el login con Google
/// y la gestión de sesiones de usuario
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
    } catch (e) {
      String errorMsg = 'Error al iniciar sesión';
      
      // Proporcionar mensajes de error más descriptivos
      if (e.toString().contains('ApiException: 10')) {
        errorMsg = 'Error de configuración de Google Sign-In.\n\n'
            'Por favor, verifica:\n'
            '1. El SHA-1 está registrado en Firebase Console\n'
            '2. El archivo google-services.json está actualizado\n'
            '3. El applicationId coincide con el de Firebase\n\n'
            'Consulta AUTENTICACION.md para más detalles.';
      } else if (e.toString().contains('network')) {
        errorMsg = 'Error de conexión. Verifica tu conexión a Internet.';
      } else if (e.toString().contains('sign_in_failed')) {
        errorMsg = 'Error al iniciar sesión con Google. Intenta nuevamente.';
      }
      
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      debugPrint('Error en signInWithGoogle: $e');
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

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
