import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/sesion.dart';
import 'ver_sesion_screen.dart';
import 'home_screen.dart';

class ListaSesionesScreen extends StatelessWidget {
  const ListaSesionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sesiones Registradas')),
      body: FutureBuilder(
        future: Hive.openBox<Sesion>('sesiones'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final box = snapshot.data as Box<Sesion>;

          if (box.isEmpty) {
            return const Center(child: Text('Aún no has registrado sesiones.'));
          }

          final sesiones = box.values.toList();

          return ListView.builder(
            itemCount: sesiones.length,
            itemBuilder: (context, index) {
              final sesion = sesiones[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(
                    '${sesion.tipo} - ${sesion.fecha.toLocal().toString().split(' ')[0]}',
                  ),
                  subtitle: Text(
                    '${sesion.lugar} • ${sesion.partidas.length} partidas',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VerSesionScreen(sesion: sesion),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        },
        tooltip: 'Inicio',
        child: const Icon(Icons.home),
      ),
    );
  }
}
