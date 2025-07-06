import 'package:flutter/material.dart';
import '../models/partida.dart';
import '../utils/registro_tiros_utils.dart';
import '../widgets/marcador_bolos.dart';
import 'home_screen.dart';

class EditarPartidaScreen extends StatefulWidget {
  final Partida partida;
  final Function(Partida partidaActualizada) onGuardar;

  const EditarPartidaScreen({
    super.key,
    required this.partida,
    required this.onGuardar,
  });

  @override
  State<EditarPartidaScreen> createState() => _EditarPartidaScreenState();
}

class _EditarPartidaScreenState extends State<EditarPartidaScreen> {
  final _formKey = GlobalKey<FormState>();
  late List<List<String>> framesText;
  late String? notas;

  @override
  void initState() {
    super.initState();
    framesText = widget.partida.frames.map((f) => List<String>.from(f)..length = 3).toList();
    notas = widget.partida.notas;
  }

  void _guardar() {
    final nuevosFrames = interpretarFrames(framesText);
    final nuevoTotal = calcularPuntuacionPartida(nuevosFrames);

    if (nuevoTotal == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La partida no tiene puntuación válida.')),
      );
      return;
    }

    final partidaActualizada = widget.partida.copyWith(
      frames: nuevosFrames,
      notas: notas,
      total: nuevoTotal,
    );

    widget.onGuardar(partidaActualizada);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final frames = interpretarFrames(framesText);
    final puntuacionActual = calcularPuntuacionPartida(frames);
    final puntuacionMaxima = calcularPuntuacionMaximaPosible(frames);
    final buenaRacha = esBuenaRacha(frames);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Partida')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarcadorBolos(
              frames: framesText,
              puntuaciones: calcularPuntuacionPorFrame(framesText),
              frameActivo: framesText.indexWhere(
                (f) => tipoDeFrame(f, esUltimo: framesText.indexOf(f) == 9) == TipoFrame.incompleto,
              ),
              onChanged: (frame, tiro, valor) {
                setState(() {
                  framesText[frame][tiro] = valor;
                });
              },
              autoFocusEnabled: true,
              autoAdvanceFocus: true,
            ),
            const SizedBox(height: 16),
            Text('Puntuación actual: $puntuacionActual'),
            Text('Máximo posible: $puntuacionMaxima', style: const TextStyle(color: Colors.grey)),
            if (buenaRacha)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.whatshot, color: Colors.orange),
                    SizedBox(width: 6),
                    Text('¡Vas en racha!', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: notas,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
              onChanged: (v) => notas = v,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save),
              label: const Text('Guardar cambios'),
            ),
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
