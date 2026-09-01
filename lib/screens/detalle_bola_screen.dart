import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/bowling_ball.dart';
import '../repositories/data_repository.dart';
import '../services/analytics_service.dart';
import '../services/ball_stats_service.dart';
import 'editar_bola_screen.dart';

/// Pantalla de detalle de una bola: muestra sus datos, estadísticas de
/// rendimiento y el historial de mantenimiento, con acciones para editar,
/// archivar/reactivar y registrar nuevos mantenimientos.
class DetalleBolaScreen extends StatefulWidget {
  final BowlingBall ball;

  const DetalleBolaScreen({super.key, required this.ball});

  @override
  State<DetalleBolaScreen> createState() => _DetalleBolaScreenState();
}

class _DetalleBolaScreenState extends State<DetalleBolaScreen> {
  late BowlingBall _bola;
  bool _cargando = true;
  String? _error;
  EstadisticasBola _stats = EstadisticasBola.vacia();
  List<BallMaintenance> _mantenimientos = [];

  @override
  void initState() {
    super.initState();
    _bola = widget.ball;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final repo = Provider.of<DataRepository>(context, listen: false);
      final partidas = await repo.obtenerPartidasPorBola(_bola.id);
      final mantenimientos = await repo.listarMantenimientosPorBola(_bola.id);
      if (!mounted) return;
      setState(() {
        _stats = BallStatsService.calcular(partidas);
        _mantenimientos = mantenimientos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los datos de la bola.';
        _cargando = false;
      });
    }
  }

  Future<void> _editar() async {
    final editada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditarBolaScreen(ball: _bola)),
    );
    if (editada == true) {
      final repo = Provider.of<DataRepository>(context, listen: false);
      final actualizada = await repo.obtenerBola(_bola.id);
      if (actualizada != null && mounted) {
        setState(() => _bola = actualizada);
      }
    }
  }

  Future<void> _archivarOReactivar() async {
    final repo = Provider.of<DataRepository>(context, listen: false);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_bola.isActive ? 'Archivar bola' : 'Reactivar bola'),
        content: Text(
          _bola.isActive
              ? '¿Quieres archivar "${_bola.name}"? Ya no aparecerá para seleccionar en nuevas partidas, pero conservarás su historial y estadísticas.'
              : '¿Quieres reactivar "${_bola.name}" para volver a usarla en tus partidas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    final nuevoEstadoActivo = !_bola.isActive;
    if (_bola.isActive) {
      await repo.archivarBola(_bola);
    } else {
      await repo.reactivarBola(_bola);
    }
    // No confiamos en que `archivarBola`/`reactivarBola` mute `_bola` in
    // place: reconstruimos explícitamente el estado local con `copyWith`,
    // usando el valor calculado antes de la llamada al repositorio.
    if (mounted) {
      setState(() {
        _bola = _bola.copyWith(isActive: nuevoEstadoActivo);
      });
    }
  }

  Future<void> _agregarMantenimiento() async {
    String tipo = BallMaintenanceType.cleaning;
    DateTime fecha = DateTime.now();
    final notasController = TextEditingController();

    final registrado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nuevo mantenimiento',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: BallMaintenanceType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(BallMaintenanceType.label(t)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => tipo = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(fecha)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final seleccionada = await showDatePicker(
                        context: context,
                        initialDate: fecha,
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now(),
                      );
                      if (seleccionada != null) {
                        setModalState(() => fecha = seleccionada);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notasController,
                    decoration: const InputDecoration(labelText: 'Notas'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Guardar mantenimiento'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (registrado != true) {
      notasController.dispose();
      return;
    }
    if (!mounted) {
      notasController.dispose();
      return;
    }

    final repo = Provider.of<DataRepository>(context, listen: false);
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    final mantenimiento = BallMaintenance(
      ballId: _bola.id,
      type: tipo,
      date: fecha,
      notes: notasController.text.trim().isEmpty
          ? null
          : notasController.text.trim(),
    );
    notasController.dispose();
    await repo.crearMantenimiento(mantenimiento);
    try {
      await analytics.logMaintenanceLogged(tipo);
    } catch (_) {
      // Ignorar errores de analítica.
    }
    await _cargarDatos();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_bola.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar',
              onPressed: _editar,
            ),
            IconButton(
              icon: Icon(_bola.isActive ? Icons.archive_outlined : Icons.unarchive_outlined),
              tooltip: _bola.isActive ? 'Archivar' : 'Reactivar',
              onPressed: _archivarOReactivar,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Estadísticas'),
              Tab(text: 'Mantenimiento'),
            ],
          ),
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : TabBarView(
                    children: [
                      _buildEstadisticas(),
                      _buildMantenimiento(),
                    ],
                  ),
        floatingActionButton: Builder(
          builder: (context) {
            final controller = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                if (controller.index != 1) return const SizedBox.shrink();
                return FloatingActionButton.extended(
                  onPressed: _agregarMantenimiento,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar mantenimiento'),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEstadisticas() {
    if (_stats.partidasJugadas == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Todavía no hay partidas registradas con esta bola.\n'
            'Asigna esta bola al registrar una partida para ver sus estadísticas aquí.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final tendenciaTexto = _stats.tendencia > 0.05
        ? '▲ Mejorando (+${_stats.tendencia.toStringAsFixed(1)})'
        : _stats.tendencia < -0.05
            ? '▼ Bajando (${_stats.tendencia.toStringAsFixed(1)})'
            : '– Estable';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _KpiCard(label: 'Partidas jugadas', value: '${_stats.partidasJugadas}'),
        _KpiCard(label: 'Promedio', value: _stats.promedio.toStringAsFixed(1)),
        _KpiCard(label: 'Mejor partida', value: '${_stats.mejorPartida}'),
        _KpiCard(
          label: '% de strikes',
          value: '${_stats.strikeRate.toStringAsFixed(1)}%',
        ),
        _KpiCard(label: 'Tendencia', value: tendenciaTexto),
      ],
    );
  }

  Widget _buildMantenimiento() {
    if (_mantenimientos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay mantenimientos registrados para esta bola.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _mantenimientos.length,
      itemBuilder: (context, index) {
        final m = _mantenimientos[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.build_outlined),
            title: Text(BallMaintenanceType.label(m.type)),
            subtitle: Text(
              [
                DateFormat('dd/MM/yyyy').format(m.date),
                if (m.notes != null && m.notes!.trim().isNotEmpty) m.notes!,
              ].join(' · '),
            ),
          ),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;

  const _KpiCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
