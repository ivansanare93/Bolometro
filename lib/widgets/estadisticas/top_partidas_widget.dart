import 'package:flutter/material.dart';
import '../../models/partida.dart';

class TopPartidasWidget extends StatelessWidget {
  final List<Partida> partidas;
  final String titulo;
  final Color color;

  const TopPartidasWidget({
    Key? key,
    required this.partidas,
    required this.titulo,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? color.withOpacity(0.20)
        : color.withOpacity(0.10);
    final borderColor = color.withOpacity(isDark ? 0.28 : 0.18);
    final fechaColor = Theme.of(
      context,
    ).colorScheme.onSurface.withOpacity(isDark ? 0.70 : 0.58);
    final puntosColor = Theme.of(
      context,
    ).colorScheme.onSurface.withOpacity(0.88);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 9,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          ...partidas.map((p) {
            final fecha = p.fecha != null
                ? "${p.fecha!.day.toString().padLeft(2, '0')}/${p.fecha!.month.toString().padLeft(2, '0')}/${p.fecha!.year}"
                : "Sin fecha";
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Text("🎳", style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    "${p.total} pts",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: puntosColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    fecha,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: fechaColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
