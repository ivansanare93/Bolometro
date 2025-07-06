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
  final f10 = frames[9];
  final t1 = f10[0].toUpperCase();
  final t2 = f10[1].toUpperCase();

  return t1 == 'X' || t2 == '/' || t2 == 'X';
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
    if (t0 == 'X' || t1 == '/' || t1 == 'X') {
      if (t2 != null && t2.isNotEmpty) return TipoFrame.strike;
      return TipoFrame.incompleto;
    } else {
      if (t0 != null && t1 != null) return TipoFrame.abierto;
      return TipoFrame.incompleto;
    }
  }

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

List<int?> calcularPuntuacionPorFrame(
  List<List<String>> frames, {
  bool permitirNulos = false,
}) {
  List<int?> puntuaciones = List.filled(10, null);
  int acumulado = 0;

  for (int i = 0; i < frames.length && i < 10; i++) {
    final frame = frames[i];
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

int _valorTiro(String tiro) {
  tiro = tiro.trim().toUpperCase();
  if (tiro == 'X') return 10;
  if (tiro == '/')
    return 10; // solo seguro si se usa en frame 10 o ya controlado
  if (tiro == '-') return 0;
  return int.tryParse(tiro) ?? 0;
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
  int total = 0;
  int framesCompletos = 0;

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
          total += 20; // máximo bonus posible
        }
        framesCompletos++;
        break;

      case TipoFrame.spare:
        total += 10;
        final bonus = obtenerProximosTiros(frames, i, 1);
        if (bonus.isNotEmpty) {
          total += tiroToInt(bonus[0]);
        } else {
          total += 10;
        }
        framesCompletos++;
        break;

      case TipoFrame.abierto:
        if (frame.length >= 2) {
          total += tiroToInt(frame[0]) + tiroToInt(frame[1]);
        }
        framesCompletos++;
        break;

      case TipoFrame.incompleto:
      case TipoFrame.invalido:
        // Aún no jugado, contamos el máximo posible
        break;
    }
  }

  // Si quedan frames sin jugar, asumimos que son strikes (30 puntos por frame)
  final framesRestantes = 10 - framesCompletos;
  total += framesRestantes * 30;

  return total.clamp(0, 300);
}
