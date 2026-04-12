import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/partida.dart';
import '../providers/keyboard_provider.dart';
import '../services/analytics_service.dart';
import '../utils/app_constants.dart';
import '../utils/pines_a_tiro_utils.dart';
import '../utils/registro_tiros_utils.dart';
import '../widgets/marcador_bolos.dart';
import '../widgets/teclado_selector_pins.dart';
import '../utils/teclado_tiros_adaptativo.dart';
import '../widgets/resumen_puntuacion.dart';
import '../widgets/score_sheet_pin_strip.dart';
import '../widgets/notas_field.dart';
import 'home.dart';
import '../l10n/app_localizations.dart';

class EditarPartidaScreen extends StatefulWidget {
  final Partida partida;
  final Function(Partida partidaActualizada) onGuardar;

  const EditarPartidaScreen({
    super.key,
    required this.partida,
    required this.onGuardar,
  });

  @override
  State<EditarPartidaScreen> createState() => _EditarPartidaScreenState();
}

class _EditarPartidaScreenState extends State<EditarPartidaScreen>
    with SingleTickerProviderStateMixin {
  late List<List<String>> framesText;
  late String? notas;
  Map<int, Set<int>> erroresPorTiro = {};
  final marcadorKey = GlobalKey<MarcadorBolosState>();
  final ValueNotifier<Set<String>> teclasDeshabilitadas = ValueNotifier({});
  final ValueNotifier<bool> mostrarTeclado = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  bool _modoVisual = false;
  bool mostrarSelectorpines = false;
  int? _frameActivo;
  int? _tiroActivo;
  late List<List<List<int>?>> pinesPorTiro;

  late AnimationController _animController;
  late Animation<double> _animacionTeclado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logScreenView('edit_game_screen');
      } catch (e) {
        debugPrint('Error logging screen view: $e');
      }
      final keyboardProvider =
          Provider.of<KeyboardProvider>(context, listen: false);
      keyboardProvider.initializationFuture.then((_) {
        if (mounted) {
          setState(() {
            _modoVisual = keyboardProvider.modoVisual;
            mostrarSelectorpines = _modoVisual;
          });
        }
      });
    });
    framesText = widget.partida.frames
        .map((f) => f.map((v) => v == '0' ? '-' : v).toList()..length = 3)
        .toList();
    notas = widget.partida.notas;
    erroresPorTiro = _obtenerErroresPorTiro(framesText);
    pinesPorTiro = List.generate(
      10,
      (i) => List<List<int>?>.from(
        widget.partida.pinesPorTiro.length > i
            ? widget.partida.pinesPorTiro[i]
            : List.filled(3, null),
      ),
    );

    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animacionTeclado = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    mostrarTeclado.addListener(() {
      if (mostrarTeclado.value) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final f = marcadorKey.currentState;
      if (f != null && f.frameActivoGetter >= 0 && f.tiroActivoGetter >= 0) {
        teclasDeshabilitadas.value = TecladoTiros.calcularTeclasDeshabilitadas(
          frame: f.frameActivoGetter,
          tiro: f.tiroActivoGetter,
          frames: framesText,
        );
        mostrarTeclado.value = true;
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Map<int, Set<int>> _obtenerErroresPorTiro(List<List<String>> frames) {
    final errores = <int, Set<int>>{};
    for (int i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final erroresFrame = validarFrame(frame, index: i);
      for (final error in erroresFrame) {
        final mensaje = error.mensaje;
        if (mensaje.contains('Tiro 1')) {
          errores[i] = (errores[i] ?? {})..add(0);
        } else if (mensaje.contains('Tiro 2')) {
          errores[i] = (errores[i] ?? {})..add(1);
        } else if (mensaje.contains('Tiro 3')) {
          errores[i] = (errores[i] ?? {})..add(2);
        } else {
          errores[i] = (errores[i] ?? {})..addAll({0, 1, 2});
        }
      }
    }
    return errores;
  }

  Future<void> _guardar() async {
    final nuevosFrames = interpretarFrames(framesText);
    final errores = validarPartida(framesText);

    if (errores.isNotEmpty) {
      marcadorKey.currentState?.enfocarPrimerError();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.gameErrors),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errores.map((e) => Text('• $e')).toList(),
          ),
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.understood),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    final nuevoTotal = calcularPuntuacionPartida(nuevosFrames);

    if (nuevoTotal == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.gameInvalidScore),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
      return;
    }

    final partidaActualizada = widget.partida.copyWith(
      frames: nuevosFrames,
      notas: notas,
      total: nuevoTotal,
      pinesPorTiro: pinesPorTiro,
    );

    try {
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await analytics.logGameEdited();
    } catch (e) {
      debugPrint('Error logging game edit: $e');
    }

    widget.onGuardar(partidaActualizada);
    Navigator.pop(context);
  }

  void _actualizarTeclasDeshabilitadas() {
    final f = marcadorKey.currentState;
    if (f != null && f.frameActivoGetter >= 0 && f.tiroActivoGetter >= 0) {
      teclasDeshabilitadas.value = TecladoTiros.calcularTeclasDeshabilitadas(
        frame: f.frameActivoGetter,
        tiro: f.tiroActivoGetter,
        frames: framesText,
      );
      mostrarTeclado.value = true;
    }
  }

  void _onCampoVisualActivo(int frame, int tiro) {
    setState(() {
      _frameActivo = frame;
      _tiroActivo = tiro;
      mostrarSelectorpines = true;
    });
    _scrollToBottom();
  }

  void _onAceptarSeleccionPins(List<int> seleccionados) {
    final frame = _frameActivo!;
    final tiro = _tiroActivo!;

    final valor = pinesAValorTiro(
      frame: frame,
      tiro: tiro,
      seleccionados: seleccionados,
      pinesPorTiroFrame: pinesPorTiro[frame],
      framesText: framesText,
    );

    final updatedFrames = List<List<String>>.generate(
      10,
      (i) => List<String>.from(framesText[i]),
    );
    updatedFrames[frame][tiro] = valor;

    int nextFrame = frame;
    int nextTiro = tiro;

    if (frame < 9) {
      if (valor == AppConstants.simboloStrike || tiro == 1) {
        nextFrame = frame + 1;
        nextTiro = 0;
      } else {
        nextTiro = 1;
      }
    } else {
      if (tiro < 2) {
        if (tiro == 1 && !mostrarTercerTiro(updatedFrames)) {
          // No third shot needed
        } else {
          nextTiro = tiro + 1;
        }
      }
    }

    final advanced = !(nextFrame == frame && nextTiro == tiro);

    setState(() {
      pinesPorTiro[frame][tiro] = seleccionados;
      framesText[frame][tiro] = valor;
      erroresPorTiro = _obtenerErroresPorTiro(framesText);
      if (!advanced) {
        mostrarSelectorpines = false;
      }
    });

    if (advanced) {
      marcadorKey.currentState?.setTiroActivo(nextFrame, nextTiro);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final frames = interpretarFrames(framesText);
    final puntuacionActual = calcularPuntuacionPartida(frames);
    final puntuacionMaxima = calcularPuntuacionMaximaPosible(frames);
    final buenaRacha = esBuenaRacha(frames);

    List<int> pinesDeshabilitados = [];
    bool esStrikeEnPrimerTiro = false;

    if (_modoVisual && _frameActivo != null && _tiroActivo != null) {
      pinesDeshabilitados = calcularPinesDeshabilitados(
        frame: _frameActivo!,
        tiro: _tiroActivo!,
        pinesPorTiroFrame: pinesPorTiro[_frameActivo!],
      );
    }

    if (_modoVisual &&
        _frameActivo != null &&
        _tiroActivo == 1 &&
        _frameActivo! < 9) {
      final prevTiro = pinesPorTiro[_frameActivo!][0];
      if (prevTiro != null && prevTiro.length == 10) {
        esStrikeEnPrimerTiro = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editGameTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: AppLocalizations.of(context)!.home,
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    final newModoVisual = !_modoVisual;
                    setState(() {
                      _modoVisual = newModoVisual;
                      mostrarSelectorpines = newModoVisual;
                      _actualizarTeclasDeshabilitadas();
                    });
                    Provider.of<KeyboardProvider>(context, listen: false)
                        .setModoVisual(newModoVisual);
                    if (newModoVisual) _scrollToBottom();
                  },
                  icon: Icon(
                    _modoVisual ? Icons.keyboard : Icons.push_pin_rounded,
                  ),
                  label: Text(
                    _modoVisual
                        ? AppLocalizations.of(context)!.switchToClassicKeyboard
                        : AppLocalizations.of(context)!.registerPinsVisually,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _modoVisual
                        ? Colors.orange
                        : const Color(0xFF0077B6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            MarcadorBolos(
              key: marcadorKey,
              frames: framesText,
              puntuaciones: calcularPuntuacionPorFrame(framesText),
              frameActivo: framesText.indexWhere(
                (f) =>
                    tipoDeFrame(f, esUltimo: framesText.indexOf(f) == 9) ==
                    TipoFrame.incompleto,
              ),
              erroresPorTiro: erroresPorTiro,
              onChanged: (frame, tiro, valor) {
                setState(() {
                  framesText[frame][tiro] = valor.trim().toUpperCase();
                  if (!_modoVisual) pinesPorTiro[frame][tiro] = null;
                  erroresPorTiro = _obtenerErroresPorTiro(framesText);
                });
                if (!_modoVisual) {
                  _actualizarTeclasDeshabilitadas();
                }
              },
              onCampoActivoCambio: _modoVisual
                  ? (frame, tiro) => _onCampoVisualActivo(frame, tiro)
                  : (frame, tiro) {
                      mostrarTeclado.value = true;
                      _actualizarTeclasDeshabilitadas();
                    },
              autoFocusEnabled: !_modoVisual,
              autoAdvanceFocus: true,
            ),

            if (_modoVisual &&
                pinesPorTiro.any((f) => f.any((t) => t != null))) ...[
              const SizedBox(height: 6),
              ScoreSheetPinStrip(
                pinesPorTiro: pinesPorTiro,
                frameActivo: _frameActivo,
              ),
            ],

            const SizedBox(height: 8),
            ResumenPuntuacion(
              puntuacionActual: puntuacionActual,
              puntuacionMaxima: puntuacionMaxima,
              buenaRacha: buenaRacha,
            ),

            if (_modoVisual &&
                mostrarSelectorpines &&
                _frameActivo != null &&
                _tiroActivo != null &&
                !(esStrikeEnPrimerTiro &&
                    _tiroActivo == 1 &&
                    _frameActivo! < 9))
              Builder(
                builder: (_) {
                  List<int> pinesIniciales =
                      pinesPorTiro[_frameActivo!][_tiroActivo!] ?? [];

                  if (_frameActivo == 9) {
                    if (_tiroActivo == 1) {
                      final tiro1 = pinesPorTiro[9][0] ?? [];
                      if (tiro1.length == 10) {
                        pinesIniciales = [];
                      } else {
                        pinesIniciales = tiro1;
                      }
                    } else if (_tiroActivo == 2) {
                      final tiro1 = pinesPorTiro[9][0] ?? [];
                      final tiro2 = pinesPorTiro[9][1] ?? [];
                      final huboStrike1 = tiro1.length == 10;
                      final huboSpare =
                          !huboStrike1 && (tiro1.length + tiro2.length == 10);

                      if (huboStrike1 || huboSpare) {
                        pinesIniciales = [];
                      } else {
                        pinesIniciales = [...tiro1, ...tiro2];
                      }
                    }
                  }

                  return SelectorpinesWidget(
                    key: ValueKey((_frameActivo!, _tiroActivo!)),
                    pinesIniciales: pinesIniciales,
                    pinesDeshabilitados: pinesDeshabilitados,
                    onAceptar: _onAceptarSeleccionPins,
                    isFrame10: _frameActivo == 9,
                    tiroActual: _tiroActivo!,
                    frames: framesText,
                  );
                },
              )
            else if (!_modoVisual)
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) => Opacity(
                  opacity: _animController.value,
                  child: SizeTransition(
                    sizeFactor: _animacionTeclado,
                    axisAlignment: -1.0,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: mostrarTeclado,
                      builder: (context, visible, _) {
                        if (!visible) return const SizedBox.shrink();
                        return TecladoTiros(
                          onKeyPress: (valor) {
                            if (valor == '⌫') {
                              marcadorKey.currentState?.borrarValor();
                            } else if (valor == '→') {
                              marcadorKey.currentState?.siguiente();
                            } else {
                              marcadorKey.currentState?.insertarValor(valor);
                            }
                            _actualizarTeclasDeshabilitadas();
                          },
                          deshabilitadosNotifier: teclasDeshabilitadas,
                        );
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (!_modoVisual)
              NotasField(
                initialValue: notas,
                onChanged: (v) => notas = v,
                onTap: () {
                  marcadorKey.currentState?.desactivarCampoActivo();
                  mostrarTeclado.value = false;
                  setState(() {});
                },
              ),
            const SizedBox(height: 40), // Deja espacio para el botón fijo
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
        child: ElevatedButton.icon(
          onPressed: _guardar,
          icon: const Icon(Icons.save),
          label: Text(AppLocalizations.of(context)!.saveChanges),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
