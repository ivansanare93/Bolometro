import 'package:flutter/material.dart';
import '../models/partida.dart';
import 'ver_partida_screen.dart';
import 'registro_partida_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Crear una partida de ejemplo
    final partidaEjemplo = Partida(
      fecha: DateTime.now(),
      lugar: 'Bolera Central',
      tipo: 'Entrenamiento',
      frames: [
        [10], [7, 2], [9, 0], [10], [10], [6, 3], [8, 1], [10], [9, 1], [10, 10, 9]
      ],
      notas: 'Gran partida, muchos strikes',
      total: 198,
    );

return Scaffold(
  appBar: AppBar(
    title: const Text('Mis Partidas de Bolos'),
  ),
  body: Center(
    child: Column(
      mainAxisSize: MainAxisSize.min, // Centrado verticalmente
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerPartidaScreen(partida: partidaEjemplo),
              ),
            );
          },
          child: const Text('Ver partida de ejemplo'),
        ),
        const SizedBox(height: 16), // Espacio entre botones
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegistroPartidaScreen(),
              ),
            );
          },
          child: const Text('Registrar nueva partida'),
        ),
      ],
    ),
  ),
);
  }
}
