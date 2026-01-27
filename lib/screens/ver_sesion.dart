import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/sesion.dart';
import '../models/partida.dart';
import '../utils/app_constants.dart';
import 'editar_partida.dart';
import 'home.dart';

class VerSesion extends StatefulWidget {
  final Sesion sesion;
  const VerSesion({super.key, required this.sesion});

  @override
  State<VerSesion> createState() => _VerSesionState();
}

class _VerSesionState extends State<VerSesion> {
  late Sesion sesionActual;

  @override
  void initState() {
    super.initState();
    sesionActual = widget.sesion;
  }

  Future<void> _editarPartida(int index) async {
    final partidaOriginal = sesionActual.partidas[index];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarPartidaScreen(
          partida: partidaOriginal,
          onGuardar: (partidaActualizada) async {
            try {
              final box = Hive.box<Sesion>(AppConstants.boxSesiones);
              final sesionIndex = box.values.toList().indexOf(sesionActual);
              if (sesionIndex == -1) {
                debugPrint('Sesión no encontrada en Hive');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: sesión no encontrada'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              final nuevasPartidas = List<Partida>.from(sesionActual.partidas);
              nuevasPartidas[index] = partidaActualizada;

              setState(() {
                sesionActual = sesionActual.copyWith(partidas: nuevasPartidas);
              });

              await box.putAt(sesionIndex, sesionActual);

              Navigator.pop(context); // Cierra edición
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Partida actualizada')),
              );
            } on HiveError catch (e) {
              debugPrint('Error de Hive al actualizar partida: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al guardar cambios. Intenta nuevamente.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              debugPrint('Error al actualizar partida: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error inesperado al guardar cambios'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _eliminarPartida(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar partida'),
        content: const Text('¿Seguro que deseas eliminar esta partida?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final box = Hive.box<Sesion>(AppConstants.boxSesiones);
        final sesionIndex = box.values.toList().indexOf(sesionActual);
        if (sesionIndex == -1) {
          debugPrint('Sesión no encontrada en Hive');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: sesión no encontrada'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final nuevasPartidas = List<Partida>.from(sesionActual.partidas)
          ..removeAt(index);

        setState(() {
          sesionActual = sesionActual.copyWith(partidas: nuevasPartidas);
        });

        await box.putAt(sesionIndex, sesionActual);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Partida eliminada')));
        }
      } on HiveError catch (e) {
        debugPrint('Error de Hive al eliminar partida: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar partida. Intenta nuevamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error al eliminar partida: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error inesperado al eliminar partida'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final esEntrenamiento = sesionActual.tipo.toLowerCase() == 'entrenamiento';
    final colorTipo = esEntrenamiento
        ? Theme.of(context).colorScheme.primary
        : Colors.red.shade700;

    // RESUMEN
    final promedio = sesionActual.partidas.isNotEmpty
        ? (sesionActual.partidas.map((p) => p.total).reduce((a, b) => a + b) /
                  sesionActual.partidas.length)
              .toStringAsFixed(1)
        : '-';

    final mejor = sesionActual.partidas.isEmpty
        ? '-'
        : sesionActual.partidas
              .map((p) => p.total)
              .reduce((a, b) => a > b ? a : b)
              .toString();

    final peor = sesionActual.partidas.isEmpty
        ? '-'
        : sesionActual.partidas
              .map((p) => p.total)
              .reduce((a, b) => a < b ? a : b)
              .toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${sesionActual.tipo} • ${sesionActual.lugar.isNotEmpty ? sesionActual.lugar : "Sin lugar"}',
        ),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // RESUMEN SESION
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            margin: const EdgeInsets.only(bottom: 18),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        esEntrenamiento
                            ? Icons.fitness_center
                            : Icons.emoji_events,
                        color: colorTipo,
                        size: 32,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        sesionActual.tipo.toUpperCase(),
                        style: TextStyle(
                          color: colorTipo,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.grey[600],
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${sesionActual.fecha.day}/${sesionActual.fecha.month}/${sesionActual.fecha.year}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (sesionActual.notas != null &&
                      sesionActual.notas!.trim().isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.sticky_note_2, color: colorTipo, size: 20),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            sesionActual.notas!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _KpiSmall(
                        title: "Promedio",
                        value: promedio,
                        color: Colors.blue[700]!,
                      ),
                      _KpiSmall(
                        title: "Mejor",
                        value: mejor,
                        color: Colors.green[700]!,
                      ),
                      _KpiSmall(
                        title: "Peor",
                        value: peor,
                        color: Colors.red[400]!,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // PARTIDAS
          Text(
            'Partidas (${sesionActual.partidas.length}):',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (sesionActual.partidas.isEmpty)
            Center(
              child: Text(
                "No hay partidas registradas",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ...sesionActual.partidas.asMap().entries.map((entry) {
            final idx = entry.key;
            final partida = entry.value;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 7),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '🎳 Partida ${idx + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Editar',
                          onPressed: () => _editarPartida(idx),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Eliminar',
                          onPressed: () => _eliminarPartida(idx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(Icons.scoreboard, size: 20, color: colorTipo),
                        const SizedBox(width: 5),
                        Text(
                          'Puntos: ${partida.total}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorTipo,
                          ),
                        ),
                        if (partida.notas != null &&
                            partida.notas!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Icon(
                              Icons.sticky_note_2,
                              size: 18,
                              color: Colors.amber[800],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Marcador visual (frames)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(10, (i) {
                          final frame = partida.frames[i];
                          final isLast = i == 9;
                          final tiros = isLast
                              ? frame.take(3).toList()
                              : frame.take(2).toList();

                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(6),
                              color: Theme.of(context).cardColor,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'F${i + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: tiros.map((t) {
                                    return Container(
                                      width: 24,
                                      height: 28,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade500,
                                        ),
                                        color: isDark
                                            ? Colors.grey.shade800
                                            : Colors.white,
                                      ),
                                      child: Text(
                                        t,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    if (partida.notas != null &&
                        partida.notas!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.note, size: 20, color: Colors.amber[800]),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              partida.notas!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _KpiSmall extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _KpiSmall({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: color.withOpacity(0.82),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
