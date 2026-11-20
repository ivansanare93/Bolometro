import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/partida.dart';
import '../providers/keyboard_provider.dart';
import '../services/analytics_service.dart';
import '../services/draft_service.dart';
import '../utils/app_constants.dart';
import '../utils/pines_a_tiro_utils.dart';
import '../utils/registro_tiros_utils.dart';
import '../widgets/marcador_bolos.dart';
import '../widgets/teclado_selector_pins.dart';
import '../widgets/keyboard_mode_selector.dart';
import '../widgets/game_entry_viewport.dart';
import '../widgets/resumen_puntuacion.dart';
import '../widgets/notas_field.dart';
import '../widgets/score_sheet_pin_strip.dart';
import '../widgets/game_ball_assignments.dart';
import '../repositories/data_repository.dart';
import 'home.dart';
import 'score_photo_screen.dart';
import '../services/score_photo_review.dart';
import '../utils/teclado_tiros_adaptativo.dart';
import '../l10n/app_localizations.dart';

class RegistroSesionScreen extends StatefulWidget {
  final void Function(Partida nuevaPartida) onGuardar;
  const RegistroSesionScreen({super.key, required this.onGuardar});

  @override
  State<RegistroSesionScreen> createState() => _RegistroSesionScreenState();
}

class _RegistroSesionScreenState extends State<RegistroSesionScreen>
    with WidgetsBindingObserver {
  final marcadorKey = GlobalKey<MarcadorBolosState>();
  late List<List<String>> framesText;
  String? notas;
  String? _ballId;
  Map<String, String?> _ballAssignments = {};
  String? _draftUid;
  Map<int, Set<int>> erroresPorTiro = {};

  // Estructura visual de pines: [frame][tiro][pines]
  late List<List<List<int>?>> pinesPorTiro;

  // Estado visual
  bool _modoVisual = false;
  int? _frameActivo;
  int? _tiroActivo;
  bool mostrarSelectorpines = false;

  // Scroll controller for the body
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _pinSelectorKey = GlobalKey();
  int _focusRequest = 0;

  // Notifier para teclas deshabilitadas
  final ValueNotifier<Set<String>> teclasDeshabilitadas = ValueNotifier({});

  @override
  void initState() {
    super.initState();
    _draftUid = context.read<DataRepository?>()?.arsenalUserId;
    WidgetsBinding.instance.addObserver(this);
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreDraftIfAvailable();
      final keyboardProvider = Provider.of<KeyboardProvider>(
        context,
        listen: false,
      );
      keyboardProvider.initializationFuture.then((_) {
        if (mounted) {
          setState(() {
            _modoVisual = keyboardProvider.modoVisual;
            mostrarSelectorpines = _modoVisual;
          });
          if (_modoVisual) _enfocarSelectorPines();
          _actualizarTeclasDeshabilitadas(
            frame: _frameActivo,
            tiro: _tiroActivo,
          );
        }
      });
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logScreenView('register_game_screen');
      } catch (e) {
        debugPrint('Error logging screen view: $e');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveDraft();
    }
  }

  void _saveDraft() {
    DraftService.savePartidaDraft(
      framesText: framesText,
      ownerUid: _draftUid,
      ballId: _ballId,
      ballIdsByThrow: _ballAssignments,
      notas: notas,
      pinesPorTiro: pinesPorTiro,
    );
  }

  Future<void> _restoreDraftIfAvailable() async {
    final draft = await DraftService.loadPartidaDraft(ownerUid: _draftUid);
    if (draft == null) return;

    // Restore framesText
    final framesRaw = draft['framesText'] as List<dynamic>?;
    if (framesRaw == null || framesRaw.isEmpty) return;

    final restoredFrames = framesRaw
        .map((f) => f.toString().split(','))
        .toList();
    // Ensure each frame has 3 slots
    final normalizedFrames = restoredFrames.map((frame) {
      while (frame.length < 3) frame.add('');
      return frame.take(3).toList();
    }).toList();
    while (normalizedFrames.length < 10) {
      normalizedFrames.add(['', '', '']);
    }

    // Check if the draft has any meaningful data
    final hasData =
        normalizedFrames.any((f) => f.any((t) => t.isNotEmpty)) ||
        draft['ballId'] != null ||
        (draft['ballIdsByThrow'] as Map? ?? {}).isNotEmpty;
    if (!hasData) return;

    // Restore pinesPorTiro
    final pinesRaw = draft['pinesPorTiro'] as List<dynamic>?;
    List<List<List<int>?>> restoredPines = List.generate(
      10,
      (_) => List.filled(3, null),
    );
    if (pinesRaw != null) {
      for (int i = 0; i < pinesRaw.length && i < 10; i++) {
        final tiros = pinesRaw[i].toString().split(';');
        for (int j = 0; j < tiros.length && j < 3; j++) {
          if (tiros[j] == 'null' || tiros[j].isEmpty) {
            restoredPines[i][j] = null;
          } else {
            restoredPines[i][j] = tiros[j]
                .split(',')
                .map((p) => int.tryParse(p) ?? 0)
                .toList();
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        framesText = normalizedFrames;
        notas = draft['notas'] as String?;
        _ballId = draft['ballId'] as String?;
        _ballAssignments = Partida.parseBallAssignments(
          draft['ballIdsByThrow'],
        );
        pinesPorTiro = restoredPines;
        erroresPorTiro = _obtenerErroresPorTiro(framesText);
        final iFrame = framesText.indexWhere(
          (f) =>
              tipoDeFrame(f, esUltimo: framesText.indexOf(f) == 9) ==
              TipoFrame.incompleto,
        );
        _frameActivo = iFrame >= 0 ? iFrame : 0;
        _tiroActivo = 0;
        _actualizarTeclasDeshabilitadas(frame: _frameActivo, tiro: _tiroActivo);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.draftRestoredGame),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  bool _tieneDataSinGuardar() {
    final algunFrameConDatos = framesText.any(
      (frame) => frame.any((tiro) => tiro.isNotEmpty),
    );
    final notasConDatos = notas != null && notas!.trim().isNotEmpty;
    return algunFrameConDatos ||
        notasConDatos ||
        _ballId != null ||
        _ballAssignments.isNotEmpty;
  }

  Future<bool> _confirmarSalirSinGuardar() async {
    if (!_tieneDataSinGuardar()) return true;
    final l10n = AppLocalizations.of(context)!;
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.discardChanges),
        content: Text(l10n.discardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    return resultado == true;
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

  Future<void> _importarFoto() async {
    final accountToken = context.read<DataRepository?>()?.seasonAccountToken;
    final score = await Navigator.push<ReviewedPhotoScore>(
      context,
      MaterialPageRoute(builder: (_) => const ScorePhotoScreen()),
    );
    if (!mounted ||
        score == null ||
        _draftUid != context.read<DataRepository?>()?.arsenalUserId ||
        accountToken != context.read<DataRepository?>()?.seasonAccountToken)
      return;
    if (framesText.any((f) => f.any((t) => t.trim().isNotEmpty)) ||
        pinesPorTiro.any((f) => f.any((t) => t != null))) {
      final l = AppLocalizations.of(context)!;
      final replace = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(l.photoScoreReplaceTitle),
          content: Text(l.photoScoreReplaceBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l.photoScoreCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(l.photoScoreReplace),
            ),
          ],
        ),
      );
      if (!mounted ||
          replace != true ||
          _draftUid != context.read<DataRepository?>()?.arsenalUserId ||
          accountToken != context.read<DataRepository?>()?.seasonAccountToken)
        return;
    }
    setState(() {
      framesText = score.frames
          .map(
            (f) => List.generate(
              3,
              (t) => t >= f.length
                  ? ''
                  : f[t] == '0'
                  ? '-'
                  : f[t],
            ),
          )
          .toList();
      // OCR scores do not identify the individual fallen pins.
      pinesPorTiro = List.generate(10, (_) => List.filled(3, null));
      erroresPorTiro = _obtenerErroresPorTiro(framesText);
      _frameActivo = 0;
      _tiroActivo = 0;
    });
    _actualizarTeclasDeshabilitadas(frame: 0, tiro: 0);
    _saveDraft();
  }

  Future<void> _guardar() async {
    if (_draftUid != context.read<DataRepository?>()?.arsenalUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.ballAccountChanged),
        ),
      );
      return;
    }
    final nuevosFrames = interpretarFrames(framesText);
    final errores = validarPartida(framesText);
    // A complete gutter game is legitimate. The legacy validator treats an
    // all-miss game as empty; only waive that error after strict validation.
    final completeZero =
        ScorePhotoCandidate(frames: framesText, printedTotal: '0')
            .validate(
              reviewedFrames: Set.of(List.generate(10, (i) => i)),
              totalReviewed: true,
            )
            .canApply;
    if (completeZero) errores.clear();

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
    if (nuevoTotal == 0 && !completeZero) {
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
      ballId: _ballId,
      ballIdsByThrow: _ballAssignments,
    );

    try {
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await analytics.logGameCreated(nuevoTotal);
      if (nuevaPartida.usedBallIds.isNotEmpty) {
        await analytics.logBallAssignedToGame();
      }
    } catch (e) {
      debugPrint('Error logging game creation: $e');
    }

    widget.onGuardar(nuevaPartida);
    await DraftService.clearPartidaDraft(ownerUid: _draftUid);
    Navigator.pop(context);
  }

  // Cuando tocas un campo en modo visual
  void _onCampoVisualActivo(int frame, int tiro) {
    setState(() {
      _frameActivo = frame;
      _tiroActivo = tiro;
      mostrarSelectorpines = true;
    });
    _enfocarSelectorPines();
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

    // Build updated frames to determine if a third shot is needed
    final updatedFrames = List<List<String>>.generate(
      10,
      (i) => List<String>.from(framesText[i]),
    );
    updatedFrames[frame][tiro] = valor;

    // Compute next frame/tiro (mirrors MarcadorBolos.insertarValor logic)
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
      // Frame 10
      if (tiro < 2) {
        if (tiro == 1 && !mostrarTercerTiro(updatedFrames)) {
          // No third shot needed — stay on current cell (done)
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
      // When advanced, _frameActivo/_tiroActivo and mostrarSelectorpines are
      // updated by _onCampoVisualActivo via setTiroActivo below.
    });

    if (advanced) {
      // setTiroActivo triggers _onCampoVisualActivo → updates _frameActivo,
      // _tiroActivo, and mostrarSelectorpines = true.
      marcadorKey.currentState?.setTiroActivo(nextFrame, nextTiro);
    }

    _saveDraft();
  }

  void _enfocarSelectorPines() {
    final request = ++_focusRequest;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_modoVisual || request != _focusRequest) return;
      final target = _pinSelectorKey.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
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
    if (context.watch<DataRepository?>()?.arsenalUserId != _draftUid) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppLocalizations.of(context)!.ballAccountChanged,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final frames = interpretarFrames(framesText);
    final puntuacionActual = calcularPuntuacionPartida(frames);
    final puntuacionMaxima = calcularPuntuacionMaximaPosible(frames);
    final buenaRacha = esBuenaRacha(frames);
    bool esStrikeEnPrimerTiro = false;

    // Pines ya tirados en tiros previos del frame activo (para deshabilitar).
    // calcularPinesDeshabilitados handles all cases: frames 1-9 as well as all
    // frame-10 scenarios (strike, spare, third tiro, and the degenerate case
    // where tiro 2 is shown without a valid strike/spare – pins from both prior
    // shots are disabled so no new selection is possible).
    List<int> pinesDeshabilitados = [];

    if (_modoVisual && _frameActivo != null && _tiroActivo != null) {
      pinesDeshabilitados = calcularPinesDeshabilitados(
        frame: _frameActivo!,
        tiro: _tiroActivo!,
        pinesPorTiroFrame: pinesPorTiro[_frameActivo!],
      );
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          if (_draftUid != context.read<DataRepository?>()?.arsenalUserId) {
            _saveDraft();
          } else {
            DraftService.clearPartidaDraft(ownerUid: _draftUid);
          }
          return;
        }
        Future.microtask(() async {
          final debesSalir = await _confirmarSalirSinGuardar();
          if (debesSalir && mounted) {
            await DraftService.clearPartidaDraft(ownerUid: _draftUid);
            if (mounted) Navigator.pop(context);
          }
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.registerGame),
          centerTitle: true,
          actions: [
            IconButton(
              key: const ValueKey('import-score-photo'),
              icon: const Icon(Icons.document_scanner_outlined),
              tooltip: AppLocalizations.of(context)!.photoScoreTitle,
              onPressed: _importarFoto,
            ),
            IconButton(
              icon: const Icon(Icons.home),
              tooltip: AppLocalizations.of(context)!.home,
              onPressed: () async {
                final debesSalir = await _confirmarSalirSinGuardar();
                if (!debesSalir || !mounted) return;
                DraftService.clearPartidaDraft(ownerUid: _draftUid);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: GameEntryViewport(
          pinMode: _modoVisual,
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          header: [
            // Mode toggle
            KeyboardModeSelector(
              modoVisual: _modoVisual,
              onChanged: (newModoVisual) {
                setState(() {
                  _modoVisual = newModoVisual;
                  mostrarSelectorpines = newModoVisual;
                  _actualizarTeclasDeshabilitadas(
                    frame: _frameActivo,
                    tiro: _tiroActivo,
                  );
                });
                Provider.of<KeyboardProvider>(
                  context,
                  listen: false,
                ).setModoVisual(newModoVisual);
                if (newModoVisual) _enfocarSelectorPines();
              },
            ),
            const SizedBox(height: 12),
            // Scoresheet
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
                  if (!_modoVisual || valor.isEmpty) {
                    pinesPorTiro[frame][tiro] = null;
                  }
                  erroresPorTiro = _obtenerErroresPorTiro(framesText);
                });
                if (!_modoVisual) {
                  _frameActivo = frame;
                  _tiroActivo = tiro;
                  _actualizarTeclasDeshabilitadas(frame: frame, tiro: tiro);
                }
                _saveDraft();
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
          ],
          children: [
            // Pin strip: shown in visual mode once at least one throw has pin data
            if (_modoVisual &&
                pinesPorTiro.any((f) => f.any((t) => t != null))) ...[
              const SizedBox(height: 6),
              ScoreSheetPinStrip(
                pinesPorTiro: pinesPorTiro,
                frameActivo: _frameActivo,
              ),
            ],

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
                      // Always start with an empty selection; the pins
                      // knocked in tiro 1 are shown as disabled (greyed out)
                      // via pinesDeshabilitados, which already provides the
                      // visual feedback. Pre-selecting them caused those pin
                      // numbers to be included in 'seleccionados', making
                      // the recorded count for tiro 2 incorrectly high.
                      pinesIniciales = [];
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

                  return KeyedSubtree(
                    key: _pinSelectorKey,
                    child: SelectorpinesWidget(
                      key: ValueKey((_frameActivo!, _tiroActivo!)),
                      pinesIniciales: pinesIniciales,
                      pinesDeshabilitados: pinesDeshabilitados,
                      onAceptar: _onAceptarSeleccionPins,
                      onBorrar: () => marcadorKey.currentState?.borrarValor(),
                      isFrame10: _frameActivo == 9,
                      tiroActual: _tiroActivo!,
                      frames: framesText,
                      frameActual: _frameActivo!,
                    ),
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
            GameBallAssignments(
              ballId: _ballId,
              assignments: _ballAssignments,
              activeFrame: () => _frameActivo ?? 0,
              onChanged: (id, assignments) {
                if (_draftUid != context.read<DataRepository?>()?.arsenalUserId)
                  return;
                setState(() {
                  _ballId = id;
                  _ballAssignments = Map.of(assignments);
                });
                _saveDraft();
              },
            ),
            const SizedBox(height: 16),
            if (!_modoVisual)
              NotasField(
                initialValue: notas,
                onChanged: (v) {
                  notas = v;
                  _saveDraft();
                },
                onFocusChange: (focused) {},
              ),
            const SizedBox(height: 40),
          ],
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
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          child: ElevatedButton.icon(
            onPressed: _guardar,
            icon: const Icon(Icons.save),
            label: Text(AppLocalizations.of(context)!.saveGame),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
    );
  }
}
