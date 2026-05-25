import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/nota.dart';
import '../models/sesion.dart';
import '../repositories/data_repository.dart';
import '../l10n/app_localizations.dart';

/// Predefined accent colours for notes.
const List<int> _kNoteColors = [
  0xFFEF9A9A, // red
  0xFFFFCC80, // orange
  0xFFFFF59D, // yellow
  0xFFA5D6A7, // green
  0xFF90CAF9, // blue
  0xFFCE93D8, // purple
  0xFFB0BEC5, // grey-blue
];

// Default review time to keep reminders visible early in the day.
const int _kDefaultReviewHour = 9;
const int _kAttachmentIdRandomBound = 1 << 20;
final Random _attachmentIdRandom = Random();

class _NoteTemplate {
  final String id;
  final String Function(AppLocalizations l10n) name;
  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n) content;
  final String category;
  final List<String> tags;

  const _NoteTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
  });
}

const List<_NoteTemplate> _kNoteTemplates = [
  _NoteTemplate(
    id: 'tecnica',
    name: _templateTechniqueName,
    title: _templateTechniqueTitle,
    content: _templateTechniqueContent,
    category: NotaCategoria.tecnica,
    tags: ['tecnica', 'timing', 'ejecucion'],
  ),
  _NoteTemplate(
    id: 'pista',
    name: _templateLaneName,
    title: _templateLaneTitle,
    content: _templateLaneContent,
    category: NotaCategoria.aceite,
    tags: ['pista', 'lectura', 'transicion'],
  ),
  _NoteTemplate(
    id: 'aceite',
    name: _templateOilName,
    title: _templateOilTitle,
    content: _templateOilContent,
    category: NotaCategoria.aceite,
    tags: ['aceite', 'patron', 'linea'],
  ),
  _NoteTemplate(
    id: 'equipamiento',
    name: _templateEquipmentName,
    title: _templateEquipmentTitle,
    content: _templateEquipmentContent,
    category: NotaCategoria.equipamiento,
    tags: ['equipamiento', 'bola', 'ajuste'],
  ),
  _NoteTemplate(
    id: 'review',
    name: _templateReviewName,
    title: _templateReviewTitle,
    content: _templateReviewContent,
    category: NotaCategoria.general,
    tags: ['review', 'sesion', 'aprendizaje'],
  ),
];

String _templateTechniqueName(AppLocalizations l10n) => l10n.noteTemplateTechnique;
String _templateTechniqueTitle(AppLocalizations l10n) => l10n.noteTemplateTechniqueTitle;
String _templateTechniqueContent(AppLocalizations l10n) => l10n.noteTemplateTechniqueContent;
String _templateLaneName(AppLocalizations l10n) => l10n.noteTemplateLaneRead;
String _templateLaneTitle(AppLocalizations l10n) => l10n.noteTemplateLaneReadTitle;
String _templateLaneContent(AppLocalizations l10n) => l10n.noteTemplateLaneReadContent;
String _templateOilName(AppLocalizations l10n) => l10n.noteTemplateOilPattern;
String _templateOilTitle(AppLocalizations l10n) => l10n.noteTemplateOilPatternTitle;
String _templateOilContent(AppLocalizations l10n) => l10n.noteTemplateOilPatternContent;
String _templateEquipmentName(AppLocalizations l10n) => l10n.noteTemplateEquipmentAdjust;
String _templateEquipmentTitle(AppLocalizations l10n) => l10n.noteTemplateEquipmentAdjustTitle;
String _templateEquipmentContent(AppLocalizations l10n) => l10n.noteTemplateEquipmentAdjustContent;
String _templateReviewName(AppLocalizations l10n) => l10n.noteTemplatePostReview;
String _templateReviewTitle(AppLocalizations l10n) => l10n.noteTemplatePostReviewTitle;
String _templateReviewContent(AppLocalizations l10n) => l10n.noteTemplatePostReviewContent;

class EditarNotaScreen extends StatefulWidget {
  final Nota? nota;
  final String? initialRelatedSessionId;
  final String? initialTemplateId;

  const EditarNotaScreen({
    super.key,
    this.nota,
    this.initialRelatedSessionId,
    this.initialTemplateId,
  });

  @override
  State<EditarNotaScreen> createState() => _EditarNotaScreenState();
}

class _EditarNotaScreenState extends State<EditarNotaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _contenidoController;
  late TextEditingController _tagsController;
  late TextEditingController _boleraController;
  late TextEditingController _patronAceiteController;
  late TextEditingController _equipamientoController;
  late TextEditingController _condicionPistaController;
  bool _guardando = false;

  String? _categoria;
  String _tipo = NotaTipo.review;
  String _estado = NotaEstado.pendiente;
  bool _favorita = false;
  bool _pinned = false;
  bool _archivada = false;
  int? _colorValue;
  String? _relatedSessionId;
  List<NotaAdjunto> _adjuntos = [];
  bool _revisarAntesProximaSesion = false;
  DateTime? _fechaRevision;
  int _attachmentCounter = 0;
  bool _cargandoSesiones = true;
  List<Sesion> _sesiones = [];

  bool get _esNueva => widget.nota == null;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.nota?.titulo ?? '');
    _contenidoController = TextEditingController(text: widget.nota?.contenido ?? '');
    _tagsController =
        TextEditingController(text: (widget.nota?.tags ?? const []).join(', '));
    _boleraController = TextEditingController(text: widget.nota?.bolera ?? '');
    _patronAceiteController =
        TextEditingController(text: widget.nota?.patronAceite ?? '');
    _equipamientoController =
        TextEditingController(text: widget.nota?.equipamientoUsado ?? '');
    _condicionPistaController =
        TextEditingController(text: widget.nota?.condicionPista ?? '');
    _categoria = widget.nota?.categoria;
    _tipo = widget.nota?.tipo ?? NotaTipo.review;
    _estado = widget.nota?.estado ?? NotaEstado.pendiente;
    _favorita = widget.nota?.favorita ?? false;
    _pinned = widget.nota?.pinned ?? false;
    _archivada = widget.nota?.archivada ?? false;
    _colorValue = widget.nota?.colorValue;
    _relatedSessionId = widget.nota?.relatedSessionId ?? widget.initialRelatedSessionId;
    _adjuntos = (widget.nota?.adjuntos ?? const <NotaAdjunto>[])
        .map((a) => a.copyWith())
        .toList();
    _revisarAntesProximaSesion =
        widget.nota?.revisarAntesProximaSesion ?? false;
    _fechaRevision = widget.nota?.fechaRevision;
    _contenidoController.addListener(() => setState(() {}));
    _cargarSesiones();

    if (_esNueva && widget.initialTemplateId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _NoteTemplate? template;
        for (final t in _kNoteTemplates) {
          if (t.id == widget.initialTemplateId) {
            template = t;
            break;
          }
        }
        if (template != null && mounted) {
          _aplicarPlantilla(template);
        }
      });
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    _tagsController.dispose();
    _boleraController.dispose();
    _patronAceiteController.dispose();
    _equipamientoController.dispose();
    _condicionPistaController.dispose();
    super.dispose();
  }

  Future<void> _cargarSesiones() async {
    try {
      final repo = Provider.of<DataRepository>(context, listen: false);
      final sesiones = await repo.obtenerSesiones();
      sesiones.sort((a, b) => b.fecha.compareTo(a.fecha));
      if (!mounted) return;
      setState(() {
        _sesiones = sesiones;
        _cargandoSesiones = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sesiones = [];
        _cargandoSesiones = false;
      });
    }
  }

  List<String> _parseTags() {
    return Nota.normalizeTagsFromText(_tagsController.text);
  }

  String _label(BuildContext context, String es, String en) {
    return Localizations.localeOf(context).languageCode == 'es' ? es : en;
  }

  Future<void> _agregarAdjuntosImagen() async {
    final picker = ImagePicker();
    final selected = await picker.pickMultiImage(imageQuality: 80);
    if (selected.isEmpty || !mounted) return;
    setState(() {
      final existingPaths = _adjuntos.map((a) => a.localPath).toSet();
      for (final file in selected) {
        if (existingPaths.contains(file.path)) continue;
        _attachmentCounter++;
        _adjuntos.add(
          NotaAdjunto(
            id:
                'att_${DateTime.now().microsecondsSinceEpoch}_${file.path.hashCode}_${_attachmentCounter}_${_attachmentIdRandom.nextInt(_kAttachmentIdRandomBound)}',
            tipo: NotaAdjuntoTipo.imagen,
            localPath: file.path,
            createdAt: DateTime.now(),
          ),
        );
      }
    });
  }

  void _eliminarAdjunto(NotaAdjunto adjunto) {
    setState(() {
      _adjuntos.removeWhere((a) => a.id == adjunto.id);
    });
  }

  Future<void> _seleccionarFechaRevision() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _fechaRevision ?? now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _fechaRevision = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _kDefaultReviewHour,
      );
      _revisarAntesProximaSesion = true;
    });
  }

  String _sessionIdFromSesion(Sesion sesion) =>
      sesion.fecha.millisecondsSinceEpoch.toString();

  String _sessionLabel(BuildContext context, Sesion sesion) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat('dd/MM/yyyy').format(sesion.fecha);
    final place = sesion.lugar.trim().isEmpty ? l10n.noLocation : sesion.lugar;
    return '$date • $place';
  }

  String _defaultTipoForCategory(String category) {
    switch (category) {
      case NotaCategoria.tecnica:
        return NotaTipo.tecnica;
      case NotaCategoria.aceite:
        return NotaTipo.aceite;
      case NotaCategoria.equipamiento:
        return NotaTipo.equipamiento;
      case NotaCategoria.mental:
        return NotaTipo.mental;
      case NotaCategoria.bolera:
        return NotaTipo.pista;
      default:
        return NotaTipo.review;
    }
  }

  void _aplicarPlantilla(_NoteTemplate template) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _tituloController.text = template.title(l10n);
      _contenidoController.text = template.content(l10n);
      _categoria = template.category;
      _tipo = NotaTipo.values.contains(template.id)
          ? template.id
          : _defaultTipoForCategory(template.category);
      _tagsController.text = template.tags.join(', ');
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final repo = Provider.of<DataRepository>(context, listen: false);
      final ahora = DateTime.now();
      final tags = _parseTags();

      if (_esNueva) {
        final nuevaNota = Nota(
          titulo: _tituloController.text.trim(),
          contenido: _contenidoController.text.trim(),
          fechaCreacion: ahora,
          fechaModificacion: ahora,
          categoria: _categoria,
          favorita: _favorita,
          colorValue: _colorValue,
          tags: tags,
          pinned: _pinned,
          archivada: _archivada,
          relatedSessionId: _relatedSessionId,
          tipo: _tipo,
          estado: _estado,
          bolera: _boleraController.text.trim().isEmpty
              ? null
              : _boleraController.text.trim(),
          patronAceite: _patronAceiteController.text.trim().isEmpty
              ? null
              : _patronAceiteController.text.trim(),
          equipamientoUsado: _equipamientoController.text.trim().isEmpty
              ? null
              : _equipamientoController.text.trim(),
           condicionPista: _condicionPistaController.text.trim().isEmpty
               ? null
               : _condicionPistaController.text.trim(),
           adjuntos: _adjuntos,
           revisarAntesProximaSesion: _revisarAntesProximaSesion,
           fechaRevision: _fechaRevision,
         );
         await repo.guardarNota(nuevaNota);
       } else {
        widget.nota!.titulo = _tituloController.text.trim();
        widget.nota!.contenido = _contenidoController.text.trim();
        widget.nota!.fechaModificacion = ahora;
        widget.nota!.categoria = _categoria;
        widget.nota!.favorita = _favorita;
        widget.nota!.colorValue = _colorValue;
        widget.nota!.tags = tags;
        widget.nota!.pinned = _pinned;
        widget.nota!.archivada = _archivada;
        widget.nota!.relatedSessionId = _relatedSessionId;
        widget.nota!.tipo = _tipo;
        widget.nota!.estado = _estado;
        widget.nota!.bolera = _boleraController.text.trim().isEmpty
            ? null
            : _boleraController.text.trim();
        widget.nota!.patronAceite = _patronAceiteController.text.trim().isEmpty
            ? null
            : _patronAceiteController.text.trim();
        widget.nota!.equipamientoUsado =
            _equipamientoController.text.trim().isEmpty
            ? null
            : _equipamientoController.text.trim();
         widget.nota!.condicionPista = _condicionPistaController.text.trim().isEmpty
             ? null
             : _condicionPistaController.text.trim();
         widget.nota!.adjuntos = _adjuntos;
         widget.nota!.revisarAntesProximaSesion = _revisarAntesProximaSesion;
         widget.nota!.fechaRevision = _fechaRevision;
         // Any explicit edit is treated as a restore if the note was soft-deleted.
         widget.nota!.fechaEliminacion = null;
         await repo.actualizarNota(widget.nota!);
       }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noteSaved),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
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

  int _wordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  Color _accentColor(BuildContext context) {
    if (_colorValue != null) {
      return Color(_colorValue! | 0xFF000000);
    }
    return Theme.of(context).colorScheme.primary;
  }

  Color _onAccentColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    String? helperText,
    TextStyle? helperStyle,
    bool alignLabelWithHint = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      helperStyle: helperStyle,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark
          ? cs.surface.withOpacity(0.6)
          : Colors.white.withOpacity(0.92),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: border(cs.outlineVariant),
      enabledBorder: border(cs.outlineVariant),
      focusedBorder: border(_accentColor(context), 1.8),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? cs.surface.withOpacity(0.92)
            : Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _accentColor(context).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _accentColor(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: foregroundColor?.withOpacity(0.22) ?? cs.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final wordCount = _wordCount(_contenidoController.text);
    final accentColor = _accentColor(context);
    final onAccentColor = _onAccentColor(accentColor);
    final headerSubtitle = _esNueva
        ? _label(
            context,
            'Captura ideas, ajustes y aprendizajes de cada sesión.',
            'Capture ideas, adjustments, and learnings from each session.',
          )
        : _label(
            context,
            'Actualiza tu nota y mantén tus referencias siempre claras.',
            'Update your note and keep your references clear.',
          );

    final sessionItems = <DropdownMenuItem<String?>>[
      DropdownMenuItem<String?>(
        value: null,
        child: Text(l10n.noteNoLinkedSession),
      ),
      ..._sesiones.map(
        (s) => DropdownMenuItem<String?>(
          value: _sessionIdFromSesion(s),
          child: Text(_sessionLabel(context, s)),
        ),
      ),
    ];

    if (_relatedSessionId != null &&
        !_sesiones.any((s) => _sessionIdFromSesion(s) == _relatedSessionId)) {
      sessionItems.add(
        DropdownMenuItem<String?>(
          value: _relatedSessionId,
          child: Text(l10n.noteLinkedSessionUnknown),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(
              _pinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            tooltip: _pinned ? l10n.noteUnpin : l10n.notePin,
            onPressed: () => setState(() => _pinned = !_pinned),
          ),
          IconButton(
            icon: Icon(
              _favorita ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _favorita ? Colors.amber : null,
            ),
            tooltip: l10n.noteFavorite,
            onPressed: () => setState(() => _favorita = !_favorita),
          ),
          if (_guardando)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ElevatedButton.icon(
          onPressed: _guardando ? null : _guardar,
          icon: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline_rounded),
          label: Text(_guardando ? _label(context, 'Guardando...', 'Saving...') : l10n.save),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accentColor.withOpacity(0.14),
                cs.surface,
                cs.surface,
              ],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor,
                      Color.alphaBlend(Colors.white.withOpacity(0.08), accentColor),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.28),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            _esNueva ? Icons.note_add_rounded : Icons.edit_note_rounded,
                            color: onAccentColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _esNueva ? l10n.newNote : l10n.editNote,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: onAccentColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                headerSubtitle,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: onAccentColor.withOpacity(0.9),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildInfoChip(
                          context,
                          icon: Icons.category_rounded,
                          label: _categoria == null
                              ? l10n.noteCategoryNone
                              : _categoryLabel(context, _categoria),
                          backgroundColor: Colors.white.withOpacity(0.14),
                          foregroundColor: onAccentColor,
                        ),
                        _buildInfoChip(
                          context,
                          icon: Icons.style_rounded,
                          label: _typeLabel(context, _tipo),
                          backgroundColor: Colors.white.withOpacity(0.14),
                          foregroundColor: onAccentColor,
                        ),
                        _buildInfoChip(
                          context,
                          icon: Icons.flag_rounded,
                          label: _statusLabel(context, _estado),
                          backgroundColor: Colors.white.withOpacity(0.14),
                          foregroundColor: onAccentColor,
                        ),
                        _buildInfoChip(
                          context,
                          icon: Icons.text_fields_rounded,
                          label: wordCount > 0
                              ? l10n.noteWordCount(wordCount)
                              : _label(context, 'Sin contenido aún', 'No content yet'),
                          backgroundColor: Colors.white.withOpacity(0.14),
                          foregroundColor: onAccentColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_esNueva) ...[
                _buildSectionCard(
                  context,
                  icon: Icons.auto_awesome_rounded,
                  title: l10n.noteTemplates,
                  subtitle: _label(
                    context,
                    'Empieza más rápido con una base para cada tipo de nota.',
                    'Start faster with a base for each note type.',
                  ),
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _kNoteTemplates
                          .map(
                            (template) => ActionChip(
                              avatar: Icon(
                                Icons.bolt_rounded,
                                size: 18,
                                color: accentColor,
                              ),
                              label: Text(template.name(l10n)),
                              backgroundColor: accentColor.withOpacity(0.08),
                              side: BorderSide(
                                color: accentColor.withOpacity(0.18),
                              ),
                              onPressed: () => _aplicarPlantilla(template),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
              _buildSectionCard(
                context,
                icon: Icons.tune_rounded,
                title: _label(context, 'Resumen de la nota', 'Note overview'),
                subtitle: _label(
                  context,
                  'Define el enfoque principal para organizarla mejor.',
                  'Define the main focus to organize it better.',
                ),
                children: [
                  TextFormField(
                    controller: _tituloController,
                    decoration: _fieldDecoration(
                      context,
                      label: l10n.noteTitle,
                      hint: l10n.noteTitleHint,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 120,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.noteTitleRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: _fieldDecoration(
                      context,
                      label: l10n.noteCategory,
                    ).copyWith(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.noteCategoryNone),
                          selected: _categoria == null,
                          onSelected: (_) => setState(() => _categoria = null),
                        ),
                        ...NotaCategoria.values.map(
                          (key) => ChoiceChip(
                            label: Text(_categoryLabel(context, key)),
                            selected: _categoria == key,
                            onSelected: (_) => setState(() => _categoria = key),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: _fieldDecoration(
                      context,
                      label: l10n.noteType,
                    ).copyWith(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: NotaTipo.values
                          .map(
                            (key) => ChoiceChip(
                              label: Text(_typeLabel(context, key)),
                              selected: _tipo == key,
                              onSelected: (_) => setState(() => _tipo = key),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: _fieldDecoration(
                      context,
                      label: l10n.noteStatus,
                    ).copyWith(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: NotaEstado.values
                          .map(
                            (key) => ChoiceChip(
                              label: Text(_statusLabel(context, key)),
                              selected: _estado == key,
                              onSelected: (_) => setState(() => _estado = key),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSectionCard(
                context,
                icon: Icons.location_on_outlined,
                title: _label(context, 'Contexto y detalles', 'Context and details'),
                subtitle: _label(
                  context,
                  'Añade referencias útiles para recordar mejor cada ajuste.',
                  'Add useful references to better remember each adjustment.',
                ),
                children: [
                  TextFormField(
                    controller: _boleraController,
                    decoration: _fieldDecoration(
                      context,
                      label: l10n.noteBowlingAlley,
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _patronAceiteController,
                    decoration: _fieldDecoration(
                      context,
                      label: l10n.noteOilPattern,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _equipamientoController,
                    decoration: _fieldDecoration(
                      context,
                      label: l10n.noteBallOrEquipment,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _condicionPistaController,
                    decoration: _fieldDecoration(
                      context,
                      label: l10n.noteLaneCondition,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tagsController,
                    decoration: _fieldDecoration(
                      context,
                      label: l10n.noteTags,
                      hint: l10n.noteTagsHint,
                    ),
                    textCapitalization: TextCapitalization.none,
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: _fieldDecoration(
                      context,
                      label: l10n.noteRelatedSession,
                    ).copyWith(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    child: _cargandoSesiones
                        ? const LinearProgressIndicator(minHeight: 2)
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              isExpanded: true,
                              value: _relatedSessionId,
                              items: sessionItems,
                              onChanged: (value) {
                                setState(() => _relatedSessionId = value);
                              },
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSectionCard(
                context,
                icon: Icons.palette_outlined,
                title: _label(context, 'Recordatorios y estilo', 'Reminders and style'),
                subtitle: _label(
                  context,
                  'Personaliza la nota y destaca lo que necesitas revisar.',
                  'Customize the note and highlight what you need to review.',
                ),
                children: [
                  InputDecorator(
                    decoration: _fieldDecoration(
                      context,
                      label: _label(context, 'Adjuntos', 'Attachments'),
                    ).copyWith(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_adjuntos.isEmpty)
                          Text(
                            _label(
                              context,
                              'Añade capturas o fotos para complementar la nota.',
                              'Add screenshots or photos to complement the note.',
                            ),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _adjuntos
                                .map(
                                  (adjunto) => Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: SizedBox(
                                          width: 84,
                                          height: 84,
                                          child: File(adjunto.localPath).existsSync()
                                              ? Image.file(
                                                  File(adjunto.localPath),
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: cs.surfaceContainerHighest,
                                                  child: Icon(
                                                    Icons.image_not_supported_outlined,
                                                    color: cs.outline,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        right: -6,
                                        top: -6,
                                        child: IconButton(
                                          iconSize: 18,
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _eliminarAdjunto(adjunto),
                                          icon: const Icon(Icons.cancel_rounded),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _agregarAdjuntosImagen,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(_label(context, 'Añadir imágenes', 'Add images')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      value: _revisarAntesProximaSesion,
                      onChanged: (v) => setState(() {
                        _revisarAntesProximaSesion = v;
                        if (!v) _fechaRevision = null;
                      }),
                      title: Text(
                        _label(
                          context,
                          'Revisar antes de próxima sesión',
                          'Review before next session',
                        ),
                      ),
                    ),
                  ),
                  if (_revisarAntesProximaSesion) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _fechaRevision == null
                                  ? _label(context, 'Sin fecha de revisión', 'No review date')
                                  : '${_label(context, 'Fecha de revisión', 'Review date')}: ${DateFormat('dd/MM/yyyy').format(_fechaRevision!)}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: _seleccionarFechaRevision,
                            icon: const Icon(Icons.event_outlined),
                            label: Text(_label(context, 'Elegir fecha', 'Pick date')),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withOpacity(0.42),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      value: _archivada,
                      onChanged: (v) => setState(() => _archivada = v),
                      title: Text(l10n.noteArchived),
                      subtitle: Text(l10n.noteArchivedHint),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: _fieldDecoration(
                      context,
                      label: l10n.noteColorLabel,
                    ).copyWith(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _colorValue = null),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _colorValue == null ? accentColor : cs.outlineVariant,
                                width: _colorValue == null ? 3 : 1.5,
                              ),
                              color: cs.surface,
                            ),
                            child: Icon(
                              Icons.format_color_reset_outlined,
                              size: 18,
                              color: cs.outline,
                            ),
                          ),
                        ),
                        ..._kNoteColors.map((c) {
                          final selected = _colorValue == c;
                          return GestureDetector(
                            onTap: () => setState(() => _colorValue = c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(c | 0xFF000000),
                                border: Border.all(
                                  color: selected ? accentColor : cs.outlineVariant,
                                  width: selected ? 3 : 1.5,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: Color(c | 0xFF000000).withOpacity(0.35),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: selected
                                  ? const Icon(Icons.check, size: 18, color: Colors.black54)
                                  : null,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildSectionCard(
                context,
                icon: Icons.subject_rounded,
                title: l10n.noteContent,
                subtitle: _label(
                  context,
                  'Escribe observaciones, ideas clave y próximos pasos.',
                  'Write observations, key ideas, and next steps.',
                ),
                children: [
                  TextFormField(
                    controller: _contenidoController,
                    decoration: _fieldDecoration(
                      context,
                      label: l10n.noteContent,
                      hint: l10n.noteContentHint,
                      helperText: wordCount > 0 ? l10n.noteWordCount(wordCount) : null,
                      helperStyle: TextStyle(color: cs.outline, fontSize: 12),
                      alignLabelWithHint: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    minLines: 8,
                    keyboardType: TextInputType.multiline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
