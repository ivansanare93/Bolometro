import 'package:flutter/material.dart';

class ResumenPuntuacion extends StatelessWidget {
  final int puntuacionActual;
  final int puntuacionMaxima;
  final bool buenaRacha;

  const ResumenPuntuacion({
    super.key,
    required this.puntuacionActual,
    required this.puntuacionMaxima,
    required this.buenaRacha,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  'Puntuación actual: $puntuacionActual',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('🚀', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  'Máximo posible: $puntuacionMaxima',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (buenaRacha)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.whatshot, color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: 6),
                    Text('¡Vas en racha!',
                        style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
