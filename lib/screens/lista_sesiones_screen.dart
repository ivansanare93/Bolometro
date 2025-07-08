import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/sesion.dart';
import 'ver_sesion_screen.dart';
import 'home_screen.dart';
import '../utils/ui_herlpers.dart ';

class ListaSesionesScreen extends StatefulWidget {
  const ListaSesionesScreen({super.key});

  @override
  State<ListaSesionesScreen> createState() => _ListaSesionesScreenState();
}

class _ListaSesionesScreenState extends State<ListaSesionesScreen> {
  String _filtro = 'Todas';

  List<Sesion> _filtrarSesiones(List<Sesion> sesiones) {
    switch (_filtro) {
      case 'Entrenamiento':
        return sesiones
            .where((s) => s.tipo.toLowerCase().contains('entrena'))
            .toList();
      case 'Competición':
        return sesiones
            .where((s) => s.tipo.toLowerCase().contains('comp'))
            .toList();
      default:
        return sesiones;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sesiones Registradas')),
      body: FutureBuilder(
        future: Hive.openBox<Sesion>('sesiones'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final box = snapshot.data as Box<Sesion>;

          if (box.isEmpty) {
            return const Center(child: Text('Aún no has registrado sesiones.'));
          }

          final sesiones = box.values.toList()
            ..sort((a, b) => b.fecha.compareTo(a.fecha));

          final filtradas = _filtrarSesiones(sesiones);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _filtro,
                      onChanged: (value) {
                        if (value != null) setState(() => _filtro = value);
                      },
                      items: const [
                        DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                        DropdownMenuItem(
                          value: 'Entrenamiento',
                          child: Text('Entrenamientos'),
                        ),
                        DropdownMenuItem(
                          value: 'Competición',
                          child: Text('Competiciones'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtradas.length,
                  itemBuilder: (context, index) {
                    final sesion = filtradas[index];
                    final esCompeticion = sesion.tipo.toLowerCase().contains(
                      'comp',
                    );
                    final iconColor = esCompeticion
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.tertiary;

                    final promedio = sesion.partidas.isNotEmpty
                        ? (sesion.partidas
                                      .map((p) => p.total)
                                      .reduce((a, b) => a + b) /
                                  sesion.partidas.length)
                              .round()
                        : 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: iconoTipoSesion(sesion.tipo, context),
                        title: Text(
                          '${sesion.tipo} - ${sesion.fecha.toLocal().toString().split(' ')[0]}',
                        ),
                        subtitle: Text(
                          '${sesion.lugar} • ${sesion.partidas.length} partidas • Prom: $promedio',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VerSesionScreen(sesion: sesion),
                            ),
                          );
                        },
                        onLongPress: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('¿Eliminar sesión?'),
                              content: const Text(
                                'Esta acción no se puede deshacer.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Eliminar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await box.deleteAt(
                              sesiones.indexOf(filtradas[index]),
                            );
                            setState(() {});
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        },
        tooltip: 'Inicio',
        child: const Icon(Icons.home),
      ),
    );
  }
}
