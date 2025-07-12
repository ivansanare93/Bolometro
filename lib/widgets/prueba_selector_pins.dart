// widgets/selector_pines_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SelectorpinesWidget extends StatefulWidget {
  final List<int> pinesIniciales;
  final List<int> pinesDeshabilitados;
  final void Function(List<int>) onAceptar;

  const SelectorpinesWidget({
    super.key,
    required this.pinesIniciales,
    required this.pinesDeshabilitados,
    required this.onAceptar,
  });

  @override
  State<SelectorpinesWidget> createState() => _SelectorpinesWidgetState();
}

class _SelectorpinesWidgetState extends State<SelectorpinesWidget> {
  late List<bool> _pinesCaidos;

  @override
  void initState() {
    super.initState();
    _pinesCaidos = List.generate(
      10,
      (i) => widget.pinesIniciales.contains(i + 1),
    );
  }

  void _togglePino(int index) {
    if (widget.pinesDeshabilitados.contains(index + 1)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pinesCaidos[index] = !_pinesCaidos[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final azulFondo = const Color(0xFFF0F8FF);
    final azul = const Color(0xFF0077B6);
    final filas = [
      [7, 8, 9, 10],
      [4, 5, 6],
      [2, 3],
      [1],
    ];
    final seleccionados = List.generate(
      10,
      (i) => _pinesCaidos[i] ? i + 1 : null,
    ).whereType<int>().toList();

    return Card(
      elevation: 6,
      color: azulFondo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecciona los pines que has tirado',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...filas.map(
              (fila) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: fila.map((pino) {
                  final idx = pino - 1;
                  final deshabilitado = widget.pinesDeshabilitados.contains(
                    pino,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: GestureDetector(
                      onTap: deshabilitado ? null : () => _togglePino(idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: deshabilitado
                              ? Colors.grey[300]
                              : _pinesCaidos[idx]
                              ? azul
                              : Colors.white,
                          border: Border.all(
                            color: deshabilitado
                                ? Colors.grey[400]!
                                : _pinesCaidos[idx]
                                ? azul
                                : Colors.grey[300]!,
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(19),
                          boxShadow: [
                            if (_pinesCaidos[idx] && !deshabilitado)
                              const BoxShadow(
                                color: Colors.blueAccent,
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            pino.toString(),
                            style: TextStyle(
                              color: deshabilitado
                                  ? Colors.grey
                                  : _pinesCaidos[idx]
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              shadows: [
                                if (_pinesCaidos[idx] && !deshabilitado)
                                  const Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 6,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.restart_alt_rounded),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: azul,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: () {
                      setState(
                        () => _pinesCaidos = List.generate(10, (_) => false),
                      );
                    },
                    label: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: () => widget.onAceptar(seleccionados),
                    label: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
