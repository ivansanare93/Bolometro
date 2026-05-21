import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
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

  String _label(BuildContext context, String es, String en) {
    return Localizations.localeOf(context).languageCode == 'es' ? es : en;
  }

  String _buildShareText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final metadata = <String>[
      if (nota.categoria != null)
        '${l10n.noteCategory}: ${_categoryLabel(context, nota.categoria)}',
      '${l10n.noteType}: ${_typeLabel(context, nota.tipo)}',
      '${l10n.noteStatus}: ${_statusLabel(context, nota.estado)}',
      if ((nota.bolera ?? '').isNotEmpty) '${l10n.noteBowlingAlley}: ${nota.bolera}',
      if ((nota.patronAceite ?? '').isNotEmpty) '${l10n.noteOilPattern}: ${nota.patronAceite}',
      if ((nota.equipamientoUsado ?? '').isNotEmpty)
        '${l10n.noteBallOrEquipment}: ${nota.equipamientoUsado}',
      if ((nota.condicionPista ?? '').isNotEmpty)
        '${l10n.noteLaneCondition}: ${nota.condicionPista}',
      if (nota.tags.isNotEmpty) 'Tags: ${nota.tags.map((t) => '#$t').join(' ')}',
      '${l10n.modified}: ${_formatFecha(nota.fechaModificacion)}',
    ];
    return '${nota.titulo}\n\n${nota.contenido}\n\n${metadata.join('\n')}';
  }

  Future<void> _compartirNota() async {
    await Share.share(_buildShareText(context), subject: nota.titulo);
  }

  String _buildMarkdown(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final b = StringBuffer();
    b.writeln('# ${nota.titulo}');
    b.writeln();
    b.writeln('- ${l10n.created}: ${_formatFecha(nota.fechaCreacion)}');
    b.writeln('- ${l10n.modified}: ${_formatFecha(nota.fechaModificacion)}');
    b.writeln('- ${l10n.noteType}: ${_typeLabel(context, nota.tipo)}');
    b.writeln('- ${l10n.noteStatus}: ${_statusLabel(context, nota.estado)}');
    if (nota.categoria != null) {
      b.writeln('- ${l10n.noteCategory}: ${_categoryLabel(context, nota.categoria)}');
    }
    if (nota.tags.isNotEmpty) {
      b.writeln('- Tags: ${nota.tags.map((t) => '#$t').join(' ')}');
    }
    if (nota.revisarAntesProximaSesion) {
      b.writeln(
        '- ${_label(context, 'Revisar antes de próxima sesión', 'Review before next session')}: ✅',
      );
    }
    if (nota.fechaRevision != null) {
      b.writeln('- ${_label(context, 'Fecha de revisión', 'Review date')}: ${DateFormat('dd/MM/yyyy').format(nota.fechaRevision!)}');
    }
    b.writeln();
    b.writeln('## ${l10n.noteContent}');
    b.writeln();
    b.writeln(nota.contenido.isEmpty ? '-' : nota.contenido);
    return b.toString();
  }

  Future<void> _exportarMarkdown() async {
    final dir = await getTemporaryDirectory();
    final safeName =
        nota.titulo.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final file = File('${dir.path}/nota_${safeName.isEmpty ? nota.id : safeName}.md');
    await file.writeAsString(_buildMarkdown(context));
    await Share.shareXFiles([XFile(file.path)], text: nota.titulo);
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
          PopupMenuButton<String>(
            tooltip: _label(context, 'Compartir/Exportar', 'Share/Export'),
            onSelected: (value) async {
              if (value == 'share') {
                await _compartirNota();
              } else if (value == 'export') {
                await _exportarMarkdown();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share',
                child: Text(l10n.share),
              ),
              PopupMenuItem(
                value: 'export',
                child: Text(l10n.export),
              ),
            ],
          ),
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
            if (nota.adjuntos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _label(context, 'Adjuntos', 'Attachments'),
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: nota.adjuntos.map((adjunto) {
                  final localExists = adjunto.localPath.isNotEmpty &&
                      File(adjunto.localPath).existsSync();
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 92,
                      height: 92,
                      child: localExists
                          ? Image.file(File(adjunto.localPath), fit: BoxFit.cover)
                          : (adjunto.remoteUrl ?? '').isNotEmpty
                              ? Image.network(
                                  adjunto.remoteUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: cs.surfaceVariant,
                                    child: const Icon(Icons.broken_image_outlined),
                                  ),
                                )
                              : Container(
                                  color: cs.surfaceVariant,
                                  child: const Icon(Icons.image_not_supported_outlined),
                                ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (nota.revisarAntesProximaSesion || nota.fechaRevision != null) ...[
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label(context, 'Revisión', 'Review'),
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (nota.revisarAntesProximaSesion)
                        Text(
                          _label(
                            context,
                            'Marcada para revisar antes de próxima sesión',
                            'Marked to review before next session',
                          ),
                        ),
                      if (nota.fechaRevision != null)
                        Text(
                          '${_label(context, 'Fecha de revisión', 'Review date')}: ${DateFormat('dd/MM/yyyy').format(nota.fechaRevision!)}',
                        ),
                    ],
                  ),
                ),
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
