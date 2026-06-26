import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sesion.dart';
import '../widgets/sesion_card.dart';
import 'ver_sesion.dart';
import '../utils/app_constants.dart';
import '../repositories/data_repository.dart';
import '../services/analytics_service.dart';
import 'home.dart';
import '../l10n/app_localizations.dart';
import '../widgets/skeleton_loaders.dart';

class ListaSesionesScreen extends StatefulWidget {
  const ListaSesionesScreen({super.key});

  @override
  State<ListaSesionesScreen> createState() => _ListaSesionesScreenState();
}

class _ListaSesionesScreenState extends State<ListaSesionesScreen> {
  static const String _filtroTodasTemporadas = '__all_seasons__';
  String _filtroTipo = AppConstants.tipoTodos;
  String _filtroTemporada = _filtroTodasTemporadas;
  List<String> _temporadas = [];
  final List<Sesion> _sesiones = [];
  final List<Sesion> _sesionesFiltradas = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logScreenView('sessions_list_screen');
      } catch (e) {
        debugPrint('Error logging screen view: $e');
      }
    });
    _scrollController.addListener(_onScroll);
    _cargarSesiones();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - AppConstants.scrollThreshold) {
      if (!_isLoading && _hasMore) {
        _cargarMasSesiones();
      }
    }
  }

  Future<void> _cargarSesiones() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _sesiones.clear();
      _temporadas.clear();
      _sesionesFiltradas.clear();
    });

    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      final nuevasSesiones = await dataRepository.obtenerSesionesPaginadas(
        limite: AppConstants.pageSize,
        offset: 0,
      );

      setState(() {
        _sesiones.addAll(nuevasSesiones);
        _recalcularTemporadas();
        _aplicarFiltro();
        _hasMore = nuevasSesiones.length >= AppConstants.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar sesiones: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.sessionLoadError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cargarMasSesiones() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      final nuevasSesiones = await dataRepository.obtenerSesionesPaginadas(
        limite: AppConstants.pageSize,
        offset: (_currentPage + 1) * AppConstants.pageSize,
      );

      setState(() {
        _currentPage++;
        _sesiones.addAll(nuevasSesiones);
        _recalcularTemporadas();
        _aplicarFiltro();
        _hasMore = nuevasSesiones.length >= AppConstants.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar más sesiones: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _aplicarFiltro() {
    if (_filtroTemporada != _filtroTodasTemporadas &&
        !_temporadas.contains(_filtroTemporada)) {
      _filtroTemporada = _filtroTodasTemporadas;
    }

    _sesionesFiltradas.clear();
    _sesionesFiltradas.addAll(
      _sesiones.where((s) {
        final coincideTipo =
            _filtroTipo == AppConstants.tipoTodos || s.tipo == _filtroTipo;
        final coincideTemporada =
            _filtroTemporada == _filtroTodasTemporadas ||
                s.temporadaNormalizada == _filtroTemporada;
        return coincideTipo && coincideTemporada;
      }),
    );
  }

  List<String> _temporadasDisponibles() {
    return _temporadas;
  }

  void _recalcularTemporadas() {
    _temporadas = _sesiones.map((s) => s.temporadaNormalizada).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
  }

  Future<void> _borrarSesion(Sesion sesion) async {
    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      await dataRepository.eliminarSesion(sesion);
      
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await analytics.logSessionDeleted();
      
      setState(() {
        _sesiones.remove(sesion);
        _recalcularTemporadas();
        _aplicarFiltro();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.sessionDeletedSuccess)),
        );
      }
    } catch (e) {
      debugPrint('Error al borrar sesión: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.sessionDeleteErrorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _mostrarDialogoConfirmacion() async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteSessionTitle),
        content: Text(
          AppLocalizations.of(context)!.deleteSessionConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _confirmarYEliminarSesion(Sesion sesion) async {
    final confirm = await _mostrarDialogoConfirmacion();
    if (confirm) {
      await _borrarSesion(sesion);
    }
  }

  String _translateTipo(String tipo, AppLocalizations l10n) {
    if (tipo == AppConstants.tipoEntrenamiento) return l10n.training;
    if (tipo == AppConstants.tipoCompeticion) return l10n.competition;
    if (tipo == AppConstants.tipoTodos) return l10n.all;
    return tipo;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sessionListTitle),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Filter chips ──
          _FilterBar(
            filtroTipo: _filtroTipo,
            filtroTemporada: _filtroTemporada,
            temporadasDisponibles: _temporadasDisponibles(),
            onChanged: (v) {
              setState(() {
                _filtroTipo = v;
                _aplicarFiltro();
              });
            },
            onTemporadaChanged: (v) {
              setState(() {
                _filtroTemporada = v;
                _aplicarFiltro();
              });
            },
            translateTipo: (t) => _translateTipo(t, l10n),
            isDark: isDark,
            cs: cs,
          ),

          // ── Session count summary ──
          if (!_isLoading && _sesionesFiltradas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Text(
                '${_sesionesFiltradas.length} ${l10n.sessions.toLowerCase()}',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.45),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // ── List ──
          Expanded(
            child: _sesionesFiltradas.isEmpty && !_isLoading
                ? _EmptyState(cs: cs, l10n: l10n)
                : RefreshIndicator(
                    onRefresh: _cargarSesiones,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                        top: 4,
                        bottom: 16 + MediaQuery.of(context).padding.bottom,
                      ),
                      itemCount:
                          _sesionesFiltradas.length + (_hasMore && _isLoading ? 1 : 0),
                      itemBuilder: (context, idx) {
                        if (idx >= _sesionesFiltradas.length) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SessionCardSkeleton(),
                          );
                        }

                        final sesion = _sesionesFiltradas[idx];

                        return Dismissible(
                          key: ValueKey(sesion.key ?? sesion.fecha.toString()),
                          direction: DismissDirection.endToStart,
                          background: _DismissBackground(),
                          confirmDismiss: (_) => _mostrarDialogoConfirmacion(),
                          onDismissed: (_) => _borrarSesion(sesion),
                          child: SesionCard(
                            sesion: sesion,
                            onDelete: () => _confirmarYEliminarSesion(sesion),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VerSesion(sesion: sesion),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  static const String _filtroTodasTemporadas = '__all_seasons__';
  final String filtroTipo;
  final String filtroTemporada;
  final List<String> temporadasDisponibles;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onTemporadaChanged;
  final String Function(String) translateTipo;
  final bool isDark;
  final ColorScheme cs;

  const _FilterBar({
    required this.filtroTipo,
    required this.filtroTemporada,
    required this.temporadasDisponibles,
    required this.onChanged,
    required this.onTemporadaChanged,
    required this.translateTipo,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final seasonValues = {
      _filtroTodasTemporadas,
      ...temporadasDisponibles,
    };
    final selectedSeason = seasonValues.contains(filtroTemporada)
        ? filtroTemporada
        : _filtroTodasTemporadas;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: AppConstants.tiposSesionConTodos.map((tipo) {
              final selected = filtroTipo == tipo;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(translateTipo(tipo)),
                  selected: selected,
                  onSelected: (_) => onChanged(tipo),
                  selectedColor: cs.primary,
                  backgroundColor:
                      isDark ? const Color(0xFF1A1F2E) : Colors.grey[100],
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : cs.onSurface.withOpacity(0.75),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: selected ? cs.primary : cs.onSurface.withOpacity(0.18),
                    width: 1.2,
                  ),
                  elevation: selected ? 2 : 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F2E) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withOpacity(0.18)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedSeason,
                items: [
                  DropdownMenuItem(
                    value: _filtroTodasTemporadas,
                    child: Text('Temporada: ${l10n.all}'),
                  ),
                  ...temporadasDisponibles.map(
                    (temporada) => DropdownMenuItem(
                      value: temporada,
                      child: Text('Temporada: $temporada'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onTemporadaChanged(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme cs;
  final AppLocalizations l10n;

  const _EmptyState({required this.cs, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_score_rounded,
              color: cs.primary.withOpacity(0.45),
              size: 46,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.noSessionsSaved,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.65),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.createFirstSession,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withOpacity(0.40),
            ),
          ),
        ],
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF5350), Color(0xFFB71C1C)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            l10n.delete,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
