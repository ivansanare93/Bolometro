import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:bolometro/models/sesion.dart';
import '../l10n/app_localizations.dart';

class MapaCalorGitHub extends StatelessWidget {
  final Map<DateTime, int> partidasPorDia;

  const MapaCalorGitHub({super.key, required this.partidasPorDia});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hoy = DateTime.now();
    final firstDay = hoy.subtract(const Duration(days: 365));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.heatmap,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        HeatMapCalendar(
          datasets: partidasPorDia,
          colorMode: ColorMode.color,
          colorsets: const {
            1: Color(0xFFBBDEFB),
            3: Color(0xFF64B5F6),
            5: Color(0xFF1976D2),
          },
          borderRadius: 8,
          size: 22,
          showColorTip: false,
          margin: const EdgeInsets.symmetric(vertical: 8),
          initDate: firstDay,
          onClick: (date) {
            final count = partidasPorDia[date] ?? 0;
            if (count > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${date.day}/${date.month}/${date.year}: ${l10n.gamesCount(count)}',
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _LeyendaItem(color: const Color(0xFFBBDEFB), label: l10n.heatmap1Game),
            const SizedBox(width: 8),
            _LeyendaItem(color: const Color(0xFF64B5F6), label: l10n.heatmap3Games),
            const SizedBox(width: 8),
            _LeyendaItem(color: const Color(0xFF1976D2), label: l10n.heatmap5Games),
          ],
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LeyendaItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

Map<DateTime, int> contarPartidasPorDia(List<Sesion> sesiones) {
  final Map<DateTime, int> partidasPorDia = {};
  for (final sesion in sesiones) {
    for (final partida in sesion.partidas) {
      // Use partida.fecha if available, otherwise fall back to sesion.fecha
      final fecha = partida.fecha ?? sesion.fecha;
      final soloDia = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
      );
      partidasPorDia.update(soloDia, (count) => count + 1, ifAbsent: () => 1);
    }
  }
  return partidasPorDia;
}
