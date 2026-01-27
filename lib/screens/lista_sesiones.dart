import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sesion.dart';
import '../widgets/sesion_card.dart';
import '../screens/ver_sesion.dart';
import '../utils/app_constants.dart';
import '../repositories/data_repository.dart';
import '../services/analytics_service.dart';
import 'home.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ListaSesionesScreen extends StatefulWidget {
  const ListaSesionesScreen({super.key});

  @override
  State<ListaSesionesScreen> createState() => _ListaSesionesScreenState();
}

class _ListaSesionesScreenState extends State<ListaSesionesScreen> {
  String _filtroTipo = AppConstants.tipoTodos;
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
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      analytics.logScreenView('sessions_list_screen');
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
    _sesionesFiltradas.clear();
    if (_filtroTipo == AppConstants.tipoTodos) {
      _sesionesFiltradas.addAll(_sesiones);
    } else {
      _sesionesFiltradas.addAll(
        _sesiones.where((s) => s.tipo == _filtroTipo),
      );
    }
  }

  Future<void> _borrarSesion(Sesion sesion) async {
    try {
      final dataRepository = Provider.of<DataRepository>(context, listen: false);
      await dataRepository.eliminarSesion(sesion);
      
      final analytics = Provider.of<AnalyticsService>(context, listen: false);
      await analytics.logSessionDeleted();
      
      setState(() {
        _sesiones.remove(sesion);
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.sessionListTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: "Inicio",
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
          // Filtro visual optimizado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? cs.surface : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.primary.withOpacity(0.38),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(isDark ? 0.13 : 0.06),
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Row(
                children: [
                  Icon(Icons.filter_list_rounded, color: cs.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Filtrar:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.84),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filtroTipo,
                        borderRadius: BorderRadius.circular(12),
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: cs.primary),
                        dropdownColor: isDark ? cs.surface : Colors.white,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        items: AppConstants.tiposSesionConTodos
                            .map(
                              (tipo) => DropdownMenuItem(
                                value: tipo,
                                child: Text(
                                  tipo,
                                  style: TextStyle(
                                    color: cs.onSurface.withOpacity(
                                      tipo == _filtroTipo ? 1.0 : 0.72,
                                    ),
                                    fontWeight: tipo == _filtroTipo
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _filtroTipo = v ?? AppConstants.tipoTodos;
                            _aplicarFiltro();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _sesionesFiltradas.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          color: cs.primary.withOpacity(0.48),
                          size: 54,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay sesiones guardadas.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarSesiones,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _sesionesFiltradas.length + (_hasMore && _isLoading ? 1 : 0),
                      itemBuilder: (context, idx) {
                        // Mostrar indicador de carga al final
                        if (idx >= _sesionesFiltradas.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final sesion = _sesionesFiltradas[idx];

                        return Dismissible(
                          key: ValueKey(sesion.key ?? sesion.fecha.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            alignment: Alignment.centerRight,
                            color: Colors.red[400],
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                          confirmDismiss: (_) => _mostrarDialogoConfirmacion(),
                          onDismissed: (_) => _borrarSesion(sesion),
                          child: SesionCard(
                            sesion: sesion,
                            onDelete: () => _confirmarYEliminarSesion(sesion),
                            // VER SESIÓN
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
          )
        ],
      ),
    );
  }
}
