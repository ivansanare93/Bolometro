import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/sesion.dart';
import '../widgets/sesion_card.dart';
import '../screens/ver_sesion.dart';
import 'home.dart';

class ListaSesionesScreen extends StatefulWidget {
  const ListaSesionesScreen({super.key});

  @override
  State<ListaSesionesScreen> createState() => _ListaSesionesScreenState();
}

class _ListaSesionesScreenState extends State<ListaSesionesScreen> {
  String _filtroTipo = 'Todos';

  @override
  Widget build(BuildContext context) {
    final Box<Sesion> sesionesBox = Hive.box<Sesion>('sesiones');
    final sesiones = sesionesBox.values.toList();
    final sesionesFiltradas = _filtroTipo == 'Todos'
        ? sesiones
        : sesiones.where((s) => s.tipo == _filtroTipo).toList();

    void borrarSesion(int index) async {
      await sesionesBox.deleteAt(index);
      setState(() {});
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesiones guardadas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: "Inicio",
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
      body: Column(
        children: [
          // Filtro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.filter_alt_outlined, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Filtrar:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButton<String>(
                        value: _filtroTipo,
                        borderRadius: BorderRadius.circular(12),
                        underline: const SizedBox(),
                        isExpanded: true,
                        style: Theme.of(context).textTheme.bodyLarge,
                        items: ['Todos', 'Entrenamiento', 'Competición']
                            .map(
                              (tipo) => DropdownMenuItem(
                                value: tipo,
                                child: Text(tipo),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _filtroTipo = v ?? 'Todos'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: sesionesFiltradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          color: Colors.blue[300],
                          size: 54,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay sesiones guardadas.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: sesionesFiltradas.length,
                    itemBuilder: (context, idx) {
                      final sesion = sesionesFiltradas[idx];
                      final originalIndex = sesiones.indexOf(sesion);

                      return Dismissible(
                        key: ValueKey(sesion.key ?? originalIndex),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          alignment: Alignment.centerRight,
                          color: Colors.red[400],
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Eliminar sesión'),
                                  content: const Text(
                                    '¿Seguro que deseas eliminar esta sesión?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Eliminar',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: (_) => borrarSesion(originalIndex),
                        child: SesionCard(
                          sesion: sesion,
                          // VER SESIÓN
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VerSesion(sesion: sesion),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
