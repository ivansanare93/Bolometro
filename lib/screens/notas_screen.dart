import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/nota.dart';
import '../repositories/data_repository.dart';
import '../l10n/app_localizations.dart';
import 'editar_nota_screen.dart';
import 'ver_nota_screen.dart';
import 'home.dart';

enum _SortMode { newest, oldest, title, favFirst }
enum _ArchiveFilter { active, archived, all }

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

  String? _categoriaFiltro;
  String? _tagFiltro;
  String? _tipoFiltro;
  String? _estadoFiltro;
  _SortMode _sortMode = _SortMode.newest;
  _ArchiveFilter _archiveFilter = _ArchiveFilter.active;
  bool _soloPinned = false;

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

  int _comparePinned(Nota a, Nota b) {
    if (a.pinned == b.pinned) return 0;
    return a.pinned ? -1 : 1;
  }

  List<Nota> _aplicarFiltroYOrden(List<Nota> notas) {
    final query = _busquedaController.text.trim().toLowerCase();

    List<Nota> resultado = notas.where((n) {
      final tagsText = n.tags.join(' ').toLowerCase();
      final categoryText = (n.categoria ?? '').toLowerCase();
      final relatedSessionText = (n.relatedSessionId ?? '').toLowerCase();
      final alleyText = (n.bolera ?? '').toLowerCase();
      final oilPatternText = (n.patronAceite ?? '').toLowerCase();
      final equipText = (n.equipamientoUsado ?? '').toLowerCase();
      final laneConditionText = (n.condicionPista ?? '').toLowerCase();

      final matchQuery = query.isEmpty ||
          n.titulo.toLowerCase().contains(query) ||
          n.contenido.toLowerCase().contains(query) ||
          tagsText.contains(query) ||
          categoryText.contains(query) ||
          relatedSessionText.contains(query) ||
          n.tipo.toLowerCase().contains(query) ||
          n.estado.toLowerCase().contains(query) ||
          alleyText.contains(query) ||
          oilPatternText.contains(query) ||
          equipText.contains(query) ||
          laneConditionText.contains(query);

      final matchCategoria =
          _categoriaFiltro == null || n.categoria == _categoriaFiltro;

      final matchTag = _tagFiltro == null || n.tags.contains(_tagFiltro);
      final matchTipo = _tipoFiltro == null || n.tipo == _tipoFiltro;
      final matchEstado = _estadoFiltro == null || n.estado == _estadoFiltro;

      final matchArchivo = switch (_archiveFilter) {
        _ArchiveFilter.active => !n.archivada,
        _ArchiveFilter.archived => n.archivada,
        _ArchiveFilter.all => true,
      };

      final matchPinned = !_soloPinned || n.pinned;

      return matchQuery &&
          matchCategoria &&
          matchTag &&
          matchTipo &&
          matchEstado &&
          matchArchivo &&
          matchPinned;
    }).toList();

    switch (_sortMode) {
      case _SortMode.newest:
        resultado.sort((a, b) {
          final pinCompare = _comparePinned(a, b);
          if (pinCompare != 0) return pinCompare;
          return b.fechaModificacion.compareTo(a.fechaModificacion);
        });
        break;
      case _SortMode.oldest:
        resultado.sort((a, b) {
          final pinCompare = _comparePinned(a, b);
          if (pinCompare != 0) return pinCompare;
          return a.fechaModificacion.compareTo(b.fechaModificacion);
        });
        break;
      case _SortMode.title:
        resultado.sort((a, b) {
          final pinCompare = _comparePinned(a, b);
          if (pinCompare != 0) return pinCompare;
          return a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase());
        });
        break;
      case _SortMode.favFirst:
        resultado.sort((a, b) {
          final pinCompare = _comparePinned(a, b);
          if (pinCompare != 0) return pinCompare;
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

  Future<void> _abrirNueva({String? templateId, String? relatedSessionId}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarNotaScreen(
          initialTemplateId: templateId,
          initialRelatedSessionId: relatedSessionId,
        ),
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
      await _eliminarNota(nota);
    }
  }

  Future<void> _eliminarNota(Nota nota) async {
    final repo = Provider.of<DataRepository>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
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

  Future<void> _togglePinned(Nota nota) async {
    final repo = Provider.of<DataRepository>(context, listen: false);
    nota.pinned = !nota.pinned;
    await repo.actualizarNota(nota);
    await _cargarNotas();
  }

  Future<void> _toggleArchived(Nota nota) async {
    final repo = Provider.of<DataRepository>(context, listen: false);
    nota.archivada = !nota.archivada;
    await repo.actualizarNota(nota);
    await _cargarNotas();
  }

  String _formatFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  List<String> get _categoriasUsadas {
    final usadas = _notas.map((n) => n.categoria).whereType<String>().toSet();
    return NotaCategoria.values.where(usadas.contains).toList();
  }

  List<String> get _tagsUsados {
    final tags = _notas.expand((n) => n.tags).map((t) => t.trim()).where((t) => t.isNotEmpty).toSet().toList();
    tags.sort();
    return tags;
  }

  int get _notasPorValidarCount {
    return _notas.where((n) {
      if (n.archivada) return false;
      return n.estado == NotaEstado.pendiente || n.estado == NotaEstado.probado;
    }).length;
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
    final tagsUsados = _tagsUsados;
    final tiposUsados = NotaTipo.values.where((tipo) => _notas.any((n) => n.tipo == tipo)).toList();
    final estadosUsados = NotaEstado.values.where((estado) => _notas.any((n) => n.estado == estado)).toList();
    final notasPorValidarCount = _notasPorValidarCount;

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
          if (!_cargando && notasPorValidarCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Material(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.pending_actions_rounded, color: cs.onTertiaryContainer),
                  title: Text(
                    l10n.notesPendingValidationCount(notasPorValidarCount),
                    style: TextStyle(color: cs.onTertiaryContainer, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    l10n.notesPendingValidation,
                    style: TextStyle(color: cs.onTertiaryContainer),
                  ),
                ),
              ),
            ),
          if (!_cargando)
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
                      selected: _archiveFilter == _ArchiveFilter.all,
                      onSelected: (_) {
                        setState(() {
                          _archiveFilter = _ArchiveFilter.all;
                          _notasFiltradas = _aplicarFiltroYOrden(_notas);
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l10n.noteFilterActive),
                      selected: _archiveFilter == _ArchiveFilter.active,
                      onSelected: (_) {
                        setState(() {
                          _archiveFilter = _ArchiveFilter.active;
                          _notasFiltradas = _aplicarFiltroYOrden(_notas);
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l10n.noteFilterArchived),
                      selected: _archiveFilter == _ArchiveFilter.archived,
                      onSelected: (_) {
                        setState(() {
                          _archiveFilter = _ArchiveFilter.archived;
                          _notasFiltradas = _aplicarFiltroYOrden(_notas);
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l10n.notePin),
                      selected: _soloPinned,
                      onSelected: (_) {
                        setState(() {
                          _soloPinned = !_soloPinned;
                          _notasFiltradas = _aplicarFiltroYOrden(_notas);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
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
                      label: Text(l10n.noteFilterAllCategories),
                      selected: _categoriaFiltro == null,
                      onSelected: (_) {
                        setState(() {
                          _categoriaFiltro = null;
                          _notasFiltradas = _aplicarFiltroYOrden(_notas);
                        });
                      },
                    ),
                  ),
                  ...categoriasUsadas.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_categoryLabel(context, cat)),
                        selected: _categoriaFiltro == cat,
                        onSelected: (_) {
                          setState(() {
                            _categoriaFiltro = _categoriaFiltro == cat ? null : cat;
                            _notasFiltradas = _aplicarFiltroYOrden(_notas);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!_cargando && tagsUsados.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l10n.noteFilterAllTags),
                      selected: _tagFiltro == null,
                      onSelected: (_) {
                        setState(() {
                          _tagFiltro = null;
                          _notasFiltradas = _aplicarFiltroYOrden(_notas);
                        });
                      },
                    ),
                  ),
                  ...tagsUsados.map(
                    (tag) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('#$tag'),
                        selected: _tagFiltro == tag,
                        onSelected: (_) {
                          setState(() {
                            _tagFiltro = _tagFiltro == tag ? null : tag;
                            _notasFiltradas = _aplicarFiltroYOrden(_notas);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!_cargando && tiposUsados.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l10n.noteFilterAllTypes),
                      selected: _tipoFiltro == null,
                      onSelected: (_) {
                        setState(() {
                          _tipoFiltro = null;
                          _notasFiltradas = _aplicarFiltroYOrden(_notas);
                        });
                      },
                    ),
                  ),
                  ...tiposUsados.map(
                    (tipo) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_typeLabel(context, tipo)),
                        selected: _tipoFiltro == tipo,
                        onSelected: (_) {
                          setState(() {
                            _tipoFiltro = _tipoFiltro == tipo ? null : tipo;
                            _notasFiltradas = _aplicarFiltroYOrden(_notas);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!_cargando && estadosUsados.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l10n.noteFilterAllStatuses),
                      selected: _estadoFiltro == null,
                      onSelected: (_) {
                        setState(() {
                          _estadoFiltro = null;
                          _notasFiltradas = _aplicarFiltroYOrden(_notas);
                        });
                      },
                    ),
                  ),
                  ...estadosUsados.map(
                    (estado) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_statusLabel(context, estado)),
                        selected: _estadoFiltro == estado,
                        onSelected: (_) {
                          setState(() {
                            _estadoFiltro = _estadoFiltro == estado ? null : estado;
                            _notasFiltradas = _aplicarFiltroYOrden(_notas);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _notasFiltradas.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📓', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                l10n.noNotes,
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.noNotesHint,
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              if (_busquedaController.text.isEmpty) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _abrirNueva(templateId: 'tecnica'),
                                  icon: const Icon(Icons.auto_awesome),
                                  label: Text(l10n.noteCreateFromTemplate),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                        itemCount: _notasFiltradas.length,
                        itemBuilder: (context, index) {
                          final nota = _notasFiltradas[index];
                          final accent = _accentColor(context, nota);
                          return Dismissible(
                            key: ValueKey(nota.id),
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
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(l10n.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
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
                            onDismissed: (_) => _eliminarNota(nota),
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
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 14, 8, 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: accent,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                if (nota.pinned)
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 4),
                                                    child: Icon(
                                                      Icons.push_pin,
                                                      size: 16,
                                                    ),
                                                  ),
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
                                                    padding:
                                                        EdgeInsets.only(left: 4),
                                                    child: Icon(
                                                      Icons.star_rounded,
                                                      size: 16,
                                                      color: Colors.amber,
                                                    ),
                                                  ),
                                                if (nota.archivada)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 4),
                                                    child: Icon(
                                                      Icons.archive_outlined,
                                                      size: 16,
                                                      color: cs.outline,
                                                    ),
                                                  ),
                                              ],
                                            ),
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
                                             const SizedBox(height: 4),
                                             Wrap(
                                               spacing: 6,
                                               runSpacing: 4,
                                               children: [
                                                 Chip(
                                                   label: Text(
                                                     _typeLabel(context, nota.tipo),
                                                     style: const TextStyle(fontSize: 11),
                                                   ),
                                                   padding: EdgeInsets.zero,
                                                   materialTapTargetSize:
                                                       MaterialTapTargetSize.shrinkWrap,
                                                   visualDensity: VisualDensity.compact,
                                                 ),
                                                 Chip(
                                                   avatar: nota.estado == NotaEstado.validado
                                                       ? const Icon(Icons.verified_outlined, size: 14)
                                                       : nota.estado == NotaEstado.descartado
                                                           ? const Icon(Icons.block_outlined, size: 14)
                                                           : const Icon(Icons.pending_actions_outlined, size: 14),
                                                   label: Text(
                                                     _statusLabel(context, nota.estado),
                                                     style: const TextStyle(fontSize: 11),
                                                   ),
                                                   padding: EdgeInsets.zero,
                                                   materialTapTargetSize:
                                                       MaterialTapTargetSize.shrinkWrap,
                                                   visualDensity: VisualDensity.compact,
                                                 ),
                                               ],
                                             ),
                                             if ((nota.bolera ?? '').isNotEmpty ||
                                                 (nota.patronAceite ?? '').isNotEmpty ||
                                                 (nota.equipamientoUsado ?? '').isNotEmpty ||
                                                 (nota.condicionPista ?? '').isNotEmpty) ...[
                                               const SizedBox(height: 4),
                                               Text(
                                                 [
                                                   if ((nota.bolera ?? '').isNotEmpty) '${l10n.noteBowlingAlley}: ${nota.bolera}',
                                                   if ((nota.patronAceite ?? '').isNotEmpty) '${l10n.noteOilPattern}: ${nota.patronAceite}',
                                                   if ((nota.equipamientoUsado ?? '').isNotEmpty) '${l10n.noteBallOrEquipment}: ${nota.equipamientoUsado}',
                                                   if ((nota.condicionPista ?? '').isNotEmpty) '${l10n.noteLaneCondition}: ${nota.condicionPista}',
                                                 ].join(' • '),
                                                 maxLines: 1,
                                                 overflow: TextOverflow.ellipsis,
                                                 style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
                                               ),
                                             ],
                                             if (nota.tags.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: nota.tags
                                                    .take(3)
                                                    .map(
                                                      (tag) => Text(
                                                        '#$tag',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: cs.primary,
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ],
                                            if (nota.contenido.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                nota.contenido,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
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
                                                  Icons.edit_calendar_outlined,
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
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'pin') {
                                            _togglePinned(nota);
                                          } else if (value == 'archive') {
                                            _toggleArchived(nota);
                                          } else if (value == 'delete') {
                                            _confirmarEliminar(nota);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'pin',
                                            child: Text(
                                              nota.pinned
                                                  ? l10n.noteUnpin
                                                  : l10n.notePin,
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'archive',
                                            child: Text(
                                              nota.archivada
                                                  ? l10n.noteUnarchive
                                                  : l10n.noteArchive,
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text(l10n.delete),
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
