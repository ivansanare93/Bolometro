import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/nota.dart';
import '../repositories/data_repository.dart';
import '../l10n/app_localizations.dart';
import 'editar_nota_screen.dart';
import 'ver_nota_screen.dart';
import 'home.dart';

enum _SortMode { newest, oldest, title, favFirst }

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

  String? _categoriaFiltro; // null = all
  _SortMode _sortMode = _SortMode.newest;

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
        _notasFiltradas = _aplicarFiltroYOrden(notas);
        _cargando = false;
      });
    }
  }

  List<Nota> _aplicarFiltroYOrden(List<Nota> notas) {
    final query = _busquedaController.text.trim().toLowerCase();
    List<Nota> resultado = notas.where((n) {
      final matchQuery = query.isEmpty ||
          n.titulo.toLowerCase().contains(query) ||
          n.contenido.toLowerCase().contains(query);
      final matchCategoria =
          _categoriaFiltro == null || n.categoria == _categoriaFiltro;
      return matchQuery && matchCategoria;
    }).toList();

    switch (_sortMode) {
      case _SortMode.newest:
        resultado.sort((a, b) => b.fechaModificacion.compareTo(a.fechaModificacion));
        break;
      case _SortMode.oldest:
        resultado.sort((a, b) => a.fechaModificacion.compareTo(b.fechaModificacion));
        break;
      case _SortMode.title:
        resultado.sort((a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()));
        break;
      case _SortMode.favFirst:
        resultado.sort((a, b) {
          if (a.favorita == b.favorita) {
            return b.fechaModificacion.compareTo(a.fechaModificacion);
          }
          return a.favorita ? -1 : 1;
        });
        break;
    }
    return resultado;
  }

  void _filtrarNotas() {
    setState(() {
      _notasFiltradas = _aplicarFiltroYOrden(_notas);
    });
  }

  Future<void> _abrirNueva() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const EditarNotaScreen(),
      ),
    );
    if (resultado == true) {
      await _cargarNotas();
    }
  }

  Future<void> _abrirVer(Nota nota) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VerNotaScreen(nota: nota),
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

  Future<void> _completarEliminacion(Nota nota) async {
    final l10n = AppLocalizations.of(context)!;
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

  String _formatFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  /// Returns all distinct categories used across all notes.
  List<String> get _categoriasUsadas {
    return _notas
        .map((n) => n.categoria)
        .whereType<String>()
        .toSet()
        .toList();
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

  Color _accentColor(BuildContext context, Nota nota) {
    if (nota.colorValue != null) {
      return Color(nota.colorValue! | 0xFF000000);
    }
    return Theme.of(context).colorScheme.primary;
  }

  void _mostrarSortDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.sortNotes),
        children: [
          _SortTile(
            label: l10n.sortNewest,
            icon: Icons.arrow_downward,
            selected: _sortMode == _SortMode.newest,
            onTap: () {
              setState(() {
                _sortMode = _SortMode.newest;
                _notasFiltradas = _aplicarFiltroYOrden(_notas);
              });
              Navigator.pop(ctx);
            },
          ),
          _SortTile(
            label: l10n.sortOldest,
            icon: Icons.arrow_upward,
            selected: _sortMode == _SortMode.oldest,
            onTap: () {
              setState(() {
                _sortMode = _SortMode.oldest;
                _notasFiltradas = _aplicarFiltroYOrden(_notas);
              });
              Navigator.pop(ctx);
            },
          ),
          _SortTile(
            label: l10n.sortByTitle,
            icon: Icons.sort_by_alpha,
            selected: _sortMode == _SortMode.title,
            onTap: () {
              setState(() {
                _sortMode = _SortMode.title;
                _notasFiltradas = _aplicarFiltroYOrden(_notas);
              });
              Navigator.pop(ctx);
            },
          ),
          _SortTile(
            label: l10n.sortFavFirst,
            icon: Icons.star_outline_rounded,
            selected: _sortMode == _SortMode.favFirst,
            onTap: () {
              setState(() {
                _sortMode = _SortMode.favFirst;
                _notasFiltradas = _aplicarFiltroYOrden(_notas);
              });
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final categoriasUsadas = _categoriasUsadas;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notebook),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: l10n.sortNotes,
            onPressed: _mostrarSortDialog,
          ),
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: AppLocalizations.of(context)!.home,
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────────
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

          // ── Category filter chips ───────────────────────────────────────
          if (!_cargando && categoriasUsadas.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l10n.filterAll),
                      selected: _categoriaFiltro == null,
                      onSelected: (_) {
                        setState(() {
                          _categoriaFiltro = null;
                          _notasFiltradas = _aplicarFiltroYOrden(_notas);
                        });
                      },
                    ),
                  ),
                  ...categoriasUsadas.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_categoryLabel(context, cat)),
                          selected: _categoriaFiltro == cat,
                          onSelected: (_) {
                            setState(() {
                              _categoriaFiltro =
                                  _categoriaFiltro == cat ? null : cat;
                              _notasFiltradas =
                                  _aplicarFiltroYOrden(_notas);
                            });
                          },
                        ),
                      )),
                ],
              ),
            ),

          // ── Notes list ──────────────────────────────────────────────────
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
                            if (_busquedaController.text.isEmpty &&
                                _categoriaFiltro == null) ...[
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
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                        itemCount: _notasFiltradas.length,
                        itemBuilder: (context, index) {
                          final nota = _notasFiltradas[index];
                          final accent = _accentColor(context, nota);
                          return Dismissible(
                            key: ValueKey(nota.key ?? nota.titulo),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete_sweep_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            confirmDismiss: (_) async {
                              final l10n = AppLocalizations.of(context)!;
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l10n.deleteNoteConfirm),
                                  content: Text(nota.titulo),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text(l10n.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            Theme.of(ctx).colorScheme.error,
                                      ),
                                      child: Text(l10n.delete),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) => _completarEliminacion(nota),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _abrirVer(nota),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 14, 8, 14),
                                  child: Row(
                                    children: [
                                      // Left accent bar with note colour
                                      Container(
                                        width: 4,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: accent,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Note info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Title row + favourite star
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    nota.titulo,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (nota.favorita)
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                        left: 4),
                                                    child: Icon(
                                                      Icons.star_rounded,
                                                      size: 16,
                                                      color: Colors.amber,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            // Category chip
                                            if (nota.categoria != null) ...[
                                              const SizedBox(height: 4),
                                              Chip(
                                                label: Text(
                                                  _categoryLabel(
                                                      context, nota.categoria),
                                                  style: const TextStyle(
                                                      fontSize: 11),
                                                ),
                                                padding: EdgeInsets.zero,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            ],
                                            if (nota.contenido
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                nota.contenido,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: cs.onSurface
                                                          .withOpacity(0.7),
                                                    ),
                                              ),
                                            ],
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .edit_calendar_outlined,
                                                  size: 12,
                                                  color: cs.outline,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  _formatFecha(
                                                      nota.fechaModificacion),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                          color: cs.outline),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Actions column
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.delete_outline,
                                                color: cs.error),
                                            tooltip: l10n.delete,
                                            onPressed: () =>
                                                _confirmarEliminar(nota),
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            color: cs.outline,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirNueva,
        tooltip: l10n.newNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SimpleDialogOption(
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: selected ? cs.primary : cs.onSurface),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: selected ? cs.primary : null,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal))),
          if (selected) Icon(Icons.check, size: 18, color: cs.primary),
        ],
      ),
    );
  }
}


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

  Future<void> _abrirNueva() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const EditarNotaScreen(),
      ),
    );
    if (resultado == true) {
      await _cargarNotas();
    }
  }

  Future<void> _abrirVer(Nota nota) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VerNotaScreen(nota: nota),
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

  Future<void> _completarEliminacion(Nota nota) async {
    final l10n = AppLocalizations.of(context)!;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: AppLocalizations.of(context)!.home,
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
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
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                        itemCount: _notasFiltradas.length,
                        itemBuilder: (context, index) {
                          final nota = _notasFiltradas[index];
                          return Dismissible(
                            key: ValueKey(nota.key ?? nota.titulo),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete_sweep_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            confirmDismiss: (_) async {
                              final l10n = AppLocalizations.of(context)!;
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l10n.deleteNoteConfirm),
                                  content: Text(nota.titulo),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text(l10n.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            Theme.of(ctx).colorScheme.error,
                                      ),
                                      child: Text(l10n.delete),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) => _completarEliminacion(nota),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _abrirVer(nota),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 14, 8, 14),
                                  child: Row(
                                    children: [
                                      // Left accent bar
                                      Container(
                                        width: 4,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: cs.primary,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Note info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nota.titulo,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (nota.contenido
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                nota.contenido,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: cs.onSurface
                                                          .withOpacity(0.7),
                                                    ),
                                              ),
                                            ],
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .edit_calendar_outlined,
                                                  size: 12,
                                                  color: cs.outline,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  _formatFecha(
                                                      nota.fechaModificacion),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                          color: cs.outline),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Actions column
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.delete_outline,
                                                color: cs.error),
                                            tooltip: l10n.delete,
                                            onPressed: () =>
                                                _confirmarEliminar(nota),
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            color: cs.outline,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirNueva,
        tooltip: l10n.newNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}

