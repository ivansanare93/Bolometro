import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MiniGraficoPromedioMovil extends StatelessWidget {
  final List<double> promedios;

  const MiniGraficoPromedioMovil({super.key, required this.promedios});

  @override
  Widget build(BuildContext context) {
    if (promedios.isEmpty) {
      return const Text(
        "No hay suficientes datos para mostrar la evolución móvil.",
        style: TextStyle(fontSize: 13),
      );
    }

    final colorLinea = Theme.of(context).brightness == Brightness.dark
        ? Colors.cyanAccent
        : Colors.indigo;
    final colorDegrade = Theme.of(context).brightness == Brightness.dark
        ? Colors.cyanAccent.withOpacity(0.22)
        : Colors.indigo.withOpacity(0.16);

    final minValor = promedios.reduce((a, b) => a < b ? a : b);
    final maxValor = promedios.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        // Leyenda limpia para Mín y Máx arriba del gráfico
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 0, top: 2),
          child: Row(
            children: [
              Text(
                "Máx: ${maxValor.toStringAsFixed(1)}",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorLinea,
                ),
              ),
              const SizedBox(width: 24),
              Text(
                "Mín: ${minValor.toStringAsFixed(1)}",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorLinea.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 78,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 4,
              right: 12,
              top: 0,
              bottom: 0,
            ),
            child: LineChart(
              LineChartData(
                minY: minValor - 6,
                maxY: maxValor + 6,
                titlesData: FlTitlesData(
                  show: false, // Ocultamos todos los ejes y ticks
                ),
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
                    color: colorLinea,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: colorDegrade),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Último valor destacado a la derecha
        Padding(
          padding: const EdgeInsets.only(right: 18, top: 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Última: ${promedios.last.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colorLinea,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
