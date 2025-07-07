import 'package:flutter/material.dart';

class MarcadorBolos extends StatefulWidget {
  final List<List<String>> frames;
  final List<int?> puntuaciones;
  final int? frameActivo;
  final void Function(int frame, int tiro, String valor)? onChanged;
  final bool autoFocusEnabled;
  final bool autoAdvanceFocus;
  final Map<int, Set<int>>? erroresPorTiro;

  MarcadorBolos({
    super.key,
    required this.frames,
    required this.puntuaciones,
    this.frameActivo,
    this.onChanged,
    this.autoFocusEnabled = false,
    this.autoAdvanceFocus = false,
    this.erroresPorTiro,
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
      (i) => List.generate(
        3,
        (j) => TextEditingController(text: widget.frames[i][j]),
      ),
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
          final puntaje = index < widget.puntuaciones.length
              ? widget.puntuaciones[index]
              : null;
          final esActivo = index == widget.frameActivo;
          final esUltimo = index == 9;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: esActivo
                  ? const Color(0xFFE0F3FF)
                  : const Color(0xFFF0F8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: esActivo
                    ? const Color(0xFF0077B6)
                    : Colors.grey.shade400,
                width: 2,
              ),
              boxShadow: esActivo
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              children: [
                Text(
                  'Frame ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int tiro = 0; tiro < (esUltimo ? 3 : 2); tiro++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: (widget.erroresPorTiro?[index]?.contains(tiro) ?? false)
                                  ? Colors.red
                                  : const Color(0xFF0077B6),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: TextField(
                              controller: _controllers[index][tiro],
                              focusNode: _focusNodes[index][tiro],
                              autofocus:
                                  widget.autoFocusEnabled &&
                                  index == 0 &&
                                  tiro == 0,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero,
                                focusedBorder: (widget.erroresPorTiro?[index]?.contains(tiro) ?? false)
                                    ? const OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.red, width: 2),
                                      )
                                    : null,
                              ),
                              onChanged: (v) {
                                widget.onChanged?.call(index, tiro, v);
                                if (widget.autoAdvanceFocus &&
                                    v.trim().isNotEmpty) {
                                  final valor = v.trim().toUpperCase();

                                  if (esUltimo) {
                                    if (tiro == 0 && valor == 'X') {
                                      FocusScope.of(
                                        context,
                                      ).requestFocus(_focusNodes[index][1]);
                                    } else if (tiro == 1 &&
                                        (frame[0] == 'X' || frame[1] == '/')) {
                                      FocusScope.of(
                                        context,
                                      ).requestFocus(_focusNodes[index][2]);
                                    } else if (tiro < 2) {
                                      FocusScope.of(context).requestFocus(
                                        _focusNodes[index][tiro + 1],
                                      );
                                    }
                                  } else {
                                    if (tiro == 0) {
                                      if (valor == 'X') {
                                        if (index < 9) {
                                          FocusScope.of(context).requestFocus(
                                            _focusNodes[index + 1][0],
                                          );
                                        }
                                      } else {
                                        FocusScope.of(
                                          context,
                                        ).requestFocus(_focusNodes[index][1]);
                                      }
                                    } else if (tiro == 1 && index < 9) {
                                      FocusScope.of(
                                        context,
                                      ).requestFocus(_focusNodes[index + 1][0]);
                                    }
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  puntaje?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: puntaje == null
                        ? Colors.grey
                        : const Color(0xFF0077B6),
                    fontWeight: puntaje == null
                        ? FontWeight.normal
                        : FontWeight.bold,
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
