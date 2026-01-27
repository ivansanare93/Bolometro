import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../repositories/data_repository.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import '../models/perfil_usuario.dart';
import '../utils/app_constants.dart';

/// Pantalla de inicio de sesión con Google
class LoginScreen extends StatefulWidget {
  final VoidCallback? onContinueWithoutLogin;
  
  const LoginScreen({super.key, this.onContinueWithoutLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isProcessing = false;

  Future<void> _handleGoogleSignIn() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final dataRepository = Provider.of<DataRepository>(context, listen: false);

    setState(() {
      _isProcessing = true;
    });

    final success = await authService.signInWithGoogle();

    if (success && authService.userId != null) {
      // Configurar el repositorio con el usuario autenticado
      dataRepository.setUser(authService.userId);

      // Auto-poblar perfil con datos de Google si no existe
      try {
        final perfilBox = await Hive.openBox<PerfilUsuario>(AppConstants.boxPerfilUsuario);
        final perfilExistente = perfilBox.get('perfil');
        
        // Si no hay perfil o el perfil está vacío, crear uno con datos de Google
        if (perfilExistente == null || (perfilExistente.nombre.trim().isEmpty)) {
          final user = authService.user;
          if (user != null) {
            final nuevoPerfil = PerfilUsuario(
              nombre: user.displayName ?? 'Usuario',
              email: user.email,
              googlePhotoUrl: user.photoURL,
              googleDisplayName: user.displayName,
              isFromGoogle: true,
            );
            await perfilBox.put('perfil', nuevoPerfil);
            debugPrint('Perfil creado automáticamente con datos de Google');
          }
        }
      } catch (e) {
        debugPrint('Error al crear perfil desde Google: $e');
      }

      // Sincronizar datos locales a la nube
      try {
        await dataRepository.sincronizarANube();
      } catch (e) {
        debugPrint('Error al sincronizar datos: $e');
        // No bloqueamos el flujo si falla la sincronización
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (authService.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authService.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _continueOffline() async {
    final dataRepository = Provider.of<DataRepository>(context, listen: false);
    
    // Configurar modo offline
    dataRepository.setUser(null);
    
    // Notificar al AuthWrapper que el usuario continuó sin login
    widget.onContinueWithoutLogin?.call();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Image.asset(
                'assets/logo_bolometro.png',
                height: 120,
              ),
              const SizedBox(height: 16),
              
              // Título
              Text(
                'Bolómetro',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Subtítulo
              Text(
                'Registra y analiza tus partidas de bolos',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Beneficios de iniciar sesión
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Por qué iniciar sesión?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem(
                      Icons.cloud_sync,
                      'Sincroniza tus datos en todos tus dispositivos',
                    ),
                    _buildBenefitItem(
                      Icons.backup,
                      'Copia de seguridad automática en la nube',
                    ),
                    _buildBenefitItem(
                      Icons.group_add,
                      'Prepárate para funciones sociales futuras',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Botón de inicio de sesión con Google
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleGoogleSignIn,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const FaIcon(FontAwesomeIcons.google, size: 20),
                label: Text(
                  _isProcessing ? 'Iniciando sesión...' : 'Continuar con Google',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Botón para continuar sin iniciar sesión
              TextButton(
                onPressed: _isProcessing ? null : _continueOffline,
                child: Text(
                  'Continuar sin iniciar sesión',
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Nota sobre privacidad
              Text(
                'Tus datos personales están seguros. Solo accedemos a tu información básica de perfil.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
