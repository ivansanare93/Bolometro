import 'package:flutter/material.dart';
import '../models/partida.dart';

class VerPartidaScreen extends StatelessWidget {
  final Partida partida;

  const VerPartidaScreen({super.key, required this.partida});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Partida'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fecha: ${partida.fecha.toLocal().toString().split(" ")[0]}'),
            Text('Lugar: ${partida.lugar}'),
            Text('Tipo: ${partida.tipo}'),
            SizedBox(height: 20),
            Text('Frames:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...List.generate(partida.frames.length, (index) {
              final frame = partida.frames[index];
              return Text('Frame ${index + 1}: ${frame.join(" - ")}');
            }),
            SizedBox(height: 10),
            Text('Total: ${partida.total} puntos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Notas: ${partida.notas ?? "Sin notas"}'),
          ],
        ),
      ),
    );
  }
}
