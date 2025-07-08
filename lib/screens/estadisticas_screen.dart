import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sesion.dart';
import '../utils/database_utils.dart';
import '../utils/ui_herlpers.dart';
import 'home_screen.dart';

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
      appBar: AppBar(title: const Text('Estadísticas')),
      body: FutureBuilder<List<Sesion>>(
        future: _sesionesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Aún no hay sesiones registradas.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final sesiones = snapshot.data!;
          final sesionesFiltradas = _filtroTipo == 'Todos'
              ? sesiones
              : sesiones.where((s) => s.tipo == _filtroTipo).toList();

          final partidas = sesionesFiltradas.expand((s) => s.partidas).toList();

          if (partidas.isEmpty) {
            return const Center(
              child: Text('No hay partidas para el filtro seleccionado.'),
            );
          }

          final promedio =
              partidas.map((p) => p.total).reduce((a, b) => a + b) /
              partidas.length;
          final mejor = partidas
              .map((p) => p.total)
              .reduce((a, b) => a > b ? a : b);
          final peor = partidas
              .map((p) => p.total)
              .reduce((a, b) => a < b ? a : b);

          List<FlSpot> spotsEntrenamiento = [];
          List<FlSpot> spotsCompeticion = [];
          int index = 0;

          for (var s in sesionesFiltradas) {
            for (var p in s.partidas) {
              if (p.tipo == 'Entrenamiento') {
                spotsEntrenamiento.add(
                  FlSpot(index.toDouble(), p.total.toDouble()),
                );
              } else if (p.tipo == 'Competición') {
                spotsCompeticion.add(
                  FlSpot(index.toDouble(), p.total.toDouble()),
                );
              }
              index++;
            }
          }

          final maxY =
              300.0; // Valor máximo fijo ya que no se puede superar 300

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Filtrar por tipo:'),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _filtroTipo,
                      items: ['Todos', 'Entrenamiento', 'Competición']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (valor) {
                        if (valor != null) {
                          setState(() {
                            _filtroTipo = valor;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Promedio: ${promedio.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  'Mejor partida: $mejor',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Peor partida: $peor',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Text(
                  'Evolución de puntuaciones',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: LineChart(
                    LineChartData(
                      maxY: maxY,
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 50,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                value.toInt().toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(show: true, horizontalInterval: 50),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spotsEntrenamiento,
                          isCurved: true,
                          color: colorTipoSesion('Entrenamiento', context),
                          barWidth: 2,
                          dotData: FlDotData(show: true),
                        ),
                        LineChartBarData(
                          spots: spotsCompeticion,
                          isCurved: true,
                          color: colorTipoSesion('Competición', context),
                          barWidth: 2,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: colorTipoSesion('Entrenamiento', context),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    const Text('Entrenamiento'),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.circle,
                      color: colorTipoSesion('Competición', context),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    const Text('Competición'),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Sesiones analizadas: ${sesionesFiltradas.length}'),
                Text('Partidas analizadas: ${partidas.length}'),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        },
        tooltip: 'Inicio',
        child: const Icon(Icons.home),
      ),
    );
  }
}
