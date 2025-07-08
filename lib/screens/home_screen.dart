import 'package:flutter/material.dart';
import 'registro_sesion_screen.dart';
import 'estadisticas_screen.dart';
import 'lista_sesiones_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../screens/registro_completo_sesion_screen .dart';

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

                              // 🌙 Modo oscuro
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: const [
                  SizedBox(height: 32),
                  Image(
                    image: AssetImage('assets/logo_bolometro.png'),
                    height: 120,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '¡Bienvenid@, vamos a lanzar unos strikes!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
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
      ),
    );
  }
}
