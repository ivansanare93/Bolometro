import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/sesion.dart';
import '../models/partida.dart';
import 'home_screen.dart';
import 'editar_partida_screen.dart'; // Asegúrate de que exista este archivo

class VerSesionScreen extends StatelessWidget {
  final Sesion sesion;

  const VerSesionScreen({super.key, required this.sesion});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool esEntrenamiento = sesion.tipo.toLowerCase() == 'entrenamiento';

    final Color colorDiferenciador = esEntrenamiento
        ? Theme.of(context).colorScheme.primary
        : Colors.red.shade700;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de la Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              '📅 Fecha: ${sesion.fecha.toLocal().toString().split(" ")[0]}',
            ),
            Text('📍 Lugar: ${sesion.lugar}'),
            const SizedBox(height: 10),
            Chip(
              label: Text(
                sesion.tipo.toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: colorDiferenciador,
            ),
            const SizedBox(height: 16),
            if (sesion.notas != null && sesion.notas!.trim().isNotEmpty) ...[
              const Text('📝 Notas:'),
              Text(sesion.notas!),
              const SizedBox(height: 16),
            ],
            const Divider(),
            const Text(
              'Partidas:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...sesion.partidas.asMap().entries.map((entry) {
              final index = entry.key;
              final partida = entry.value;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '🎳 Partida ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Editar',
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditarPartidaScreen(
                                    partida: partida,
                                    onGuardar: (partidaActualizada) async {
                                      final box = Hive.box<Sesion>('sesiones');
                                      final sesionIndex = box.values
                                          .toList()
                                          .indexOf(sesion);
                                      if (sesionIndex == -1) return;

                                      final nuevasPartidas = List<Partida>.from(
                                        sesion.partidas,
                                      );
                                      nuevasPartidas[index] =
                                          partidaActualizada;

                                      final sesionActualizada = sesion.copyWith(
                                        partidas: nuevasPartidas,
                                      );
                                      await box.putAt(
                                        sesionIndex,
                                        sesionActualizada,
                                      );

                                      Navigator.pop(
                                        context,
                                      ); // Cierra la pantalla de edición
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => VerSesionScreen(
                                            sesion: sesionActualizada,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Puntaje total: ${partida.total}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.note,
                                size: 20,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  partida.notas!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
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
