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
import 'package:hive/hive.dart';
import '../models/perfil_usuario.dart';
import 'dart:io';

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
    _perfilBoxFuture = Hive.openBox<PerfilUsuario>('perfilUsuario');
  }

  Future<void> _refrescarPerfil() async {
    setState(() {
      _perfilBoxFuture = Hive.openBox<PerfilUsuario>('perfilUsuario');
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
        future: _perfilBoxFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final perfil = snapshot.data!.get('perfil');
          final tienePerfil =
              perfil != null && (perfil.nombre.trim().isNotEmpty);

          // Avatar: comprobamos si la imagen existe realmente
          final avatarFileExists =
              perfil != null &&
              perfil.avatarPath != null &&
              perfil.avatarPath!.isNotEmpty &&
              File(perfil.avatarPath!).existsSync();

          final avatar = (perfil != null && avatarFileExists)
              ? CircleAvatar(
                  radius: 46,
                  backgroundImage: FileImage(File(perfil.avatarPath!)),
                )
              : CircleAvatar(
                  radius: 46,
                  backgroundColor: cs.primary.withOpacity(0.10),
                  child: Icon(Icons.person, size: 46, color: cs.primary),
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
                            ? '¡Bienvenido, ${perfil!.nombre}!'
                            : '¡Bienvenid@! Antes de nada, crea tu perfil para empezar',
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
                              color: cs.primary,
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
                              color: cs.primary.withOpacity(0.68),
                            ),
                          ),
                        ),
                      const SizedBox(height: 9),
                      tienePerfil
                          ? OutlinedButton.icon(
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
                              label: const Text(
                                'Crear mi perfil',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
                      title: const Text('Nueva Sesión'),
                      subtitle: const Text('Registrar varias partidas'),
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
                            builder: (_) =>
                                const EstadisticasPantallaCompleta(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
