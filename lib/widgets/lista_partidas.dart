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
        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          child: ListTile(
            title: Text('Partida ${index + 1} - ${p.total} puntos'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar',
                  onPressed: () => onEditar(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Borrar',
                  onPressed: () => onBorrar(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
