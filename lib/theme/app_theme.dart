import 'package:flutter/material.dart';

class AppTheme {
  static const Color fondo = Color(0xFFF0F8FF); // Fondo general
  static const Color primario = Color(0xFF0077B6); // Azul principal

  static final ThemeData azul = ThemeData(
    brightness: Brightness.light,

    scaffoldBackgroundColor: fondo,
    primaryColor: primario,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primario,
      primary: primario,
      secondary: Colors.blue.shade100,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: primario,
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: Colors.blue.shade50,
      selectedColor: primario,
      labelStyle: const TextStyle(color: Colors.black),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      brightness: Brightness.light,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    iconTheme: const IconThemeData(color: primario),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF222222)),
      bodySmall: TextStyle(color: Color(0xFF444444)),
      titleMedium: TextStyle(fontWeight: FontWeight.bold),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primario,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primario),
    ),
  );
  static final ThemeData oscuro = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0E1A),
    primaryColor: const Color(0xFF0096C7),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF0096C7),
      secondary: Color(0xFF00B4D8),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1F2E),
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFF1A1F2E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: Colors.blueGrey.shade700,
      selectedColor: const Color(0xFF00B4D8),
      labelStyle: const TextStyle(color: Colors.white),
      secondaryLabelStyle: const TextStyle(color: Colors.black),
      brightness: Brightness.dark,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    iconTheme: const IconThemeData(color: Color(0xFF00B4D8)),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.grey),
      titleMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0096C7),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF00B4D8)),
    ),
  );
}
