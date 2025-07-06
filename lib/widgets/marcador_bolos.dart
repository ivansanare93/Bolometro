import 'package:flutter/material.dart';

class MarcadorBolos extends StatefulWidget {
  final List<List<String>> frames;
  final List<int?> puntuaciones;
  final int? frameActivo;
  final void Function(int frame, int tiro, String valor)? onChanged;
  final bool autoFocusEnabled;
  final bool autoAdvanceFocus;

  const MarcadorBolos({
    super.key,
    required this.frames,
    required this.puntuaciones,
    this.frameActivo,
    this.onChanged,
    this.autoFocusEnabled = false,
    this.autoAdvanceFocus = false,
  });

  @override
  State<MarcadorBolos> createState() => _MarcadorBolosState();
}

class _MarcadorBolosState extends State<MarcadorBolos> {
  late List<List<TextEditingController>> _controllers;
  late List<List<FocusNode>> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      10,
      (i) => List.generate(3, (j) => TextEditingController(text: widget.frames[i][j])),
    );
    _focusNodes = List.generate(
      10,
      (i) => List.generate(3, (j) => FocusNode()),
    );
  }

  @override
  void dispose() {
    for (final frameControllers in _controllers) {
      for (final c in frameControllers) {
        c.dispose();
      }
    }
    for (final frameFocus in _focusNodes) {
      for (final f in frameFocus) {
        f.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(10, (index) {
          final frame = widget.frames[index];
          final puntaje = index < widget.puntuaciones.length ? widget.puntuaciones[index] : null;
          final esActivo = index == widget.frameActivo;
          final esUltimo = index == 9;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: esActivo ? Colors.blue.shade50 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: esActivo ? Colors.blue : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text('Frame ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int tiro = 0; tiro < (esUltimo ? 3 : 2); tiro++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: SizedBox(
                          width: 36,
                          child: TextField(
                            controller: _controllers[index][tiro],
                            focusNode: _focusNodes[index][tiro],
                            autofocus: widget.autoFocusEnabled && index == 0 && tiro == 0,
                            textAlign: TextAlign.center,
                            onChanged: (v) {
                              widget.onChanged?.call(index, tiro, v);
                              if (widget.autoAdvanceFocus && v.trim().isNotEmpty) {
                                if (tiro == 0 && (!esUltimo || frame[0] != 'X')) {
                                  FocusScope.of(context).requestFocus(_focusNodes[index][1]);
                                } else if (tiro == 1 && esUltimo) {
                                  FocusScope.of(context).requestFocus(_focusNodes[index][2]);
                                }
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  puntaje?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: puntaje == null ? Colors.grey : Colors.black,
                    fontWeight: puntaje == null ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
