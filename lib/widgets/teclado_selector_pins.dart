import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_constants.dart';
import '../l10n/app_localizations.dart';

class SelectorpinesWidget extends StatefulWidget {
  final List<int> pinesIniciales;
  final List<int> pinesDeshabilitados;
  final void Function(List<int>) onAceptar;
  final bool isFrame10;
  final int tiroActual; // 0 = primer tiro, 1 = segundo tiro, 2 = tercero
  final List<List<String>> frames; // lista completa de frames

  const SelectorpinesWidget({
    super.key,
    required this.pinesIniciales,
    required this.pinesDeshabilitados,
    required this.onAceptar,
    required this.isFrame10,
    required this.tiroActual,
    required this.frames,
  });

  @override
  State<SelectorpinesWidget> createState() => _SelectorpinesWidgetState();
}

class _SelectorpinesWidgetState extends State<SelectorpinesWidget>
    with SingleTickerProviderStateMixin {
  late List<bool> _pinesCaidos;
  late List<double> _scaleList;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  Color? _falloOverlayColor;

  @override
  void initState() {
    super.initState();
    _pinesCaidos = List.generate(
      AppConstants.maxPinesBowling,
      (i) => widget.pinesIniciales.contains(i + 1),
    );
    _scaleList = List.filled(AppConstants.maxPinesBowling, 1.0);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 14,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _togglePino(int index) {
    if (widget.pinesDeshabilitados.contains(index + 1)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pinesCaidos[index] = !_pinesCaidos[index];
      _scaleList[index] = 1.18;
    });
    Future.delayed(const Duration(milliseconds: 110), () {
      if (mounted) {
        setState(() {
          _scaleList[index] = 1.0;
        });
      }
    });
  }

  /// Returns the list of pin numbers available in the current shot
  /// (i.e., pins not already knocked down / not disabled).
  List<int> _pinesDisponibles() {
    return List.generate(AppConstants.maxPinesBowling, (i) => i + 1)
        .where((p) => !widget.pinesDeshabilitados.contains(p))
        .toList();
  }

  void _marcarPleno() {
    HapticFeedback.heavyImpact();
    final todosLosPines = _pinesDisponibles();
    setState(() {
      _pinesCaidos = List.generate(
        AppConstants.maxPinesBowling,
        (i) => !widget.pinesDeshabilitados.contains(i + 1),
      );
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) widget.onAceptar(todosLosPines);
    });
  }

  void _marcarRemate() {
    HapticFeedback.heavyImpact();
    final pinesRemate = _pinesDisponibles();
    setState(() {
      for (int i = 0; i < 10; i++) {
        if (!widget.pinesDeshabilitados.contains(i + 1)) {
          _pinesCaidos[i] = true;
        }
      }
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) widget.onAceptar(pinesRemate);
    });
  }

  void _marcarFallo() {
    HapticFeedback.heavyImpact();
    setState(() {
      _pinesCaidos = List.generate(10, (_) => false);
      _falloOverlayColor = Colors.red.withOpacity(0.15);
    });
    _shakeController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) {
        setState(() => _falloOverlayColor = null);
        widget.onAceptar([]);
      }
    });
  }

  int _parseTiro(String tiro, String previo) {
    if (tiro == AppConstants.simboloStrike) return AppConstants.maxPinesBowling;
    if (tiro == AppConstants.simboloSpare) return AppConstants.maxPinesBowling - _parseTiro(previo, '');
    if (tiro == AppConstants.simboloFallo) return 0;
    return int.tryParse(tiro) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final azul = cs.primary;
    final l10n = AppLocalizations.of(context)!;

    final fondoCard = isDark ? const Color(0xFF23272A) : cs.background;
    final fondoPinNoSel = isDark ? const Color(0xFF30353A) : cs.surfaceVariant;
    final pinBordeNoSel = isDark ? const Color(0xFF50555A) : cs.outlineVariant;

    final filas = [
      [7, 8, 9, AppConstants.maxPinesBowling],
      [4, 5, 6],
      [2, 3],
      [1],
    ];

    final int tiroActual = widget.tiroActual;
    final bool esPrimerTiro = tiroActual == 0;
    final bool esSegundoTiro = tiroActual == 1;
    final bool esTercerTiro = tiroActual == 2;
    final bool todosCaidos = _pinesCaidos.every((v) => v);
    final bool ningunoCaido = _pinesCaidos.every((v) => !v);

    final seleccionados = List.generate(
      AppConstants.maxPinesBowling,
      (i) => _pinesCaidos[i] ? i + 1 : null,
    ).whereType<int>().toList();

    // ---- LÓGICA BOTONES ----
    bool mostrarPleno = false;
    bool mostrarRemate = false;
    bool mostrarFallo = false;

    if (widget.isFrame10) {
      final frame10 = widget.frames[AppConstants.totalFrames - 1];
      final tiro1 = frame10.isNotEmpty ? frame10[0] : '';
      final tiro2 = frame10.length > 1 ? frame10[1] : '';

      if (esPrimerTiro) {
        // Primer tiro → strike posible o fallo
        mostrarPleno = !todosCaidos;
        mostrarRemate = false;
        mostrarFallo = true;
      } else if (esSegundoTiro) {
        final primerTiroStrike = tiro1 == AppConstants.simboloStrike;
        if (primerTiroStrike) {
          // Después de strike → tablero reseteado
          mostrarPleno = !todosCaidos;
          mostrarRemate = false;
          mostrarFallo = true;
        } else {
          final pinosTiro1 = _parseTiro(tiro1, '');
          final quedanPinos = AppConstants.maxPinesBowling - pinosTiro1;
          if (quedanPinos > 0) {
            mostrarPleno = false;
            mostrarRemate = !todosCaidos;
            mostrarFallo = true;
          } else {
            mostrarPleno = false;
            mostrarRemate = false;
            mostrarFallo = true; // aún puede fallar (ej. cero pinos)
          }
        }
      } else if (esTercerTiro) {
        final primerTiroStrike = tiro1 == AppConstants.simboloStrike;
        final pinosTiro1 = tiro1.isNotEmpty ? _parseTiro(tiro1, '') : 0;
        final pinosTiro2 = tiro2.isNotEmpty ? _parseTiro(tiro2, tiro1) : 0;
        final spareEnPrimerosDos =
            !primerTiroStrike && (pinosTiro1 + pinosTiro2 == 10);

        final habilitarTercerTiro = primerTiroStrike || spareEnPrimerosDos;

        if (habilitarTercerTiro) {
          mostrarPleno = !todosCaidos;
          mostrarRemate = false;
          mostrarFallo = true;

          // Resetear pinos una sola vez, sin bucles de build
          if (_pinesCaidos.every((v) => !v)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _pinesCaidos = List.generate(10, (_) => false);
                });
              }
            });
          }
        } else {
          // No corresponde tercer tiro → bloquear explícitamente
          mostrarPleno = false;
          mostrarRemate = false;
          mostrarFallo = false;
        }
      }
    } else {
      // Frames 1-9
      mostrarPleno = esPrimerTiro && !todosCaidos;
      mostrarRemate = esSegundoTiro && !todosCaidos;
      mostrarFallo = true;
    }

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        double offset =
            _shakeAnimation.value *
            (_shakeController.status == AnimationStatus.forward ? 1 : -1);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: Stack(
            children: [
              child!,
              if (_falloOverlayColor != null)
                Positioned.fill(child: Container(color: _falloOverlayColor)),
            ],
          ),
        );
      },
      child: Card(
        elevation: 7,
        color: fondoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona los pines que has tirado',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (mostrarPleno)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.bolt, size: 18),
                        label: Text(l10n.strike),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _marcarPleno,
                      ),
                    ),
                  if (mostrarRemate)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.auto_fix_high, size: 18),
                        label: Text(l10n.spare),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azul,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _marcarRemate,
                      ),
                    ),
                  if (mostrarFallo)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.close, size: 18),
                        label: Text(l10n.miss),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[500],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _marcarFallo,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ...filas.map(
                (fila) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: fila.map((pino) {
                    final idx = pino - 1;
                    final deshabilitado = widget.pinesDeshabilitados.contains(
                      pino,
                    );
                    final seleccionado = _pinesCaidos[idx];

                    final pinEstaDeshabilitado = deshabilitado;

                    final pinFondo = pinEstaDeshabilitado
                        ? fondoPinNoSel.withOpacity(0.28)
                        : seleccionado
                        ? azul
                        : fondoPinNoSel;
                    final pinBorde = pinEstaDeshabilitado
                        ? fondoPinNoSel.withOpacity(0.45)
                        : seleccionado
                        ? azul
                        : pinBordeNoSel;
                    final pinTexto = pinEstaDeshabilitado
                        ? cs.onSurface.withOpacity(0.30)
                        : seleccionado
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      child: AnimatedScale(
                        scale: _scaleList[idx],
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeInOutCubic,
                        child: GestureDetector(
                          onTap: pinEstaDeshabilitado
                              ? null
                              : () => _togglePino(idx),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: pinFondo,
                              border: Border.all(color: pinBorde, width: 2.5),
                              borderRadius: BorderRadius.circular(19),
                            ),
                            child: Center(
                              child: Text(
                                pino.toString(),
                                style: TextStyle(
                                  color: pinTexto,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.restart_alt_rounded),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.surfaceVariant,
                        foregroundColor: azul,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: () {
                        setState(() {
                          _pinesCaidos = List.generate(10, (_) => false);
                          _scaleList = List.filled(10, 1.0);
                        });
                      },
                      label: Text(l10n.clear),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: () => widget.onAceptar(seleccionados),
                      label: Text(l10n.accept),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
