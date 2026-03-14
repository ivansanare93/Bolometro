import 'package:flutter/material.dart';
import '../models/partida.dart';
import '../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteGameTitle),
        content: Text(l10n.deleteGameConfirmation),
        actions: [
          TextButton(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (partidas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            l10n.noGamesAdded,
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
              title: Text('${l10n.gameNumber(index + 1)} - ${l10n.points(p.total)}'),
              onTap: () => onEditar(index),
            ),
          ),
        );
      },
    );
  }
}
