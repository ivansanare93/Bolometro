import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/nota.dart';
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

class EditarNotaScreen extends StatefulWidget {
  final Nota? nota;

  const EditarNotaScreen({super.key, this.nota});

  @override
  State<EditarNotaScreen> createState() => _EditarNotaScreenState();
}

class _EditarNotaScreenState extends State<EditarNotaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _contenidoController;
  bool _guardando = false;

  String? _categoria;
  bool _favorita = false;
  int? _colorValue;

  bool get _esNueva => widget.nota == null;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.nota?.titulo ?? '');
    _contenidoController =
        TextEditingController(text: widget.nota?.contenido ?? '');
    _categoria = widget.nota?.categoria;
    _favorita = widget.nota?.favorita ?? false;
    _colorValue = widget.nota?.colorValue;
    _contenidoController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final repo = Provider.of<DataRepository>(context, listen: false);
      final ahora = DateTime.now();

      if (_esNueva) {
        final nuevaNota = Nota(
          titulo: _tituloController.text.trim(),
          contenido: _contenidoController.text.trim(),
          fechaCreacion: ahora,
          fechaModificacion: ahora,
          categoria: _categoria,
          favorita: _favorita,
          colorValue: _colorValue,
        );
        await repo.guardarNota(nuevaNota);
      } else {
        widget.nota!.titulo = _tituloController.text.trim();
        widget.nota!.contenido = _contenidoController.text.trim();
        widget.nota!.fechaModificacion = ahora;
        widget.nota!.categoria = _categoria;
        widget.nota!.favorita = _favorita;
        widget.nota!.colorValue = _colorValue;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_esNueva ? l10n.newNote : l10n.editNote),
        centerTitle: true,
        actions: [
          // Favourite toggle
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
            // ── Title ──────────────────────────────────────────────────────
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

            // ── Category ───────────────────────────────────────────────────
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
                  // "None" chip
                  ChoiceChip(
                    label: Text(l10n.noteCategoryNone),
                    selected: _categoria == null,
                    onSelected: (_) => setState(() => _categoria = null),
                  ),
                  ...NotaCategoria.values.map((key) => ChoiceChip(
                        label: Text(_categoryLabel(context, key)),
                        selected: _categoria == key,
                        onSelected: (_) => setState(() => _categoria = key),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Color ──────────────────────────────────────────────────────
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
                  // "No colour" option
                  GestureDetector(
                    onTap: () => setState(() => _colorValue = null),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _colorValue == null
                              ? cs.primary
                              : cs.outlineVariant,
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

            // ── Content ────────────────────────────────────────────────────
            TextFormField(
              controller: _contenidoController,
              decoration: InputDecoration(
                labelText: l10n.noteContent,
                hintText: l10n.noteContentHint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                helperText: wordCount > 0 ? l10n.noteWordCount(wordCount) : null,
                helperStyle:
                    TextStyle(color: cs.outline, fontSize: 12),
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
