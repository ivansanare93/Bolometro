// Este widget define el contenido visual del diálogo de nueva partida con mejoras
// visuales, separación por secciones y botones llamativos.

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:test_bolos/widgets/marcador_bolos.dart';
import '../utils/registro_tiros_utils.dart';

class DialogoNuevaPartida extends StatelessWidget {
  final List<List<String>> framesText;
  final void Function() onCancelar;
  final void Function() onGuardar;
  final void Function(int frame, int tiro, String valor) onTiroChanged;
  final String? notas;
  final void Function(String) onNotasChanged;

  const DialogoNuevaPartida({
    super.key,
    required this.framesText,
    required this.onCancelar,
    required this.onGuardar,
    required this.onTiroChanged,
    required this.notas,
    required this.onNotasChanged,
  });

  @override
  Widget build(BuildContext context) {
    final frames = interpretarFrames(framesText);
    final puntuaciones = calcularPuntuacionPorFrame(framesText);
    final puntuacionTotal = calcularPuntuacionPartida(frames);
    final puntuacionMaxima = calcularPuntuacionMaximaPosible(frames);
    final buenaRacha = esBuenaRacha(frames);

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).dialogBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  FaIcon(FontAwesomeIcons.bowlingBall, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Nueva Partida',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text('🎯 Tiros por frame', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),

            // Sección editable del marcador directamente
            MarcadorBolos(
              frames: framesText,
              puntuaciones: puntuaciones,
              frameActivo: framesText.indexWhere(
                (f) => tipoDeFrame(f, esUltimo: framesText.indexOf(f) == 9) == TipoFrame.incompleto,
              ),
              onChanged: (frame, tiro, valor) => onTiroChanged(frame, tiro, valor),
            ),

            const SizedBox(height: 20),
            const Text('📋 Marcador', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: MarcadorBolos(
                frames: framesText,
                puntuaciones: puntuaciones,
                frameActivo: framesText.indexWhere(
                  (f) => tipoDeFrame(f, esUltimo: framesText.indexOf(f) == 9) == TipoFrame.incompleto,
                ),
                onChanged: (frame, tiro, valor) => onTiroChanged(frame, tiro, valor),
              ),
            ),

            const SizedBox(height: 16),
            Text('📊 Puntos actuales: $puntuacionTotal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text('💯 Máximo posible: $puntuacionMaxima', style: const TextStyle(color: Colors.grey)),
            if (buenaRacha)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: const [
                    Icon(Icons.whatshot, color: Colors.orange),
                    SizedBox(width: 6),
                    Text('¡Vas en racha!', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),

            const SizedBox(height: 20),
            const Text('📝 Notas', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            TextFormField(
              initialValue: notas,
              onChanged: onNotasChanged,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onCancelar,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onGuardar,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Guardar partida'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
