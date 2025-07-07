import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
    final colorPrimario = Theme.of(context).colorScheme.primary;
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

          final partidasPorTipo = {
            'Entrenamiento': partidas
                .where((p) => p.tipo == 'Entrenamiento')
                .toList(),
            'Competición': partidas
                .where((p) => p.tipo == 'Competición')
                .toList(),
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filtros
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
                      onChanged: (valor) =>
                          setState(() => _filtroTipo = valor!),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Métricas
                Text(
                  'Promedio: ${promedio.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  'Mejor partida: $mejor',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Peor partida: $peor',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),

                // Gráfico de barras por tipo
                Text(
                  'Promedio por tipo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 300,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final keys = partidasPorTipo.keys.toList();
                              if (value.toInt() >= keys.length)
                                return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  keys[value.toInt()],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(partidasPorTipo.length, (i) {
                        final tipo = partidasPorTipo.keys.elementAt(i);
                        final lista = partidasPorTipo[tipo]!;
                        final prom =
                            lista.map((p) => p.total).reduce((a, b) => a + b) /
                            lista.length;

                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: prom,
                              color: colorPrimario,
                              width: 24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Sesiones analizadas: ${sesionesFiltradas.length}'),
                Text('Partidas analizadas: ${partidas.length}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
