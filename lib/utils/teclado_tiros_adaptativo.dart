import 'package:flutter/material.dart';

class TecladoTiros extends StatelessWidget {
  final void Function(String valor) onKeyPress;
  final ValueNotifier<Set<String>> deshabilitadosNotifier;

  const TecladoTiros({
    super.key,
    required this.onKeyPress,
    required this.deshabilitadosNotifier,
  });

  static Set<String> calcularTeclasDeshabilitadas({
    required int frame,
    required int tiro,
    required List<List<String>> frames,
  }) {
    final deshabilitadas = <String>{};
    final t1 = frames[frame][0];
    final t2 = frames[frame][1];
    final esUltimo = frame == 9;

    final numeros = List.generate(10, (i) => '$i');

    if (tiro == 0) {
      // Primer tiro: no se permite spare
      deshabilitadas.add('/');
    } else if (tiro == 1) {
      deshabilitadas.add('X'); // Nunca puede haber strike en segundo tiro

      if (t1 == 'X') {
        // Strike en el primer tiro: segundo tiro no se usa
        deshabilitadas.addAll(numeros);
        deshabilitadas.add('/');
      } else if (t1.isNotEmpty && t1 != '-') {
        final primerValor = int.tryParse(t1);
        if (primerValor != null) {
          for (var n in numeros) {
            final segundoValor = int.parse(n);
            if (primerValor + segundoValor >= 10) {
              deshabilitadas.add(n); // suma 10: debería usarse '/'
            }
          }
        }
      }
    } else if (tiro == 2 && esUltimo) {
      // Solo se permite tercer tiro en el 10 si hay strike o spare antes
      if (!(t1 == 'X' || t2 == '/' || t2 == 'X')) {
        deshabilitadas.addAll(numeros + ['X', '/']);
      }
    }

    return deshabilitadas;
  }

  @override
  Widget build(BuildContext context) {
    final botones = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['-', '0', '/'],
      ['X', '⌫', '→'],
    ];

    return ValueListenableBuilder<Set<String>>(
      valueListenable: deshabilitadosNotifier,
      builder: (context, deshabilitados, _) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: botones.map((fila) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: fila.map((valor) {
                  final deshabilitado = deshabilitados.contains(valor);
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: AnimatedScale(
                      scale: 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: ElevatedButton(
                        onPressed: deshabilitado
                            ? null
                            : () => onKeyPress(valor),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: deshabilitado
                              ? Colors.grey.shade300
                              : Theme.of(context).colorScheme.primary,
                          foregroundColor: deshabilitado
                              ? Colors.grey
                              : Theme.of(context).colorScheme.onPrimary,
                          minimumSize: const Size(56, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          valor,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
