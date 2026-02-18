import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../models/perfil_usuario.dart';
import '../utils/app_constants.dart';
import '../services/analytics_service.dart';
import '../services/achievement_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../repositories/data_repository.dart';
import 'home.dart';

class PerfilUsuarioScreen extends StatefulWidget {
  const PerfilUsuarioScreen({super.key});

  @override
  State<PerfilUsuarioScreen> createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  late Box<PerfilUsuario> perfilBox;
  PerfilUsuario? perfil;

  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _clubController;
  late TextEditingController _bioController;
  String? _manoDominante;
  DateTime? _fechaNacimiento;
  String? _avatarPath;
  bool _clearGooglePhoto = false; // Flag para limpiar foto de Google

  void _initializeDefaultValues() {
    perfil = PerfilUsuario(nombre: '');
    _nombreController = TextEditingController(text: '');
    _emailController = TextEditingController(text: '');
    _clubController = TextEditingController(text: '');
    _bioController = TextEditingController(text: '');
    _manoDominante = null;
    _fechaNacimiento = null;
    _avatarPath = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logScreenView('profile_screen');
      } catch (e) {
        debugPrint('Error logging screen view: $e');
      }
      _ensureFriendCode();
    });
    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      perfilBox = Hive.box<PerfilUsuario>(dataRepository.perfilBoxName);
      perfil = perfilBox.get('perfil');
      // Si no hay perfil, crea uno por defecto
      if (perfil == null) {
        perfil = PerfilUsuario(nombre: '');
        perfilBox.put('perfil', perfil!);
      }
      _nombreController = TextEditingController(text: perfil?.nombre ?? '');
      _emailController = TextEditingController(text: perfil?.email ?? '');
      _clubController = TextEditingController(text: perfil?.club ?? '');
      _bioController = TextEditingController(text: perfil?.bio ?? '');
      _manoDominante = perfil?.manoDominante;
      _fechaNacimiento = perfil?.fechaNacimiento;
      _avatarPath = perfil?.avatarPath;
    } on HiveError catch (e) {
      debugPrint('Error de Hive al cargar perfil: $e');
      // Intentar abrir la box nuevamente o crear valores por defecto
      try {
        final dataRepository = Provider.of<DataRepository>(context, listen: false);
        perfilBox = Hive.box<PerfilUsuario>(dataRepository.perfilBoxName);
      } catch (_) {
        // Si falla, será necesario recrear la box en un futuro acceso
        debugPrint('No se pudo abrir la box de perfil');
      }
      _initializeDefaultValues();
    } catch (e) {
      debugPrint('Error inesperado al inicializar perfil: $e');
      _initializeDefaultValues();
    }
  }

  Future<void> _ensureFriendCode() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;
      
      if (userId == null) return; // No hacer nada si no hay usuario autenticado
      
      if (perfil?.friendCode?.isEmpty ?? true) {
        final firestoreService = FirestoreService();
        final friendCode = await firestoreService.generarCodigoAmigoUnico();
        
        final updatedPerfil = perfil!.copyWith(friendCode: friendCode);
        
        await perfilBox.put('perfil', updatedPerfil);
        await firestoreService.guardarPerfil(userId, updatedPerfil);
        
        setState(() {
          perfil = updatedPerfil;
        });
        
        debugPrint('Código de amigo generado: $friendCode');
      }
    } catch (e) {
      debugPrint('Error al generar código de amigo: $e');
    }
  }

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.fixErrorsBeforeSaving),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        ),
      );
      return;
    }

    try {
      final nuevoPerfil = PerfilUsuario(
        nombre: _nombreController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        avatarPath: _avatarPath,
        club: _clubController.text.trim().isEmpty
            ? null
            : _clubController.text.trim(),
        manoDominante: _manoDominante,
        fechaNacimiento: _fechaNacimiento,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        // Preservar datos de Google si existen, excepto si se solicitó limpiar foto
        googlePhotoUrl: _clearGooglePhoto ? null : perfil?.googlePhotoUrl,
        googleDisplayName: perfil?.googleDisplayName,
        isFromGoogle: perfil?.isFromGoogle ?? false,
        friendCode: perfil?.friendCode, // Preservar el código de amigo
      );

      await perfilBox.put('perfil', nuevoPerfil);
      setState(() {
        perfil = nuevoPerfil;
      });
      
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await analytics.logProfileUpdated();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profileSaved),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
        );

        // Espera un poco para que se vea el mensaje y navega al Home
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } on HiveError catch (e) {
      debugPrint('Error de Hive al guardar perfil: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profileSaveError),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al guardar perfil: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profileUnexpectedSaveError),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
        );
      }
    }
  }

  Future<void> _seleccionarAvatar() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );
    if (img != null) {
      setState(() {
        _avatarPath = img.path;
        // Al seleccionar una foto local, preservar datos de Google para uso futuro
        _clearGooglePhoto = false;
      });
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        await analytics.logAvatarChanged();
      } catch (e) {
        debugPrint('Error logging avatar change: $e');
      }
    }
  }

  void _quitarAvatar() {
    setState(() {
      _avatarPath = null;
      // Marcar para limpiar la foto de Google del perfil al guardar
      _clearGooglePhoto = true;
    });
  }

  void _confirmarEliminarPerfil() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteProfileConfirmation),
        content: Text(
          AppLocalizations.of(context)!.deleteProfileMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await perfilBox.delete('perfil');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.profileDeleted),
              backgroundColor: Colors.red[600],
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } on HiveError catch (e) {
        debugPrint('Error de Hive al eliminar perfil: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.profileDeleteError),
              backgroundColor: Colors.red[600],
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error al eliminar perfil: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.profileUnexpectedDeleteError),
              backgroundColor: Colors.red[600],
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _clubController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avatarFileExists =
        _avatarPath != null && File(_avatarPath!).existsSync();
    
    // Mostrar foto de Google si está disponible y no hay foto local
    final showGooglePhoto = perfil?.hasGooglePhoto == true && !avatarFileExists;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myProfile),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: AppLocalizations.of(context)!.home,
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Mostrar info si el perfil es de Google
              if (perfil?.isFromGoogle == true)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cs.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: cs.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.profileFromGoogle,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Avatar and Level Badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _seleccionarAvatar,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: cs.primary.withOpacity(0.09),
                      child: avatarFileExists
                          ? ClipOval(
                              child: Image.file(
                                File(_avatarPath!),
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              ),
                            )
                          : showGooglePhoto
                              ? ClipOval(
                                  child: Image.network(
                                    perfil!.googlePhotoUrl!,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback a icono por defecto si falla la carga
                                      return Icon(Icons.person, size: 48, color: cs.primary);
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Icon(Icons.person, size: 48, color: cs.primary),
                    ),
                  ),
                  // Level badge
                  Consumer<AchievementService>(
                    builder: (context, achievementService, child) {
                      final level = achievementService.userProgress?.currentLevel ?? 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cs.primary, cs.primaryContainer],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '$level',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (avatarFileExists || showGooglePhoto)
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(AppLocalizations.of(context)!.removePhoto),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: _quitarAvatar,
                ),
              if (_avatarPath != null && !avatarFileExists && !showGooglePhoto)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    AppLocalizations.of(context)!.imageNotFound,
                    style: TextStyle(color: Colors.red[400], fontSize: 13),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                showGooglePhoto 
                    ? AppLocalizations.of(context)!.usingGooglePhoto
                    : AppLocalizations.of(context)!.tapToChangeImage,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),
              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.name,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? AppLocalizations.of(context)!.enterYourName
                    : null,
              ),
              const SizedBox(height: 16),
              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(v.trim())) {
                    return AppLocalizations.of(context)!.enterValidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Código de Amigo (solo lectura)
              if (perfil?.friendCode != null)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outline),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.tag),
                    title: Text(AppLocalizations.of(context)!.yourFriendCode),
                    subtitle: Text(
                      perfil!.friendCode!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: AppLocalizations.of(context)!.copyFriendCode,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: perfil!.friendCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.friendCodeCopied),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Club
              TextFormField(
                controller: _clubController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.clubName,
                  prefixIcon: const Icon(Icons.sports),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Mano dominante
              DropdownButtonFormField<String>(
                value: _manoDominante,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.hand,
                  prefixIcon: const Icon(Icons.pan_tool_alt_outlined),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.rightHand), value: 'Derecha'),
                  DropdownMenuItem(
                    child: Text(AppLocalizations.of(context)!.leftHand),
                    value: 'Izquierda',
                  ),
                  DropdownMenuItem(child: Text(AppLocalizations.of(context)!.bothHands), value: 'Ambas'),
                ],
                onChanged: (v) => setState(() => _manoDominante = v),
              ),
              const SizedBox(height: 16),
              // Fecha de nacimiento
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de nacimiento',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                _fechaNacimiento ?? DateTime(now.year - 18),
                            firstDate: DateTime(now.year - 100),
                            lastDate: now,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(colorScheme: cs),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() => _fechaNacimiento = picked);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            _fechaNacimiento == null
                                ? AppLocalizations.of(context)!.selectDate
                                : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                            style: TextStyle(
                              fontSize: 16,
                              color: _fechaNacimiento == null
                                  ? cs.onSurface.withOpacity(0.5)
                                  : cs.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Bio
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.aboutMe,
                  prefixIcon: const Icon(Icons.info_outline),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 26),
              ElevatedButton.icon(
                onPressed: _guardarPerfil,
                icon: const Icon(Icons.save),
                label: Text(AppLocalizations.of(context)!.saveProfile),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: Text(
                  AppLocalizations.of(context)!.deleteProfile,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _confirmarEliminarPerfil,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
