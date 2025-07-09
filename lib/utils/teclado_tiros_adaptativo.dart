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
    final esUltimo = frame == 9;
    final t1 = frames[frame][0];
    final t2 = frames[frame][1];
    final numeros = List.generate(10, (i) => '$i');

    if (esUltimo) {
      if (tiro == 0) {
        deshabilitadas.add('/'); // primer tiro nunca puede ser spare
      } else if (tiro == 1) {
        deshabilitadas.add(
          'X',
        ); // segundo tiro nunca puede ser strike (salvo si el primero fue X)

        if (t1 == 'X') {
          // Strike en el primero → todo permitido menos '/'
          deshabilitadas.clear();
          deshabilitadas.add('/');
        } else if (t1.isNotEmpty && t1 != '-') {
          final primerValor = int.tryParse(t1);
          if (primerValor != null) {
            for (var n in numeros) {
              final segundoValor = int.parse(n);
              if (primerValor + segundoValor > 10) {
                deshabilitadas.add(n);
              }
            }
          }
        }
      } else if (tiro == 2) {
        // Tercer tiro solo si hubo X o / antes
        if (!(t1 == 'X' || t2 == '/' || t2 == 'X')) {
          deshabilitadas.addAll(numeros + ['X', '/']);
        }
      }
    } else {
      // Frames 1–9
      if (tiro == 0) {
        deshabilitadas.add('/');
      } else if (tiro == 1) {
        deshabilitadas.add('X');
        if (t1 == 'X') {
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
      ['-', '/', 'X'],
      ['⌫', '→', ''],
    ];

    return ValueListenableBuilder<Set<String>>(
      valueListenable: deshabilitadosNotifier,
      builder: (context, deshabilitados, _) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: botones.map((fila) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: fila.map((valor) {
                  if (valor.isEmpty) {
                    return const SizedBox(width: 64, height: 64);
                  }
                  final deshabilitado = deshabilitados.contains(valor);
                  return Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: AnimatedScale(
                      scale: 1.0,
                      duration: const Duration(milliseconds: 120),
                      child: ElevatedButton(
                        onPressed: deshabilitado
                            ? null
                            : () => onKeyPress(valor),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: deshabilitado
                              ? Colors.grey.shade300
                              : Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: deshabilitado
                              ? Colors.grey.shade600
                              : Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                          minimumSize: const Size(64, 64),
                          elevation: deshabilitado ? 0 : 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          valor,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
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
