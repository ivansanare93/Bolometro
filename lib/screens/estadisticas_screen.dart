import 'package:flutter/material.dart';
import '../models/sesion.dart';
import '../utils/database_utils.dart';
import 'package:fl_chart/fl_chart.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  late Future<List<Sesion>> _sesionesFuture;

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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              const Icon(Icons.info_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Todavía no has registrado sesiones.\n¡Empieza una para ver tus estadísticas!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/registro');
                },
                icon: const Icon(Icons.add),
                label: const Text('Registrar primera sesión'),
              ),
            ],
              ),
            );
          }

          final sesiones = snapshot.data!;
          final partidas = sesiones.expand((s) => s.partidas).toList();

          final promedio = partidas.isNotEmpty
              ? partidas.map((p) => p.total).reduce((a, b) => a + b) /
                  partidas.length
              : 0;

          final promedioPorTipo = <String, List<int>>{};
          for (var s in sesiones) {
            promedioPorTipo.putIfAbsent(s.tipo, () => []);
            promedioPorTipo[s.tipo]!.addAll(s.partidas.map((p) => p.total));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promedio general: ${promedio.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                if (promedioPorTipo.isNotEmpty)
                  SizedBox(
                    height: 220,
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
                                final tipo = promedioPorTipo.keys
                                    .elementAt(value.toInt());
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    tipo,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles:
                              AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles:
                              AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(promedioPorTipo.length, (i) {
                          final tipo = promedioPorTipo.keys.elementAt(i);
                          final valores = promedioPorTipo[tipo]!;
                          final prom = valores.reduce((a, b) => a + b) / valores.length;

                          return BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                              toY: prom,
                              color: colorPrimario,
                              width: 24,
                              borderRadius: BorderRadius.circular(4),
                            )
                          ]);
                        }),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  'Total de sesiones: ${sesiones.length}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Total de partidas: ${partidas.length}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
