import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/data_repository.dart';
import '../services/arsenal_remote_store.dart';

String describeArsenalPayload(Map<dynamic, dynamic>? payload) {
  if (payload == null) return 'No disponible; vuelve a sincronizar.';
  const labels = {
    'name': 'Nombre',
    'brand': 'Marca',
    'weightLbs': 'Peso (lb)',
    'coverstock': 'Cubierta',
    'finish': 'Acabado',
    'purchaseDate': 'Compra',
    'isActive': 'Activa',
    'notes': 'Notas',
    'type': 'Mantenimiento',
    'date': 'Fecha',
  };
  return labels.entries
      .where((e) => payload[e.key] != null)
      .map((e) => '${e.value}: ${payload[e.key]}')
      .join('\n');
}

class ArsenalHistoryButton extends StatelessWidget {
  final String collection;
  final String id;
  final Future<void> Function() onRestored;
  const ArsenalHistoryButton({
    super.key,
    required this.collection,
    required this.id,
    required this.onRestored,
  });

  Future<void> _open(BuildContext context) async {
    final repo = context.read<DataRepository>();
    final service = repo.arsenalSync;
    if (service == null) return;
    try {
      final history = await service.history(collection, id);
      if (!context.mounted || !identical(service, repo.arsenalSync)) return;
      final chosen = await showDialog<ArsenalVersion>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Versiones del respaldo'),
          children: history.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No hay versiones respaldadas para este registro.',
                    ),
                  ),
                ]
              : history
                    .map(
                      (version) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, version),
                        child: Text(
                          '${version.kind == 'conflict' ? 'Alternativa en conflicto' : 'Versión respaldada'} · ${version.record.revision}\n${describeArsenalPayload(version.record.payload)}',
                        ),
                      ),
                    )
                    .toList(),
        ),
      );
      if (chosen == null ||
          !context.mounted ||
          !identical(service, repo.arsenalSync))
        return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restaurar esta versión'),
          content: const Text(
            'Se guardará como una nueva revisión de la misma bola o mantenimiento. El historial respaldado se conserva. Si hay cambios locales pendientes, primero debes respaldarlos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restaurar'),
            ),
          ],
        ),
      );
      if (confirm != true || !identical(service, repo.arsenalSync)) return;
      await service.restoreVersion(collection, chosen);
      await onRestored();
      await repo.sincronizarArsenal();
    } catch (error) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo completar la operación. Las copias se conservan. $error',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Versiones del respaldo',
    icon: const Icon(Icons.history),
    onPressed:
        context.watch<DataRepository>().arsenalUserId == null ||
            !context.read<DataRepository>().arsenalBackupEnabled
        ? null
        : () => _open(context),
  );
}
