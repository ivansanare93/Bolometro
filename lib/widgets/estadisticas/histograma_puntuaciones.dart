import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HistogramaPuntuaciones extends StatelessWidget {
  final Map<String, int> histograma;

  const HistogramaPuntuaciones({super.key, required this.histograma});

  @override
  Widget build(BuildContext context) {
    final keys = histograma.keys.toList()..sort();
    return RepaintBoundary(
      child: SizedBox(
        height: 130,
        child: BarChart(
          BarChartData(
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < keys.length) {
                      return Text(keys[idx], style: const TextStyle(fontSize: 11));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: [
              for (var i = 0; i < keys.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: histograma[keys[i]]!.toDouble(),
                      color: Colors.blue[400],
                      width: 14,
                    )
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
