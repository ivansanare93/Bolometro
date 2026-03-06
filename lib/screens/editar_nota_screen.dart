import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/nota.dart';
import '../repositories/data_repository.dart';
import '../l10n/app_localizations.dart';

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

  bool get _esNueva => widget.nota == null;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.nota?.titulo ?? '');
    _contenidoController =
        TextEditingController(text: widget.nota?.contenido ?? '');
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
        );
        await repo.guardarNota(nuevaNota);
      } else {
        widget.nota!.titulo = _tituloController.text.trim();
        widget.nota!.contenido = _contenidoController.text.trim();
        widget.nota!.fechaModificacion = ahora;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esNueva ? l10n.newNote : l10n.editNote),
        centerTitle: true,
        actions: [
          if (_guardando)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
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
            TextFormField(
              controller: _contenidoController,
              decoration: InputDecoration(
                labelText: l10n.noteContent,
                hintText: l10n.noteContentHint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
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
