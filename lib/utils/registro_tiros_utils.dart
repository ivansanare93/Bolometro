bool esEntradaValida(String entrada) {
  final validos = RegExp(r'^[0-9Xx/\-]$');
  return entrada.isEmpty || validos.hasMatch(entrada);
}

int parseTiro(String s) {
  final tiro = s.trim().toUpperCase();
  if (tiro == 'X') return 10;
  if (tiro == '/') return -1; // sólo válido dentro del frame
  if (tiro == '-') return 0;
  return int.tryParse(tiro) ?? 0;
}

bool sumaValida(String t1, String t2, int frameIndex) {
  // En el frame 10 no se valida
  if (frameIndex == 9) return true;

  String normalizar(String valor) {
    if (valor.toUpperCase() == 'X') return '10';
    if (valor == '-') return '0';
    return valor;
  }

  final v1 = normalizar(t1).trim();
  final v2 = normalizar(t2).trim();

  if (v1.isEmpty || v2.isEmpty) return true;

  final n1 = int.tryParse(v1) ?? 0;
  final n2 = int.tryParse(v2) ?? 0;

  // Si hay un spare, el total no importa (se da por válido)
  if (t2 == '/') return true;

  return (n1 + n2) <= 10;
}

bool mostrarTercerTiro(List<List<String>> frames) {
  if (frames.length < 10) return false;

  final f10 = frames[9];
  if (f10.length < 2) return false;

  final t0 = f10[0].trim().toUpperCase();
  final t1 = f10[1].trim().toUpperCase();

  // Ambos tiros deben estar presentes para tomar la decisión
  if (t0.isEmpty || t1.isEmpty) return false;

  return t0 == 'X' || t1 == '/';
}

List<List<String>> interpretarFrames(List<List<String>> entradas) {
  return entradas.map((frame) {
    return frame.map((tiro) {
      final limpio = tiro.trim().toUpperCase();
      if (limpio == '-') return '0';
      return limpio;
    }).toList();
  }).toList();
}

int siguienteTiro(List<List<String>> frames, int currentIndex, int n) {
  int count = 0;

  for (int i = currentIndex + 1; i < frames.length && i < 10; i++) {
    for (var tiro in frames[i]) {
      final val = tiro.trim().toUpperCase();
      if (val.isEmpty) continue;

      if (val == 'X') {
        count++;
        if (count == n) return 10;
        continue;
      }

      if (val == '/') {
        return 10;
      }

      final parsed = int.tryParse(val);
      if (parsed != null) {
        count++;
        if (count == n) return parsed;
      }
    }
  }

  return 0;
}

enum TipoFrame { strike, spare, abierto, incompleto, invalido }

TipoFrame tipoDeFrame(List<String> frame, {bool esUltimo = false}) {
  if (frame.isEmpty || frame.every((t) => t.trim().isEmpty))
    return TipoFrame.incompleto;

  String? t0 = frame.length > 0 ? frame[0] : null;
  String? t1 = frame.length > 1 ? frame[1] : null;
  String? t2 = frame.length > 2 ? frame[2] : null;

  if (esUltimo) {
    // Si hay strike en tiro 1 o spare en tiro 2, puede haber tercer tiro
    if ((t0 == 'X') || (t1 == '/') || (t1 == 'X')) {
      if ((t0 != null && t0.isNotEmpty) &&
          (t1 != null && t1.isNotEmpty) &&
          (t2 != null && t2.isNotEmpty)) {
        return TipoFrame.strike; // Frame 10 completo con extra
      } else {
        return TipoFrame.incompleto;
      }
    } else {
      // No hay strike/spare: frame termina tras 2 tiros
      if ((t0 != null && t0.isNotEmpty) && (t1 != null && t1.isNotEmpty)) {
        return TipoFrame.abierto;
      } else {
        return TipoFrame.incompleto;
      }
    }
  }

  // Frames 1-9
  if (t0 == 'X') return TipoFrame.strike;
  if (t0 != null && t1 == '/') return TipoFrame.spare;
  if (t0 != null && t1 != null) return TipoFrame.abierto;

  return TipoFrame.incompleto;
}

int tiroToInt(String tiro, [String? anterior]) {
  if (tiro == 'X') return 10;
  if (tiro == '/') {
    if (anterior == null) return 10;
    return 10 - tiroToInt(anterior);
  }
  if (tiro == '-' || tiro.trim().isEmpty) return 0;
  return int.tryParse(tiro) ?? 0;
}

List<String> obtenerProximosTiros(
  List<List<String>> frames,
  int desdeIndex,
  int cantidad,
) {
  List<String> tiros = [];
  for (
    int i = desdeIndex + 1;
    i < frames.length && tiros.length < cantidad;
    i++
  ) {
    for (var tiro in frames[i]) {
      if (tiro.trim().isNotEmpty) tiros.add(tiro);
      if (tiros.length == cantidad) break;
    }
  }
  return tiros;
}

int calcularPuntuacionPartida(List<List<String>> frames) {
  int score = 0;

  for (int i = 0; i < frames.length && i < 10; i++) {
    final frame = frames[i];
    final esUltimo = i == 9;
    final tipo = tipoDeFrame(frame, esUltimo: esUltimo);

    String t0 = frame.length > 0 ? frame[0] : '';
    String t1 = frame.length > 1 ? frame[1] : '';
    String? t2 = frame.length > 2 ? frame[2] : null;

    switch (tipo) {
      case TipoFrame.strike:
        if (esUltimo) {
          // Frame 10 con strike
          score += tiroToInt(t0);
          score += tiroToInt(t1, t0);
          if (t2 != null) score += tiroToInt(t2, t1);
        } else {
          score += 10;
          final bonus = obtenerProximosTiros(frames, i, 2);
          if (bonus.isNotEmpty) score += tiroToInt(bonus[0]);
          if (bonus.length > 1) score += tiroToInt(bonus[1], bonus[0]);
        }
        break;

      case TipoFrame.spare:
        if (esUltimo) {
          // Frame 10 con spare
          score += tiroToInt(t0);
          score += tiroToInt(t1, t0);
          if (t2 != null) score += tiroToInt(t2, t1);
        } else {
          score += 10;
          final bonus = obtenerProximosTiros(frames, i, 1);
          if (bonus.isNotEmpty) score += tiroToInt(bonus[0]);
        }
        break;

      case TipoFrame.abierto:
        score += tiroToInt(t0);
        score += tiroToInt(t1);
        break;

      case TipoFrame.incompleto:
        // No sumar nada, pero en el futuro podrías mostrar un warning
        break;

      case TipoFrame.invalido:
        // También podrías reportarlo
        break;
    }
  }

  return score;
}

bool frame10Completo(List<String> frame) {
  // Si hay strike o spare en los dos primeros, derecho a tercer tiro
  if ((frame[0] == 'X') || (frame[1] == '/') || (frame[1] == 'X')) {
    return frame.length > 2 && frame[2].isNotEmpty;
  } else {
    // Si no, solo dos tiros permitidos
    return frame.length > 1 && frame[1].isNotEmpty;
  }
}

List<int?> calcularPuntuacionPorFrame(
  List<List<String>> frames, {
  bool permitirNulos = false,
}) {
  List<int?> puntuaciones = List.filled(10, null);
  int acumulado = 0;

  for (int i = 0; i < frames.length && i < 10; i++) {
    final frame = frames[i];

    // ⛔️ NUEVA LÍNEA: omitir si el frame está completamente vacío
    if (frame.every((t) => t.trim().isEmpty)) {
      puntuaciones[i] = null;
      continue;
    }

    final esUltimo = i == 9;
    final tipo = tipoDeFrame(frame, esUltimo: esUltimo);

    String t0 = frame.length > 0 ? frame[0] : '';
    String t1 = frame.length > 1 ? frame[1] : '';
    String? t2 = frame.length > 2 ? frame[2] : null;

    int? puntosDelFrame;

    switch (tipo) {
      case TipoFrame.strike:
        if (esUltimo) {
          if (t1.isNotEmpty && t2 != null && t2.isNotEmpty) {
            puntosDelFrame =
                tiroToInt(t0) + tiroToInt(t1, t0) + tiroToInt(t2, t1);
          } else if (!permitirNulos) {
            puntosDelFrame = 0;
          }
        } else {
          final bonus = obtenerProximosTiros(frames, i, 2);
          if (bonus.length >= 2) {
            puntosDelFrame =
                10 + tiroToInt(bonus[0]) + tiroToInt(bonus[1], bonus[0]);
          } else if (!permitirNulos) {
            puntosDelFrame = 0;
          }
        }
        break;

      case TipoFrame.spare:
        if (esUltimo) {
          if (t2 != null && t2.isNotEmpty) {
            puntosDelFrame =
                tiroToInt(t0) + tiroToInt(t1, t0) + tiroToInt(t2, t1);
          } else if (!permitirNulos) {
            puntosDelFrame = 0;
          }
        } else {
          final bonus = obtenerProximosTiros(frames, i, 1);
          if (bonus.isNotEmpty) {
            puntosDelFrame = 10 + tiroToInt(bonus[0]);
          } else if (!permitirNulos) {
            puntosDelFrame = 0;
          }
        }
        break;

      case TipoFrame.abierto:
        if (t0.isNotEmpty && t1.isNotEmpty) {
          puntosDelFrame = tiroToInt(t0) + tiroToInt(t1);
        } else if (!permitirNulos) {
          puntosDelFrame = 0;
        }
        break;

      case TipoFrame.incompleto:
      case TipoFrame.invalido:
        if (!permitirNulos) {
          puntosDelFrame = 0;
        }
        break;
    }

    if (puntosDelFrame != null) {
      acumulado += puntosDelFrame;
      puntuaciones[i] = acumulado;
    } else if (!permitirNulos) {
      puntuaciones[i] = acumulado;
    }
  }

  return puntuaciones;
}

bool esBuenaRacha(List<List<String>> frames) {
  final completados = frames
      .where((f) => f.any((t) => t.trim().isNotEmpty))
      .toList();
  if (completados.length < 2) return false;

  final ultimos = completados.reversed.take(2).toList();
  bool esPleno(String tiro) => tiro.toUpperCase() == 'X' || tiro == '/';

  return ultimos.every(
    (f) => f.isNotEmpty && esPleno(f.length > 1 ? f[1] : f[0]),
  );
}

int valorNumerico(String tiro) {
  tiro = tiro.toUpperCase().trim();
  if (tiro == 'X') return 10;
  if (tiro == '/')
    return 10; // se interpreta como spare, se ajusta en la suma real
  if (tiro == '-') return 0;
  return int.tryParse(tiro) ?? 0;
}

int calcularPuntuacionMaximaPosible(List<List<String>> frames) {
  // Si el frame 10 está completo, devuelve la puntuación real
  if (frame10Completo(frames[9])) {
    return calcularPuntuacionPartida(frames); // ¡usa aquí tu función real!
  }

  int total = 0;

  for (int i = 0; i < 10; i++) {
    final frame = frames[i];
    final esUltimo = i == 9;
    final tipo = tipoDeFrame(frame, esUltimo: esUltimo);

    switch (tipo) {
      case TipoFrame.strike:
        total += 10;
        final bonus = obtenerProximosTiros(frames, i, 2);
        if (bonus.length >= 2) {
          total += tiroToInt(bonus[0]) + tiroToInt(bonus[1], bonus[0]);
        } else {
          total += (2 - bonus.length) * 10;
          total += bonus.fold<int>(0, (s, t) => s + tiroToInt(t));
        }
        break;

      case TipoFrame.spare:
        total += 10;
        final bonus = obtenerProximosTiros(frames, i, 1);
        if (bonus.isNotEmpty) {
          total += tiroToInt(bonus[0]);
        } else {
          total += 10;
        }
        break;

      case TipoFrame.abierto:
        if (frame.length >= 2) {
          total += tiroToInt(frame[0]) + tiroToInt(frame[1]);
        } else if (frame.length == 1 && frame[0].isNotEmpty) {
          final tiro1 = tiroToInt(frame[0]);
          final max2 = (tiro1 < 10) ? (10 - tiro1) : 0;
          total += tiro1 + max2;
        }
        break;

      case TipoFrame.incompleto:
      case TipoFrame.invalido:
        if (!esUltimo) {
          total += 30;
        } else {
          // *** FRAME 10 ***
          final tirosHechos = frame.where((t) => t.isNotEmpty).length;
          final tirosRestantes = (3 - tirosHechos).clamp(0, 3);
          if (tirosRestantes > 0) {
            total += tirosRestantes * 10;
          }
        }
        break;
    }
  }

  return total.clamp(0, 300);
}

List<FrameError> validarFrame(List<String> frame, {required int index}) {
  final errores = <FrameError>[];
  final esUltimo = index == 9;
  final tiros = frame.map((t) => t.trim().toUpperCase()).toList();

  while (tiros.length < 3) tiros.add('');

  int valorNumerico(String s) {
    if (s == 'X') return 10;
    if (s == '-') return 0;
    final n = int.tryParse(s);
    return n != null ? n.clamp(0, 9) : -1;
  }

  final caracteresValidos = {
    'X',
    '/',
    '-',
    '',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  };

  if (tiros.every((t) => t.isEmpty)) return [];

  if (!esUltimo && tiros[0].isNotEmpty && tiros[1].isEmpty) return [];

  for (int i = 0; i < tiros.length; i++) {
    if (!caracteresValidos.contains(tiros[i])) {
      errores.add(
        FrameError(
          'Tiro ${i + 1} del frame ${index + 1} tiene un valor inválido.',
        ),
      );
    }
  }

  if (tiros[0] == '/') {
    errores.add(
      FrameError(
        'No se puede usar "/" como primer tiro del frame ${index + 1}.',
      ),
    );
  }

  final slashCount = tiros.where((t) => t == '/').length;
  if (slashCount > 1) {
    errores.add(FrameError('Demasiados "/" en el frame ${index + 1}.'));
  }

  if (!esUltimo) {
    final xCount = tiros.where((t) => t == 'X').length;

    if (xCount > 1) {
      errores.add(FrameError('Demasiados "X" en el frame ${index + 1}.'));
    }

    if (tiros[1] == 'X') {
      errores.add(
        FrameError(
          'No se permite una "X" como segundo tiro en el frame ${index + 1}.',
        ),
      );
    }

    if (tiros[0] != 'X' && tiros[1].isNotEmpty) {
      final v1 = valorNumerico(tiros[0]);
      final v2 = tiros[1] == '/' ? (10 - v1) : valorNumerico(tiros[1]);

      if (v1 < 0 || v2 < 0) {
        errores.add(FrameError('Tiros inválidos en el frame ${index + 1}.'));
      } else if (v1 + v2 > 10) {
        errores.add(
          FrameError('La suma de pins supera 10 en el frame ${index + 1}.'),
        );
      } else if (v1 + v2 == 10 && tiros[1] != '/') {
        errores.add(
          FrameError(
            'El segundo tiro en el frame ${index + 1} debería ser "/" al sumar 10.',
          ),
        );
      } else if (tiros[0] == '0' && tiros[1] == 'X') {
        errores.add(
          FrameError(
            'Se interpreta "0X" como spare. Usa "/" para marcar spare correctamente.',
            esCritico: false,
          ),
        );
      }
    }
  }

  if (esUltimo) {
    final t0 = tiros[0];
    final t1 = tiros[1];
    final t2 = tiros[2];

    final v0 = valorNumerico(t0);
    final v1 = t1 == '/' ? (10 - v0) : valorNumerico(t1);
    final v2 = valorNumerico(t2);

    final tieneStrikeOspare = t0 == 'X' || t1 == '/';

    if (t0.isNotEmpty && t1.isNotEmpty && !tieneStrikeOspare && t2.isNotEmpty) {
      errores.add(
        FrameError(
          'No se permite un tercer tiro en el frame 10 sin strike o spare.',
        ),
      );
    }

    if (t0 != 'X' && t1 == '/') {
      if (v0 < 0 || v0 > 9) {
        errores.add(
          FrameError(
            'Combinación inválida en el frame 10 ("/" sin primer tiro numérico válido).',
          ),
        );
      }
    }

    if (t1 == '/' && t0 == 'X') {
      errores.add(
        FrameError(
          '"/" no puede seguir a una "X" directamente en el frame 10.',
        ),
      );
    }

    if (t2.isNotEmpty && !tieneStrikeOspare) {
      errores.add(
        FrameError(
          'No se permite un tercer tiro en el frame 10 si no hay strike o spare.',
        ),
      );
    }

    if (t0 != 'X' && t1 != '/' && t2.isNotEmpty) {
      errores.add(
        FrameError(
          'No se permite un tercer tiro en el frame 10 sin strike ni spare.',
        ),
      );
    }

    if (t2 == '/' && t1 == 'X') {
      errores.add(
        FrameError(
          '"/" no es válido como tercer tiro después de "X" en el segundo tiro del frame 10.',
        ),
      );
    }
  }

  return errores;
}

List<FrameError> validarPartida(List<List<String>> frames) {
  final errores = <FrameError>[];

  if (frames.length != 10) {
    errores.add(FrameError('La partida debe tener exactamente 10 frames.'));
    return errores; // No tiene sentido seguir validando
  }

  bool alMenosUnFrameValido = false;

  for (int i = 0; i < frames.length; i++) {
    final frame = frames[i];
    final frameErrores = validarFrame(frame, index: i);

    errores.addAll(frameErrores);

    // Se considera válido si tiene al menos un tiro con valor real
    if (frame.any((t) => t.trim().isNotEmpty && t.trim() != '-')) {
      alMenosUnFrameValido = true;
    }
  }

  if (!alMenosUnFrameValido) {
    errores.add(FrameError('La partida no contiene ningún tiro válido.'));
  }

  return errores;
}

class FrameError {
  final String mensaje;
  final bool esCritico;

  FrameError(this.mensaje, {this.esCritico = true});
}


