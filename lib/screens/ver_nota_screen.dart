import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/nota.dart';
import '../repositories/data_repository.dart';
import '../l10n/app_localizations.dart';
import 'editar_nota_screen.dart';

class VerNotaScreen extends StatelessWidget {
  final Nota nota;

  const VerNotaScreen({super.key, required this.nota});

  String _formatFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteNoteConfirm),
        content: Text(nota.titulo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      final repo = Provider.of<DataRepository>(context, listen: false);
      await repo.eliminarNota(nota);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noteDeleted),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.viewNote),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.editNote,
            onPressed: () async {
              final resultado = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditarNotaScreen(nota: nota),
                ),
              );
              if (resultado == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error),
            tooltip: l10n.delete,
            onPressed: () => _confirmarEliminar(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                nota.titulo,
                style: textTheme.headlineSmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Dates row
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: cs.outline),
                const SizedBox(width: 4),
                Text(
                  '${l10n.created}: ${_formatFecha(nota.fechaCreacion)}',
                  style: textTheme.bodySmall?.copyWith(color: cs.outline),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.edit_calendar_outlined, size: 14, color: cs.outline),
                const SizedBox(width: 4),
                Text(
                  '${l10n.modified}: ${_formatFecha(nota.fechaModificacion)}',
                  style: textTheme.bodySmall?.copyWith(color: cs.outline),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Content
            if (nota.contenido.isNotEmpty)
              Text(
                nota.contenido,
                style: textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    l10n.noteContentHint,
                    style: textTheme.bodyMedium?.copyWith(
                      color: cs.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => EditarNotaScreen(nota: nota),
            ),
          );
          if (resultado == true && context.mounted) {
            Navigator.pop(context, true);
          }
        },
        icon: const Icon(Icons.edit),
        label: Text(l10n.editNote),
      ),
    );
  }
}
