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
    return RepaintBoundary(
      child: SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 30,
            sections: [
              PieChartSectionData(
                color: Colors.blue[700],
                value: porcentajeStrikes,
                title: '${porcentajeStrikes.toStringAsFixed(1)}%',
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                badgeWidget: _buildBadge(
                  'Strikes',
                  Colors.blue[700]!,
                ),
                badgePositionPercentageOffset: 1.4,
              ),
              PieChartSectionData(
                color: Colors.green[600],
                value: porcentajeSpares,
                title: '${porcentajeSpares.toStringAsFixed(1)}%',
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                badgeWidget: _buildBadge(
                  'Spares',
                  Colors.green[600]!,
                ),
                badgePositionPercentageOffset: 1.4,
              ),
              PieChartSectionData(
                color: Colors.red[400],
                value: porcentajeFallos,
                title: '${porcentajeFallos.toStringAsFixed(1)}%',
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                badgeWidget: _buildBadge(
                  'Fallos',
                  Colors.red[400]!,
                ),
                badgePositionPercentageOffset: 1.4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
