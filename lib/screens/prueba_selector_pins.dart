import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SelectorPinosWidget extends StatefulWidget {
  final void Function(List<int> pinosCaidos)? onChanged;
  final List<int>? pinosIniciales;
  final List<int>? pinosDeshabilitados; // <-- NUEVO

  const SelectorPinosWidget({
    super.key,
    this.onChanged,
    this.pinosIniciales,
    this.pinosDeshabilitados,
  });

  @override
  State<SelectorPinosWidget> createState() => _SelectorPinosWidgetState();
}

class _SelectorPinosWidgetState extends State<SelectorPinosWidget> {
  late List<bool> _pinosCaidos;

  @override
  void initState() {
    super.initState();
    _pinosCaidos = List.generate(
      10,
      (i) => widget.pinosIniciales?.contains(i + 1) ?? false,
    );
  }

  void _togglePino(int index) {
    // Si está deshabilitado, no hacer nada
    if (widget.pinosDeshabilitados?.contains(index + 1) ?? false) return;

    HapticFeedback.selectionClick();
    setState(() {
      _pinosCaidos[index] = !_pinosCaidos[index];
    });
    widget.onChanged?.call(
      List.generate(
        10,
        (i) => _pinosCaidos[i] ? i + 1 : null,
      ).whereType<int>().toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final azulFondo = const Color(0xFFF0F8FF);
    final azul = const Color(0xFF0077B6);

    // Orden oficial invertido
    final filas = [
      [7, 8, 9, 10],
      [4, 5, 6],
      [2, 3],
      [1],
    ];

    return Scaffold(
      backgroundColor: azulFondo,
      appBar: AppBar(
        title: const Text('Selecciona los pinos'),
        backgroundColor: azul,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxPinosEnFila = 4;
          final horizontalPadding = 24 * 2;
          final spacing = 16.0;
          final maxWidth =
              constraints.maxWidth -
              horizontalPadding -
              spacing * (maxPinosEnFila - 1);
          double pinoSize = maxWidth / maxPinosEnFila;
          if (pinoSize > 38) pinoSize = 38;
          if (pinoSize < 28) pinoSize = 28;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Selecciona los pinos que has tirado',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 18),
                ...filas.map((fila) => _rowPinos(fila, pinoSize, spacing)),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azul,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(
                      () => _pinosCaidos = List.generate(10, (_) => false),
                    );
                    widget.onChanged?.call([]);
                  },
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text("Limpiar"),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Devuelve los pinos seleccionados y cierra la pantalla
                    Navigator.pop(
                      context,
                      List.generate(
                        10,
                        (i) => _pinosCaidos[i] ? i + 1 : null,
                      ).whereType<int>().toList(),
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Confirmar selección"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _rowPinos(List<int> indices, double pinoSize, double spacing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: indices.map((pino) {
        final idx = pino - 1;
        final deshabilitado =
            widget.pinosDeshabilitados?.contains(pino) ?? false;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: GestureDetector(
            onTap: deshabilitado ? null : () => _togglePino(idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: pinoSize,
              height: pinoSize,
              decoration: BoxDecoration(
                color: deshabilitado
                    ? Colors.grey[300]
                    : _pinosCaidos[idx]
                    ? const Color(0xFF0077B6)
                    : Colors.white,
                border: Border.all(
                  color: deshabilitado
                      ? Colors.grey[400]!
                      : _pinosCaidos[idx]
                      ? const Color(0xFF0077B6)
                      : Colors.grey[300]!,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(pinoSize / 2),
                boxShadow: [
                  if (_pinosCaidos[idx] && !deshabilitado)
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
                        : _pinosCaidos[idx]
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: pinoSize * 0.5,
                    shadows: [
                      if (_pinosCaidos[idx] && !deshabilitado)
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
    );
  }
}

void setTiroConSelector({
  required int frame,
  required int tiro,
  required List<int> pinosSeleccionados,
  required List<List<String>> framesText,
}) {
  final pinosTirados = pinosSeleccionados.length;

  // ¿Es primer tiro?
  if (tiro == 0) {
    if (pinosTirados == 10) {
      framesText[frame][tiro] = "X"; // STRIKE
    } else if (pinosTirados == 0) {
      framesText[frame][tiro] = "-";
    } else {
      framesText[frame][tiro] = "$pinosTirados";
    }
  }
  // ¿Es segundo tiro?
  else if (tiro == 1) {
    final primero = framesText[frame][0];
    final prevTirados = primero == "X"
        ? 10
        : (primero == "-" ? 0 : int.tryParse(primero) ?? 0);

    if ((prevTirados + pinosTirados) == 10 && prevTirados != 10) {
      framesText[frame][tiro] = "/"; // SPARE
    } else if (pinosTirados == 0) {
      framesText[frame][tiro] = "-";
    } else {
      framesText[frame][tiro] = "$pinosTirados";
    }
  }
  // Tercer tiro (solo frame 10)
  else if (tiro == 2) {
    if (pinosTirados == 10) {
      framesText[frame][tiro] = "X";
    } else if (pinosTirados == 0) {
      framesText[frame][tiro] = "-";
    } else {
      framesText[frame][tiro] = "$pinosTirados";
    }
  }
}
