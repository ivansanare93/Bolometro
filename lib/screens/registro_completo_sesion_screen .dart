import 'package:flutter/material.dart';
import '../models/partida.dart';
import '../models/sesion.dart';
import '../screens/registro_sesion_screen.dart';
import '../screens/editar_partida_screen.dart';
import 'package:hive/hive.dart';
import 'home_screen.dart';
import '../widgets/lista_partidas.dart';
import '../widgets/selector_tipo_partida.dart';

class RegistroCompletoSesionScreen extends StatefulWidget {
  const RegistroCompletoSesionScreen({super.key});

  @override
  State<RegistroCompletoSesionScreen> createState() =>
      _RegistroCompletoSesionScreenState();
}

class _RegistroCompletoSesionScreenState
    extends State<RegistroCompletoSesionScreen> {
  String _lugar = '';
  String _tipo = 'Entrenamiento';
  final List<Partida> _partidas = [];

  void anadirPartida() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroSesionScreen(
          onGuardar: (partida) {
            setState(() => _partidas.add(partida));
          },
        ),
      ),
    );
  }

  void editarPartida(int index) async {
    final partidaOriginal = _partidas[index];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarPartidaScreen(
          partida: partidaOriginal,
          onGuardar: (partidaActualizada) {
            setState(() {
              _partidas[index] = partidaActualizada;
            });
          },
        ),
      ),
    );
  }

  void borrarPartida(int index) {
    setState(() => _partidas.removeAt(index));
  }

  Future<void> _guardarSesion() async {
    if (_partidas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos una partida para guardar la sesión.'),
        ),
      );
      return;
    }

    final nuevaSesion = Sesion(
      fecha: DateTime.now(),
      lugar: _lugar.trim(),
      tipo: _tipo.trim(),
      partidas: _partidas,
    );

    final box = Hive.box<Sesion>('sesiones');
    await box.add(nuevaSesion);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión guardada correctamente')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Lugar',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _lugar = v,
            ),
            const SizedBox(height: 16),
            SelectorTipoPartida(
              value: _tipo,
              onChanged: (value) =>
                  setState(() => _tipo = value ?? 'Entrenamiento'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Partidas: ${_partidas.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ElevatedButton.icon(
                  onPressed: anadirPartida,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir partida'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListaPartidas(
                partidas: _partidas,
                onEditar: editarPartida,
                onBorrar: borrarPartida,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _guardarSesion,
              icon: const Icon(Icons.save),
              label: const Text('Guardar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
