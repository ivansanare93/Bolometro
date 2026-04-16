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

  String _categoryLabel(BuildContext context, String? key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case NotaCategoria.general:
        return l10n.noteCategoryGeneral;
      case NotaCategoria.aceite:
        return l10n.noteCategoryOil;
      case NotaCategoria.tecnica:
        return l10n.noteCategoryTechnique;
      case NotaCategoria.equipamiento:
        return l10n.noteCategoryEquipment;
      case NotaCategoria.mental:
        return l10n.noteCategoryMental;
      case NotaCategoria.bolera:
        return l10n.noteCategoryAlley;
      default:
        return l10n.noteCategoryNone;
    }
  }

  Color _accentColor(BuildContext context) {
    if (nota.colorValue != null) {
      return Color(nota.colorValue! | 0xFF000000);
    }
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = _accentColor(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.viewNote),
        centerTitle: true,
        actions: [
          // Favourite indicator (read-only; tap to go to edit)
          if (nota.favorita)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.star_rounded, color: Colors.amber),
            ),
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
            // Title heading with accent bar
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      nota.titulo,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Category chip
            if (nota.categoria != null) ...[
              Chip(
                avatar: const Icon(Icons.label_outline, size: 16),
                label: Text(_categoryLabel(context, nota.categoria)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(height: 8),
            ],

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
