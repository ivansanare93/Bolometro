import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PastelPorcentajes extends StatelessWidget {
  final double porcentajeStrikes;
  final double porcentajeSpares;
  final double porcentajeFallos;

  const PastelPorcentajes({
    super.key,
    required this.porcentajeStrikes,
    required this.porcentajeSpares,
    required this.porcentajeFallos,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 34,
          sections: [
            PieChartSectionData(
              color: Colors.blue[700],
              value: porcentajeStrikes,
              title: 'Strikes\n${porcentajeStrikes.toStringAsFixed(1)}%',
              radius: 42,
              titleStyle: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            PieChartSectionData(
              color: Colors.green[600],
              value: porcentajeSpares,
              title: 'Spares\n${porcentajeSpares.toStringAsFixed(1)}%',
              radius: 39,
              titleStyle: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            PieChartSectionData(
              color: Colors.red[400],
              value: porcentajeFallos,
              title: 'Fallos\n${porcentajeFallos.toStringAsFixed(1)}%',
              radius: 37,
              titleStyle: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
