import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/achievement_service.dart';
import '../services/analytics_service.dart';
import '../repositories/data_repository.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/perfil_usuario.dart';
import '../l10n/app_localizations.dart';

/// Pantalla de inicio de sesión con Google
class LoginScreen extends StatefulWidget {
  final VoidCallback? onContinueWithoutLogin;
  
  const LoginScreen({super.key, this.onContinueWithoutLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logScreenView('login_screen');
      } catch (e) {
        debugPrint('Error logging screen view: $e');
      }
    });
  }

  Future<void> _handleGoogleSignIn() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final dataRepository = Provider.of<DataRepository>(context, listen: false);

    setState(() {
      _isProcessing = true;
    });

    final success = await authService.signInWithGoogle();

    if (success && authService.userId != null) {
      // Log successful Google sign-in
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        await analytics.logLogin('google');
      } catch (e) {
        debugPrint('Error logging login: $e');
      }
      
      // Configurar el repositorio con el usuario autenticado
      await dataRepository.setUser(authService.userId);
      // Update AchievementService to use the user-specific sessions box
      if (mounted) {
        final achievementService = Provider.of<AchievementService>(context, listen: false);
        achievementService.updateSesionesBoxName(dataRepository.sesionesBoxName);
      }

      // Poblar/actualizar perfil con datos de la cuenta de Google
      try {
        final user = authService.user;
        if (user != null) {
          // obtenerPerfil() busca primero en Firestore (modo online) y cachea
          // en Hive local para que la pantalla de perfil lo encuentre.
          final perfilExistente = await dataRepository.obtenerPerfil();

          if (perfilExistente == null || perfilExistente.nombre.trim().isEmpty) {
            // Primera vez: crear perfil completo con datos de Google
            final nuevoPerfil = PerfilUsuario(
              nombre: user.displayName ?? 'Usuario',
              email: user.email,
              googlePhotoUrl: user.photoURL,
              googleDisplayName: user.displayName,
              isFromGoogle: true,
            );
            await dataRepository.guardarPerfil(nuevoPerfil);
            debugPrint('Perfil creado automáticamente con datos de Google');
          } else {
            // Perfil existente: actualizar campos de Google por si han cambiado
            // (foto, nombre visible, email). Las personalizaciones del usuario
            // (club, mano dominante, bio, etc.) se preservan.
            // Solo se actualiza un campo si el nuevo valor de Google no es nulo
            // y difiere del valor almacenado, evitando guardados innecesarios.
            final fotoActualizada = user.photoURL != null &&
                user.photoURL != perfilExistente.googlePhotoUrl;
            final nombreActualizado = user.displayName != null &&
                user.displayName != perfilExistente.googleDisplayName;
            final emailActualizado = user.email != null &&
                user.email != perfilExistente.email;

            if (fotoActualizada || nombreActualizado || emailActualizado) {
              final perfilActualizado = perfilExistente.copyWith(
                googlePhotoUrl: user.photoURL,
                googleDisplayName: user.displayName,
                email: user.email ?? perfilExistente.email,
                isFromGoogle: true,
              );
              await dataRepository.guardarPerfil(perfilActualizado);
              debugPrint('Datos de Google actualizados en el perfil existente');
            }
          }
        }
      } catch (e) {
        debugPrint('Error al crear/actualizar perfil desde Google: $e');
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
    await dataRepository.setUser(null);
    // Update AchievementService to use the default sessions box
    if (mounted) {
      final achievementService = Provider.of<AchievementService>(context, listen: false);
      achievementService.updateSesionesBoxName(dataRepository.sesionesBoxName);
    }
    
    // Notificar al AuthWrapper que el usuario continuó sin login
    widget.onContinueWithoutLogin?.call();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    
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
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Subtítulo
              Text(
                l10n.loginSubtitle,
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
                      l10n.whySignIn,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem(
                      Icons.cloud_sync,
                      l10n.syncDevices,
                    ),
                    _buildBenefitItem(
                      Icons.backup,
                      l10n.autoBackup,
                    ),
                    _buildBenefitItem(
                      Icons.group_add,
                      l10n.socialFeatures,
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
                  _isProcessing ? l10n.signingIn : l10n.continueWithGoogle,
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
                  l10n.continueWithoutLogin,
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Nota sobre privacidad
              Text(
                l10n.privacyNote,
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
