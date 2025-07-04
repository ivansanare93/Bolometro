import 'package:flutter/material.dart';
import '../models/partida.dart';
import 'ver_partida_screen.dart';
//import 'package:hive/hive.dart';

class RegistroPartidaScreen extends StatefulWidget {
  const RegistroPartidaScreen({super.key});

  @override
  State<RegistroPartidaScreen> createState() => _RegistroPartidaScreenState();
}

class _RegistroPartidaScreenState extends State<RegistroPartidaScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _fecha = DateTime.now();
  String _lugar = '';
  String _tipo = 'Entrenamiento';
  List<List<String>> _framesText = List.generate(10, (_) => ['', '']);
  String? _notas;

  void _guardarPartida() async {
    final frames = interpretarFrames(_framesText);
    final total = calcularPuntuacionTotal(frames);

    final tienePuntos = frames.any((f) => f.any((p) => p > 0));
    if (!tienePuntos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes introducir al menos un tiro con puntuación')),
      );
      return;
    }

    final nuevaPartida = Partida(
      fecha: _fecha,
      lugar: _lugar,
      tipo: _tipo,
      frames: frames,
      notas: _notas,
      total: total,
    );

    //final box = Hive.box<Partida>('partidas');
    //await box.add(nuevaPartida);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerPartidaScreen(partida: nuevaPartida),
      ),
    );
  }

  bool _esEntradaValida(String valor) {
    valor = valor.trim().toUpperCase();
    if (valor == 'X' || valor == '/') return true;
    final num = int.tryParse(valor);
    return num != null && num >= 0 && num <= 10;
  }

  bool _sumaValida(String v1, String v2, int frameIndex) {
    final val1 = v1.trim().toUpperCase();
    final val2 = v2.trim().toUpperCase();
    if (val1 == 'X') return true;
    final t1 = _parseTiro(val1);
    final t2 = val2 == '/' ? (10 - t1) : _parseTiro(val2);
    if (frameIndex == 9) return true;
    return (t1 + t2) <= 10;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Partida')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fecha: ${_fecha.toLocal().toString().split(" ")[0]}'),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fecha,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _fecha = picked);
                },
                child: const Text('Seleccionar fecha'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Lugar'),
                validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio' : null,
                onChanged: (value) => _lugar = value,
              ),
              DropdownButtonFormField<String>(
                value: _tipo,
                items: ['Entrenamiento', 'Competición']
                    .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
                    .toList(),
                onChanged: (value) => setState(() => _tipo = value ?? 'Entrenamiento'),
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              const SizedBox(height: 20),
              const Text('Tiros por Frame (usa "X" para strike, "/" para spare):'),
              Column(
                children: List.generate(10, (i) {
                  return Row(
                    children: [
                      Text('Frame ${i + 1}:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Tiro 1'),
                          onChanged: (value) => _framesText[i][0] = value,
                          validator: (value) =>
                              value != null && _esEntradaValida(value) ? null : 'Tiro inválido',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Tiro 2'),
                          onChanged: (value) => _framesText[i][1] = value,
                          validator: (value) {
                            final tiro1 = _framesText[i][0];
                            if (tiro1.trim().toUpperCase() == 'X' && (value == null || value.trim().isEmpty)) {
                              return null;
                            }
                            if (value == null || !_esEntradaValida(value)) return 'Tiro inválido';
                            if (!_sumaValida(tiro1, value, i)) return 'Suma > 10';
                            return null;
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                onChanged: (value) => _notas = value,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) _guardarPartida();
                  },
                  child: const Text('Guardar partida'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  List<List<int>> interpretarFrames(List<List<String>> input) {
    List<List<int>> frames = [];
    for (int i = 0; i < input.length; i++) {
      final entrada = input[i];
      int tiro1 = 0;
      int tiro2 = 0;

      if (entrada[0].toUpperCase() == 'X') {
        tiro1 = 10;
        if (i == 9 && entrada[1].isNotEmpty) {
          tiro2 = _parseTiro(entrada[1]);
          frames.add([tiro1, tiro2]);
        } else {
          frames.add([tiro1]);
        }
      } else {
        tiro1 = _parseTiro(entrada[0]);
        tiro2 = entrada[1] == '/' ? (10 - tiro1) : _parseTiro(entrada[1]);
        frames.add([tiro1, tiro2]);
      }
    }
    return frames;
  }

  int _parseTiro(String valor) {
    valor = valor.trim().toUpperCase();
    if (valor == 'X') return 10;
    return int.tryParse(valor) ?? 0;
  }

  int calcularPuntuacionTotal(List<List<int>> frames) {
    int total = 0;
    int frameIndex = 0;
    for (int i = 0; i < 10; i++) {
      final frame = frames[frameIndex];
      if (frame.length == 1 && frame[0] == 10) {
        total += 10 + _siguienteTiro(frames, frameIndex, 1) + _siguienteTiro(frames, frameIndex, 2);
        frameIndex += 1;
      } else if (frame.length >= 2 && frame[0] + frame[1] == 10) {
        total += 10 + _siguienteTiro(frames, frameIndex, 1);
        frameIndex += 1;
      } else {
        total += frame.take(2).fold(0, (a, b) => a + b);
        frameIndex += 1;
      }
    }
    return total;
  }

  int _siguienteTiro(List<List<int>> frames, int currentFrameIndex, int n) {
    int count = 0;
    for (int i = currentFrameIndex + 1; i < frames.length; i++) {
      for (int tiro in frames[i]) {
        count += 1;
        if (count == n) return tiro;
      }
    }
    return 0;
  }
}
