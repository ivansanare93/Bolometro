import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(BolosApp());
}

class BolosApp extends StatelessWidget {
  const BolosApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Bolos',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomeScreen(), //pantalla inicial
    );
  }
}