/// Utility functions to translate a list of knocked-down pins into the
/// corresponding shot value (e.g. "X", "/", "-", or a number string).
library;

/// Converts a list of knocked-down [seleccionados] pin numbers (1–10) into
/// the textual shot value to display on the score board.
///
/// Parameters:
/// - [frame]: 0-indexed frame number (0–9).
/// - [tiro]: 0-indexed shot index within the frame (0 = first, 1 = second,
///   2 = third, only valid for frame 10).
/// - [seleccionados]: list of pin numbers (1–10) knocked down on this shot.
/// - [pinesPorTiroFrame]: all pin-selection data for the current frame, i.e.
///   `pinesPorTiro[frame]` (list of 3 nullable lists).
/// - [framesText]: the full 10×3 text grid of shot values (for reading
///   previously recorded shots in frame 10).
///
/// Returns the shot value as a string: "X", "/", "-", or a digit 1–9.
String pinesAValorTiro({
  required int frame,
  required int tiro,
  required List<int> seleccionados,
  required List<List<int>?> pinesPorTiroFrame,
  required List<List<String>> framesText,
}) {
  if (frame < 9) {
    // Frames 1–9
    if (tiro == 0) {
      return seleccionados.length == 10 ? 'X' : _valoresTiro(seleccionados);
    } else if (tiro == 1) {
      final prevTiro = pinesPorTiroFrame[0] ?? [];
      final union = <int>{...prevTiro, ...seleccionados};
      if (union.length == 10 && prevTiro.length != 10) return '/';
      return _valoresTiro(seleccionados);
    } else {
      return _valoresTiro(seleccionados);
    }
  } else {
    // Frame 10
    final tiro1Text = framesText[9][0];
    final tiro2Text = framesText[9][1];

    if (tiro == 0) {
      return seleccionados.length == 10
          ? 'X'
          : _valoresTiro(seleccionados);
    } else if (tiro == 1) {
      final prevTiro = pinesPorTiroFrame[0] ?? [];
      final union = <int>{...prevTiro, ...seleccionados};
      if (seleccionados.length == 10) return 'X';
      if (union.length == 10 && prevTiro.length != 10) return '/';
      return _valoresTiro(seleccionados);
    } else {
      // Third shot of frame 10
      final primerTiroStrike = tiro1Text == 'X';
      final t1Val = _parseTiroText(tiro1Text, '');
      final t2Val = _parseTiroText(tiro2Text, tiro1Text);
      final sparePrevio =
          !primerTiroStrike && tiro1Text.isNotEmpty && tiro2Text.isNotEmpty && (t1Val + t2Val == 10);

      if (primerTiroStrike || sparePrevio) {
        final segundoTiroPins = pinesPorTiroFrame[1] ?? [];
        final unionConSegundo = <int>{...segundoTiroPins, ...seleccionados};
        if (primerTiroStrike &&
            segundoTiroPins.isNotEmpty &&
            segundoTiroPins.length < 10 &&
            unionConSegundo.length == 10) {
          return '/';
        }
        if (seleccionados.length == 10) return 'X';
        return _valoresTiro(seleccionados);
      } else {
        return '-';
      }
    }
  }
}

/// Calculates which pins should be disabled (already knocked down and
/// unavailable) for the given shot in a frame.
///
/// Returns a list of pin numbers (1–10) that cannot be knocked down again.
List<int> calcularPinesDeshabilitados({
  required int frame,
  required int tiro,
  required List<List<int>?> pinesPorTiroFrame,
}) {
  if (frame == 9) {
    final primerTiro = pinesPorTiroFrame[0] ?? [];
    final segundoTiro = pinesPorTiroFrame[1] ?? [];

    if (tiro == 0) {
      return const [];
    } else if (tiro == 1) {
      if (primerTiro.length == 10) return const [];
      return List<int>.from(primerTiro);
    } else {
      if (primerTiro.length == 10) {
        if (segundoTiro.length == 10) return const [];
        return List<int>.from(segundoTiro);
      } else if (primerTiro.length + segundoTiro.length == 10) {
        return const [];
      } else {
        return List<int>.from({...primerTiro, ...segundoTiro});
      }
    }
  } else {
    // Frames 1–9: disable any pins knocked down in prior shots of this frame
    final deshabilitados = <int>[];
    for (int prev = 0; prev < tiro; prev++) {
      deshabilitados.addAll(pinesPorTiroFrame[prev] ?? []);
    }
    return deshabilitados;
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

String _valoresTiro(List<int> seleccionados) {
  if (seleccionados.isEmpty) return '-';
  return '${seleccionados.length}';
}

int _parseTiroText(String tiro, String previo) {
  if (tiro == 'X') return 10;
  if (tiro == '/') return 10 - _parseTiroText(previo, '');
  if (tiro == '-') return 0;
  return int.tryParse(tiro) ?? 0;
}
