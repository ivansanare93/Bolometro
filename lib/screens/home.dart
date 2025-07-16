import 'package:flutter/material.dart';
import 'registro_sesion.dart';
import 'estadisticas.dart';
import 'lista_sesiones.dart';
import '../screens/perfil_usuario.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'registro_completo_sesion .dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../widgets/teclado_selector_pins.dart';
import 'package:hive/hive.dart';
import '../models/perfil_usuario.dart';
import 'dart:io';

class HomeScreen extends StatelessWidget {
  final bool mostrarAppBar;

  const HomeScreen({super.key, this.mostrarAppBar = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: mostrarAppBar
          ? AppBar(
              title: Row(
                children: const [
                  FaIcon(FontAwesomeIcons.bowlingBall),
                  SizedBox(width: 8),
                  Text('Menú Inicial'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Ajustes',
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

                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ajustes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Modo oscuro'),
                                  Switch(
                                    value: themeProvider.isDarkMode,
                                    onChanged: (val) {
                                      themeProvider.toggleTheme(val);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: 32),
                              const Text(
                                'Más opciones próximamente...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
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
                        );
                      },
                    );
                  },
                ),
              ],
            )
          : null,
      body: FutureBuilder<Box<PerfilUsuario>>(
        future: Hive.openBox<PerfilUsuario>('perfilUsuario'),
        builder: (context, snapshot) {
          final perfil = snapshot.hasData ? snapshot.data!.get('perfil') : null;
          final tienePerfil =
              perfil != null && (perfil.nombre.trim().isNotEmpty);

          final avatar =
              (perfil != null &&
                  perfil.avatarPath != null &&
                  perfil.avatarPath!.isNotEmpty)
              ? CircleAvatar(
                  radius: 46,
                  backgroundImage: FileImage(File(perfil.avatarPath!)),
                )
              : CircleAvatar(
                  radius: 46,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.10),
                  child: Icon(
                    Icons.person,
                    size: 46,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );

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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PerfilUsuarioScreen(),
                            ),
                          );
                        },
                        child: avatar,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tienePerfil
                            ? '¡Bienvenido, ${perfil!.nombre}!'
                            : '¡Bienvenid@, vamos a lanzar unos strikes!',
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
                            'Club: ${perfil.club}',
                            style: TextStyle(
                              fontSize: 15,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.68),
                            ),
                          ),
                        ),
                      if (tienePerfil && perfil.manoDominante != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            'Mano dominante: ${perfil.manoDominante}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.secondary.withOpacity(0.8),
                            ),
                          ),
                        ),
                      const SizedBox(height: 9),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit, size: 19),
                        label: const Text('Editar mi perfil'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PerfilUsuarioScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('🎳', style: TextStyle(fontSize: 32)),
                    ),
                    title: const Text('Nueva Sesión'),
                    subtitle: const Text('Registrar varias partidas'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegistroCompletoSesionScreen(),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Text('📋', style: TextStyle(fontSize: 32)),
                    title: const Text('Ver sesiones'),
                    subtitle: const Text('Listado de sesiones registradas'),
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
                    title: const Text('Estadísticas'),
                    subtitle: const Text('Resumen de tu rendimiento'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EstadisticasScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
