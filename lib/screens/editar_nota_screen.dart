import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final wordCount = _wordCount(_contenidoController.text);

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
        title: Text(_esNueva ? l10n.newNote : l10n.editNote),
        centerTitle: true,
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
          else
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: l10n.save,
              onPressed: _guardar,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_esNueva) ...[
              Text(
                l10n.noteTemplates,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kNoteTemplates
                    .map(
                      (template) => ActionChip(
                        avatar: const Icon(Icons.auto_awesome, size: 18),
                        label: Text(template.name(l10n)),
                        onPressed: () => _aplicarPlantilla(template),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _tituloController,
              decoration: InputDecoration(
                labelText: l10n.noteTitle,
                hintText: l10n.noteTitleHint,
                border: const OutlineInputBorder(),
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
              decoration: InputDecoration(
                labelText: l10n.noteCategory,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
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
              decoration: InputDecoration(
                labelText: l10n.noteType,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
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
              decoration: InputDecoration(
                labelText: l10n.noteStatus,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _boleraController,
              decoration: InputDecoration(
                labelText: l10n.noteBowlingAlley,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _patronAceiteController,
              decoration: InputDecoration(
                labelText: l10n.noteOilPattern,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _equipamientoController,
              decoration: InputDecoration(
                labelText: l10n.noteBallOrEquipment,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _condicionPistaController,
              decoration: InputDecoration(
                labelText: l10n.noteLaneCondition,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: l10n.noteTags,
                hintText: l10n.noteTagsHint,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.noteRelatedSession,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _archivada,
              onChanged: (v) => setState(() => _archivada = v),
              title: Text(l10n.noteArchived),
              subtitle: Text(l10n.noteArchivedHint),
            ),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.noteColorLabel,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _colorValue = null),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              _colorValue == null ? cs.primary : cs.outlineVariant,
                          width: _colorValue == null ? 3 : 1.5,
                        ),
                        color: cs.surface,
                      ),
                      child: Icon(Icons.format_color_reset_outlined,
                          size: 16, color: cs.outline),
                    ),
                  ),
                  ..._kNoteColors.map((c) {
                    final selected = _colorValue == c;
                    return GestureDetector(
                      onTap: () => setState(() => _colorValue = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(c | 0xFF000000),
                          border: Border.all(
                            color: selected ? cs.primary : cs.outlineVariant,
                            width: selected ? 3 : 1.5,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.black54)
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contenidoController,
              decoration: InputDecoration(
                labelText: l10n.noteContent,
                hintText: l10n.noteContentHint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                helperText: wordCount > 0 ? l10n.noteWordCount(wordCount) : null,
                helperStyle: TextStyle(color: cs.outline, fontSize: 12),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              minLines: 8,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
      ),
    );
  }
}
