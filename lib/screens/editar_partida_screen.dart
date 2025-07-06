import 'package:flutter/material.dart';
import '../models/partida.dart';
import '../utils/registro_tiros_utils.dart';
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
    framesText = widget.partida.frames
        .map((f) => List<String>.from(f)..length = 3)
        .toList();
    notas = widget.partida.notas;
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final nuevosFrames = interpretarFrames(framesText);
      final nuevoTotal = calcularPuntuacionPartida(nuevosFrames);

      if (nuevoTotal == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La partida no tiene puntuación válida.'),
          ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Partida')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ...List.generate(10, (i) {
                final mostrarT3 = i == 9 && mostrarTercerTiro(framesText);
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: framesText[i][0],
                        decoration: InputDecoration(
                          labelText: 'F${i + 1} - T1',
                        ),
                        onChanged: (v) {
                          framesText[i][0] = v;
                          if (i == 9) setState(() {});
                        },
                        validator: (value) {
                          final v = value?.trim().toUpperCase() ?? '';
                          if (v == '/')
                            return 'No se puede usar "/" como primer tiro';
                          return esEntradaValida(v) ? null : 'Inválido';
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: framesText[i][1],
                        decoration: const InputDecoration(labelText: 'T2'),
                        onChanged: (v) {
                          final t1 = framesText[i][0];
                          final t2 = v.trim().toUpperCase();

                          if (t1 == '0' && t2 == 'X') {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Un 0 seguido de 'X' se interpreta como '/' (spare).",
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            });
                            framesText[i][1] = '/';
                          } else {
                            framesText[i][1] = t2;
                          }

                          if (i == 9) setState(() {});
                        },
                        validator: (value) {
                          final t1 = framesText[i][0];
                          final t2 = framesText[i][1];

                          if (t1.toUpperCase() == 'X' && (t2.isEmpty))
                            return null;

                          if (!esEntradaValida(t2)) return 'Inválido';
                          if (!sumaValida(t1, t2, i)) return 'Suma > 10';
                          return null;
                        },
                      ),
                    ),

                    if (mostrarT3) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: framesText[i][2],
                          decoration: const InputDecoration(labelText: 'T3'),
                          onChanged: (v) => framesText[i][2] = v,
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            return esEntradaValida(v) ? null : 'Inválido';
                          },
                        ),
                      ),
                    ],
                  ],
                );
              }),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: notas,
                decoration: const InputDecoration(labelText: 'Notas'),
                onChanged: (v) => notas = v,
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
