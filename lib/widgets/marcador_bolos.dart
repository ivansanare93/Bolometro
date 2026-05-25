import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import '../utils/registro_tiros_utils.dart';
import '../utils/app_constants.dart';

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
  static const double _frameScrollEdgePadding = 12.0;
  late int frameActivo;
  late int tiroActivo;
  late List<List<TextEditingController>> _controllers;
  late List<List<FocusNode>> _focusNodes;
  late ScrollController _scrollController;
  late List<GlobalKey> _frameKeys;
  final GlobalKey _scrollViewportKey = GlobalKey();
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
      AppConstants.totalFrames,
      (i) => List.generate(
        AppConstants.maxTirosFrame10,
        (j) => TextEditingController(text: widget.frames[i][j]),
      ),
    );
    _focusNodes = List.generate(
      AppConstants.totalFrames,
      (i) => List.generate(AppConstants.maxTirosFrame10, (j) => FocusNode()),
    );
    _scrollController = ScrollController();
    _frameKeys = List.generate(AppConstants.totalFrames, (_) => GlobalKey());
  }

  void _scrollAlFrameActivo() {
    if (frameActivo >= 0 && frameActivo < AppConstants.totalFrames) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;

        final frameContext = _frameKeys[frameActivo].currentContext;
        final viewportContext = _scrollViewportKey.currentContext;
        if (frameContext == null || viewportContext == null) return;

        final frameBox = frameContext.findRenderObject() as RenderBox?;
        final viewportBox = viewportContext.findRenderObject() as RenderBox?;
        if (frameBox == null || viewportBox == null) return;

        final frameOffset =
            frameBox.localToGlobal(Offset.zero, ancestor: viewportBox);
        final frameWidth = frameBox.size.width;
        final viewportWidth = viewportBox.size.width;
        final currentOffset = _scrollController.offset;
        double targetOffset = currentOffset;

        if (frameOffset.dx < _frameScrollEdgePadding) {
          targetOffset =
              currentOffset + (frameOffset.dx - _frameScrollEdgePadding);
        } else if (frameOffset.dx + frameWidth >
            viewportWidth - _frameScrollEdgePadding) {
          targetOffset = currentOffset +
              (frameOffset.dx +
                  frameWidth -
                  (viewportWidth - _frameScrollEdgePadding));
        }

        targetOffset = targetOffset
            .clamp(0.0, _scrollController.position.maxScrollExtent)
            .toDouble();

        if ((targetOffset - currentOffset).abs() < 1) return;

        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
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

      if (frameActivo < AppConstants.totalFrames - 1) {
        if (valor == AppConstants.simboloStrike || tiroActivo == 1) {
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
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        key: _scrollViewportKey,
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(10, (index) {
              final frame = widget.frames[index];
              final puntaje = index < widget.puntuaciones.length
                  ? widget.puntuaciones[index]
                  : null;
              final esUltimo = index == 9;
              final estaActivo = index == frameActivo;

              final tirosEnFrame = esUltimo
                  ? (mostrarTercerTiro(widget.frames) ? 3 : 2)
                  : 2;

              return IntrinsicWidth(
                child: Container(
                  key: _frameKeys[index],
                  decoration: BoxDecoration(
                    color: estaActivo
                        ? (isDark
                            ? theme.colorScheme.primary.withOpacity(0.18)
                            : theme.colorScheme.primary.withOpacity(0.07))
                        : null,
                    border: index > 0
                        ? Border(
                            left: BorderSide(
                              color: theme.dividerColor,
                              width: 0.8,
                            ),
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Frame number header
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        color: estaActivo
                            ? theme.colorScheme.primary
                            : (isDark
                                ? const Color(0xFF1E2533)
                                : theme.colorScheme.surfaceVariant),
                        child: Text(
                          '${index + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: estaActivo
                                ? Colors.white
                                : (isDark
                                    ? Colors.white60
                                    : theme.colorScheme.onSurfaceVariant),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Input cells
                      Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(tirosEnFrame, (tiro) {
                          final esCampoActivo =
                              index == frameActivo && tiro == tiroActivo;

                          bool frameCompletoParaValidar() {
                            if (esUltimo) {
                              if (tiro == 2) {
                                final t1 = frame[0];
                                final t2 = frame[1];
                                return (t1 == AppConstants.simboloStrike ||
                                        t2 == AppConstants.simboloSpare) &&
                                    frame[2].isNotEmpty;
                              }
                              return frame[0].isNotEmpty &&
                                  frame[1].isNotEmpty;
                            } else {
                              return frame[0].isNotEmpty &&
                                  frame[1].isNotEmpty;
                            }
                          }

                          final mostrarError =
                              (widget.erroresPorTiro?[index]?.contains(tiro) ??
                                  false) &&
                              frameCompletoParaValidar();

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2),
                            child: AnimatedScale(
                              scale: esCampoActivo ? 1.08 : 1.0,
                              duration: const Duration(milliseconds: 150),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: esCampoActivo
                                      ? (isDark
                                          ? Colors.green.shade900
                                          : Colors.green.shade50)
                                      : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: mostrarError
                                        ? theme.colorScheme.error
                                        : esCampoActivo
                                            ? Colors.green.shade600
                                            : (isDark
                                                ? Colors.white24
                                                : theme.colorScheme.outline
                                                    .withOpacity(0.6)),
                                    width: esCampoActivo ? 2.0 : 1.0,
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
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: esCampoActivo
                                          ? Colors.green.shade700
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
                    ),
                    // Divider
                    Divider(
                        height: 1,
                        thickness: 0.5,
                        color: theme.dividerColor),
                    // Score
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        puntaje?.toString() ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: puntaje == null
                              ? theme.hintColor
                              : (estaActivo
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primary
                                      .withOpacity(0.75)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
