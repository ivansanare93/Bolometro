import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import '../utils/registro_tiros_utils.dart';

class MarcadorBolos extends StatefulWidget {
  final List<List<String>> frames;
  final List<int?> puntuaciones;
  final int? frameActivo;
  final void Function(int frame, int tiro, String valor)? onChanged;
  final bool autoFocusEnabled;
  final bool autoAdvanceFocus;
  final Map<int, Set<int>>? erroresPorTiro;
  final void Function(int frame, int tiro)? onCampoActivoCambio;

  const MarcadorBolos({
    super.key,
    required this.frames,
    required this.puntuaciones,
    this.frameActivo,
    this.onChanged,
    this.autoFocusEnabled = false,
    this.autoAdvanceFocus = false,
    this.erroresPorTiro,
    this.onCampoActivoCambio,
  });

  @override
  MarcadorBolosState createState() => MarcadorBolosState();
}

class MarcadorBolosState extends State<MarcadorBolos> {
  late int frameActivo;
  late int tiroActivo;
  late List<List<TextEditingController>> _controllers;
  late List<List<FocusNode>> _focusNodes;
  late ScrollController _scrollController;
  final ValueNotifier<bool> hayCampoActivoNotifier = ValueNotifier(false);

  void setTiroActivo(int frame, int tiro) {
    setState(() {
      frameActivo = frame;
      tiroActivo = tiro;
      hayCampoActivoNotifier.value = true;
    });
    widget.onCampoActivoCambio?.call(frame, tiro);
    _scrollAlFrameActivo();
  }

  int get frameActivoGetter => frameActivo;
  int get tiroActivoGetter => tiroActivo;

  bool get hayCampoActivo {
    return _focusNodes.any((fila) => fila.any((nodo) => nodo.hasFocus));
  }

  void desactivarCampoActivo() {
    setState(() {
      frameActivo = -1;
      tiroActivo = -1;
      hayCampoActivoNotifier.value = false;
    });
  }

  @override
  void initState() {
    super.initState();
    frameActivo = widget.frameActivo ?? 0;
    tiroActivo = 0;
    hayCampoActivoNotifier.value = false;
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
    _scrollController = ScrollController();
  }

  void _scrollAlFrameActivo() {
    if (frameActivo >= 0 && frameActivo < 10) {
      final offset = frameActivo * 100.0;
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void enfocarPrimerError() {
    final errores = widget.erroresPorTiro;
    if (errores != null && errores.isNotEmpty) {
      final primerFrame = errores.keys.first;
      setState(() {
        frameActivo = primerFrame;
        tiroActivo = errores[primerFrame]?.first ?? 0;
        hayCampoActivoNotifier.value = true;
      });
      widget.onCampoActivoCambio?.call(frameActivo, tiroActivo);
      _scrollAlFrameActivo();
    }
  }

  void insertarValor(String valor) {
    setState(() {
      _controllers[frameActivo][tiroActivo].text = valor;
      widget.onChanged?.call(frameActivo, tiroActivo, valor);

      if (frameActivo < 9) {
        if (valor == 'X' || tiroActivo == 1) {
          frameActivo++;
          tiroActivo = 0;
        } else {
          tiroActivo = 1;
        }
      } else {
        if (tiroActivo == 1 && !mostrarTercerTiro(widget.frames)) {
          return;
        }
        if (tiroActivo < 2) {
          tiroActivo++;
        }
      }

      widget.onCampoActivoCambio?.call(frameActivo, tiroActivo);
      hayCampoActivoNotifier.value = true;
      _scrollAlFrameActivo();
    });
  }

  void borrarValor() {
    setState(() {
      _controllers[frameActivo][tiroActivo].text = '';
      widget.onChanged?.call(frameActivo, tiroActivo, '');
      widget.onCampoActivoCambio?.call(frameActivo, tiroActivo);
      hayCampoActivoNotifier.value = true;
    });
  }

  void siguiente() {
    setState(() {
      if (frameActivo < 9) {
        if (tiroActivo == 0) {
          tiroActivo = 1;
        } else {
          frameActivo++;
          tiroActivo = 0;
        }
      } else {
        if (tiroActivo == 1 && !mostrarTercerTiro(widget.frames)) {
          return;
        }
        if (tiroActivo < 2) {
          tiroActivo++;
        }
      }
      widget.onCampoActivoCambio?.call(frameActivo, tiroActivo);
      hayCampoActivoNotifier.value = true;
      _scrollAlFrameActivo();
    });
  }
  
  @override
void didUpdateWidget(covariant MarcadorBolos oldWidget) {
  super.didUpdateWidget(oldWidget);
  // Si los frames han cambiado, actualiza los controllers
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < 3; j++) {
      if (_controllers[i][j].text != widget.frames[i][j]) {
        _controllers[i][j].text = widget.frames[i][j];
      }
    }
  }
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
    _scrollController.dispose();
    hayCampoActivoNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: Row(
        children: List.generate(10, (index) {
          final frame = widget.frames[index];
          final puntaje = index < widget.puntuaciones.length
              ? widget.puntuaciones[index]
              : null;
          final esUltimo = index == 9;

          final tirosEnFrame = esUltimo
              ? (mostrarTercerTiro(widget.frames) ? 3 : 2)
              : 2;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: index == frameActivo
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                width: 2,
              ),
              boxShadow: index == frameActivo
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.2),
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
                  children: List.generate(tirosEnFrame, (tiro) {
                    final esCampoActivo =
                        index == frameActivo && tiro == tiroActivo;

                    bool frameCompletoParaValidar() {
                      if (esUltimo) {
                        if (tiro == 2) {
                          final t1 = frame[0];
                          final t2 = frame[1];
                          return (t1 == 'X' || t2 == '/') &&
                              frame[2].isNotEmpty;
                        }
                        return frame[0].isNotEmpty && frame[1].isNotEmpty;
                      } else {
                        return frame[0].isNotEmpty && frame[1].isNotEmpty;
                      }
                    }

                    final mostrarError =
                        (widget.erroresPorTiro?[index]?.contains(tiro) ??
                            false) &&
                        frameCompletoParaValidar();

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedScale(
                        scale: esCampoActivo ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: mostrarError
                                  ? theme.colorScheme.error
                                  : esCampoActivo
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                              width: esCampoActivo ? 2.5 : 1.5,
                            ),
                          ),
                          child: Center(
                            child: TextField(
                              controller: _controllers[index][tiro],
                              focusNode: _focusNodes[index][tiro],
                              readOnly: true,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: esCampoActivo
                                    ? Colors.green
                                    : theme.colorScheme.onSurface,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                isCollapsed: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onTap: () {
                                setState(() {
                                  frameActivo = index;
                                  tiroActivo = tiro;
                                  hayCampoActivoNotifier.value = true;
                                });
                                widget.onChanged?.call(
                                  index,
                                  tiro,
                                  _controllers[index][tiro].text,
                                );
                                widget.onCampoActivoCambio?.call(
                                  frameActivo,
                                  tiroActivo,
                                );
                                _scrollAlFrameActivo();
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  puntaje?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: puntaje == null
                        ? theme.hintColor
                        : theme.colorScheme.primary,
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
