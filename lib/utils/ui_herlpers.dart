// ui_helpers.dart

import 'package:flutter/material.dart';

/// Devuelve el ícono correspondiente al tipo de sesión
/// con color adaptado a modo claro u oscuro.
Widget iconoTipoSesion(String tipo, BuildContext context, {double size = 24}) {
  final esCompeticion = tipo.toLowerCase().contains('comp');

  final brightness = Theme.of(context).brightness;
  final isDarkMode = brightness == Brightness.dark;

  final color = esCompeticion
      ? (isDarkMode ? const Color(0xFF90CAF9) : const Color(0xFF0077B6)) // azul
      : (isDarkMode ? const Color(0xFFA5D6A7) : const Color(0xFF2A9D8F)); // verde

  final icon = esCompeticion ? Icons.emoji_events : Icons.fitness_center;

  return Icon(icon, color: color, size: size);
}

/// Devuelve el color del tipo de sesión para usar en gráficos u otros elementos visuales.
Color colorTipoSesion(String tipo, BuildContext context) {
  final esCompeticion = tipo.toLowerCase().contains('comp');
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return esCompeticion
      ? (isDark ? const Color(0xFF90CAF9) : const Color(0xFF0077B6)) // azul
      : (isDark ? const Color(0xFFA5D6A7) : const Color(0xFF2A9D8F)); // verde
}
