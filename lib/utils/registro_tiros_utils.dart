import 'app_constants.dart';

bool esEntradaValida(String entrada) {
  final validos = RegExp(r'^[0-9Xx/\-]$');
  return entrada.isEmpty || validos.hasMatch(entrada);
}

int parseTiro(String s) {
  final tiro = s.trim().toUpperCase();
  if (tiro == AppConstants.simboloStrike) return AppConstants.maxPinesBowling;
  if (tiro == AppConstants.simboloSpare) return -1; // sólo válido dentro del frame
  if (tiro == AppConstants.simboloFallo) return 0;
  return int.tryParse(tiro) ?? 0;
}

bool sumaValida(String t1, String t2, int frameIndex) {
  // En el frame 10 no se valida
  if (frameIndex == AppConstants.totalFrames - 1) return true;

  String normalizar(String valor) {
    if (valor.toUpperCase() == AppConstants.simboloStrike) return '${AppConstants.maxPinesBowling}';
    if (valor == AppConstants.simboloFallo) return '0';
    return valor;
  }

  final v1 = normalizar(t1).trim();
  final v2 = normalizar(t2).trim();

  if (v1.isEmpty || v2.isEmpty) return true;

  final n1 = int.tryParse(v1) ?? 0;
  final n2 = int.tryParse(v2) ?? 0;

  // Si hay un spare, el total no importa (se da por válido)
  if (t2 == AppConstants.simboloSpare) return true;

  return (n1 + n2) <= AppConstants.maxPinesBowling;
}

bool mostrarTercerTiro(List<List<String>> frames) {
  if (frames.length < AppConstants.totalFrames) return false;

  final f10 = frames[AppConstants.totalFrames - 1];
  if (f10.length < AppConstants.maxTirosPorFrame) return false;

  final t0 = f10[0].trim().toUpperCase();
  final t1 = f10[1].trim().toUpperCase();

  // Ambos tiros deben estar presentes para tomar la decisión
  if (t0.isEmpty || t1.isEmpty) return false;

  return t0 == AppConstants.simboloStrike || t1 == AppConstants.simboloSpare;
}

List<List<String>> interpretarFrames(List<List<String>> entradas) {
  return entradas.map((frame) {
    return frame.map((tiro) {
      final limpio = tiro.trim().toUpperCase();
      if (limpio == AppConstants.simboloFallo) return '0';
      return limpio;
    }).toList();
  }).toList();
}

int siguienteTiro(List<List<String>> frames, int currentIndex, int n) {
  int count = 0;

  for (int i = currentIndex + 1; i < frames.length && i < AppConstants.totalFrames; i++) {
    for (var tiro in frames[i]) {
      final val = tiro.trim().toUpperCase();
      if (val.isEmpty) continue;

      if (val == AppConstants.simboloStrike) {
        count++;
        if (count == n) return AppConstants.maxPinesBowling;
        continue;
      }

      if (val == AppConstants.simboloSpare) {
        return AppConstants.maxPinesBowling;
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
    if ((t0 == AppConstants.simboloStrike) || (t1 == AppConstants.simboloSpare) || (t1 == AppConstants.simboloStrike)) {
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
  if (t0 == AppConstants.simboloStrike) return TipoFrame.strike;
  if (t0 != null && t1 == AppConstants.simboloSpare) return TipoFrame.spare;
  if (t0 != null && t1 != null) return TipoFrame.abierto;

  return TipoFrame.incompleto;
}

int tiroToInt(String tiro, [String? anterior]) {
  if (tiro == AppConstants.simboloStrike) return AppConstants.maxPinesBowling;
  if (tiro == AppConstants.simboloSpare) {
    if (anterior == null) return AppConstants.maxPinesBowling;
    return AppConstants.maxPinesBowling - tiroToInt(anterior);
  }
  if (tiro == AppConstants.simboloFallo || tiro.trim().isEmpty) return 0;
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

  for (int i = 0; i < frames.length && i < AppConstants.totalFrames; i++) {
    final frame = frames[i];
    final esUltimo = i == AppConstants.totalFrames - 1;
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
          score += AppConstants.maxPinesBowling;
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
          score += AppConstants.maxPinesBowling;
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
  if ((frame[0] == AppConstants.simboloStrike) || (frame[1] == AppConstants.simboloSpare) || (frame[1] == AppConstants.simboloStrike)) {
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
  List<int?> puntuaciones = List.filled(AppConstants.totalFrames, null);
  int acumulado = 0;

  for (int i = 0; i < frames.length && i < AppConstants.totalFrames; i++) {
    final frame = frames[i];

    // ⛔️ NUEVA LÍNEA: omitir si el frame está completamente vacío
    if (frame.every((t) => t.trim().isEmpty)) {
      puntuaciones[i] = null;
      continue;
    }

    final esUltimo = i == AppConstants.totalFrames - 1;
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
                AppConstants.maxPinesBowling + tiroToInt(bonus[0]) + tiroToInt(bonus[1], bonus[0]);
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
            puntosDelFrame = AppConstants.maxPinesBowling + tiroToInt(bonus[0]);
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
  bool esPleno(String tiro) => tiro.toUpperCase() == AppConstants.simboloStrike || tiro == AppConstants.simboloSpare;

  return ultimos.every(
    (f) => f.isNotEmpty && esPleno(f.length > 1 ? f[1] : f[0]),
  );
}

int valorNumerico(String tiro) {
  tiro = tiro.toUpperCase().trim();
  if (tiro == AppConstants.simboloStrike) return AppConstants.maxPinesBowling;
  if (tiro == AppConstants.simboloSpare)
    return AppConstants.maxPinesBowling; // se interpreta como spare, se ajusta en la suma real
  if (tiro == AppConstants.simboloFallo) return 0;
  return int.tryParse(tiro) ?? 0;
}

int calcularPuntuacionMaximaPosible(List<List<String>> frames) {
  // Si el frame 10 está completo, devuelve la puntuación real
  if (frame10Completo(frames[AppConstants.totalFrames - 1])) {
    return calcularPuntuacionPartida(frames); // ¡usa aquí tu función real!
  }

  int total = 0;

  for (int i = 0; i < AppConstants.totalFrames; i++) {
    final frame = frames[i];
    final esUltimo = i == AppConstants.totalFrames - 1;
    final tipo = tipoDeFrame(frame, esUltimo: esUltimo);

    switch (tipo) {
      case TipoFrame.strike:
        total += AppConstants.maxPinesBowling;
        final bonus = obtenerProximosTiros(frames, i, 2);
        if (bonus.length >= 2) {
          total += tiroToInt(bonus[0]) + tiroToInt(bonus[1], bonus[0]);
        } else {
          total += (2 - bonus.length) * AppConstants.maxPinesBowling;
          total += bonus.fold<int>(0, (s, t) => s + tiroToInt(t));
        }
        break;

      case TipoFrame.spare:
        total += AppConstants.maxPinesBowling;
        final bonus = obtenerProximosTiros(frames, i, 1);
        if (bonus.isNotEmpty) {
          total += tiroToInt(bonus[0]);
        } else {
          total += AppConstants.maxPinesBowling;
        }
        break;

      case TipoFrame.abierto:
        if (frame.length >= 2) {
          total += tiroToInt(frame[0]) + tiroToInt(frame[1]);
        } else if (frame.length == 1 && frame[0].isNotEmpty) {
          final tiro1 = tiroToInt(frame[0]);
          final max2 = (tiro1 < AppConstants.maxPinesBowling) ? (AppConstants.maxPinesBowling - tiro1) : 0;
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
          final tirosRestantes = (AppConstants.maxTirosFrame10 - tirosHechos).clamp(0, AppConstants.maxTirosFrame10);
          if (tirosRestantes > 0) {
            total += tirosRestantes * AppConstants.maxPinesBowling;
          }
        }
        break;
    }
  }

  return total.clamp(0, 300);
}

List<FrameError> validarFrame(List<String> frame, {required int index}) {
  final errores = <FrameError>[];
  final esUltimo = index == AppConstants.totalFrames - 1;
  final tiros = frame.map((t) => t.trim().toUpperCase()).toList();

  while (tiros.length < AppConstants.maxTirosFrame10) tiros.add('');

  int valorNumerico(String s) {
    if (s == AppConstants.simboloStrike) return AppConstants.maxPinesBowling;
    if (s == AppConstants.simboloFallo) return 0;
    final n = int.tryParse(s);
    return n != null ? n.clamp(0, 9) : -1;
  }

  final caracteresValidos = {
    AppConstants.simboloStrike,
    AppConstants.simboloSpare,
    AppConstants.simboloFallo,
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

  if (tiros[0] == AppConstants.simboloSpare) {
    errores.add(
      FrameError(
        'No se puede usar "${AppConstants.simboloSpare}" como primer tiro del frame ${index + 1}.',
      ),
    );
  }

  final slashCount = tiros.where((t) => t == AppConstants.simboloSpare).length;
  if (slashCount > 1) {
    errores.add(FrameError('Demasiados "${AppConstants.simboloSpare}" en el frame ${index + 1}.'));
  }

  if (!esUltimo) {
    final xCount = tiros.where((t) => t == AppConstants.simboloStrike).length;

    if (xCount > 1) {
      errores.add(FrameError('Demasiados "${AppConstants.simboloStrike}" en el frame ${index + 1}.'));
    }

    if (tiros[1] == AppConstants.simboloStrike) {
      errores.add(
        FrameError(
          'No se permite una "${AppConstants.simboloStrike}" como segundo tiro en el frame ${index + 1}.',
        ),
      );
    }

    if (tiros[0] != AppConstants.simboloStrike && tiros[1].isNotEmpty) {
      final v1 = valorNumerico(tiros[0]);
      final v2 = tiros[1] == AppConstants.simboloSpare ? (AppConstants.maxPinesBowling - v1) : valorNumerico(tiros[1]);

      if (v1 < 0 || v2 < 0) {
        errores.add(FrameError('Tiros inválidos en el frame ${index + 1}.'));
      } else if (v1 + v2 > AppConstants.maxPinesBowling) {
        errores.add(
          FrameError('La suma de pins supera ${AppConstants.maxPinesBowling} en el frame ${index + 1}.'),
        );
      } else if (v1 + v2 == AppConstants.maxPinesBowling && tiros[1] != AppConstants.simboloSpare) {
        errores.add(
          FrameError(
            'El segundo tiro en el frame ${index + 1} debería ser "${AppConstants.simboloSpare}" al sumar ${AppConstants.maxPinesBowling}.',
          ),
        );
      } else if (tiros[0] == '0' && tiros[1] == AppConstants.simboloStrike) {
        errores.add(
          FrameError(
            'Se interpreta "0${AppConstants.simboloStrike}" como spare. Usa "${AppConstants.simboloSpare}" para marcar spare correctamente.',
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
    final v1 = t1 == AppConstants.simboloSpare ? (AppConstants.maxPinesBowling - v0) : valorNumerico(t1);
    final v2 = valorNumerico(t2);

    final tieneStrikeOspare = t0 == AppConstants.simboloStrike || t1 == AppConstants.simboloSpare;

    if (t0.isNotEmpty && t1.isNotEmpty && !tieneStrikeOspare && t2.isNotEmpty) {
      errores.add(
        FrameError(
          'No se permite un tercer tiro en el frame ${AppConstants.totalFrames} sin strike o spare.',
        ),
      );
    }

    if (t0 != AppConstants.simboloStrike && t1 == AppConstants.simboloSpare) {
      if (v0 < 0 || v0 > 9) {
        errores.add(
          FrameError(
            'Combinación inválida en el frame ${AppConstants.totalFrames} ("${AppConstants.simboloSpare}" sin primer tiro numérico válido).',
          ),
        );
      }
    }

    if (t1 == AppConstants.simboloSpare && t0 == AppConstants.simboloStrike) {
      errores.add(
        FrameError(
          '"${AppConstants.simboloSpare}" no puede seguir a una "${AppConstants.simboloStrike}" directamente en el frame ${AppConstants.totalFrames}.',
        ),
      );
    }

    if (t2.isNotEmpty && !tieneStrikeOspare) {
      errores.add(
        FrameError(
          'No se permite un tercer tiro en el frame ${AppConstants.totalFrames} si no hay strike o spare.',
        ),
      );
    }

    if (t0 != AppConstants.simboloStrike && t1 != AppConstants.simboloSpare && t2.isNotEmpty) {
      errores.add(
        FrameError(
          'No se permite un tercer tiro en el frame ${AppConstants.totalFrames} sin strike ni spare.',
        ),
      );
    }

    if (t2 == AppConstants.simboloSpare && t1 == AppConstants.simboloStrike) {
      errores.add(
        FrameError(
          '"${AppConstants.simboloSpare}" no es válido como tercer tiro después de "${AppConstants.simboloStrike}" en el segundo tiro del frame ${AppConstants.totalFrames}.',
        ),
      );
    }
  }

  return errores;
}

List<FrameError> validarPartida(List<List<String>> frames) {
  final errores = <FrameError>[];

  if (frames.length != AppConstants.totalFrames) {
    errores.add(FrameError('La partida debe tener exactamente ${AppConstants.totalFrames} frames.'));
    return errores; // No tiene sentido seguir validando
  }

  bool alMenosUnFrameValido = false;

  for (int i = 0; i < frames.length; i++) {
    final frame = frames[i];
    final frameErrores = validarFrame(frame, index: i);

    errores.addAll(frameErrores);

    // Se considera válido si tiene al menos un tiro con valor real
    if (frame.any((t) => t.trim().isNotEmpty && t.trim() != AppConstants.simboloFallo)) {
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


