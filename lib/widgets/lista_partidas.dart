import 'package:flutter/material.dart';
import '../models/partida.dart';

class ListaPartidas extends StatelessWidget {
  final List<Partida> partidas;
  final void Function(int index) onEditar;
  final void Function(int index) onBorrar;

  const ListaPartidas({
    super.key,
    required this.partidas,
    required this.onEditar,
    required this.onBorrar,
  });

  Future<bool?> _confirmarBorrado(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar partida?'),
        content: const Text(
          '¿Seguro que quieres eliminar esta partida? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (partidas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No hay partidas añadidas',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: partidas.length,
      itemBuilder: (_, index) {
        final p = partidas[index];
        return Dismissible(
          key: Key('partida_$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmarBorrado(context),
          onDismissed: (_) => onBorrar(index),
          child: Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
            child: ListTile(
              title: Text('Partida ${index + 1} - ${p.total} puntos'),
              onTap: () => onEditar(index), // ← Toca para editar
            ),
          ),
        );
      },
    );
  }
}
