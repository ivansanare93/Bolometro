import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'home.dart';
import '../models/sesion.dart';
import '../utils/database_utils.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  late Future<List<Sesion>> _sesionesFuture;
  String _filtroTipo = 'Todos';

  @override
  void initState() {
    super.initState();
    _sesionesFuture = cargarSesionesDesdeHive();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
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
      body: FutureBuilder<List<Sesion>>(
        future: _sesionesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FiltroTipo(
                    filtroTipo: _filtroTipo,
                    onChanged: (valor) {
                      if (valor != null) setState(() => _filtroTipo = valor);
                    },
                  ),
                  const SizedBox(height: 32),
                  const Center(child: Text('Aún no hay sesiones registradas.')),
                ],
              ),
            );
          }
          final sesiones = snapshot.data!;
          final sesionesFiltradas = _filtroTipo == 'Todos'
              ? sesiones
              : sesiones.where((s) => s.tipo == _filtroTipo).toList();

          final partidas = sesionesFiltradas.expand((s) => s.partidas).toList();

          final promedio = partidas.isNotEmpty
              ? partidas.map((p) => p.total).reduce((a, b) => a + b) /
                    partidas.length
              : 0;
          final mejor = partidas.isNotEmpty
              ? partidas.map((p) => p.total).reduce((a, b) => a > b ? a : b)
              : 0;
          final peor = partidas.isNotEmpty
              ? partidas.map((p) => p.total).reduce((a, b) => a < b ? a : b)
              : 0;


          // Spots y fechas SOLO en la primera partida de cada sesión
          List<FlSpot> spotsEntrenamiento = [];
          List<FlSpot> spotsCompeticion = [];
          Map<int, String> fechasPrimeraPartida = {}; // índice -> fecha
          int idx = 0;
          for (var s in sesionesFiltradas) {
            for (int i = 0; i < s.partidas.length; i++) {
              var p = s.partidas[i];
              if (i == 0) {
                fechasPrimeraPartida[idx] = _formatearFechaCorta(p.fecha);
              }
              if (s.tipo == 'Entrenamiento') {
                spotsEntrenamiento.add(
                  FlSpot(idx.toDouble(), p.total.toDouble()),
                );
              } else if (s.tipo == 'Competición') {
                spotsCompeticion.add(
                  FlSpot(idx.toDouble(), p.total.toDouble()),
                );
              }
              idx++;
            }
          }

          final maxY = calcularMaxY(spotsEntrenamiento, spotsCompeticion);

          // Spots y fechas para la gráfica de sesiones (promedio por sesión)
          List<FlSpot> spotsSesiones = [];
          List<String> fechasSesiones = [];
          for (int i = 0; i < sesionesFiltradas.length; i++) {
            final s = sesionesFiltradas[i];
            if (s.partidas.isNotEmpty) {
              final promedio =
                  s.partidas.map((p) => p.total).reduce((a, b) => a + b) /
                  s.partidas.length;
              spotsSesiones.add(FlSpot(i.toDouble(), promedio));
              fechasSesiones.add(_formatearFechaCorta(s.fecha));
            }
          }
          final double maxYSesiones = spotsSesiones.isEmpty
              ? 50
              : ((spotsSesiones
                                    .map((e) => e.y)
                                    .reduce((a, b) => a > b ? a : b) +
                                10) /
                            50)
                        .ceil() *
                    50.0;
          final double maxYFinalSesiones = maxYSesiones > 300
              ? 300
              : maxYSesiones;

          final bool hayEntrenamiento = sesionesFiltradas.any(
            (s) => s.tipo == "Entrenamiento",
          );
          final bool hayCompeticion = sesionesFiltradas.any(
            (s) => s.tipo == "Competición",
          );

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _FiltroTipo(
                filtroTipo: _filtroTipo,
                onChanged: (valor) {
                  if (valor != null) setState(() => _filtroTipo = valor);
                },
              ),
              const SizedBox(height: 16),

            
              // KPIs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _KpiCard(
                      label: "Promedio",
                      value: promedio.toStringAsFixed(1),
                      icon: Icons.bar_chart_rounded,
                      color: Colors.blue[700]!,
                    ),
                    _KpiCard(
                      label: "Mejor partida",
                      value: "$mejor",
                      icon: Icons.emoji_events_rounded,
                      color: Colors.green[600]!,
                    ),
                    _KpiCard(
                      label: "Peor partida",
                      value: "$peor",
                      icon: Icons.sentiment_dissatisfied_rounded,
                      color: Colors.red[400]!,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- TÍTULO y LEYENDA para la gráfica de partidas ---
              Text(
                "Evolución de puntuación por partidas",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _LeyendaPartidas(
                mostrarEntrenamiento: hayEntrenamiento,
                mostrarCompeticion: hayCompeticion,
              ),
              const SizedBox(height: 8),

              // Gráfica principal (por partidas)
              SizedBox(
                height: 260,
                child: _EvolucionGrafica(
                  spotsEntrenamiento: spotsEntrenamiento,
                  spotsCompeticion: spotsCompeticion,
                  maxY: maxY,
                  fechasPrimeraPartida: fechasPrimeraPartida,
                ),
              ),

              // Separador visual
              const SizedBox(height: 28),
              Divider(color: Colors.grey, thickness: 0.5, height: 0),
              const SizedBox(height: 16),

              // --- TÍTULO y LEYENDA para la gráfica de sesiones ---
              Text(
                "Evolución promedio por sesión",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const _LeyendaSesiones(),
              const SizedBox(height: 8),

              SizedBox(
                height: 220,
                child: _EvolucionSesionesGrafica(
                  spots: spotsSesiones,
                  fechas: fechasSesiones,
                  maxY: maxYFinalSesiones,
                ),
              ),

              const SizedBox(height: 24),

              // Resumen
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Resumen rápido",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Sesiones analizadas: ${sesionesFiltradas.length}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(MdiIcons.bowling, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text('Partidas analizadas: ${partidas.length}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatearFechaCorta(DateTime fecha) {
    return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}";
  }
}

// Widget KPI Card igual que antes
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Agrupa partidas por día ---
Map<DateTime, int> contarPartidasPorDia(List<Sesion> sesiones) {
  final Map<DateTime, int> partidasPorDia = {};
  for (final sesion in sesiones) {
    for (final partida in sesion.partidas) {
      final soloDia = DateTime(
        partida.fecha.year,
        partida.fecha.month,
        partida.fecha.day,
      );
      partidasPorDia.update(soloDia, (count) => count + 1, ifAbsent: () => 1);
    }
  }
  return partidasPorDia;
}

// Widget de filtro separado
class _FiltroTipo extends StatelessWidget {
  final String filtroTipo;
  final ValueChanged<String?> onChanged;

  const _FiltroTipo({required this.filtroTipo, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.filter_alt_outlined, size: 22),
        const SizedBox(width: 8),
        const Text('Filtrar por tipo:'),
        const SizedBox(width: 14),
        DropdownButton<String>(
          value: filtroTipo,
          borderRadius: BorderRadius.circular(12),
          items: [
            'Todos',
            'Entrenamiento',
            'Competición',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// --- LEYENDAS DIFERENCIADAS ---
class _LeyendaPartidas extends StatelessWidget {
  final bool mostrarEntrenamiento;
  final bool mostrarCompeticion;

  const _LeyendaPartidas({
    this.mostrarEntrenamiento = true,
    this.mostrarCompeticion = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (mostrarEntrenamiento)
          _LeyendaItem(color: Colors.blue[700]!, label: 'Entrenamiento'),
        if (mostrarEntrenamiento && mostrarCompeticion)
          const SizedBox(width: 16),
        if (mostrarCompeticion)
          _LeyendaItem(color: Colors.green[600]!, label: 'Competición'),
      ],
    );
  }
}

class _LeyendaSesiones extends StatelessWidget {
  const _LeyendaSesiones();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LeyendaItem(color: Colors.indigo[700]!, label: 'Promedio por sesión'),
      ],
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LeyendaItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---- Gráfica de evolución de partidas ----
class _EvolucionGrafica extends StatelessWidget {
  final List<FlSpot> spotsEntrenamiento;
  final List<FlSpot> spotsCompeticion;
  final double maxY;
  final Map<int, String> fechasPrimeraPartida;

  const _EvolucionGrafica({
    required this.spotsEntrenamiento,
    required this.spotsCompeticion,
    required this.maxY,
    required this.fechasPrimeraPartida,
  });

  @override
  Widget build(BuildContext context) {
    if (spotsEntrenamiento.isEmpty && spotsCompeticion.isEmpty) {
      return Center(
        child: Text(
          "No hay datos suficientes para mostrar la gráfica.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            maxY: maxY,
            minY: 0,
            backgroundColor: Colors.transparent,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                tooltipRoundedRadius: 12,
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((spot) {
                    final int puntos = spot.y.toInt();
                    return LineTooltipItem(
                      'Puntuación: $puntos',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 50,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.blueGrey.withOpacity(0.12),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 50,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    int idx = value.toInt();
                    if (fechasPrimeraPartida.containsKey(idx)) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          fechasPrimeraPartida[idx]!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  reservedSize: 36,
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: Colors.blueGrey.withOpacity(0.20),
                width: 2,
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spotsEntrenamiento,
                isCurved: true,
                color: Colors.blue[700],
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: Colors.blue[700]!,
                      ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue[700]!.withOpacity(0.09),
                ),
              ),
              LineChartBarData(
                spots: spotsCompeticion,
                isCurved: true,
                color: Colors.green[600],
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: Colors.green[600]!,
                      ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.green[600]!.withOpacity(0.09),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Gráfica de evolución por sesiones ----
class _EvolucionSesionesGrafica extends StatelessWidget {
  final List<FlSpot> spots;
  final List<String> fechas;
  final double maxY;

  const _EvolucionSesionesGrafica({
    required this.spots,
    required this.fechas,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return Center(
        child: Text(
          "No hay sesiones suficientes para mostrar la gráfica.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            maxY: maxY,
            minY: 0,
            backgroundColor: Colors.transparent,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.indigo.withOpacity(0.85),
                tooltipRoundedRadius: 12,
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((spot) {
                    final int puntos = spot.y.toInt();
                    return LineTooltipItem(
                      'Promedio: $puntos',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 50,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.blueGrey.withOpacity(0.12),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 50,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    int idx = value.toInt();
                    if (idx >= 0 && idx < fechas.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          fechas[idx],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  reservedSize: 36,
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: Colors.blueGrey.withOpacity(0.20),
                width: 2,
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.indigo[700],
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: Colors.indigo[700]!,
                      ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.indigo[700]!.withOpacity(0.09),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Utilidad para calcular maxY ---
double calcularMaxY(List<FlSpot> spots1, List<FlSpot> spots2) {
  final todos = [...spots1, ...spots2];
  if (todos.isEmpty) return 50; // valor mínimo
  final maxY = todos.map((e) => e.y).reduce((a, b) => a > b ? a : b);
  final ajustado = ((maxY + 10) / 50).ceil() * 50.0;
  return ajustado > 300 ? 300 : ajustado;
}
