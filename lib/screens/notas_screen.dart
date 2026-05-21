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
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  List<String> get _categoriasUsadas {
    final usadas = _notas.map((n) => n.categoria).whereType<String>().toSet();
    return NotaCategoria.values.where(usadas.contains).toList();
  }

  List<String> get _tagsUsados {
    final tags = _notas
        .expand((n) => n.tags)
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    tags.sort();
    return tags;
  }

  int get _notasPorValidarCount {
    return _notas.where((n) {
      if (n.archivada) return false;
      return n.estado == NotaEstado.pendiente || n.estado == NotaEstado.probado;
    }).length;
  }

  int get _notasPendientesRevisionCount {
    final ahora = DateTime.now();
    return _notas.where((n) {
      if (n.archivada || n.fechaEliminacion != null) return false;
      if (n.revisarAntesProximaSesion) return true;
      final fechaRevision = n.fechaRevision;
      return fechaRevision != null &&
          (fechaRevision.isBefore(ahora) ||
              fechaRevision.isAtSameMomentAs(ahora));
    }).length;
  }

  int get _activeAdvancedFiltersCount {
    int count = 0;
    if (_categoriaFiltro != null) count++;
    if (_tagFiltro != null) count++;
    if (_tipoFiltro != null) count++;
    if (_estadoFiltro != null) count++;
    return count;
  }

  String _label(BuildContext context, String es, String en) {
    return Localizations.localeOf(context).languageCode == 'es' ? es : en;
  }

  String _mostFrequentValue(Iterable<String> values, String fallback) {
    final count = <String, int>{};
    for (final value in values) {
      final key = value.trim();
      if (key.isEmpty) continue;
      count[key] = (count[key] ?? 0) + 1;
    }
    if (count.isEmpty) return fallback;
    final ordered = count.entries.toList();
    ordered.sort((a, b) => b.value.compareTo(a.value));
    return ordered.first.key;
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

  Color _statusColor(ColorScheme cs, String estado) {
    switch (estado) {
      case NotaEstado.validado:
        return cs.primary;
      case NotaEstado.descartado:
        return cs.error;
      case NotaEstado.probado:
        return cs.secondary;
      default:
        return cs.outline;
    }
  }

  String _cleanPreview(String content) {
    return content
        .replaceAll(r'\n', ' ')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _mostrarFiltrosBottomSheet() {
    final l10n = AppLocalizations.of(context)!;
    final categoriasUsadas = _categoriasUsadas;
    final tagsUsados = _tagsUsados;
    final tiposPresentes = _notas.map((n) => n.tipo).toSet();
    final estadosPresentes = _notas.map((n) => n.estado).toSet();
    final tiposUsados =
        NotaTipo.values.where(tiposPresentes.contains).toList();
    final estadosUsados =
        NotaEstado.values.where(estadosPresentes.contains).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          void updateFilter(VoidCallback fn) {
            setState(fn);
            setSheetState(() {});
          }

          final topTag = _mostFrequentValue(
            _notas.expand((n) => n.tags),
            _label(context, '-', '-'),
          );
          final topBolera = _mostFrequentValue(
            _notas.map((n) => n.bolera ?? ''),
            _label(context, 'Sin datos', 'No data'),
          );
          final conAdjuntosCount =
              _notas.where((n) => n.adjuntos.isNotEmpty).length;

          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.92,
            expand: false,
            builder: (_, scrollController) => Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.noteAdvancedFilters,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_activeAdvancedFiltersCount > 0 ||
                          _sortMode != _SortMode.newest)
                        TextButton(
                          onPressed: () {
                            updateFilter(() {
                              _categoriaFiltro = null;
                              _tagFiltro = null;
                              _tipoFiltro = null;
                              _estadoFiltro = null;
                              _sortMode = _SortMode.newest;
                              _notasFiltradas =
                                  _aplicarFiltroYOrden(_notas);
                            });
                          },
                          child: Text(l10n.noteResetFilters),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      _SheetSectionTitle(title: l10n.noteSortOrder),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildSortChip(
                              setSheetState,
                              l10n.sortNewest,
                              Icons.arrow_downward,
                              _SortMode.newest),
                          _buildSortChip(
                              setSheetState,
                              l10n.sortOldest,
                              Icons.arrow_upward,
                              _SortMode.oldest),
                          _buildSortChip(
                              setSheetState,
                              l10n.sortByTitle,
                              Icons.sort_by_alpha,
                              _SortMode.title),
                          _buildSortChip(
                              setSheetState,
                              l10n.sortFavFirst,
                              Icons.star_outline_rounded,
                              _SortMode.favFirst),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (categoriasUsadas.isNotEmpty) ...[
                        _SheetSectionTitle(
                            title: l10n.noteFilterAllCategories),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            FilterChip(
                              label: Text(l10n.filterAll),
                              selected: _categoriaFiltro == null,
                              onSelected: (_) => updateFilter(() {
                                _categoriaFiltro = null;
                                _notasFiltradas =
                                    _aplicarFiltroYOrden(_notas);
                              }),
                            ),
                            ...categoriasUsadas.map(
                              (cat) => FilterChip(
                                label:
                                    Text(_categoryLabel(context, cat)),
                                selected: _categoriaFiltro == cat,
                                onSelected: (_) => updateFilter(() {
                                  _categoriaFiltro =
                                      _categoriaFiltro == cat
                                          ? null
                                          : cat;
                                  _notasFiltradas =
                                      _aplicarFiltroYOrden(_notas);
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (tiposUsados.isNotEmpty) ...[
                        _SheetSectionTitle(
                            title: l10n.noteFilterAllTypes),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            FilterChip(
                              label: Text(l10n.filterAll),
                              selected: _tipoFiltro == null,
                              onSelected: (_) => updateFilter(() {
                                _tipoFiltro = null;
                                _notasFiltradas =
                                    _aplicarFiltroYOrden(_notas);
                              }),
                            ),
                            ...tiposUsados.map(
                              (tipo) => FilterChip(
                                label: Text(_typeLabel(context, tipo)),
                                selected: _tipoFiltro == tipo,
                                onSelected: (_) => updateFilter(() {
                                  _tipoFiltro =
                                      _tipoFiltro == tipo ? null : tipo;
                                  _notasFiltradas =
                                      _aplicarFiltroYOrden(_notas);
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (estadosUsados.isNotEmpty) ...[
                        _SheetSectionTitle(
                            title: l10n.noteFilterAllStatuses),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            FilterChip(
                              label: Text(l10n.filterAll),
                              selected: _estadoFiltro == null,
                              onSelected: (_) => updateFilter(() {
                                _estadoFiltro = null;
                                _notasFiltradas =
                                    _aplicarFiltroYOrden(_notas);
                              }),
                            ),
                            ...estadosUsados.map(
                              (estado) => FilterChip(
                                label:
                                    Text(_statusLabel(context, estado)),
                                selected: _estadoFiltro == estado,
                                onSelected: (_) => updateFilter(() {
                                  _estadoFiltro =
                                      _estadoFiltro == estado
                                          ? null
                                          : estado;
                                  _notasFiltradas =
                                      _aplicarFiltroYOrden(_notas);
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (tagsUsados.isNotEmpty) ...[
                        _SheetSectionTitle(
                            title: l10n.noteFilterAllTags),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            FilterChip(
                              label: Text(l10n.filterAll),
                              selected: _tagFiltro == null,
                              onSelected: (_) => updateFilter(() {
                                _tagFiltro = null;
                                _notasFiltradas =
                                    _aplicarFiltroYOrden(_notas);
                              }),
                            ),
                            ...tagsUsados.map(
                              (tag) => FilterChip(
                                label: Text('#$tag'),
                                selected: _tagFiltro == tag,
                                onSelected: (_) => updateFilter(() {
                                  _tagFiltro =
                                      _tagFiltro == tag ? null : tag;
                                  _notasFiltradas =
                                      _aplicarFiltroYOrden(_notas);
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Divider(),
                      const SizedBox(height: 8),
                      _SheetSectionTitle(title: l10n.noteSummary),
                      _SummaryGrid(
                        items: [
                          _SummaryItem(
                            icon: Icons.notes_outlined,
                            label: _label(context, 'Total', 'Total'),
                            value: '${_notas.length}',
                          ),
                          _SummaryItem(
                            icon: Icons.tag_outlined,
                            label:
                                _label(context, 'Top tag', 'Top tag'),
                            value: topTag,
                          ),
                          _SummaryItem(
                            icon: Icons.place_outlined,
                            label: _label(context, 'Bolera frecuente',
                                'Frequent alley'),
                            value: topBolera,
                          ),
                          _SummaryItem(
                            icon: Icons.attach_file_outlined,
                            label: _label(context, 'Con adjuntos',
                                'With attachments'),
                            value: '$conAdjuntosCount',
                          ),
                          _SummaryItem(
                            icon: Icons.notifications_active_outlined,
                            label: _label(context, 'Por revisar',
                                'Pending review'),
                            value: '$_notasPendientesRevisionCount',
                          ),
                          _SummaryItem(
                            icon: Icons.pending_actions_outlined,
                            label: _label(
                                context, 'Por validar', 'To validate'),
                            value: '$_notasPorValidarCount',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortChip(
    StateSetter setSheetState,
    String label,
    IconData icon,
    _SortMode mode,
  ) {
    return FilterChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      selected: _sortMode == mode,
      onSelected: (_) {
        setState(() {
          _sortMode = mode;
          _notasFiltradas = _aplicarFiltroYOrden(_notas);
        });
        setSheetState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final notasPorValidarCount = _notasPorValidarCount;
    final activeAdvanced = _activeAdvancedFiltersCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notebook),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: l10n.home,
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
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
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
          // Quick filter row
          if (!_cargando)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(l10n.noteFilterActive),
                      selected: _archiveFilter == _ArchiveFilter.active,
                      onSelected: (_) {
                        setState(() {
                          _archiveFilter =
                              _archiveFilter == _ArchiveFilter.active
                                  ? _ArchiveFilter.all
                                  : _ArchiveFilter.active;
                          _notasFiltradas = _aplicarFiltroYOrden(_notas);
                        });
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(l10n.noteFilterArchived),
                      selected:
                          _archiveFilter == _ArchiveFilter.archived,
                      onSelected: (_) {
                        setState(() {
                          _archiveFilter =
                              _archiveFilter == _ArchiveFilter.archived
                                  ? _ArchiveFilter.all
                                  : _ArchiveFilter.archived;
                          _notasFiltradas = _aplicarFiltroYOrden(_notas);
                        });
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      avatar: const Icon(Icons.push_pin_outlined,
                          size: 16),
                      label: Text(l10n.notePin),
                      selected: _soloPinned,
                      onSelected: (_) {
                        setState(() {
                          _soloPinned = !_soloPinned;
                          _notasFiltradas = _aplicarFiltroYOrden(_notas);
                        });
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Badge(
                      isLabelVisible: activeAdvanced > 0,
                      label: Text('$activeAdvanced'),
                      child: FilterChip(
                        avatar: const Icon(Icons.tune_outlined, size: 16),
                        label: Text(l10n.noteAdvancedFilters),
                        selected: activeAdvanced > 0,
                        onSelected: (_) =>
                            _mostrarFiltrosBottomSheet(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Compact pending validation notice
          if (!_cargando && notasPorValidarCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
              child: Material(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  child: Row(
                    children: [
                      Icon(Icons.pending_actions_rounded,
                          size: 16, color: cs.onTertiaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.notesPendingValidationCount(
                              notasPorValidarCount),
                          style: TextStyle(
                            color: cs.onTertiaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Notes list
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _notasFiltradas.isEmpty
                    ? Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📓',
                                  style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                l10n.noNotes,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.noNotesHint,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              if (_busquedaController.text.isEmpty) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _abrirNueva(
                                      templateId: 'tecnica'),
                                  icon: const Icon(Icons.auto_awesome),
                                  label:
                                      Text(l10n.noteCreateFromTemplate),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                        itemCount: _notasFiltradas.length,
                        itemBuilder: (context, index) {
                          final nota = _notasFiltradas[index];
                          return Dismissible(
                            key: ValueKey(nota.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin:
                                  const EdgeInsets.symmetric(vertical: 3),
                              decoration: BoxDecoration(
                                color: cs.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete_sweep_outlined,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            confirmDismiss: (_) async {
                              final l10n =
                                  AppLocalizations.of(context)!;
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
                                        foregroundColor: Theme.of(ctx)
                                            .colorScheme
                                            .error,
                                      ),
                                      child: Text(l10n.delete),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) => _eliminarNota(nota),
                            child: _buildNoteCard(context, nota),
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

  Widget _buildNoteCard(BuildContext context, Nota nota) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final accent = _accentColor(context, nota);
    final preview = _cleanPreview(nota.contenido);
    final visibleTags = nota.tags.take(2).toList();
    final hasMoreTags = nota.tags.length > 2;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirVer(nota),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 11, 4, 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accent bar
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
                child: Container(
                  width: 3,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        if (nota.pinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.push_pin,
                                size: 13, color: cs.primary),
                          ),
                        Expanded(
                          child: Text(
                            nota.titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (nota.favorita)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.star_rounded,
                                size: 14, color: Colors.amber),
                          ),
                        if (nota.archivada)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.archive_outlined,
                                size: 14, color: cs.outline),
                          ),
                        if (nota.adjuntos.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.attach_file_outlined,
                                size: 14, color: cs.outline),
                          ),
                      ],
                    ),
                    // Content preview
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withOpacity(0.65),
                                  height: 1.4,
                                ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Status + type chips + date row
                    Row(
                      children: [
                        _CompactChip(
                          label: _statusLabel(context, nota.estado),
                          color: _statusColor(cs, nota.estado),
                        ),
                        const SizedBox(width: 5),
                        _CompactChip(
                          label: _typeLabel(context, nota.tipo),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(Icons.edit_calendar_outlined,
                                size: 11, color: cs.outline),
                            const SizedBox(width: 2),
                            Text(
                              _formatFecha(nota.fechaModificacion),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: cs.outline, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Tags
                    if (visibleTags.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          ...visibleTags.map(
                            (tag) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                    fontSize: 11, color: cs.primary),
                              ),
                            ),
                          ),
                          if (hasMoreTags)
                            Text(
                              '+${nota.tags.length - 2}',
                              style: TextStyle(
                                  fontSize: 11, color: cs.outline),
                            ),
                        ],
                      ),
                    ],
                    // Context metadata (compact single line)
                    if ((nota.bolera ?? '').isNotEmpty ||
                        (nota.patronAceite ?? '').isNotEmpty ||
                        (nota.equipamientoUsado ?? '').isNotEmpty ||
                        (nota.condicionPista ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        [
                          if ((nota.bolera ?? '').isNotEmpty)
                            nota.bolera!,
                          if ((nota.patronAceite ?? '').isNotEmpty)
                            nota.patronAceite!,
                          if ((nota.equipamientoUsado ?? '').isNotEmpty)
                            nota.equipamientoUsado!,
                          if ((nota.condicionPista ?? '').isNotEmpty)
                            nota.condicionPista!,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: cs.outline, fontSize: 11),
                      ),
                    ],
                    // Revision reminder
                    if (nota.revisarAntesProximaSesion ||
                        nota.fechaRevision != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.notifications_active_outlined,
                              size: 11, color: cs.tertiary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              nota.fechaRevision == null
                                  ? _label(
                                      context,
                                      'Revisar antes de próxima sesión',
                                      'Review before next session',
                                    )
                                  : '${_label(context, 'Revisión', 'Review')}: ${DateFormat('dd/MM/yyyy').format(nota.fechaRevision!)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: cs.tertiary,
                                      fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Actions menu
              PopupMenuButton<String>(
                iconSize: 20,
                padding: EdgeInsets.zero,
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
                    child: Text(nota.pinned
                        ? l10n.noteUnpin
                        : l10n.notePin),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(nota.archivada
                        ? l10n.noteUnarchive
                        : l10n.noteArchive),
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
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _CompactChip extends StatelessWidget {
  final String label;
  final Color? color;

  const _CompactChip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chipColor = color ?? cs.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: chipColor.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: chipColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SheetSectionTitle extends StatelessWidget {
  final String title;

  const _SheetSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _SummaryItem {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem(
      {required this.icon, required this.label, required this.value});
}

class _SummaryGrid extends StatelessWidget {
  final List<_SummaryItem> items;

  const _SummaryGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.label,
                      style:
                          TextStyle(fontSize: 10, color: cs.outline),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
