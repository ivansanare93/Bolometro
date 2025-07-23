import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MiniGraficoPromedioMovil extends StatelessWidget {
  final List<double> promedios;

  const MiniGraficoPromedioMovil({super.key, required this.promedios});

  @override
  Widget build(BuildContext context) {
    if (promedios.isEmpty) {
      return const Text("No hay suficientes datos para mostrar la evolución móvil.");
    }
    return SizedBox(
      height: 80,
      child: LineChart(
        LineChartData(
          maxY: promedios.reduce((a, b) => a > b ? a : b) + 10,
          minY: promedios.reduce((a, b) => a < b ? a : b) - 10,
          titlesData: FlTitlesData(show: false),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: promedios
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: Colors.indigo,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
