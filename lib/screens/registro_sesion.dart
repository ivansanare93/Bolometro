import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/partida.dart';
import '../services/analytics_service.dart';
import '../utils/registro_tiros_utils.dart';
import '../widgets/marcador_bolos.dart';
import '../widgets/teclado_selector_pins.dart'; // Debe aceptar onAceptar
import '../widgets/resumen_puntuacion.dart';
import '../widgets/notas_field.dart';
import 'home.dart';
import '../utils/teclado_tiros_adaptativo.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  List<List<String>> _frames = List.generate(10, (_) => []);

  // Notifier para teclas deshabilitadas
  final ValueNotifier<Set<String>> teclasDeshabilitadas = ValueNotifier({});

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logScreenView('register_game_screen');
      } catch (e) {
        debugPrint('Error logging screen view: $e');
      }
    });
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
          title: Text(AppLocalizations.of(context)!.gameErrors),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errores.map((e) => Text('• ${e.mensaje}')).toList(),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.gameInvalidScore)),
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

    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    await analytics.logGameCreated(nuevoTotal);

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

    int _parseTiro(String tiro, String previo) {
    if (tiro == 'X') return 10;
    if (tiro == '/') return 10 - _parseTiro(previo, '');
    if (tiro == '-') return 0;
    return int.tryParse(tiro) ?? 0;
  }

  void _onAceptarSeleccionPins(List<int> seleccionados) {
    final frame = _frameActivo!;
    final tiro = _tiroActivo!;

    setState(() {
      pinesPorTiro[frame][tiro] = seleccionados;
      String valor = "";

      if (frame < 9) {
        // Frames 1–9
        if (tiro == 0 && seleccionados.length == 10) {
          valor = "X"; // Strike
        } else if (tiro == 1) {
          final prevTiro = pinesPorTiro[frame][0] ?? [];
          final union = <int>{...prevTiro, ...seleccionados};
          if (union.length == 10 && prevTiro.length != 10) {
            valor = "/"; // Spare
          } else if (seleccionados.isEmpty) {
            valor = "-";
          } else {
            valor = "${seleccionados.length}";
          }
        } else {
          valor = seleccionados.isEmpty ? "-" : "${seleccionados.length}";
        }
      } else {
        // Frame 10
        final tiro1 = framesText[9][0];
        final tiro2 = framesText[9][1];

        final primerTiroStrike = tiro1 == "X";
        final sparePrevio =
            tiro1 != "X" &&
            tiro1.isNotEmpty &&
            tiro2.isNotEmpty &&
            (_parseTiro(tiro1, "") + _parseTiro(tiro2, tiro1) == 10);

        if (tiro == 0) {
          valor = seleccionados.length == 10
              ? "X"
              : (seleccionados.isEmpty ? "-" : "${seleccionados.length}");
        } else if (tiro == 1) {
          final prevTiro = pinesPorTiro[frame][0] ?? [];
          final union = <int>{...prevTiro, ...seleccionados};
          if (union.length == 10 && prevTiro.length != 10) {
            valor = "/"; // Spare
          } else if (seleccionados.length == 10) {
            valor = "X"; // Strike en segundo tiro
          } else if (seleccionados.isEmpty) {
            valor = "-";
          } else {
            valor = "${seleccionados.length}";
          }
        } else if (tiro == 2) {
          if (primerTiroStrike || sparePrevio) {
            if (seleccionados.length == 10) {
              valor = "X"; // Strike en tercer tiro
            } else if (seleccionados.isEmpty) {
              valor = "-"; // Fallo
            } else {
              valor = "${seleccionados.length}";
            }
          } else {
            valor = "-"; // No correspondía tercer tiro → fallo por defecto
          }
        }
      }

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
    bool esStrikeEnPrimerTiro = false;

    // Pines ya tirados en tiros previos del frame activo (para deshabilitar)
    List<int> pinesDeshabilitados = [];

    if (_modoVisual && _frameActivo != null && _tiroActivo != null) {
      // --- Lógica especial para frame 10 ---
      if (_frameActivo == 9) {
        final primerTiro = pinesPorTiro[9][0] ?? [];
        final segundoTiro = pinesPorTiro[9][1] ?? [];
        final tiro = _tiroActivo!;

        if (tiro == 0) {
          // Primer tiro: todos disponibles
          pinesDeshabilitados = [];
        } else if (tiro == 1) {
          if (primerTiro.length == 10) {
            // Strike en primer tiro: todos los pines disponibles de nuevo
            pinesDeshabilitados = [];
          } else {
            // Solo puedes volver a tirar los que no tiraste antes
            pinesDeshabilitados = primerTiro;
          }
        } else if (tiro == 2) {
          if (primerTiro.length == 10) {
            // Strike en tiro 1
            if (segundoTiro.length == 10) {
              // Otro strike en tiro 2: todos los pines de nuevo
              pinesDeshabilitados = [];
            } else {
              // Solo los tirados en segundo tiro quedan deshabilitados
              pinesDeshabilitados = segundoTiro;
            }
          } else if (primerTiro.length + segundoTiro.length == 10) {
            // Spare en los dos primeros tiros: todos los pines disponibles
            pinesDeshabilitados = [];
          } else {
            // Caso raro: suma < 10, pero hay tercer tiro (no debería pasar)
            pinesDeshabilitados = [...primerTiro, ...segundoTiro];
          }
        }
      }
      // --- Resto de frames 1-9 ---
      else if (_tiroActivo! > 0) {
        for (int prev = 0; prev < _tiroActivo!; prev++) {
          pinesDeshabilitados.addAll(pinesPorTiro[_frameActivo!][prev] ?? []);
        }
      }
    }

    // --- Detectar strike en primer tiro (para bloquear el segundo en frames 1-9) ---
    if (_modoVisual &&
        _frameActivo != null &&
        _tiroActivo == 1 && // Segundo tiro
        _frameActivo! < 9) {
      // Solo frames 1-9
      final prevTiro = pinesPorTiro[_frameActivo!][0];
      if (prevTiro != null && prevTiro.length == 10) {
        esStrikeEnPrimerTiro = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.registerGame),
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
            // En un futuro activar teclado por pines
            // const SizedBox(height: 8),
            // Row(
            //   children: [
            //     ElevatedButton.icon(
            //       onPressed: () {
            //         setState(() {
            //           _modoVisual = !_modoVisual;
            //           mostrarSelectorpines = false;
            //           _actualizarTeclasDeshabilitadas(
            //             frame: _frameActivo,
            //             tiro: _tiroActivo,
            //           );
            //         });
            //       },
            //       icon: Icon(
            //         _modoVisual ? Icons.keyboard : Icons.push_pin_rounded,
            //       ),
            //       label: Text(
            //         _modoVisual
            //             ? "Cambiar a teclado clásico"
            //             : "Registrar bolos visualmente",
            //       ),
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: _modoVisual
            //             ? Colors.orange
            //             : const Color(0xFF0077B6),
            //         foregroundColor: Colors.white,
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
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

            const SizedBox(height: 8),
            ResumenPuntuacion(
              puntuacionActual: puntuacionActual,
              puntuacionMaxima: puntuacionMaxima,
              buenaRacha: buenaRacha,
            ),

            // Selector visual o teclado, según el modo
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
                      // Tiro 2 del frame 10
                      final tiro1 = pinesPorTiro[9][0] ?? [];
                      if (tiro1.length == 10) {
                        // Strike: todos en pie
                        pinesIniciales = [];
                      } else {
                        // No strike: pines caídos en el 1
                        pinesIniciales = tiro1;
                      }
                    } else if (_tiroActivo == 2) {
                      final tiro1 = pinesPorTiro[9][0] ?? [];
                      final tiro2 = pinesPorTiro[9][1] ?? [];
                      final huboStrike1 = tiro1.length == 10;
                      final huboSpare =
                          !huboStrike1 && (tiro1.length + tiro2.length == 10);

                      if (huboStrike1 || huboSpare) {
                        // Reinicio completo de pinos disponibles
                        pinesIniciales = [];
                        pinesDeshabilitados = [];
                      } else {
                        // Caso raro: no strike ni spare pero llegó un tiro 3 → bloquear
                        pinesIniciales = [...tiro1, ...tiro2];
                        pinesDeshabilitados = [...tiro1, ...tiro2];
                      }
                    }
                  }

                  return SelectorpinesWidget(
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
          label: Text(AppLocalizations.of(context)!.saveGame),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
    );
  }
}
