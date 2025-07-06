String formatearFrame(List<String> frame) {
  final List<String> resultado = [];

  for (int i = 0; i < frame.length; i++) {
    final tiro = frame[i].toUpperCase().trim();

    if (tiro == 'X') {
      resultado.add('X');
    } else if (tiro == '/') {
      resultado.add('/');
    } else if (int.tryParse(tiro) != null) {
      resultado.add(tiro);
    } else {
      resultado.add('-'); // Vacío o inválido
    }
  }

  return resultado.join(' | ');
}

String formatearFramesPartida(List<List<String>> frames) {
  final buffer = StringBuffer();

  for (int i = 0; i < frames.length; i++) {
    final frame = frames[i];
    final textoFormateado = formatearFrame(frame);
    buffer.writeln('Frame ${i + 1}: $textoFormateado');
  }

  return buffer.toString();
}
