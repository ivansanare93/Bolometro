import 'package:flutter/material.dart';
import '../../../models/partida.dart';

class TopPartidasWidget extends StatelessWidget {
  final List<Partida> partidas;
  final String titulo;
  final Color color;

  const TopPartidasWidget({
    super.key,
    required this.partidas,
    required this.titulo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.09),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...partidas.map(
              (p) => Row(
                children: [
                  const Text('🎳', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 8),
                  Text(
                    "${p.total} pts",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "${p.fecha.day.toString().padLeft(2, '0')}/${p.fecha.month.toString().padLeft(2, '0')}/${p.fecha.year}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
