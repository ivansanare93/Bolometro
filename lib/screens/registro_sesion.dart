import 'package:flutter/material.dart';
import '../models/partida.dart';
import '../utils/registro_tiros_utils.dart';
import '../widgets/marcador_bolos.dart';
import '../utils/teclado_tiros_adaptativo.dart';
import '../widgets/selector_tipo_partida.dart';
import '../widgets/resumen_puntuacion.dart';
import '../widgets/notas_field.dart';
import 'home.dart';

class RegistroSesionScreen extends StatefulWidget {
  final void Function(Partida nuevaPartida) onGuardar;

  const RegistroSesionScreen({super.key, required this.onGuardar});

  @override
  State<RegistroSesionScreen> createState() => _RegistroSesionScreenState();
}

class _RegistroSesionScreenState extends State<RegistroSesionScreen>
    with SingleTickerProviderStateMixin {
  final marcadorKey = GlobalKey<MarcadorBolosState>();
  final ValueNotifier<Set<String>> teclasDeshabilitadas = ValueNotifier({});
  final ValueNotifier<bool> mostrarTeclado = ValueNotifier(false);

  late List<List<String>> framesText;
  String _tipo = 'Entrenamiento';
  String? notas;
  Map<int, Set<int>> erroresPorTiro = {};

  late AnimationController _animController;
  late Animation<double> _animacionTeclado;

  @override
  void initState() {
    super.initState();
    framesText = List.generate(10, (_) => List.filled(3, ''));
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

  void _guardar() {
    final nuevosFrames = interpretarFrames(framesText);
    final errores = validarPartida(framesText);

    if (errores.isNotEmpty) {
      marcadorKey.currentState?.enfocarPrimerError();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Errores en la partida'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errores.map((e) => Text('• ${e.mensaje}')).toList(),
          ),
          actions: [
            TextButton(
              child: const Text('Entendido'),
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
          content: const Text('La partida no tiene puntuación válida.'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
      return;
    }

    final nuevaPartida = Partida(
      fecha: DateTime.now(),
      lugar: '', // Se podría pedir como campo si lo necesitas
      frames: nuevosFrames,
      notas: notas?.trim().isEmpty == true ? null : notas?.trim(),
      total: nuevoTotal,
    );

    widget.onGuardar(nuevaPartida);
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
      appBar: AppBar(title: const Text('Registrar partida'),
              centerTitle: true,
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
        ],),
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
            ResumenPuntuacion(
              puntuacionActual: puntuacionActual,
              puntuacionMaxima: puntuacionMaxima,
              buenaRacha: buenaRacha,
            ),
            const SizedBox(height: 16),
            NotasField(
              initialValue: notas,
              onChanged: (v) => notas = v,
              onFocusChange: (focused) {
                if (focused) {
                  marcadorKey.currentState?.desactivarCampoActivo();
                  mostrarTeclado.value = false;
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 40), // Extra espacio al final por estética
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
          label: const Text('Guardar Partida'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
    );
  }
}
