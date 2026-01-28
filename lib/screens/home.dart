import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hive/hive.dart';
import 'registro_sesion.dart';
import 'estadisticas.dart';
import 'lista_sesiones.dart';
import 'perfil_usuario.dart';
import 'friends_screen.dart';
import 'rankings_screen.dart';
import 'registro_completo_sesion.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../models/perfil_usuario.dart';
import '../utils/app_constants.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../repositories/data_repository.dart';
import '../l10n/app_localizations.dart';
import '../widgets/skeleton_loaders.dart';

class HomeScreen extends StatefulWidget {
  final bool mostrarAppBar;

  const HomeScreen({super.key, this.mostrarAppBar = true});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Box<PerfilUsuario>> _perfilBoxFuture;

  @override
  void initState() {
    super.initState();
    _perfilBoxFuture = Hive.openBox<PerfilUsuario>(AppConstants.boxPerfilUsuario);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logScreenView('home_screen');
      } catch (e) {
        debugPrint('Error logging screen view: $e');
      }
    });
  }

  Future<void> _refrescarPerfil() async {
    setState(() {
      _perfilBoxFuture = Hive.openBox<PerfilUsuario>(AppConstants.boxPerfilUsuario);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: widget.mostrarAppBar
          ? AppBar(
              title: Row(
                children: [
                  Image.asset('assets/logo_bolometro_min.png', height: 60),
                  const SizedBox(width: 2),
                  const Text('Bolómetro'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: AppLocalizations.of(context)!.settings,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (context) {
                        final themeProvider = Provider.of<ThemeProvider>(
                          context,
                        );
                        final authService = Provider.of<AuthService>(
                          context,
                          listen: false,
                        );
                        final dataRepository = Provider.of<DataRepository>(
                          context,
                          listen: false,
                        );

                        return SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              Text(
                                AppLocalizations.of(context)!.settings,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Estado de autenticación
                              if (authService.isAuthenticated) ...[
                                Container(
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
                                      Icon(
                                        Icons.cloud_done,
                                        color: cs.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)!.signedIn,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              authService.user?.email ?? 'Usuario',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: cs.onSurface
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(AppLocalizations.of(context)!.darkMode),
                                  Switch(
                                    value: themeProvider.isDarkMode,
                                    onChanged: (val) async {
                                      themeProvider.toggleTheme(val);
                                      try {
                                        final analytics = Provider.of<AnalyticsService>(
                                          context,
                                          listen: false,
                                        );
                                        await analytics.logThemeChanged(val ? 'dark' : 'light');
                                      } catch (e) {
                                        debugPrint('Error logging theme change: $e');
                                      }
                                      if (context.mounted) Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Language selection
                              Consumer<LanguageProvider>(
                                builder: (context, languageProvider, _) {
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(AppLocalizations.of(context)!.language),
                                      DropdownButton<String>(
                                        value: languageProvider.locale.languageCode,
                                        items: [
                                          DropdownMenuItem(
                                            value: 'es',
                                            child: Text(AppLocalizations.of(context)!.spanish),
                                          ),
                                          DropdownMenuItem(
                                            value: 'en',
                                            child: Text(AppLocalizations.of(context)!.english),
                                          ),
                                        ],
                                        onChanged: (String? newLanguage) async {
                                          if (newLanguage != null) {
                                            await languageProvider.setLocale(Locale(newLanguage));
                                            if (context.mounted) {
                                              try {
                                                final analytics = Provider.of<AnalyticsService>(
                                                  context,
                                                  listen: false,
                                                );
                                                await analytics.logLanguageChanged(newLanguage);
                                              } catch (e) {
                                                debugPrint('Error logging language change: $e');
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                              
                              if (authService.isAuthenticated) ...[
                                const Divider(height: 32),
                                ListTile(
                                  leading: Icon(
                                    Icons.sync,
                                    color: cs.primary,
                                  ),
                                  title: Text(AppLocalizations.of(context)!.syncData),
                                  subtitle: Text(
                                    dataRepository.isSyncing
                                        ? AppLocalizations.of(context)!.syncing
                                        : AppLocalizations.of(context)!.saveDataToCloud,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: dataRepository.isSyncing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : null,
                                  onTap: dataRepository.isSyncing
                                      ? null
                                      : () async {
                                          try {
                                            final analytics = Provider.of<AnalyticsService>(
                                              context,
                                              listen: false,
                                            );
                                            await analytics.logSync();
                                            await dataRepository
                                                .sincronizarANube();
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(context)!.syncSuccess,
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Error: ${e.toString()}',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                ),
                                const Divider(height: 32),
                                ListTile(
                                  leading: const Icon(
                                    Icons.logout,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    AppLocalizations.of(context)!.signOut,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(AppLocalizations.of(context)!.signOut),
                                        content: Text(
                                          AppLocalizations.of(context)!.signOutConfirmation,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(AppLocalizations.of(context)!.cancel),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(
                                              AppLocalizations.of(context)!.signOut,
                                              style:
                                                  const TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        final analytics = Provider.of<AnalyticsService>(
                                          context,
                                          listen: false,
                                        );
                                        await analytics.logSignOut();
                                      } catch (e) {
                                        debugPrint('Error logging sign out: $e');
                                      }
                                      await authService.signOut();
                                      dataRepository.setUser(null);
                                    }
                                  },
                                ),
                              ] else ...[
                                const Divider(height: 32),
                                Text(
                                  AppLocalizations.of(context)!.moreOptionsComingSoon,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 16),
                              const SizedBox(height: 28),
                              FutureBuilder<PackageInfo>(
                                future: PackageInfo.fromPlatform(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData)
                                    return const SizedBox(height: 18);
                                  final version = snapshot.data!.version;
                                  return Center(
                                    child: Text(
                                      'Versión: $version',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            )
          : null,
      body: FutureBuilder<Box<PerfilUsuario>>(
        future: _perfilBoxFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => const ListItemSkeleton(),
            );
          }
          final perfil = snapshot.data!.get('perfil');
          final tienePerfil =
              perfil != null && (perfil.nombre.trim().isNotEmpty);
          final authService = Provider.of<AuthService>(context, listen: false);

          // Avatar: comprobamos si la imagen existe realmente
          final avatarFileExists =
              perfil != null &&
              perfil.avatarPath != null &&
              perfil.avatarPath!.isNotEmpty &&
              File(perfil.avatarPath!).existsSync();

          // Determinar qué avatar mostrar (prioridad: local > Google > default)
          final Widget avatar;
          if (perfil != null && avatarFileExists) {
            // Usar imagen local
            avatar = CircleAvatar(
              radius: 46,
              backgroundImage: FileImage(File(perfil.avatarPath!)),
            );
          } else if (perfil != null && perfil.hasGooglePhoto) {
            // Usar foto de Google con manejo de errores
            avatar = CircleAvatar(
              radius: 46,
              backgroundColor: cs.primary.withOpacity(0.10),
              child: ClipOval(
                child: Image.network(
                  perfil.googlePhotoUrl!,
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback a icono por defecto si falla la carga
                    return Icon(Icons.person, size: 46, color: cs.primary);
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
              ),
            );
          } else {
            // Avatar por defecto
            avatar = CircleAvatar(
              radius: 46,
              backgroundColor: cs.primary.withOpacity(0.10),
              child: Icon(Icons.person, size: 46, color: cs.primary),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PerfilUsuarioScreen(),
                            ),
                          );
                          await _refrescarPerfil();
                        },
                        child: avatar,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tienePerfil
                            ? AppLocalizations.of(context)!.welcomeUser(perfil!.nombre)
                            : AppLocalizations.of(context)!.welcomeCreateProfile,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (tienePerfil &&
                          perfil.club != null &&
                          perfil.club!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3.0),
                          child: Text(
                            AppLocalizations.of(context)!.clubLabel(perfil.club!),
                            style: TextStyle(
                              fontSize: 15,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      if (tienePerfil && perfil.manoDominante != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            AppLocalizations.of(context)!.dominantHandLabel(perfil.manoDominante!),
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.primary.withOpacity(0.68),
                            ),
                          ),
                        ),
                      const SizedBox(height: 9),
                      tienePerfil
                          ? OutlinedButton.icon(
                              icon: const Icon(Icons.edit, size: 19),
                              label: Text(AppLocalizations.of(context)!.editMyProfile),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PerfilUsuarioScreen(),
                                  ),
                                );
                                await _refrescarPerfil();
                              },
                            )
                          : ElevatedButton.icon(
                              icon: const Icon(Icons.person_add_alt_1),
                              label: Text(
                                AppLocalizations.of(context)!.createMyProfile,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                minimumSize: const Size(190, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PerfilUsuarioScreen(),
                                  ),
                                );
                                await _refrescarPerfil();
                              },
                            ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),

                // SOLO mostramos el resto si existe perfil completo
                if (tienePerfil) ...[
                  Card(
                    child: ListTile(
                      leading: const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('🎳', style: TextStyle(fontSize: 32)),
                      ),
                      title: Text(AppLocalizations.of(context)!.newSession),
                      subtitle: Text(AppLocalizations.of(context)!.registerMultipleGames),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const RegistroCompletoSesionScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Text('📋', style: TextStyle(fontSize: 32)),
                      title: Text(AppLocalizations.of(context)!.viewSessions),
                      subtitle: Text(AppLocalizations.of(context)!.sessionsList),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ListaSesionesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Text('📊', style: TextStyle(fontSize: 32)),
                      title: Text(AppLocalizations.of(context)!.statistics),
                      subtitle: Text(AppLocalizations.of(context)!.performanceSummary),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const EstadisticasPantallaCompleta(),
                          ),
                        );
                      },
                    ),
                  ),
                  // Solo mostrar Friends y Rankings si el usuario está autenticado
                  if (authService.isAuthenticated) ...[
                    Card(
                      child: ListTile(
                        leading: const Text('👥', style: TextStyle(fontSize: 32)),
                        title: Text(AppLocalizations.of(context)!.friends),
                        subtitle: Text(AppLocalizations.of(context)!.manageFriends),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FriendsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    Card(
                      child: ListTile(
                        leading: const Text('🏆', style: TextStyle(fontSize: 32)),
                        title: Text(AppLocalizations.of(context)!.rankings),
                        subtitle: Text(AppLocalizations.of(context)!.compareWithFriends),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RankingsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
