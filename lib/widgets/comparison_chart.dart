import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Widget para mostrar gráficos comparativos entre dos usuarios
class ComparisonBarChart extends StatelessWidget {
  final String user1Name;
  final String user2Name;
  final Map<String, double> user1Stats;
  final Map<String, double> user2Stats;
  final List<String> statKeys;
  final List<String> statLabels;
  final Color user1Color;
  final Color user2Color;

  const ComparisonBarChart({
    super.key,
    required this.user1Name,
    required this.user2Name,
    required this.user1Stats,
    required this.user2Stats,
    required this.statKeys,
    required this.statLabels,
    this.user1Color = Colors.blue,
    this.user2Color = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(user1Name, user1Color),
            const SizedBox(width: 24),
            _buildLegendItem(user2Name, user2Color),
          ],
        ),
        const SizedBox(height: 16),
        // Chart
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxValue() * 1.1,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final stat = statKeys[group.x.toInt()];
                    final value = rodIndex == 0
                        ? user1Stats[stat] ?? 0
                        : user2Stats[stat] ?? 0;
                    final userName = rodIndex == 0 ? user1Name : user2Name;
                    return BarTooltipItem(
                      '$userName\n${value.toStringAsFixed(1)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < statLabels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            statLabels[value.toInt()],
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 40,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: _buildBarGroups(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _getMaxValue() / 5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String name, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(statKeys.length, (index) {
      final stat = statKeys[index];
      final user1Value = user1Stats[stat] ?? 0;
      final user2Value = user2Stats[stat] ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: user1Value,
            color: user1Color,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: user2Value,
            color: user2Color,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 4,
      );
    });
  }

  double _getMaxValue() {
    double max = 0;
    for (final stat in statKeys) {
      final user1Value = user1Stats[stat] ?? 0;
      final user2Value = user2Stats[stat] ?? 0;
      if (user1Value > max) max = user1Value;
      if (user2Value > max) max = user2Value;
    }
    return max > 0 ? max : 100;
  }
}

/// Widget para mostrar gráfico de tendencia de puntuaciones comparativo
class ComparisonLineChart extends StatelessWidget {
  final String user1Name;
  final String user2Name;
  final List<double> user1Scores;
  final List<double> user2Scores;
  final Color user1Color;
  final Color user2Color;

  const ComparisonLineChart({
    super.key,
    required this.user1Name,
    required this.user2Name,
    required this.user1Scores,
    required this.user2Scores,
    this.user1Color = Colors.blue,
    this.user2Color = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(user1Name, user1Color),
            const SizedBox(width: 24),
            _buildLegendItem(user2Name, user2Color),
          ],
        ),
        const SizedBox(height: 16),
        // Chart
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() % 5 == 0 || value.toInt() == 0) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // User 1 line
                if (user1Scores.isNotEmpty)
                  LineChartBarData(
                    spots: user1Scores
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: user1Color,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: user1Color.withOpacity(0.1),
                    ),
                  ),
                // User 2 line
                if (user2Scores.isNotEmpty)
                  LineChartBarData(
                    spots: user2Scores
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: user2Color,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: user2Color.withOpacity(0.1),
                    ),
                  ),
              ],
              minY: 0,
              maxY: 300,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String name, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Widget para mostrar gráfico de pastel comparativo (strikes/spares/misses)
class ComparisonPieCharts extends StatelessWidget {
  final String user1Name;
  final String user2Name;
  final Map<String, double> user1Percentages;
  final Map<String, double> user2Percentages;

  const ComparisonPieCharts({
    super.key,
    required this.user1Name,
    required this.user2Name,
    required this.user1Percentages,
    required this.user2Percentages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                user1Name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieSections(user1Percentages),
                    centerSpaceRadius: 30,
                    sectionsSpace: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              Text(
                user2Name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieSections(user2Percentages),
                    centerSpaceRadius: 30,
                    sectionsSpace: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> percentages) {
    return [
      PieChartSectionData(
        value: percentages['strikes'] ?? 0,
        title: '${(percentages['strikes'] ?? 0).toStringAsFixed(0)}%',
        color: Colors.red,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: percentages['spares'] ?? 0,
        title: '${(percentages['spares'] ?? 0).toStringAsFixed(0)}%',
        color: Colors.purple,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: percentages['fallos'] ?? 0,
        title: '${(percentages['fallos'] ?? 0).toStringAsFixed(0)}%',
        color: Colors.grey,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }
}
