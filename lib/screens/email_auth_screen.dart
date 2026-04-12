import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/achievement_service.dart';
import '../services/analytics_service.dart';
import '../repositories/data_repository.dart';
import '../models/perfil_usuario.dart';
import '../l10n/app_localizations.dart';

/// Pantalla de autenticación por correo electrónico y contraseña.
/// Permite iniciar sesión en una cuenta existente o crear una cuenta nueva.
class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isProcessing = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final dataRepository = Provider.of<DataRepository>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isProcessing = true;
    });

    final bool success;
    if (_isRegisterMode) {
      success = await authService.registerWithEmail(email, password);
    } else {
      success = await authService.signInWithEmail(email, password);
    }

    if (success && authService.userId != null) {
      // Log successful email sign-in
      try {
        final analytics =
            Provider.of<AnalyticsService>(context, listen: false);
        await analytics.logLogin('email');
      } catch (e) {
        debugPrint('Error logging login: $e');
      }

      // Configurar el repositorio con el usuario autenticado
      await dataRepository.setUser(authService.userId);
      // Update AchievementService to use the user-specific sessions box
      if (mounted) {
        final achievementService =
            Provider.of<AchievementService>(context, listen: false);
        achievementService
            .updateSesionesBoxName(dataRepository.sesionesBoxName);
      }

      // Crear/actualizar perfil con los datos del correo
      try {
        final user = authService.user;
        if (user != null) {
          final perfilExistente = await dataRepository.obtenerPerfil();

          if (perfilExistente == null || perfilExistente.nombre.trim().isEmpty) {
            // Primera vez: crear perfil con el correo como nombre provisional
            final nombreInicial = email.split('@').first;
            final nuevoPerfil = PerfilUsuario(
              nombre: nombreInicial,
              email: user.email,
              isFromGoogle: false,
            );
            await dataRepository.guardarPerfilLocal(nuevoPerfil);
            debugPrint('Perfil inicial creado para usuario de correo');
          } else if (perfilExistente.email != user.email) {
            // Actualizar email si ha cambiado
            final perfilActualizado =
                perfilExistente.copyWith(email: user.email);
            await dataRepository.guardarPerfil(perfilActualizado);
          }
        }
      } catch (e) {
        debugPrint('Error al crear/actualizar perfil desde email: $e');
      }

      // Sincronizar datos locales a la nube
      try {
        await dataRepository.sincronizarANube();
      } catch (e) {
        debugPrint('Error al sincronizar datos: $e');
      }

      // Volver a la pantalla anterior; AuthWrapper ya habrá redirigido a HomeScreen
      if (mounted) {
        Navigator.of(context).pop();
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

  Future<void> _handleResetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterEmail),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.resetPassword(email);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordResetSent),
          backgroundColor: Colors.green,
        ),
      );
    } else if (authService.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isRegisterMode ? l10n.createAccount : l10n.signIn,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: cs.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.enterEmail;
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                      return l10n.enterValidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: _isRegisterMode
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onFieldSubmitted: _isRegisterMode ? null : (_) => _handleSubmit(),
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterPassword;
                    }
                    if (_isRegisterMode && value.length < 6) {
                      return l10n.passwordTooShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm password field (only in register mode)
                if (_isRegisterMode) ...[
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleSubmit(),
                    decoration: InputDecoration(
                      labelText: '${l10n.password} (confirmar)',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.enterPassword;
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Forgot password link (only in login mode)
                if (!_isRegisterMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isProcessing ? null : _handleResetPassword,
                      child: Text(
                        l10n.forgotPassword,
                        style: TextStyle(color: cs.primary),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Submit button
                ElevatedButton(
                  onPressed: _isProcessing ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isRegisterMode ? l10n.createAccount : l10n.signIn,
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 24),

                // Toggle login / register
                Center(
                  child: TextButton(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            setState(() {
                              _isRegisterMode = !_isRegisterMode;
                              _formKey.currentState?.reset();
                              _passwordController.clear();
                              _confirmPasswordController.clear();
                            });
                          },
                    child: Text(
                      _isRegisterMode
                          ? l10n.alreadyHaveAccount
                          : l10n.noAccount,
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
