import 'package:flutter/material.dart';
import '../models/partida.dart';
import '../utils/registro_tiros_utils.dart';
import '../widgets/marcador_bolos.dart';
import '../screens/prueba_selector_pins.dart';
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

  // NUEVO: modo actual (visual o teclado clásico)
  bool _modoVisual = false;

  // Map frame-tiro -> pinos caídos
  Map<String, List<int>> pinosPorTiro = {};

  @override
  void initState() {
    super.initState();
    framesText = List.generate(10, (_) => List.filled(3, ''));
    erroresPorTiro = _obtenerErroresPorTiro(framesText);
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
      // pinosPorTiro: pinosPorTiro, // <-- agrégalo en tu modelo cuando lo amplíes
    );

    widget.onGuardar(nuevaPartida);
    Navigator.pop(context);
  }

  Future<void> _onSeleccionarPinos(int frame, int tiro) async {
    // Calcular los pinos que quedan en este tiro:
    List<int> yaTirados = [];
    if (tiro > 0) {
      final keyAnterior = '$frame-${tiro - 1}';
      yaTirados = pinosPorTiro[keyAnterior] ?? [];
    }
    final key = '$frame-$tiro';
    final seleccionados = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectorPinosWidget(
          pinosIniciales: pinosPorTiro[key] ?? [],
          // Si quieres, pasa los que ya han sido tirados para deshabilitarlos:
          pinosDeshabilitados: yaTirados,
        ),
      ),
    );
    if (seleccionados != null) {
      setState(() {
        pinosPorTiro[key] = seleccionados;
        // Calcula puntuación (strike/spare/número) y actualiza framesText
        final count = seleccionados.length;
        String valor = "";
        if (frame < 9) {
          if (tiro == 0 && count == 10) {
            valor = "X"; // Strike
          } else if (tiro == 1 &&
              ((pinosPorTiro['$frame-0']?.length ?? 0) + count == 10)) {
            valor = "/"; // Spare
          } else {
            valor = "$count";
          }
        } else {
          // Frame 10: Lógica especial
          valor = (count == 10) ? "X" : "$count";
        }
        framesText[frame][tiro] = valor;
        erroresPorTiro = _obtenerErroresPorTiro(framesText);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final frames = interpretarFrames(framesText);
    final puntuacionActual = calcularPuntuacionPartida(frames);
    final puntuacionMaxima = calcularPuntuacionMaximaPosible(frames);
    final buenaRacha = esBuenaRacha(frames);
    final ValueNotifier<Set<String>> teclasDeshabilitadas = ValueNotifier({});

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
            // Botón para alternar modo visual/clásico
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _modoVisual = !_modoVisual;
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
                  erroresPorTiro = _obtenerErroresPorTiro(framesText);
                  // Si estás en modo visual y el usuario mete un valor a mano,
                  // puedes limpiar la selección de pinos para ese tiro:
                  if (!_modoVisual) {
                    pinosPorTiro.remove('$frame-$tiro');
                  }
                });
              },
              onCampoActivoCambio: _modoVisual
                  ? (frame, tiro) => _onSeleccionarPinos(frame, tiro)
                  : (
                      frame,
                      tiro,
                    ) {}, // En modo clásico, mantén el teclado normal
              autoFocusEnabled: !_modoVisual,
              autoAdvanceFocus: true,
            ),
            const SizedBox(height: 16),
            if (!_modoVisual) // Si es modo clásico, muestra el teclado
              TecladoTiros(
                onKeyPress: (valor) {
                  if (valor == '⌫') {
                    marcadorKey.currentState?.borrarValor();
                  } else if (valor == '→') {
                    marcadorKey.currentState?.siguiente();
                  } else {
                    marcadorKey.currentState?.insertarValor(valor);
                  }
                  // ...añade lógica para teclas deshabilitadas si ya la tienes
                },
                // deshabilitadosNotifier: teclasDeshabilitadas,
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
