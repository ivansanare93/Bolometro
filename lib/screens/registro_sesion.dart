import 'package:flutter/material.dart';
import '../models/partida.dart';
import '../utils/registro_tiros_utils.dart';
import '../widgets/marcador_bolos.dart';
import '../widgets/teclado_selector_pins.dart'; // Debe aceptar onAceptar
import '../widgets/resumen_puntuacion.dart';
import '../widgets/notas_field.dart';
import 'home.dart';
import '../utils/teclado_tiros_adaptativo.dart';

class RegistroSesionScreen extends StatefulWidget {
  final void Function(Partida nuevaPartida) onGuardar;
  const RegistroSesionScreen({super.key, required this.onGuardar});

  @override
  State<RegistroSesionScreen> createState() => _RegistroSesionScreenState();
}

class _RegistroSesionScreenState extends State<RegistroSesionScreen> {
  final marcadorKey = GlobalKey<MarcadorBolosState>();
  late List<List<String>> framesText;
  String? notas;
  Map<int, Set<int>> erroresPorTiro = {};

  // Estructura visual de pines: [frame][tiro][pines]
  late List<List<List<int>?>> pinesPorTiro;

  // Estado visual
  bool _modoVisual = false;
  int? _frameActivo;
  int? _tiroActivo;
  bool mostrarSelectorpines = false;

  // Notifier para teclas deshabilitadas
  final ValueNotifier<Set<String>> teclasDeshabilitadas = ValueNotifier({});

  @override
  void initState() {
    super.initState();
    framesText = List.generate(10, (_) => List.filled(3, ''));
    erroresPorTiro = _obtenerErroresPorTiro(framesText);
    pinesPorTiro = List.generate(10, (_) => List.filled(3, null));
    // Frame/tiro activo: primero incompleto
    final iFrame = framesText.indexWhere(
      (f) =>
          tipoDeFrame(f, esUltimo: framesText.indexOf(f) == 9) ==
          TipoFrame.incompleto,
    );
    _frameActivo = iFrame >= 0 ? iFrame : 0;
    _tiroActivo = 0;
    _actualizarTeclasDeshabilitadas(frame: _frameActivo, tiro: _tiroActivo);
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
        SnackBar(content: const Text('La partida no tiene puntuación válida.')),
      );
      return;
    }

    final nuevaPartida = Partida(
      fecha: DateTime.now(),
      lugar: '',
      frames: nuevosFrames,
      notas: notas?.trim().isEmpty == true ? null : notas?.trim(),
      total: nuevoTotal,
      pinesPorTiro: pinesPorTiro, // <-- Guardamos aquí el array de pines visual
    );

    widget.onGuardar(nuevaPartida);
    Navigator.pop(context);
  }

  // Cuando tocas un campo en modo visual
  void _onCampoVisualActivo(int frame, int tiro) {
    setState(() {
      _frameActivo = frame;
      _tiroActivo = tiro;
      mostrarSelectorpines = true;
    });
  }

  // Al aceptar los pines seleccionados
  void _onAceptarSeleccionPins(List<int> seleccionados) {
    final frame = _frameActivo!;
    final tiro = _tiroActivo!;
    setState(() {
      // Guarda la selección visual
      pinesPorTiro[frame][tiro] = seleccionados;

      // Traduce a valor de marcador clásico (esto ES LO QUE SE VE EN CADA FRAME)
      final count = seleccionados.length;
      String valor = "";
      if (frame < 9) {
        if (tiro == 0 && count == 10) {
          valor = "X"; // Strike
        } else if (tiro == 1 &&
            ((pinesPorTiro[frame][0]?.length ?? 0) + count == 10)) {
          valor = "/"; // Spare
        } else if (count == 0) {
          valor = "-"; // Fallo
        } else {
          valor = "$count"; // pines caídos
        }
      } else {
        // Frame 10
        valor = (count == 10) ? "X" : (count == 0 ? "-" : "$count");
      }

      // Actualiza el marcador visual
      framesText[frame][tiro] = valor;

      erroresPorTiro = _obtenerErroresPorTiro(framesText);
      mostrarSelectorpines = false;
    });
  }

  void _actualizarTeclasDeshabilitadas({int? frame, int? tiro}) {
    final f = frame ?? _frameActivo ?? 0;
    final t = tiro ?? _tiroActivo ?? 0;
    teclasDeshabilitadas.value = TecladoTiros.calcularTeclasDeshabilitadas(
      frame: f,
      tiro: t,
      frames: framesText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final frames = interpretarFrames(framesText);
    final puntuacionActual = calcularPuntuacionPartida(frames);
    final puntuacionMaxima = calcularPuntuacionMaximaPosible(frames);
    final buenaRacha = esBuenaRacha(frames);

    // Pines ya tirados en tiros previos del frame activo (para deshabilitar)
    List<int> pinesDeshabilitados = [];
    if (_modoVisual &&
        _frameActivo != null &&
        _tiroActivo != null &&
        _tiroActivo! > 0) {
      for (int prev = 0; prev < _tiroActivo!; prev++) {
        pinesDeshabilitados.addAll(pinesPorTiro[_frameActivo!][prev] ?? []);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar partida'),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _modoVisual = !_modoVisual;
                      mostrarSelectorpines = false;
                      _actualizarTeclasDeshabilitadas(
                        frame: _frameActivo,
                        tiro: _tiroActivo,
                      );
                    });
                  },
                  icon: Icon(
                    _modoVisual ? Icons.keyboard : Icons.push_pin_rounded,
                  ),
                  label: Text(
                    _modoVisual
                        ? "Cambiar a teclado clásico"
                        : "Registrar bolos visualmente",
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
                  // Si no es visual, resetea el visual:
                  if (!_modoVisual) pinesPorTiro[frame][tiro] = null;
                  erroresPorTiro = _obtenerErroresPorTiro(framesText);
                });
                if (!_modoVisual) {
                  _frameActivo = frame;
                  _tiroActivo = tiro;
                  _actualizarTeclasDeshabilitadas(frame: frame, tiro: tiro);
                }
              },
              onCampoActivoCambio: _modoVisual
                  ? (frame, tiro) => _onCampoVisualActivo(frame, tiro)
                  : (frame, tiro) {
                      _frameActivo = frame;
                      _tiroActivo = tiro;
                      _actualizarTeclasDeshabilitadas(frame: frame, tiro: tiro);
                    },
              autoFocusEnabled: !_modoVisual,
              autoAdvanceFocus: true,
            ),
            const SizedBox(height: 16),

            // Selector visual o teclado, según el modo
            if (_modoVisual &&
                mostrarSelectorpines &&
                _frameActivo != null &&
                _tiroActivo != null)
              SelectorpinesWidget(
                pinesIniciales: pinesPorTiro[_frameActivo!][_tiroActivo!] ?? [],
                pinesDeshabilitados: pinesDeshabilitados,
                onAceptar: _onAceptarSeleccionPins,
                isFrame10: _frameActivo == 9,
                tiroActual: _tiroActivo!,
              )
            else if (!_modoVisual)
              TecladoTiros(
                onKeyPress: (valor) {
                  if (valor == '⌫') {
                    marcadorKey.currentState?.borrarValor();
                  } else if (valor == '→') {
                    marcadorKey.currentState?.siguiente();
                  } else {
                    marcadorKey.currentState?.insertarValor(valor);
                  }
                  final frame = _frameActivo ?? 0;
                  final tiro = _tiroActivo ?? 0;
                  _actualizarTeclasDeshabilitadas(frame: frame, tiro: tiro);
                },
                deshabilitadosNotifier: teclasDeshabilitadas,
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
              onFocusChange: (focused) {},
            ),
            const SizedBox(height: 40),
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
