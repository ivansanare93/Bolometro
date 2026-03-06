import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/nota.dart';
import '../repositories/data_repository.dart';
import '../l10n/app_localizations.dart';
import 'editar_nota_screen.dart';

class NotasScreen extends StatefulWidget {
  const NotasScreen({super.key});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  List<Nota> _notas = [];
  List<Nota> _notasFiltradas = [];
  bool _cargando = true;
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarNotas();
    _busquedaController.addListener(_filtrarNotas);
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarNotas() async {
    setState(() => _cargando = true);
    final repo = Provider.of<DataRepository>(context, listen: false);
    final notas = await repo.obtenerNotas();
    if (mounted) {
      setState(() {
        _notas = notas;
        _notasFiltradas = _aplicarFiltro(notas);
        _cargando = false;
      });
    }
  }

  List<Nota> _aplicarFiltro(List<Nota> notas) {
    final query = _busquedaController.text.trim().toLowerCase();
    if (query.isEmpty) return notas;
    return notas.where((n) {
      return n.titulo.toLowerCase().contains(query) ||
          n.contenido.toLowerCase().contains(query);
    }).toList();
  }

  void _filtrarNotas() {
    setState(() {
      _notasFiltradas = _aplicarFiltro(_notas);
    });
  }

  Future<void> _abrirEditar({Nota? nota}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarNotaScreen(nota: nota),
      ),
    );
    if (resultado == true) {
      await _cargarNotas();
    }
  }

  Future<void> _confirmarEliminar(Nota nota) async {
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

    if (confirmar == true && mounted) {
      final repo = Provider.of<DataRepository>(context, listen: false);
      await repo.eliminarNota(nota);
      await _cargarNotas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noteDeleted),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notebook),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: l10n.searchNotes,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busquedaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busquedaController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _notasFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('📓', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              l10n.noNotes,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (_busquedaController.text.isEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                l10n.noNotesHint,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _notasFiltradas.length,
                        itemBuilder: (context, index) {
                          final nota = _notasFiltradas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 4,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                nota.titulo,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (nota.contenido.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      nota.contenido,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    '${l10n.modified}: ${_formatFecha(nota.fechaModificacion)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: cs.outline),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: cs.error),
                                tooltip: l10n.delete,
                                onPressed: () => _confirmarEliminar(nota),
                              ),
                              onTap: () => _abrirEditar(nota: nota),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirEditar(),
        tooltip: l10n.newNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}
