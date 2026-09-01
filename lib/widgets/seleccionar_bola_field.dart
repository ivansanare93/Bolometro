import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bowling_ball.dart';
import '../repositories/data_repository.dart';

/// Abre un bottom sheet para seleccionar una bola activa entre las
/// registradas por el usuario, incluyendo la opción "Sin especificar".
/// Devuelve el [BowlingBall.id] elegido, o `null` si se elige "Sin
/// especificar" o se cierra sin seleccionar.
Future<String?> seleccionarBolaBottomSheet(
  BuildContext context, {
  String? seleccionActualId,
}) async {
  final repo = Provider.of<DataRepository>(context, listen: false);
  final bolas = await repo.listarBolasActivas();

  if (!context.mounted) return seleccionActualId;

  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  '¿Con qué bola jugaste?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Sin especificar'),
                selected: seleccionActualId == null,
                onTap: () => Navigator.pop(context, null),
              ),
              if (bolas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'Todavía no tienes bolas activas registradas. '
                    'Ve a "Mis Bolas" para agregar una.',
                  ),
                )
              else
                ...bolas.map(
                  (bola) => ListTile(
                    leading: const Text('🎳'),
                    title: Text(bola.name),
                    subtitle: bola.brand != null && bola.brand!.trim().isNotEmpty
                        ? Text(bola.brand!)
                        : null,
                    selected: seleccionActualId == bola.id,
                    onTap: () => Navigator.pop(context, bola.id),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

/// Campo compacto (ListTile) que muestra la bola seleccionada para una
/// partida y permite cambiarla mediante [seleccionarBolaBottomSheet].
class SeleccionarBolaField extends StatelessWidget {
  final String? ballId;
  final ValueChanged<String?> onChanged;

  const SeleccionarBolaField({
    super.key,
    required this.ballId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BowlingBall?>(
      future: ballId == null
          ? Future.value(null)
          : Provider.of<DataRepository>(context, listen: false)
              .obtenerBola(ballId!),
      builder: (context, snapshot) {
        final nombreBola = snapshot.data?.name ?? 'Sin especificar';
        return Card(
          child: ListTile(
            leading: const Text('🎳', style: TextStyle(fontSize: 24)),
            title: const Text('Bola utilizada'),
            subtitle: Text(nombreBola),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final seleccionada = await seleccionarBolaBottomSheet(
                context,
                seleccionActualId: ballId,
              );
              onChanged(seleccionada);
            },
          ),
        );
      },
    );
  }
}
