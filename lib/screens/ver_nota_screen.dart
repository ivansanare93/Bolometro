import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/nota.dart';
import '../models/sesion.dart';
import '../repositories/data_repository.dart';
import '../l10n/app_localizations.dart';
import 'editar_nota_screen.dart';
import 'ver_sesion.dart';

class VerNotaScreen extends StatefulWidget {
  final Nota nota;

  const VerNotaScreen({super.key, required this.nota});

  @override
  State<VerNotaScreen> createState() => _VerNotaScreenState();
}

class _VerNotaScreenState extends State<VerNotaScreen> {
  late Nota nota;
  String? _relatedSessionLabel;
  Sesion? _relatedSession;

  @override
  void initState() {
    super.initState();
    nota = widget.nota;
    _cargarReferenciaSesion();
  }

  String _formatFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  Future<void> _cargarReferenciaSesion() async {
    final relatedSessionId = nota.relatedSessionId;
    if (relatedSessionId == null || relatedSessionId.isEmpty) return;

    try {
      final repo = Provider.of<DataRepository>(context, listen: false);
      final sesiones = await repo.obtenerSesiones();
      for (final sesion in sesiones) {
        final id = sesion.fecha.millisecondsSinceEpoch.toString();
        if (id == relatedSessionId) {
          if (!mounted) return;
          setState(() {
            _relatedSession = sesion;
            final date = DateFormat('dd/MM/yyyy').format(sesion.fecha);
            final place = sesion.lugar.trim().isEmpty
                ? AppLocalizations.of(context)!.noLocation
                : sesion.lugar;
            _relatedSessionLabel = '$date • $place';
          });
          return;
        }
      }
    } catch (_) {
      // Keep fallback text with session id.
    }
  }

  Future<void> _togglePinned() async {
    final repo = Provider.of<DataRepository>(context, listen: false);
    setState(() => nota.pinned = !nota.pinned);
    await repo.actualizarNota(nota);
  }

  Future<void> _toggleArchived() async {
    final repo = Provider.of<DataRepository>(context, listen: false);
    setState(() => nota.archivada = !nota.archivada);
    await repo.actualizarNota(nota);
  }

  Future<void> _abrirSesionRelacionada() async {
    if (_relatedSession == null) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => VerSesion(sesion: _relatedSession!),
      ),
    );
    if (!mounted) return;
    await _cargarReferenciaSesion();
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

  String _typeLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case NotaTipo.tecnica:
        return l10n.noteTypeTechnique;
      case NotaTipo.pista:
        return l10n.noteTypeLane;
      case NotaTipo.aceite:
        return l10n.noteTypeOil;
      case NotaTipo.equipamiento:
        return l10n.noteTypeEquipment;
      case NotaTipo.mental:
        return l10n.noteTypeMental;
      case NotaTipo.review:
      default:
        return l10n.noteTypeReview;
    }
  }

  String _statusLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case NotaEstado.pendiente:
        return l10n.noteStatusPending;
      case NotaEstado.probado:
        return l10n.noteStatusTested;
      case NotaEstado.validado:
        return l10n.noteStatusValidated;
      case NotaEstado.descartado:
        return l10n.noteStatusDiscarded;
      default:
        return l10n.noteStatusPending;
    }
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
          IconButton(
            icon: Icon(nota.pinned ? Icons.push_pin : Icons.push_pin_outlined),
            tooltip: nota.pinned ? l10n.noteUnpin : l10n.notePin,
            onPressed: _togglePinned,
          ),
          IconButton(
            icon: Icon(
              nota.archivada ? Icons.unarchive_outlined : Icons.archive_outlined,
            ),
            tooltip: nota.archivada ? l10n.noteUnarchive : l10n.noteArchive,
            onPressed: _toggleArchived,
          ),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (nota.categoria != null)
                  Chip(
                    avatar: const Icon(Icons.label_outline, size: 16),
                    label: Text(_categoryLabel(context, nota.categoria)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                Chip(
                  avatar: const Icon(Icons.category_outlined, size: 16),
                  label: Text(_typeLabel(context, nota.tipo)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  avatar: nota.estado == NotaEstado.validado
                      ? const Icon(Icons.verified_outlined, size: 16)
                      : nota.estado == NotaEstado.descartado
                          ? const Icon(Icons.block_outlined, size: 16)
                          : const Icon(Icons.pending_actions_outlined, size: 16),
                  label: Text(_statusLabel(context, nota.estado)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (nota.pinned)
                  Chip(
                    avatar: const Icon(Icons.push_pin, size: 16),
                    label: Text(l10n.notePinned),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                if (nota.archivada)
                  Chip(
                    avatar: const Icon(Icons.archive_outlined, size: 16),
                    label: Text(l10n.noteArchived),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            if ((nota.bolera ?? '').isNotEmpty ||
                (nota.patronAceite ?? '').isNotEmpty ||
                (nota.equipamientoUsado ?? '').isNotEmpty ||
                (nota.condicionPista ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.noteContext,
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      if ((nota.bolera ?? '').isNotEmpty)
                        Text('${l10n.noteBowlingAlley}: ${nota.bolera}'),
                      if ((nota.patronAceite ?? '').isNotEmpty)
                        Text('${l10n.noteOilPattern}: ${nota.patronAceite}'),
                      if ((nota.equipamientoUsado ?? '').isNotEmpty)
                        Text('${l10n.noteBallOrEquipment}: ${nota.equipamientoUsado}'),
                      if ((nota.condicionPista ?? '').isNotEmpty)
                        Text('${l10n.noteLaneCondition}: ${nota.condicionPista}'),
                    ],
                  ),
                ),
              ),
            ],
            if (nota.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: nota.tags
                    .map(
                      (tag) => Chip(
                        label: Text('#$tag'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (nota.relatedSessionId != null && nota.relatedSessionId!.isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _relatedSession == null ? null : _abrirSesionRelacionada,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 14, color: cs.outline),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${l10n.noteRelatedSession}: ${_relatedSessionLabel ?? nota.relatedSessionId}',
                          style: textTheme.bodySmall?.copyWith(color: cs.outline),
                        ),
                      ),
                      if (_relatedSession != null)
                        Icon(Icons.open_in_new_rounded, size: 16, color: cs.outline),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
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
