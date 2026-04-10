import 'package:flutter/material.dart';

class TecladoTiros extends StatelessWidget {
  final void Function(String valor) onKeyPress;
  final ValueNotifier<Set<String>> deshabilitadosNotifier;

  const TecladoTiros({
    super.key,
    required this.onKeyPress,
    required this.deshabilitadosNotifier,
  });

  static Set<String> calcularTeclasDeshabilitadas({
    required int frame,
    required int tiro,
    required List<List<String>> frames,
  }) {
    final deshabilitadas = <String>{};
    final esUltimo = frame == 9;
    final t1 = frames[frame][0];
    final t2 = frames[frame][1];
    final numeros = List.generate(10, (i) => '$i');

    if (esUltimo) {
      // Frame 10
      if (tiro == 0) {
        deshabilitadas.add('/'); // nunca puede ser spare en primer tiro
      } else if (tiro == 1) {
        deshabilitadas.add('X'); // por defecto
        if (t1 == 'X') {
          // Strike en el primero → todo permitido menos '/'
          deshabilitadas.clear();
          deshabilitadas.add('/');
        } else if (t1.isNotEmpty && t1 != '-') {
          final primerValor = int.tryParse(t1);
          if (primerValor != null) {
            for (var n in numeros) {
              final segundoValor = int.parse(n);
              if (primerValor + segundoValor >= 10) {
                // > 10 es imposible; == 10 debe registrarse como '/' (spare)
                deshabilitadas.add(n);
              }
            }
          }
        }
      } else if (tiro == 2) {
        // --- Tercer tiro del frame 10 ---
        if (!(t1 == 'X' || t2 == '/' || t2 == 'X')) {
          // No hay derecho a tercer tiro
          deshabilitadas.addAll(numeros + ['X', '/']);
        } else {
          // Hay tercer tiro, analizar los tiros previos
          if (t2 == '/') {
            // Spare en segundo tiro: tercer tiro NO puede ser '/'
            deshabilitadas.add('/');
            // Permite 0-9 y X
          } else if (t1 == 'X' && t2 == 'X') {
            deshabilitadas.add('/');
          } else if (t1 == 'X' &&
              t2 != 'X' &&
              t2 != null &&
              t2.isNotEmpty &&
              t2 != '-') {
            // Strike y luego número: el tercer tiro se limita a los pines restantes
            final segundoValor = int.tryParse(t2) ?? 0;
            for (var n in numeros) {
              final val = int.parse(n);
              // Deshabilitar números que igualen o superen los pines restantes (eso sería spare o exceso)
              if (segundoValor + val >= 10) deshabilitadas.add(n);
            }
            // Strike no es posible si quedan menos de 10 pines
            if (segundoValor > 0) deshabilitadas.add('X');
            // '/' siempre disponible cuando quedan pines (segundoValor < 10)
          } else if (t1 == 'X' && (t2 == '-' || t2 == '')) {
            // Strike y fallo/ninguno: todo permitido
          } else if (t1 != 'X' && t2 == 'X') {
            // Segundo tiro es strike: todo permitido
          } else {
            // Por seguridad: nunca permitir '/' en el tercer tiro si no es spare
            deshabilitadas.add('/');
          }
        }
      }
    } else {
      // Frames 1–9
      if (tiro == 0) {
        deshabilitadas.add('/'); // nunca puede ser spare
      } else if (tiro == 1) {
        deshabilitadas.add('X'); // nunca puede ser strike en segundo tiro
        if (t1 == 'X') {
          // Strike en el primer tiro: bloquea TODO en tiro 2
          deshabilitadas.addAll(numeros);
          deshabilitadas.add('/');
          deshabilitadas.add('X');
          deshabilitadas.add('-');
        } else if (t1.isNotEmpty && t1 != '-') {
          final primerValor = int.tryParse(t1);
          if (primerValor != null) {
            for (var n in numeros) {
              final segundoValor = int.parse(n);
              if (primerValor + segundoValor > 10) {
                deshabilitadas.add(n);
              } else if (primerValor + segundoValor == 10) {
                // Si es justo 10, solo permitir '/'
                deshabilitadas.add(n); // ¡importante!
              }
            }
            // Habilita solo '/' si suma 10 exacto
            if (primerValor < 10) {
              // '/' solo es válido si suma 10
            } else {
              deshabilitadas.add('/');
            }
          }
        }
      }
    }
    return deshabilitadas;
  }

  @override
  Widget build(BuildContext context) {
    final botones = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['-', '/', 'X'],
      ['⌫', '→', ''],
    ];

    // Colores adaptativos
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final fondoTeclado = cs.surface;
    final colorPrincipal = cs.primary;
    final colorSplash = cs.secondary.withOpacity(0.22);
    final colorInactivo = cs.onSurface.withOpacity(0.14);
    final colorTextoActivo = cs.onPrimary;
    final colorTextoInactivo = cs.onSurface.withOpacity(0.6);

    return ValueListenableBuilder<Set<String>>(
      valueListenable: deshabilitadosNotifier,
      builder: (context, deshabilitados, _) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: fondoTeclado,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              if (theme.brightness == Brightness.light)
                BoxShadow(
                  color: colorPrincipal.withOpacity(0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: botones.map((fila) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: fila.map((valor) {
                    if (valor.isEmpty)
                      return const SizedBox(width: 60, height: 60);
                    final deshabilitado = deshabilitados.contains(valor);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.5),
                      child: TeclaAnimada(
                        deshabilitado: deshabilitado,
                        onTap: deshabilitado ? null : () => onKeyPress(valor),
                        colorFondo: deshabilitado
                            ? colorInactivo
                            : colorPrincipal,
                        colorSplash: colorSplash,
                        child: _buildKeyContent(
                          valor,
                          deshabilitado,
                          colorTextoActivo,
                          colorTextoInactivo,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildKeyContent(
    String valor,
    bool deshabilitado,
    Color colorActivo,
    Color colorInactivo,
  ) {
    final color = deshabilitado ? colorInactivo : colorActivo;
    if (valor == '⌫') {
      return Icon(Icons.backspace_rounded, size: 30, color: color);
    }
    if (valor == '→') {
      return Icon(Icons.arrow_forward_ios_rounded, size: 27, color: color);
    }
    return Text(
      valor,
      style: TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: 1.1,
      ),
    );
  }
}

class TeclaAnimada extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool deshabilitado;
  final Color colorFondo;
  final Color colorSplash;

  const TeclaAnimada({
    super.key,
    required this.child,
    required this.onTap,
    required this.deshabilitado,
    required this.colorFondo,
    required this.colorSplash,
  });

  @override
  State<TeclaAnimada> createState() => _TeclaAnimadaState();
}

class _TeclaAnimadaState extends State<TeclaAnimada> {
  double escala = 1.0;

  void _presionar() {
    if (!widget.deshabilitado) {
      setState(() => escala = 0.84); // Encoge rápido
      Future.delayed(const Duration(milliseconds: 85), () {
        if (mounted) setState(() => escala = 1.0); // Rebote rápido
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: escala,
      duration: const Duration(milliseconds: 105),
      curve: Curves.easeInOutCubic,
      child: Material(
        color: widget.colorFondo,
        shape: const CircleBorder(),
        elevation: widget.deshabilitado ? 0 : 7,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          splashColor: widget.colorSplash,
          onTap: widget.deshabilitado
              ? null
              : () {
                  _presionar();
                  widget.onTap?.call();
                },
          child: SizedBox(
            width: 60,
            height: 60,
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}
