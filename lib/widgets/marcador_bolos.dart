import 'package:flutter/material.dart';
import '../utils/registro_tiros_utils.dart';

class MarcadorBolos extends StatelessWidget {
  final List<List<dynamic>> frames;
  final List<int?> puntuaciones;
  final int? frameActivo;

  const MarcadorBolos({
    required this.frames,
    required this.puntuaciones,
    this.frameActivo,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(10, (i) {
        final tiros = i < frames.length
            ? frames[i].map((e) => e.toString()).toList()
            : <String>[];

        final punt = i < puntuaciones.length ? puntuaciones[i] : null;
        final tipo = tipoDeFrame(tiros, esUltimo: i == 9);
        final estaActivo = frameActivo == i;

        Color bgColor;
        switch (tipo) {
          case TipoFrame.strike:
          case TipoFrame.spare:
          case TipoFrame.abierto:
            bgColor = Colors.blue.shade100;
            break;
          case TipoFrame.incompleto:
            bgColor = Colors.grey.shade200;
            break;
          case TipoFrame.invalido:
            bgColor = Colors.red.shade100;
            break;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 72,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: estaActivo ? Colors.blueAccent : Colors.blue.shade300,
              width: estaActivo ? 2.5 : 1,
            ),
            boxShadow: estaActivo
                ? [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'F${i + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(tiros.join(' '), style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  punt?.toString() ?? '–',
                  key: ValueKey(punt),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: punt != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}