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

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          // Filtro visual optimizado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? cs.surface : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.primary.withOpacity(0.38),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(isDark ? 0.13 : 0.06),
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Row(
                children: [
                  Icon(Icons.filter_list_rounded, color: cs.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Filtrar:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.84),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filtroTipo,
                        borderRadius: BorderRadius.circular(12),
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: cs.primary),
                        dropdownColor: isDark ? cs.surface : Colors.white,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        items: ['Todos', 'Entrenamiento', 'Competición']
                            .map(
                              (tipo) => DropdownMenuItem(
                                value: tipo,
                                child: Text(
                                  tipo,
                                  style: TextStyle(
                                    color: cs.onSurface.withOpacity(
                                      tipo == _filtroTipo ? 1.0 : 0.72,
                                    ),
                                    fontWeight: tipo == _filtroTipo
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _filtroTipo = v ?? 'Todos'),
                      ),
                    ),
                  ),
                ],
              ),
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
                          color: cs.primary.withOpacity(0.48),
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
