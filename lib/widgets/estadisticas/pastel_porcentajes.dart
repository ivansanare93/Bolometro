import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';

class PastelPorcentajes extends StatelessWidget {
  const PastelPorcentajes({
    super.key,
    required this.porcentajeStrikes,
    required this.porcentajeSpares,
    required this.porcentajeFallos,
  });
  final double porcentajeStrikes;
  final double porcentajeSpares;
  final double porcentajeFallos;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final values = [
      (l.strikes, porcentajeStrikes, Colors.blue[700]!),
      (l.spares, porcentajeSpares, Colors.green[600]!),
      (l.misses, porcentajeFallos, Colors.red[400]!),
    ];
    return RepaintBoundary(
      child: Column(
        children: [
          if (values.any((e) => e.$2 > 0))
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: [
                    for (final e in values)
                      PieChartSectionData(
                        color: e.$3,
                        value: e.$2,
                        title: '',
                        radius: 50,
                      ),
                  ],
                ),
              ),
            ),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final e in values)
                Text(
                  '${e.$1}: ${e.$2.toStringAsFixed(1)}%',
                  style: TextStyle(color: e.$3, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
