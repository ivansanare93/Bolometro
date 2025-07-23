import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SelectorpinesWidget extends StatefulWidget {
  final List<int> pinesIniciales;
  final List<int> pinesDeshabilitados;
  final void Function(List<int>) onAceptar;
  final bool isFrame10;
  final int tiroActual; // 0 = primer tiro, 1 = segundo tiro

  const SelectorpinesWidget({
    super.key,
    required this.pinesIniciales,
    required this.pinesDeshabilitados,
    required this.onAceptar,
    required this.isFrame10,
    required this.tiroActual,
  });

  @override
  State<SelectorpinesWidget> createState() => _SelectorpinesWidgetState();
}

class _SelectorpinesWidgetState extends State<SelectorpinesWidget> {
  late List<bool> _pinesCaidos;
  late List<double> _scaleList;

  @override
  void initState() {
    super.initState();
    _pinesCaidos = List.generate(
      10,
      (i) => widget.pinesIniciales.contains(i + 1),
    );
    _scaleList = List.filled(10, 1.0);
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

  void _marcarPleno() {
    setState(() {
      _pinesCaidos = List.generate(10, (_) => true);
    });
  }

  void _marcarRemate() {
    setState(() {
      for (int i = 0; i < 10; i++) {
        if (!widget.pinesDeshabilitados.contains(i + 1)) {
          _pinesCaidos[i] = true;
        }
      }
    });
  }

  void _marcarFallo() {
    setState(() {
      _pinesCaidos = List.generate(10, (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final azul = cs.primary;

    final fondoCard = isDark ? const Color(0xFF23272A) : cs.background;
    final fondoPinNoSel = isDark ? const Color(0xFF30353A) : cs.surfaceVariant;
    final pinBordeNoSel = isDark ? const Color(0xFF50555A) : cs.outlineVariant;

    final filas = [
      [7, 8, 9, 10],
      [4, 5, 6],
      [2, 3],
      [1],
    ];

    final int tiroActual = widget.tiroActual;
    final bool esPrimerTiro = tiroActual == 0;
    final bool esSegundoTiro = tiroActual == 1;
    final bool todosCaidos = _pinesCaidos.every((v) => v);
    final bool ningunoCaido = _pinesCaidos.every((v) => !v);
    final bool strikeEnPrimerTiro =
        esSegundoTiro &&
        widget.pinesIniciales.length == 10 &&
        !widget.isFrame10;

    final seleccionados = List.generate(
      10,
      (i) => _pinesCaidos[i] ? i + 1 : null,
    ).whereType<int>().toList();

    // Mostrar Pleno solo en primer tiro y si hay pinos en pie
    final bool mostrarPleno = esPrimerTiro && !todosCaidos;

    // Mostrar Remate solo en segundo tiro, si no hubo pleno, si quedan pinos en pie y no están todos ya seleccionados
    final bool mostrarRemate =
        esSegundoTiro &&
        !strikeEnPrimerTiro &&
        !todosCaidos &&
        widget.pinesIniciales.length < 10;

    // Fallo: Solo si hay pinos en pie (para ambos tiros)
    final bool mostrarFallo = ningunoCaido;

    // Deshabilitar todo si hubo pleno en el primer tiro (segundo tiro debe estar bloqueado)
    final bool bloquearTodo = strikeEnPrimerTiro;

    return Card(
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
            if (!bloquearTodo)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (mostrarPleno)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.bolt, size: 18),
                        label: const Text('Pleno'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _marcarPleno,
                      ),
                    ),
                  if (mostrarRemate)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.auto_fix_high, size: 18),
                        label: const Text('Remate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azul,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _marcarRemate,
                      ),
                    ),
                  if (!mostrarPleno && !mostrarRemate && mostrarFallo)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Fallo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[500],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _marcarFallo,
                      ),
                    ),
                ],
              ),
            if (!bloquearTodo) const SizedBox(height: 8),
            ...filas.map(
              (fila) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: fila.map((pino) {
                  final idx = pino - 1;
                  final deshabilitado = widget.pinesDeshabilitados.contains(
                    pino,
                  );
                  final seleccionado = _pinesCaidos[idx];

                  final pinEstaDeshabilitado = deshabilitado || bloquearTodo;

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
                            boxShadow: [
                              if (seleccionado && !pinEstaDeshabilitado)
                                BoxShadow(
                                  color: azul.withOpacity(0.19),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                            ],
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
                    onPressed: bloquearTodo
                        ? null
                        : () {
                            setState(() {
                              _pinesCaidos = List.generate(10, (_) => false);
                              _scaleList = List.filled(10, 1.0);
                            });
                          },
                    label: const Text('Limpiar'),
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
                    label: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
