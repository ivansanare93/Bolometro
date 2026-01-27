import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/partida.dart';
import '../services/analytics_service.dart';
import '../utils/registro_tiros_utils.dart';
import '../widgets/marcador_bolos.dart';
import '../utils/teclado_tiros_adaptativo.dart';
import '../widgets/resumen_puntuacion.dart';
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
    });
    framesText = widget.partida.frames
        .map((f) => f.map((v) => v == '0' ? '-' : v).toList()..length = 3)
        .toList();
    notas = widget.partida.notas;
    erroresPorTiro = _obtenerErroresPorTiro(framesText);

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

  @override
  Widget build(BuildContext context) {
    final frames = interpretarFrames(framesText);
    final puntuacionActual = calcularPuntuacionPartida(frames);
    final puntuacionMaxima = calcularPuntuacionMaximaPosible(frames);
    final buenaRacha = esBuenaRacha(frames);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editGameTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: "Inicio",
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
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
                  erroresPorTiro = _obtenerErroresPorTiro(framesText);
                });
                _actualizarTeclasDeshabilitadas();
              },
              onCampoActivoCambio: (frame, tiro) {
                mostrarTeclado.value = true;
              },
              autoFocusEnabled: true,
              autoAdvanceFocus: true,
            ),
            const SizedBox(height: 16),
            ResumenPuntuacion(
              puntuacionActual: puntuacionActual,
              puntuacionMaxima: puntuacionMaxima,
              buenaRacha: buenaRacha,
            ),
            const SizedBox(height: 16),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
